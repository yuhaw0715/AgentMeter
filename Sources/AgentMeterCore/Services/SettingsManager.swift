import Foundation
import ServiceManagement

/// Manages local user preferences and configuration.
public final class SettingsManager: @unchecked Sendable {
    public static let shared = SettingsManager()

    private let userDefaults: UserDefaults

    public enum Keys {
        public static let cacheTTLSeconds = "agentmeter.cacheTTLSeconds"
        public static let customCodexPath = "agentmeter.customCodexPath"
        public static let customAntigravityPath = "agentmeter.customAntigravityPath"
        public static let selectedLimitIds = "agentmeter.selectedLimitIds"
        public static let hasCustomizedLimits = "agentmeter.hasCustomizedLimits"
        public static let launchAtLogin = "agentmeter.launchAtLogin"
        public static let appLanguage = "agentmeter.appLanguage"

        public static func selectedLimitIdsKey(for provider: ProviderType) -> String {
            return "agentmeter.selectedLimitIds.\(provider.rawValue)"
        }

        public static func hasCustomizedLimitsKey(for provider: ProviderType) -> String {
            return "agentmeter.hasCustomizedLimits.\(provider.rawValue)"
        }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// User selected UI language (.system, .zhHant, .en).
    public var appLanguage: AppLanguage {
        get {
            guard let raw = userDefaults.string(forKey: Keys.appLanguage),
                  let lang = AppLanguage(rawValue: raw) else {
                return .system
            }
            return lang
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.appLanguage)
        }
    }

    /// Cache TTL in seconds (default 300s = 5 minutes).
    public var cacheTTLSeconds: TimeInterval {
        get {
            let val = userDefaults.double(forKey: Keys.cacheTTLSeconds)
            return val > 0 ? val : 300.0
        }
        set {
            userDefaults.set(newValue, forKey: Keys.cacheTTLSeconds)
        }
    }

    /// Custom Codex CLI executable path.
    public var customCodexPath: String {
        get {
            return userDefaults.string(forKey: Keys.customCodexPath) ?? ""
        }
        set {
            userDefaults.set(newValue, forKey: Keys.customCodexPath)
        }
    }

    /// Custom Antigravity CLI executable path.
    public var customAntigravityPath: String {
        get {
            return userDefaults.string(forKey: Keys.customAntigravityPath) ?? ""
        }
        set {
            userDefaults.set(newValue, forKey: Keys.customAntigravityPath)
        }
    }

    /// Whether the user has customized visible limits for a provider.
    public func hasCustomizedLimits(for provider: ProviderType) -> Bool {
        let providerKey = Keys.hasCustomizedLimitsKey(for: provider)
        if userDefaults.object(forKey: providerKey) != nil {
            return userDefaults.bool(forKey: providerKey)
        }
        if provider == .codex {
            return userDefaults.bool(forKey: Keys.hasCustomizedLimits)
        }
        return false
    }

    /// Sets whether the user has customized visible limits for a provider.
    public func setHasCustomizedLimits(_ customized: Bool, for provider: ProviderType) {
        userDefaults.set(customized, forKey: Keys.hasCustomizedLimitsKey(for: provider))
        if provider == .codex {
            userDefaults.set(customized, forKey: Keys.hasCustomizedLimits)
        }
    }

    /// Ordered list of user-selected limit IDs for a provider.
    public func selectedLimitIds(for provider: ProviderType) -> [String] {
        let providerKey = Keys.selectedLimitIdsKey(for: provider)
        if let list = userDefaults.stringArray(forKey: providerKey) {
            return list
        }
        if provider == .codex, let legacyList = userDefaults.stringArray(forKey: Keys.selectedLimitIds) {
            return legacyList
        }
        return []
    }

    /// Sets user-selected limit IDs for a provider.
    public func setSelectedLimitIds(_ ids: [String], for provider: ProviderType) {
        userDefaults.set(ids, forKey: Keys.selectedLimitIdsKey(for: provider))
        setHasCustomizedLimits(true, for: provider)
        if provider == .codex {
            userDefaults.set(ids, forKey: Keys.selectedLimitIds)
            userDefaults.set(true, forKey: Keys.hasCustomizedLimits)
        }
    }

    /// Whether the user has customized their visible limit list (defaults to Codex).
    public var hasCustomizedLimits: Bool {
        get {
            return hasCustomizedLimits(for: .codex)
        }
        set {
            setHasCustomizedLimits(newValue, for: .codex)
        }
    }

    /// Ordered list of user-selected limit IDs for Menu Bar display (defaults to Codex).
    public var selectedLimitIds: [String] {
        get {
            return selectedLimitIds(for: .codex)
        }
        set {
            setSelectedLimitIds(newValue, for: .codex)
        }
    }

    /// Restores the default automatic limits selection for a provider (or all providers if nil).
    public func restoreAutomaticDefaults(for provider: ProviderType? = nil) {
        if let provider = provider {
            userDefaults.removeObject(forKey: Keys.selectedLimitIdsKey(for: provider))
            userDefaults.set(false, forKey: Keys.hasCustomizedLimitsKey(for: provider))
            if provider == .codex {
                userDefaults.removeObject(forKey: Keys.selectedLimitIds)
                userDefaults.set(false, forKey: Keys.hasCustomizedLimits)
            }
        } else {
            userDefaults.removeObject(forKey: Keys.selectedLimitIds)
            userDefaults.set(false, forKey: Keys.hasCustomizedLimits)
            for p in ProviderType.allCases {
                userDefaults.removeObject(forKey: Keys.selectedLimitIdsKey(for: p))
                userDefaults.set(false, forKey: Keys.hasCustomizedLimitsKey(for: p))
            }
        }
    }

    /// Filters rate limits for Menu Bar presentation while preserving the
    /// provider snapshot order used by the Desktop dashboard.
    public func resolveVisibleLimits(from items: [RateLimitItem], for provider: ProviderType) -> [RateLimitItem] {
        if !hasCustomizedLimits(for: provider) || selectedLimitIds(for: provider).isEmpty {
            return items
        }

        // The selected IDs describe visibility, not presentation order. The
        // provider response is the source of truth for ordering so Desktop
        // and Menu Bar always show the same sequence for every provider.
        let selected = Set(selectedLimitIds(for: provider))
        let visibleItems = items.filter { selected.contains($0.id) }

        return visibleItems.isEmpty ? items : visibleItems
    }

    /// Filters rate limits for Menu Bar presentation (defaults to Codex).
    public func resolveVisibleLimits(from items: [RateLimitItem]) -> [RateLimitItem] {
        return resolveVisibleLimits(from: items, for: .codex)
    }

    /// Launch at login preference.
    public var isLaunchAtLoginEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return userDefaults.bool(forKey: Keys.launchAtLogin)
        }
    }

    public func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                // Log or handle error gracefully in sandbox/test environments
            }
        }
        userDefaults.set(enabled, forKey: Keys.launchAtLogin)
    }
}
