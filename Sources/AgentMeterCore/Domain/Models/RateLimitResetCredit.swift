import Foundation

/// A single read-only Codex rate-limit reset credit returned by app-server.
///
/// The identifier and metadata are retained for future use, while the current
/// UI intentionally presents only a localized ordinal and expiration state.
public struct RateLimitResetCredit: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let resetType: String?
    public let status: String?
    public let grantedAt: Date?
    public let expiresAt: Date?
    public let title: String?
    public let description: String?

    public init(
        id: String,
        resetType: String? = nil,
        status: String? = nil,
        grantedAt: Date? = nil,
        expiresAt: Date? = nil,
        title: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.resetType = resetType
        self.status = status
        self.grantedAt = grantedAt
        self.expiresAt = expiresAt
        self.title = title
        self.description = description
    }

    /// Whether this cached detail has reached or passed its expiration time.
    /// The service-provided count is never changed by this local presentation state.
    public func isExpired(at date: Date = Date()) -> Bool {
        guard let expiresAt else { return false }
        return date >= expiresAt
    }
}
