import Foundation

/// Availability of Google AI Credits as reported by the official Antigravity
/// CLI. A known zero balance is represented by `.available`, not `.unknown`.
public enum AntigravityAICreditsStatus: String, Sendable, Codable, Equatable {
    case available
    case unsupportedPlan
    case cliFieldUnavailable
    case unknown
}

/// Read-only AI Credits information observed alongside an Antigravity quota
/// snapshot. AgentMeter never purchases, enables, or consumes these credits.
public struct AntigravityAICredits: Sendable, Codable, Equatable {
    public let status: AntigravityAICreditsStatus
    public let availableCount: Int?
    public let observedAt: Date

    public init(
        status: AntigravityAICreditsStatus,
        availableCount: Int? = nil,
        observedAt: Date = Date()
    ) {
        self.status = status
        self.availableCount = availableCount.map { max(0, $0) }
        self.observedAt = observedAt
    }

    public static func available(_ count: Int, observedAt: Date = Date()) -> Self {
        Self(status: .available, availableCount: count, observedAt: observedAt)
    }

    public static func cliFieldUnavailable(observedAt: Date = Date()) -> Self {
        Self(status: .cliFieldUnavailable, observedAt: observedAt)
    }
}
