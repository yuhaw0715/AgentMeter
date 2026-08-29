import Foundation

/// Represents a single normalized rate limit metric item.
public struct RateLimitItem: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let usedPercentage: Double
    public let resetAt: Date?
    public let rawLimit: Double?
    public let rawUsed: Double?
    public let rawRemaining: Double?
    public let statusDescription: String?

    public init(
        id: String,
        name: String,
        usedPercentage: Double,
        resetAt: Date? = nil,
        rawLimit: Double? = nil,
        rawUsed: Double? = nil,
        rawRemaining: Double? = nil,
        statusDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.usedPercentage = max(0.0, min(100.0, usedPercentage))
        self.resetAt = resetAt
        self.rawLimit = rawLimit
        self.rawUsed = rawUsed
        self.rawRemaining = rawRemaining
        self.statusDescription = statusDescription
    }

    /// Integer used percentage rounded for clean UI display.
    public var usedPercentageInt: Int {
        return Int(usedPercentage.rounded())
    }

    /// Integer remaining percentage (0 to 100).
    public var remainingPercentageInt: Int {
        return max(0, 100 - usedPercentageInt)
    }

    /// Progress ratio for UI progress indicators (0.0 to 1.0).
    public var progressRatio: Double {
        return usedPercentage / 100.0
    }

    /// Indicates whether the limit is fully exhausted.
    public var isLimitReached: Bool {
        return usedPercentageInt >= 100
    }

    /// Indicates whether a reset timestamp is available.
    public var hasResetTime: Bool {
        return resetAt != nil
    }
}
