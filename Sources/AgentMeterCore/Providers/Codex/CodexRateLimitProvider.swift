import Foundation

/// Provider implementing quota monitoring for ChatGPT Codex.
public final class CodexRateLimitProvider: AgentProvider, Sendable {
    public let providerType: ProviderType = .codex
    private let environmentDetector: CodexEnvironmentDetector
    private let transportOverride: (any CodexJSONRPCTransport)?

    public init(
        environmentDetector: CodexEnvironmentDetector = CodexEnvironmentDetector(),
        transport: (any CodexJSONRPCTransport)? = nil
    ) {
        self.environmentDetector = environmentDetector
        self.transportOverride = transport
    }

    public func checkEnvironment() async -> EnvironmentStatus {
        return await environmentDetector.detectStatus()
    }

    public func fetchRateLimits() async throws -> RateLimitSnapshot {
        guard let transport = resolveTransport() else {
            throw CodexError.invalidExecutablePath
        }

        let response = try await transport.sendRequest(method: "account/rateLimits/read", params: nil, timeout: 10.0)
        return try parseRateLimits(from: response.dictionary)
    }

    private func resolveTransport() -> (any CodexJSONRPCTransport)? {
        if let transportOverride = transportOverride {
            return transportOverride
        }
        guard let execPath = environmentDetector.resolveExecutablePath() else {
            return nil
        }
        return CodexProcessManager(executablePath: execPath)
    }

    /// Dynamically parses any rate-limit JSON-RPC result payload into a normalized RateLimitSnapshot.
    public func parseRateLimits(from result: [String: Any]) throws -> RateLimitSnapshot {
        var items: [RateLimitItem] = []
        let accountEmail = result["email"] as? String ?? result["accountEmail"] as? String
        var accountPlan = result["plan"] as? String ?? result["accountPlan"] as? String

        // Case 1: Official Codex Structure (`rateLimits` object containing `primary` and `secondary`)
        if let rateLimitsObj = result["rateLimits"] as? [String: Any] {
            if let plan = rateLimitsObj["planType"] as? String {
                accountPlan = plan.capitalized
            }

            // Primary Window (e.g. 5-hour limit, 300 mins)
            if let primary = rateLimitsObj["primary"] as? [String: Any] {
                let durationMins = primary["windowDurationMins"] as? Int ?? 300
                let name = durationMins == 300 ? "5-Hour Session Limit" : "\(durationMins / 60)-Hour Limit"
                if let item = parseSingleLimitDict(primary, fallbackId: "codex_primary", fallbackName: name) {
                    items.append(item)
                }
            }

            // Secondary Window (e.g. Weekly limit, 10080 mins)
            if let secondary = rateLimitsObj["secondary"] as? [String: Any] {
                let durationMins = secondary["windowDurationMins"] as? Int ?? 10080
                let name = durationMins == 10080 ? "Weekly Limit" : "\(durationMins / 1440)-Day Limit"
                if let item = parseSingleLimitDict(secondary, fallbackId: "codex_secondary", fallbackName: name) {
                    items.append(item)
                }
            }
        }

        // Case 2: Array of limits (e.g. rateLimits / rate_limits / limits)
        if items.isEmpty, let limitsArray = (result["rateLimits"] ?? result["rate_limits"] ?? result["limits"]) as? [[String: Any]] {
            for (index, dict) in limitsArray.enumerated() {
                if let item = parseSingleLimitDict(dict, fallbackId: "limit_\(index + 1)", fallbackName: "Limit \(index + 1)") {
                    items.append(item)
                }
            }
        }

        // Case 3: Dictionary of key-value limit blocks (e.g. fiveHourLimit: {...}, weeklyLimit: {...})
        if items.isEmpty {
            for (key, value) in result {
                // This is a separate summary object, not a quota limit block.
                if key == "rateLimitResetCredits" {
                    continue
                }
                if let subDict = value as? [String: Any] {
                    if let item = parseSingleLimitDict(subDict, fallbackId: key, fallbackName: formatKeyAsTitle(key)) {
                        items.append(item)
                    }
                }
            }
        }

        // Case 4: Flat percentage keys (e.g. { "5h_used_percent": 30, "weekly_used_percent": 80 })
        if items.isEmpty {
            for (key, value) in result {
                if let num = value as? NSNumber, key.lowercased().contains("percent") || key.lowercased().contains("usage") {
                    let formattedTitle = formatKeyAsTitle(key)
                    items.append(RateLimitItem(
                        id: key,
                        name: formattedTitle,
                        usedPercentage: num.doubleValue
                    ))
                }
            }
        }

        // Sort items logically (5-hour/hourly first, weekly second, then alphabetically)
        items.sort { itemA, itemB in
            let rankA = sortPriority(for: itemA.name)
            let rankB = sortPriority(for: itemB.name)
            if rankA != rankB {
                return rankA < rankB
            }
            return itemA.name < itemB.name
        }

        let resetCredits = parseResetCredits(from: result)

        return RateLimitSnapshot(
            provider: .codex,
            fetchedAt: Date(),
            items: items,
            accountEmail: accountEmail,
            accountPlan: accountPlan,
            resetCredits: resetCredits
        )
    }

    /// Parses the optional reset-credit portion without making the existing
    /// rate-limit payload path depend on the new field.
    private func parseResetCredits(from result: [String: Any]) -> RateLimitResetCredits? {
        guard let rawSummary = result["rateLimitResetCredits"],
              !(rawSummary is NSNull),
              let summary = rawSummary as? [String: Any],
              let availableCount = parseInteger(summary["availableCount"]) else {
            return nil
        }

        let credits: [RateLimitResetCredit]?
        if let rawCredits = summary["credits"] {
            if rawCredits is NSNull {
                credits = nil
            } else if let rawCreditArray = rawCredits as? [Any] {
                credits = rawCreditArray.enumerated().compactMap { _, rawCredit in
                    guard let credit = rawCredit as? [String: Any],
                          let id = credit["id"] as? String,
                          !id.isEmpty else {
                        return nil
                    }

                    return RateLimitResetCredit(
                        id: id,
                        resetType: credit["resetType"] as? String,
                        status: credit["status"] as? String,
                        grantedAt: parseDate(credit["grantedAt"]),
                        expiresAt: parseDate(credit["expiresAt"]),
                        title: credit["title"] as? String,
                        description: credit["description"] as? String
                    )
                }
            } else {
                // A malformed collection is treated as unavailable detail,
                // while the authoritative total remains usable.
                credits = nil
            }
        } else {
            credits = nil
        }

        return RateLimitResetCredits(availableCount: availableCount, credits: credits)
    }

    private func parseInteger(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber else { return nil }
        return number.intValue
    }

    private func parseDate(_ value: Any?) -> Date? {
        if let date = value as? Date {
            return date
        }

        if let string = value as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: string) ?? ISO8601DateFormatter().date(from: string)
        }

        if let number = value as? NSNumber {
            let timestamp = number.doubleValue
            guard timestamp > 0 else { return nil }
            return Date(timeIntervalSince1970: timestamp > 10_000_000_000 ? timestamp / 1000.0 : timestamp)
        }

        return nil
    }

    private func parseSingleLimitDict(_ dict: [String: Any], fallbackId: String, fallbackName: String) -> RateLimitItem? {
        let id = dict["id"] as? String ?? dict["name"] as? String ?? fallbackId
        let name = dict["title"] as? String ?? dict["displayName"] as? String ?? dict["name"] as? String ?? fallbackName

        // Extract usage percentage
        var usedPercentage: Double = 0.0
        if let usedPercent = (dict["usedPercent"] ?? dict["used_percent"] ?? dict["percentage"] ?? dict["usagePercent"]) as? NSNumber {
            usedPercentage = usedPercent.doubleValue
        } else if let usedRatio = (dict["usedRatio"] ?? dict["ratio"]) as? NSNumber {
            usedPercentage = usedRatio.doubleValue * 100.0
        } else if let used = (dict["used"] ?? dict["current"] ?? dict["consumed"]) as? NSNumber,
                  let limit = (dict["limit"] ?? dict["total"] ?? dict["max"]) as? NSNumber,
                  limit.doubleValue > 0 {
            usedPercentage = (used.doubleValue / limit.doubleValue) * 100.0
        }

        // Extract reset timestamp
        var resetAt: Date? = nil
        if let resetStr = (dict["resetsAt"] ?? dict["reset_at"] ?? dict["resetTime"] ?? dict["resets_at"]) as? String {
            resetAt = ISO8601DateFormatter().date(from: resetStr)
        } else if let resetUnix = (dict["resetsAt"] ?? dict["reset_at"] ?? dict["resetTimestamp"] ?? dict["resets_at_timestamp"]) as? NSNumber {
            let val = resetUnix.doubleValue
            // Detect milliseconds vs seconds
            if val > 10_000_000_000 {
                resetAt = Date(timeIntervalSince1970: val / 1000.0)
            } else if val > 0 {
                resetAt = Date(timeIntervalSince1970: val)
            }
        } else if let resetInSec = (dict["resetsInSeconds"] ?? dict["resets_in_seconds"] ?? dict["expiresIn"]) as? NSNumber {
            resetAt = Date().addingTimeInterval(resetInSec.doubleValue)
        }

        let rawLimit = (dict["limit"] ?? dict["total"]) as? NSNumber
        let rawUsed = (dict["used"] ?? dict["current"]) as? NSNumber
        let rawRemaining = (dict["remaining"] ?? dict["available"]) as? NSNumber
        let statusDesc = dict["status"] as? String

        return RateLimitItem(
            id: id,
            name: name,
            usedPercentage: usedPercentage,
            resetAt: resetAt,
            rawLimit: rawLimit?.doubleValue,
            rawUsed: rawUsed?.doubleValue,
            rawRemaining: rawRemaining?.doubleValue,
            statusDescription: statusDesc
        )
    }

    private func formatKeyAsTitle(_ key: String) -> String {
        return key
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func sortPriority(for title: String) -> Int {
        let lower = title.lowercased()
        if lower.contains("5") || lower.contains("hour") || lower.contains("session") || lower.contains("primary") {
            return 1
        }
        if lower.contains("day") || lower.contains("daily") {
            return 2
        }
        if lower.contains("week") || lower.contains("weekly") || lower.contains("secondary") {
            return 3
        }
        if lower.contains("month") || lower.contains("monthly") {
            return 4
        }
        return 10
    }
}
