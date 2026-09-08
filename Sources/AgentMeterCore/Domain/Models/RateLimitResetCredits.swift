import Foundation

/// The normalized Codex reset-credit summary.
///
/// `credits == nil` means the service returned a known total but did not
/// provide detail rows. An empty array means details were provided and there
/// are no detail rows, which is intentionally distinct from `nil`.
public struct RateLimitResetCredits: Sendable, Codable, Equatable, Hashable {
    public let availableCount: Int
    public let credits: [RateLimitResetCredit]?

    public init(availableCount: Int, credits: [RateLimitResetCredit]? = nil) {
        self.availableCount = max(0, availableCount)
        guard let credits else {
            self.credits = nil
            return
        }

        // Keep the service order for equal expiration dates while putting the
        // earliest known expiration first and undated credits last.
        self.credits = credits.enumerated()
            .sorted { lhs, rhs in
                switch (lhs.element.expiresAt, rhs.element.expiresAt) {
                case let (left?, right?):
                    if left != right { return left < right }
                    return lhs.offset < rhs.offset
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }

    /// Whether the response included a detail collection (including an empty one).
    public var detailsProvided: Bool {
        credits != nil
    }

    /// Number of credits represented by the authoritative count but absent from
    /// the supplied detail rows. A nil value means the detail collection itself
    /// was not provided, so no difference can be calculated.
    public var missingDetailCount: Int? {
        guard let credits else { return nil }
        return max(availableCount - credits.count, 0)
    }

    /// Whether the service explicitly reported that no credits are available.
    public var isKnownZero: Bool {
        availableCount == 0 && credits?.isEmpty == true
    }
}
