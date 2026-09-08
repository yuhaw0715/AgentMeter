import Foundation

/// Represents a rate limit snapshot retrieved at a specific point in time.
public struct RateLimitSnapshot: Sendable, Codable, Equatable {
    public let provider: ProviderType
    public let fetchedAt: Date
    public let items: [RateLimitItem]
    public let accountEmail: String?
    public let accountPlan: String?
    public let resetCredits: RateLimitResetCredits?
    public let antigravityAICredits: AntigravityAICredits?

    public init(
        provider: ProviderType,
        fetchedAt: Date = Date(),
        items: [RateLimitItem],
        accountEmail: String? = nil,
        accountPlan: String? = nil,
        resetCredits: RateLimitResetCredits? = nil,
        antigravityAICredits: AntigravityAICredits? = nil
    ) {
        self.provider = provider
        self.fetchedAt = fetchedAt
        self.items = items
        self.accountEmail = accountEmail
        self.accountPlan = accountPlan
        self.resetCredits = resetCredits
        self.antigravityAICredits = antigravityAICredits
    }

    /// Helper to find a specific limit item by id.
    public func item(withId id: String) -> RateLimitItem? {
        return items.first { $0.id == id }
    }
}
