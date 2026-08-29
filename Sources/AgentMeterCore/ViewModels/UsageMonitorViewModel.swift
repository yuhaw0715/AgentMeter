import Foundation
import Observation

/// Coordinates application state, quota fetching, caching, and environment diagnostics.
@Observable
@MainActor
public final class UsageMonitorViewModel {
    public var selectedProvider: ProviderType = .codex
    public var currentSnapshot: RateLimitSnapshot?
    public var environmentStatus: EnvironmentStatus = .healthy
    public var isRefreshing: Bool = false
    public var lastError: String?
    public var lastRefreshTime: Date?
    public var selectedLimitVersion: Int = 0

    public let cacheManager: SmartCacheManager
    public let settingsManager: SettingsManager
    private let provider: any AgentProvider

    public init(
        provider: (any AgentProvider)? = nil,
        cacheManager: SmartCacheManager = .shared,
        settingsManager: SettingsManager = .shared
    ) {
        self.provider = provider ?? CodexRateLimitProvider(
            environmentDetector: CodexEnvironmentDetector(
                customExecutablePath: settingsManager.customCodexPath.isEmpty ? nil : settingsManager.customCodexPath
            )
        )
        self.cacheManager = cacheManager
        self.settingsManager = settingsManager
        self.currentSnapshot = cacheManager.currentSnapshot
    }

    /// Visible limits filtered according to user preferences.
    public var visibleLimits: [RateLimitItem] {
        _ = selectedLimitVersion
        guard let snapshot = currentSnapshot else { return [] }
        return settingsManager.resolveVisibleLimits(from: snapshot.items)
    }

    /// Checks if a specific limit ID is currently enabled for Menu Bar.
    public func isLimitVisible(id: String) -> Bool {
        _ = selectedLimitVersion
        if !settingsManager.hasCustomizedLimits {
            return true
        }
        return settingsManager.selectedLimitIds.contains(id)
    }

    /// Toggles or sets a limit ID's visibility for Menu Bar and triggers instant reactive updates.
    public func setLimitVisibility(id: String, isVisible: Bool, allItems: [RateLimitItem]) {
        if !settingsManager.hasCustomizedLimits {
            settingsManager.selectedLimitIds = allItems.map { $0.id }
        }

        var current = Set(settingsManager.selectedLimitIds)
        if isVisible {
            current.insert(id)
        } else {
            current.remove(id)
        }
        settingsManager.selectedLimitIds = Array(current)
        selectedLimitVersion += 1
    }

    /// Restores automatic default visibility for all limits.
    public func restoreDefaultLimits() {
        settingsManager.restoreAutomaticDefaults()
        selectedLimitVersion += 1
    }

    /// Evaluates current environment status.
    public func checkEnvironment() async {
        let status = await provider.checkEnvironment()
        self.environmentStatus = status
    }

    /// Active refresh triggered by Desktop app opening or manual trigger.
    public func refreshDesktop() async {
        await executeFetch(bypassCache: true)
    }

    /// Menu Bar refresh utilizing Smart Cache unless expired or forced.
    public func refreshMenuBar(force: Bool = false) async {
        if !force {
            if let fresh = cacheManager.getFreshSnapshot(ttl: settingsManager.cacheTTLSeconds) {
                self.currentSnapshot = fresh
                self.lastError = nil
                return
            }
        }
        await executeFetch(bypassCache: force)
    }

    /// Retry action when a previous refresh encountered an error.
    public func retry() async {
        await executeFetch(bypassCache: true)
    }

    private func executeFetch(bypassCache: Bool) async {
        guard !isRefreshing else { return }

        isRefreshing = true
        lastError = nil

        await checkEnvironment()
        guard environmentStatus.isReady else {
            isRefreshing = false
            return
        }

        do {
            let snapshot = try await provider.fetchRateLimits()
            self.currentSnapshot = snapshot
            self.lastRefreshTime = snapshot.fetchedAt
            self.cacheManager.store(snapshot)
            self.lastError = nil
        } catch {
            // When refresh fails, invalidate cache to avoid presenting stale data as current
            self.cacheManager.invalidate()
            self.lastError = error.localizedDescription
        }

        isRefreshing = false
    }
}
