import Foundation

/// Detects and verifies the local Google Antigravity CLI (agy) environment.
public struct AntigravityEnvironmentDetector: Sendable {
    public let customExecutablePath: String?
    public static let minimumRequiredVersion = "1.1.11"

    public static let commonPaths = [
        "~/.local/bin/agy",
        "/opt/homebrew/bin/agy",
        "/usr/local/bin/agy",
        "~/.cargo/bin/agy",
        "/usr/bin/agy",
        "/bin/agy"
    ]

    public init(customExecutablePath: String? = nil) {
        self.customExecutablePath = customExecutablePath
    }

    /// Resolves the absolute path to the agy binary based on custom path, standard locations, and system PATH.
    public func resolveExecutablePath() -> String? {
        let fileManager = FileManager.default

        // 1. Check custom path if provided
        if let custom = customExecutablePath?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            let expanded = NSString(string: custom).expandingTildeInPath
            if fileManager.isExecutableFile(atPath: expanded) {
                return expanded
            }
        }

        // 2. Check standard common locations (priority: ~/.local/bin/agy first)
        for path in Self.commonPaths {
            let expanded = NSString(string: path).expandingTildeInPath
            if fileManager.isExecutableFile(atPath: expanded) {
                return expanded
            }
        }

        // 3. Search via PATH environment
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            for dir in pathEnv.split(separator: ":") {
                let candidate = (String(dir) as NSString).appendingPathComponent("agy")
                if fileManager.isExecutableFile(atPath: candidate) {
                    return candidate
                }
            }
        }

        return nil
    }

    /// Evaluates the environment readiness and version compatibility.
    public func detectStatus() async -> EnvironmentStatus {
        guard let execPath = resolveExecutablePath() else {
            return .cliMissing(expectedPath: customExecutablePath?.isEmpty == false ? customExecutablePath! : "~/.local/bin/agy")
        }

        // Check if executable runs and report version
        let (output, exitCode) = await runProcess(executable: execPath, arguments: ["--version"], timeout: 3.0)
        guard exitCode == 0 else {
            return .error(description: "Failed to execute agy binary at \(execPath): \(output)")
        }

        guard let version = Self.parseVersion(from: output) else {
            return .error(description: "Unable to parse agy version output: \(output)")
        }

        if !Self.isVersionSupported(version, minimumRequired: Self.minimumRequiredVersion) {
            return .unsupportedVersion(current: version, required: Self.minimumRequiredVersion)
        }

        return .healthy
    }

    /// Parses a semantic version string from CLI version output.
    public static func parseVersion(from output: String) -> String? {
        let pattern = #"\b(\d+)\.(\d+)\.(\d+)(?:-[\w\.\-]+)?\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let range = NSRange(output.startIndex..<output.endIndex, in: output)
        guard let match = regex.firstMatch(in: output, options: [], range: range),
              let matchRange = Range(match.range, in: output) else {
            return nil
        }
        return String(output[matchRange])
    }

    /// Compares two semantic version strings (major.minor.patch).
    public static func isVersionSupported(_ version: String, minimumRequired: String = minimumRequiredVersion) -> Bool {
        let cleanVersion = version.split(separator: "-").first.map(String.init) ?? version
        let cleanMin = minimumRequired.split(separator: "-").first.map(String.init) ?? minimumRequired

        let currentParts = cleanVersion.split(separator: ".").compactMap { Int($0) }
        let requiredParts = cleanMin.split(separator: ".").compactMap { Int($0) }

        guard currentParts.count >= 2, requiredParts.count >= 2 else {
            return false
        }

        let maxCount = max(currentParts.count, requiredParts.count)
        for i in 0..<maxCount {
            let curr = i < currentParts.count ? currentParts[i] : 0
            let req = i < requiredParts.count ? requiredParts[i] : 0

            if curr > req {
                return true
            } else if curr < req {
                return false
            }
        }
        return true
    }

    /// Helper to execute a short-lived process with timeout.
    private func runProcess(executable: String, arguments: [String], timeout: TimeInterval) async -> (output: String, exitCode: Int32) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()

                process.executableURL = URL(fileURLWithPath: executable)
                process.arguments = arguments
                process.standardOutput = pipe
                process.standardError = pipe

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
                        continuation.resume(returning: ("Process execution timed out", -1))
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

                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        let output = String(data: data, encoding: .utf8) ?? ""
                        continuation.resume(returning: (output.trimmingCharacters(in: .whitespacesAndNewlines), process.terminationStatus))
                    }
                } catch {
                    lock.withLock {
                        guard !hasResumed else { return }
                        hasResumed = true
                        timer.cancel()
                        continuation.resume(returning: (error.localizedDescription, -1))
                    }
                }
            }
        }
    }
}
