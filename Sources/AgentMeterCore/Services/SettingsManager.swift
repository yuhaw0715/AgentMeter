import Foundation
import ServiceManagement

/// Manages local user preferences and configuration.
public final class SettingsManager: @unchecked Sendable {
    public static let shared = SettingsManager()

    private let userDefaults: UserDefaults

    public enum Keys {
        public static let cacheTTLSeconds = "agentmeter.cacheTTLSeconds"
        public static let customCodexPath = "agentmeter.customCodexPath"
        public static let selectedLimitIds = "agentmeter.selectedLimitIds"
        public static let hasCustomizedLimits = "agentmeter.hasCustomizedLimits"
        public static let launchAtLogin = "agentmeter.launchAtLogin"
        public static let appLanguage = "agentmeter.appLanguage"
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

    /// Whether the user has customized their visible limit list.
    public var hasCustomizedLimits: Bool {
        get {
            return userDefaults.bool(forKey: Keys.hasCustomizedLimits)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasCustomizedLimits)
        }
    }

    /// Ordered list of user-selected limit IDs for Menu Bar display.
    public var selectedLimitIds: [String] {
        get {
            return userDefaults.stringArray(forKey: Keys.selectedLimitIds) ?? []
        }
        set {
            userDefaults.set(newValue, forKey: Keys.selectedLimitIds)
            hasCustomizedLimits = true
        }
    }

    /// Restores the default automatic limits selection.
    public func restoreAutomaticDefaults() {
        userDefaults.removeObject(forKey: Keys.selectedLimitIds)
        userDefaults.set(false, forKey: Keys.hasCustomizedLimits)
    }

    /// Filters and orders rate limits for Menu Bar presentation.
    public func resolveVisibleLimits(from items: [RateLimitItem]) -> [RateLimitItem] {
        if !hasCustomizedLimits || selectedLimitIds.isEmpty {
            return items
        }

        var resultMap: [String: RateLimitItem] = [:]
        for item in items {
            resultMap[item.id] = item
        }

        var visibleItems: [RateLimitItem] = []
        for id in selectedLimitIds {
            if let item = resultMap[id] {
                visibleItems.append(item)
            }
        }

        return visibleItems.isEmpty ? items : visibleItems
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
