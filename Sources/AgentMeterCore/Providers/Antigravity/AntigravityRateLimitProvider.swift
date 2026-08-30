import Foundation

/// Protocol for running Antigravity CLI commands (enables unit testing).
public protocol AntigravityCommandRunner: Sendable {
    func runCommand(executable: String, arguments: [String], timeout: TimeInterval) async throws -> (output: String, exitCode: Int32)
}

/// Default subprocess command runner with hard timeout.
public final class DefaultAntigravityCommandRunner: AntigravityCommandRunner, Sendable {
    public init() {}

    public func runCommand(executable: String, arguments: [String], timeout: TimeInterval) async throws -> (output: String, exitCode: Int32) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()

                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                var hasResumed = false
                let lock = NSLock()

                let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
                timer.schedule(deadline: .now() + timeout)
                timer.setEventHandler {
                    lock.withLock {
                        guard !hasResumed else { return }
                        hasResumed = true
                        if process.isRunning {
                            process.terminate()
                        }
                        continuation.resume(throwing: AntigravityError.timeout)
                    }
                    timer.cancel()
                }
                timer.resume()

                do {
                    try process.run()
                    process.waitUntilExit()

                    lock.withLock {
                        guard !hasResumed else { return }
                        hasResumed = true
                        timer.cancel()

                        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                        let stdoutString = String(data: stdoutData, encoding: .utf8) ?? ""
                        let stderrString = String(data: stderrData, encoding: .utf8) ?? ""

                        let combinedOutput = stdoutString.isEmpty ? stderrString : stdoutString
                        continuation.resume(returning: (combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus))
                    }
                } catch {
                    lock.withLock {
                        guard !hasResumed else { return }
                        hasResumed = true
                        timer.cancel()
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

/// Provider implementing quota monitoring for Google Antigravity (Gemini Models).
public final class AntigravityRateLimitProvider: AgentProvider, Sendable {
    public let providerType: ProviderType = .antigravity
    private let environmentDetector: AntigravityEnvironmentDetector
    private let commandRunner: any AntigravityCommandRunner

    public init(
        environmentDetector: AntigravityEnvironmentDetector = AntigravityEnvironmentDetector(),
        commandRunner: any AntigravityCommandRunner = DefaultAntigravityCommandRunner()
    ) {
        self.environmentDetector = environmentDetector
        self.commandRunner = commandRunner
    }

    public func checkEnvironment() async -> EnvironmentStatus {
        return await environmentDetector.detectStatus()
    }

    public func fetchRateLimits() async throws -> RateLimitSnapshot {
        guard let execPath = environmentDetector.resolveExecutablePath() else {
            throw AntigravityError.cliMissing(path: environmentDetector.customExecutablePath ?? "~/.local/bin/agy")
        }

        let (output, exitCode) = try await commandRunner.runCommand(
            executable: execPath,
            arguments: ["-p", "/usage", "--output-format", "json"],
            timeout: 10.0
        )

        // Check for authentication or API key errors
        let lowerOutput = output.lowercased()
        if lowerOutput.contains("gemini_api_key") {
            throw AntigravityError.unsupportedAPIKeyMode
        }
        if lowerOutput.contains("not authenticated") ||
            lowerOutput.contains("please login") ||
            lowerOutput.contains("login required") ||
            lowerOutput.contains("no active session") ||
            lowerOutput.contains("unauthorized") {
            throw AntigravityError.notAuthenticated(message: output)
        }

        guard exitCode == 0 else {
            throw AntigravityError.processFailed(exitCode: exitCode, output: output)
        }

        return try parseRateLimits(from: output)
    }

    /// Parses the JSON output from `agy -p "/usage" --output-format json`
    public func parseRateLimits(from jsonString: String) throws -> RateLimitSnapshot {
        guard let data = jsonString.data(using: .utf8) else {
            throw AntigravityError.invalidOutput(details: "Unable to convert string to UTF-8 data")
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AntigravityError.invalidOutput(details: "JSON parsing failed")
        }

        return try parseRateLimits(from: jsonObject)
    }

    /// Parses the dictionary payload and extracts Gemini Models quota buckets.
    public func parseRateLimits(from rootDict: [String: Any]) throws -> RateLimitSnapshot {
        // Extract groups from root.command.data.groups OR root.groups OR root.data.groups
        var groups: [[String: Any]] = []

        if let command = rootDict["command"] as? [String: Any],
           let data = command["data"] as? [String: Any],
           let commandGroups = data["groups"] as? [[String: Any]] {
            groups = commandGroups
        } else if let data = rootDict["data"] as? [String: Any],
                  let dataGroups = data["groups"] as? [[String: Any]] {
            groups = dataGroups
        } else if let directGroups = rootDict["groups"] as? [[String: Any]] {
            groups = directGroups
        }

        var items: [RateLimitItem] = []
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standardIsoFormatter = ISO8601DateFormatter()
        standardIsoFormatter.formatOptions = [.withInternetDateTime]

        for group in groups {
            let groupName = (group["name"] as? String) ?? ""
            let lowerGroupName = groupName.lowercased()

            // Strict Filter: Must be Gemini Models group; exclude Claude, GPT, 3P, etc.
            guard lowerGroupName.contains("gemini") else {
                continue
            }

            guard let buckets = group["buckets"] as? [[String: Any]] else {
                continue
            }

            for (index, bucket) in buckets.enumerated() {
                // Ignore disabled buckets
                if let isDisabled = bucket["disabled"] as? Bool, isDisabled {
                    continue
                }
                if let status = bucket["status"] as? String, status.lowercased() == "disabled" {
                    continue
                }

                let id = bucket["id"] as? String ?? "gemini_bucket_\(index + 1)"
                let name = bucket["name"] as? String ?? "Gemini Quota \(index + 1)"
                let description = bucket["description"] as? String

                // Remaining fraction: e.g. 0.9878 -> 98.78% remaining -> 1.22% used
                var usedPercentage: Double = 0.0
                var remainingFraction: Double? = nil

                if let remFraction = (bucket["remaining_fraction"] ?? bucket["remainingFraction"]) as? NSNumber {
                    let fraction = remFraction.doubleValue
                    remainingFraction = fraction
                    usedPercentage = max(0.0, min(100.0, (1.0 - fraction) * 100.0))
                } else if let usedPercent = (bucket["usedPercent"] ?? bucket["used_percent"] ?? bucket["percentage"]) as? NSNumber {
                    usedPercentage = usedPercent.doubleValue
                }

                // Reset time parsing
                var resetAt: Date? = nil
                if let resetStr = (bucket["reset_time"] ?? bucket["resetTime"] ?? bucket["resets_at"]) as? String {
                    resetAt = standardIsoFormatter.date(from: resetStr) ?? isoFormatter.date(from: resetStr)
                }

                let item = RateLimitItem(
                    id: id,
                    name: name,
                    usedPercentage: usedPercentage,
                    resetAt: resetAt,
                    rawLimit: 1.0,
                    rawUsed: remainingFraction != nil ? (1.0 - remainingFraction!) : nil,
                    rawRemaining: remainingFraction,
                    statusDescription: description
                )
                items.append(item)
            }
        }

        // Sort logically: 5-hour first, weekly second, then alphabetically
        items.sort { itemA, itemB in
            let rankA = sortPriority(for: itemA.name, id: itemA.id)
            let rankB = sortPriority(for: itemB.name, id: itemB.id)
            if rankA != rankB {
                return rankA < rankB
            }
            return itemA.name < itemB.name
        }

        return RateLimitSnapshot(
            provider: .antigravity,
            fetchedAt: Date(),
            items: items,
            accountEmail: nil,
            accountPlan: nil
        )
    }

    private func sortPriority(for name: String, id: String) -> Int {
        let combined = "\(name) \(id)".lowercased()
        if combined.contains("5") || combined.contains("hour") || combined.contains("5h") {
            return 1
        }
        if combined.contains("day") || combined.contains("daily") {
            return 2
        }
        if combined.contains("week") || combined.contains("weekly") {
            return 3
        }
        return 10
    }
}
