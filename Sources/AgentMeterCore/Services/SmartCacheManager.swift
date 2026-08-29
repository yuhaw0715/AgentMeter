import Foundation

/// Manages rate limit snapshot caching with time-to-live (TTL) validation.
public final class SmartCacheManager: @unchecked Sendable {
    public static let shared = SmartCacheManager()

    private var cachedSnapshot: RateLimitSnapshot?
    private let lock = NSLock()

    public init(initialSnapshot: RateLimitSnapshot? = nil) {
        self.cachedSnapshot = initialSnapshot
    }

    /// Stores a new snapshot in the cache.
    public func store(_ snapshot: RateLimitSnapshot) {
        lock.withLock {
            self.cachedSnapshot = snapshot
        }
    }

    /// Returns the cached snapshot if it exists and has not exceeded the given TTL in seconds.
    public func getFreshSnapshot(ttl: TimeInterval, currentDate: Date = Date()) -> RateLimitSnapshot? {
        lock.withLock {
            guard let snapshot = cachedSnapshot else {
                return nil
            }
            let age = currentDate.timeIntervalSince(snapshot.fetchedAt)
            if age >= 0 && age <= ttl {
                return snapshot
            }
            return nil
        }
    }

    /// Checks if a cached snapshot exists regardless of expiration.
    public var currentSnapshot: RateLimitSnapshot? {
        lock.withLock { cachedSnapshot }
    }

    /// Invalidates the cache completely upon refresh failure or user reset.
    public func invalidate() {
        lock.withLock {
            self.cachedSnapshot = nil
        }
    }
}
