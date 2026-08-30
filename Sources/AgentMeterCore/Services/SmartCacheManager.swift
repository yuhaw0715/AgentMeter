import Foundation

/// Manages rate limit snapshot caching with time-to-live (TTL) validation per Provider.
public final class SmartCacheManager: @unchecked Sendable {
    public static let shared = SmartCacheManager()

    private var cache: [ProviderType: RateLimitSnapshot] = [:]
    private let lock = NSLock()

    public init(initialSnapshot: RateLimitSnapshot? = nil) {
        if let initial = initialSnapshot {
            self.cache[initial.provider] = initial
        }
    }

    /// Stores a new snapshot in the cache under its provider type.
    public func store(_ snapshot: RateLimitSnapshot) {
        lock.withLock {
            self.cache[snapshot.provider] = snapshot
        }
    }

    /// Returns the cached snapshot for a specific provider if it exists and has not exceeded TTL.
    public func getFreshSnapshot(for provider: ProviderType, ttl: TimeInterval, currentDate: Date = Date()) -> RateLimitSnapshot? {
        lock.withLock {
            guard let snapshot = cache[provider] else {
                return nil
            }
            let age = currentDate.timeIntervalSince(snapshot.fetchedAt)
            if age >= 0 && age <= ttl {
                return snapshot
            }
            return nil
        }
    }

    /// Legacy helper returning fresh snapshot for Codex (or first found).
    public func getFreshSnapshot(ttl: TimeInterval, currentDate: Date = Date()) -> RateLimitSnapshot? {
        return getFreshSnapshot(for: .codex, ttl: ttl, currentDate: currentDate)
    }

    /// Checks if a cached snapshot exists for a specific provider regardless of expiration.
    public func currentSnapshot(for provider: ProviderType) -> RateLimitSnapshot? {
        lock.withLock { cache[provider] }
    }

    /// Legacy helper returning the current snapshot for Codex.
    public var currentSnapshot: RateLimitSnapshot? {
        lock.withLock { cache[.codex] }
    }

    /// Invalidates the cache for a specific provider.
    public func invalidate(for provider: ProviderType) {
        lock.withLock {
            _ = self.cache.removeValue(forKey: provider)
        }
    }

    /// Invalidates all cached snapshots.
    public func invalidate() {
        lock.withLock {
            self.cache.removeAll()
        }
    }
}
