import Foundation
import Observation

/// Coordinates application state, multi-provider quota fetching, caching, and diagnostics.
@Observable
@MainActor
public final class UsageMonitorViewModel {
    public var selectedProvider: ProviderType = .codex
    public var snapshots: [ProviderType: RateLimitSnapshot] = [:]
    public var environmentStatuses: [ProviderType: EnvironmentStatus] = [:]
    public var refreshingProviders: Set<ProviderType> = []
    public var lastErrors: [ProviderType: String] = [:]
    public var lastRefreshTimes: [ProviderType: Date] = [:]
    public var selectedLimitVersion: Int = 0

    public let cacheManager: SmartCacheManager
    public let settingsManager: SettingsManager
    public let providerRegistry: ProviderRegistry

    public init(
        providerRegistry: ProviderRegistry = .shared,
        provider: (any AgentProvider)? = nil,
        cacheManager: SmartCacheManager = .shared,
        settingsManager: SettingsManager = .shared
    ) {
        self.cacheManager = cacheManager
        self.settingsManager = settingsManager

        if let singleProvider = provider {
            self.providerRegistry = ProviderRegistry(providers: [singleProvider])
        } else {
            self.providerRegistry = providerRegistry
        }

        // Initialize snapshots from cache
        for p in ProviderType.allCases {
            if let cached = cacheManager.currentSnapshot(for: p) {
                self.snapshots[p] = cached
                self.lastRefreshTimes[p] = cached.fetchedAt
            }
        }
    }

    // MARK: - Selected Provider Convenience Accessors

    public var currentSnapshot: RateLimitSnapshot? {
        get { snapshots[selectedProvider] }
        set {
            if let val = newValue {
                snapshots[selectedProvider] = val
            } else {
                snapshots.removeValue(forKey: selectedProvider)
            }
        }
    }

    public var environmentStatus: EnvironmentStatus {
        get { environmentStatuses[selectedProvider] ?? .healthy }
        set { environmentStatuses[selectedProvider] = newValue }
    }

    public var isRefreshing: Bool {
        get { refreshingProviders.contains(selectedProvider) }
        set {
            if newValue {
                refreshingProviders.insert(selectedProvider)
            } else {
                refreshingProviders.remove(selectedProvider)
            }
        }
    }

    public var lastError: String? {
        get { lastErrors[selectedProvider] }
        set { lastErrors[selectedProvider] = newValue }
    }

    public var lastRefreshTime: Date? {
        get { lastRefreshTimes[selectedProvider] }
        set { lastRefreshTimes[selectedProvider] = newValue }
    }

    // MARK: - Visible Limits & Customization

    /// Visible limits filtered according to user preferences for the selected provider.
    public var visibleLimits: [RateLimitItem] {
        return visibleLimits(for: selectedProvider)
    }

    /// Visible limits filtered according to user preferences for a specific provider.
    public func visibleLimits(for provider: ProviderType) -> [RateLimitItem] {
        _ = selectedLimitVersion
        guard let snapshot = snapshots[provider] else { return [] }
        return settingsManager.resolveVisibleLimits(from: snapshot.items, for: provider)
    }

    /// Checks if a specific limit ID is currently enabled for Menu Bar.
    public func isLimitVisible(id: String, provider: ProviderType? = nil) -> Bool {
        _ = selectedLimitVersion
        let targetProvider = provider ?? selectedProvider
        if !settingsManager.hasCustomizedLimits(for: targetProvider) {
            return true
        }
        return settingsManager.selectedLimitIds(for: targetProvider).contains(id)
    }

    /// Toggles or sets a limit ID's visibility for Menu Bar.
    public func setLimitVisibility(id: String, isVisible: Bool, allItems: [RateLimitItem], provider: ProviderType? = nil) {
        let targetProvider = provider ?? selectedProvider
        if !settingsManager.hasCustomizedLimits(for: targetProvider) {
            settingsManager.setSelectedLimitIds(allItems.map { $0.id }, for: targetProvider)
        }

        var current = Set(settingsManager.selectedLimitIds(for: targetProvider))
        if isVisible {
            current.insert(id)
        } else {
            current.remove(id)
        }
        settingsManager.setSelectedLimitIds(Array(current), for: targetProvider)
        selectedLimitVersion += 1
    }

    /// Restores automatic default visibility for a provider (or selected provider).
    public func restoreDefaultLimits(for provider: ProviderType? = nil) {
        let targetProvider = provider ?? selectedProvider
        settingsManager.restoreAutomaticDefaults(for: targetProvider)
        selectedLimitVersion += 1
    }

    // MARK: - Environment & Refresh Operations

    /// Evaluates current environment status for a specific provider (or selected provider).
    public func checkEnvironment(for providerType: ProviderType? = nil) async {
        let targetType = providerType ?? selectedProvider
        guard let provider = providerRegistry.provider(for: targetType) else {
            environmentStatuses[targetType] = .error(description: "Provider \(targetType.displayName) not found")
            return
        }
        let status = await provider.checkEnvironment()
        environmentStatuses[targetType] = status
    }

    /// Active refresh triggered by Desktop app opening or switching tabs (bypasses cache).
    public func refreshDesktop(provider: ProviderType? = nil) async {
        let targetProvider = provider ?? selectedProvider
        await executeFetch(for: targetProvider, bypassCache: true)
    }

    /// Menu Bar refresh utilizing Smart Cache per provider unless expired or forced.
    public func refreshMenuBar(force: Bool = false) async {
        let supportedTypes = providerRegistry.supportedProviders.map { $0.providerType }
        for p in supportedTypes {
            if !force {
                if let fresh = cacheManager.getFreshSnapshot(for: p, ttl: settingsManager.cacheTTLSeconds) {
                    self.snapshots[p] = fresh
                    self.lastRefreshTimes[p] = fresh.fetchedAt
                    self.lastErrors[p] = nil
                    continue
                }
            }
            await executeFetch(for: p, bypassCache: force)
        }
    }

    /// Retry action when a previous refresh encountered an error for a provider.
    public func retry(for provider: ProviderType? = nil) async {
        let targetProvider = provider ?? selectedProvider
        await executeFetch(for: targetProvider, bypassCache: true)
    }

    /// Executes rate limit fetching for a specific provider.
    public func executeFetch(for providerType: ProviderType, bypassCache: Bool) async {
        guard !refreshingProviders.contains(providerType) else { return }

        refreshingProviders.insert(providerType)
        lastErrors[providerType] = nil

        await checkEnvironment(for: providerType)
        guard let status = environmentStatuses[providerType], status.isReady else {
            refreshingProviders.remove(providerType)
            return
        }

        guard let provider = providerRegistry.provider(for: providerType) else {
            lastErrors[providerType] = "Provider \(providerType.displayName) not registered"
            refreshingProviders.remove(providerType)
            return
        }

        do {
            let snapshot = try await provider.fetchRateLimits()
            self.snapshots[providerType] = snapshot
            self.lastRefreshTimes[providerType] = snapshot.fetchedAt
            self.cacheManager.store(snapshot)
            self.lastErrors[providerType] = nil
        } catch {
            // Invalidate cache for this provider to avoid presenting stale data as current
            self.cacheManager.invalidate(for: providerType)
            self.lastErrors[providerType] = error.localizedDescription
        }

        refreshingProviders.remove(providerType)
    }
}
