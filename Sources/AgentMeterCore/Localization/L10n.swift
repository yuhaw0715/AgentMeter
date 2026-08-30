import Foundation

/// Centralized localization dictionary supporting English and Traditional Chinese (zh-Hant).
public enum L10n {
    public static var isTraditionalChinese: Bool {
        let setting = SettingsManager.shared.appLanguage
        switch setting {
        case .zhHant:
            return true
        case .en:
            return false
        case .system:
            let preferred = Locale.preferredLanguages.first ?? ""
            return preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") || preferred.hasPrefix("zh-HK") || preferred.hasPrefix("zh")
        }
    }

    public static var appName: String { "AgentMeter" }

    // General Actions
    public static var refreshing: String { isTraditionalChinese ? "正在重新整理…" : "Refreshing…" }
    public static var refresh: String { isTraditionalChinese ? "重新整理" : "Refresh" }
    public static var retry: String { isTraditionalChinese ? "重試" : "Retry" }
    public static var quit: String { isTraditionalChinese ? "結束" : "Quit" }
    public static var checkAgain: String { isTraditionalChinese ? "重新檢查" : "Check Again" }
    public static var browse: String { isTraditionalChinese ? "瀏覽…" : "Browse…" }
    public static var copied: String { isTraditionalChinese ? "已複製！" : "Copied!" }
    public static var restoreDefaults: String { isTraditionalChinese ? "恢復自動預設值" : "Restore Automatic Defaults" }
    public static var showInMenuBar: String { isTraditionalChinese ? "顯示於 Menu Bar" : "Show in Menu Bar" }

    // Navigation & Sections
    public static var providers: String { isTraditionalChinese ? "供應商" : "Providers" }
    public static var application: String { isTraditionalChinese ? "應用程式" : "Application" }
    public static var codexTitle: String { "ChatGPT Codex" }
    public static var antigravityTitle: String { "Google Antigravity" }
    public static var settingsTitle: String { isTraditionalChinese ? "偏好設定" : "Settings" }
    public static var diagnosticsTitle: String { isTraditionalChinese ? "環境診斷" : "Diagnostics" }

    // Menu Bar
    public static var openMainWindow: String { isTraditionalChinese ? "開啟 AgentMeter…" : "Open AgentMeter…" }
    public static var fetchingQuota: String { isTraditionalChinese ? "正在抓取額度…" : "Fetching Quota…" }
    public static var fetchingCodexQuota: String { isTraditionalChinese ? "正在抓取 Codex 額度…" : "Fetching Codex Quota…" }
    public static var fetchingAntigravityQuota: String { isTraditionalChinese ? "正在抓取 Antigravity 額度…" : "Fetching Antigravity Quota…" }
    public static var noQuotaDataYet: String { isTraditionalChinese ? "尚無額度資料" : "No quota data yet" }
    public static var refreshError: String { isTraditionalChinese ? "重新整理發生錯誤" : "Refresh Error" }

    // Rate Limit Cards
    public static var limitReached: String { isTraditionalChinese ? "已達使用上限" : "Limit reached" }
    public static var resetTimeUnavailable: String { isTraditionalChinese ? "無法取得重置時間" : "Reset time unavailable" }
    public static func remainingText(_ percent: Int) -> String {
        isTraditionalChinese ? "剩餘 \(percent)%" : "\(percent)% remaining"
    }
    public static func resetsText(_ time: String) -> String {
        isTraditionalChinese ? "重置時間：\(time)" : "Resets: \(time)"
    }
    public static func localizedLimitName(_ name: String) -> String {
        if !isTraditionalChinese { return name }
        if name.contains("5-Hour Session") {
            return "5 小時工作階段額度"
        }
        if name.contains("Five Hour") || name.contains("5-Hour") || name.contains("5 Hour") || name.contains("5h") {
            return "5 小時額度"
        }
        if name.contains("Weekly") || name.contains("Week") {
            return "每週額度"
        }
        if name.contains("Daily") || name.contains("Day") {
            return "每日額度"
        }
        return name
    }

    // Dashboard
    public static var currentUsageSection: String { isTraditionalChinese ? "即時額度與用量" : "Real-time Quotas & Usage" }
    public static var currentUsageHint: String { isTraditionalChinese ? "左側勾選項目將即時同步呈現於 Menu Bar 下拉畫面" : "Checked items are synced live to the Menu Bar popover" }
    public static func updatedText(_ time: String) -> String {
        isTraditionalChinese ? "已更新：\(time)" : "Updated: \(time)"
    }
    public static var refreshFailed: String { isTraditionalChinese ? "重新整理失敗" : "Refresh Failed" }
    public static var noDataAvailable: String { isTraditionalChinese ? "尚無使用額度資料" : "No rate limit data available" }
    public static var clickRefreshHint: String { isTraditionalChinese ? "點擊重新整理以獲取目前額度資訊。" : "Click refresh to fetch current quota information." }

    // Settings
    public static var settingsSubtitle: String { isTraditionalChinese ? "自訂重新整理頻率、開機啟動與執行檔路徑。" : "Customize refresh interval, launch at login, and executable paths." }
    public static var generalSection: String { isTraditionalChinese ? "一般設定" : "General" }
    public static var languageOption: String { isTraditionalChinese ? "介面語言" : "Language" }
    public static var launchAtLoginOption: String { isTraditionalChinese ? "開機時自動啟動" : "Launch at Login" }
    public static var cacheTTLOption: String { isTraditionalChinese ? "Menu Bar 快取時間 (TTL)" : "Menu Bar Cache TTL" }
    public static var codexConfigSection: String { isTraditionalChinese ? "Codex CLI 設定" : "Codex CLI Configuration" }
    public static var antigravityConfigSection: String { isTraditionalChinese ? "Google Antigravity CLI 設定" : "Google Antigravity CLI Configuration" }
    public static var customExecutablePath: String { isTraditionalChinese ? "自訂執行檔路徑 (選填)" : "Custom Executable Path (Optional)" }
    public static var autoDetectHint: String { isTraditionalChinese ? "留空將自動於系統 PATH 搜尋 codex。" : "Leave blank to automatically detect codex on system PATH." }
    public static var antigravityAutoDetectHint: String { isTraditionalChinese ? "留空將自動搜尋 ~/.local/bin/agy 或系統 PATH。" : "Leave blank to automatically detect agy in ~/.local/bin or system PATH." }

    // Diagnostics
    public static var diagnosticsSubtitle: String { isTraditionalChinese ? "環境狀態與問題排查資訊。" : "Environment status and troubleshooting information." }
    public static var copyDiagnosticReport: String { isTraditionalChinese ? "複製診斷報告" : "Copy Diagnostic Report" }
    public static var agentMeterVersion: String { isTraditionalChinese ? "AgentMeter 版本" : "AgentMeter Version" }
    public static var macOSVersion: String { isTraditionalChinese ? "macOS 版本" : "macOS Version" }
    public static var codexCLIPath: String { isTraditionalChinese ? "Codex CLI 路徑" : "Codex CLI Path" }
    public static var antigravityCLIPath: String { isTraditionalChinese ? "Antigravity CLI 路徑" : "Antigravity CLI Path" }
    public static var environmentStatusText: String { isTraditionalChinese ? "環境狀態" : "Environment Status" }
    public static var lastRefreshTime: String { isTraditionalChinese ? "最後更新時間" : "Last Refresh Time" }
    public static var lastErrorText: String { isTraditionalChinese ? "最後錯誤訊息" : "Last Error" }
    public static var none: String { isTraditionalChinese ? "無" : "None" }
    public static var never: String { isTraditionalChinese ? "從未" : "Never" }
    public static var notFound: String { isTraditionalChinese ? "未找到" : "Not Found" }

    // Setup Guide
    public static var envReadyTitle: String { isTraditionalChinese ? "環境正常" : "Environment Ready" }
    public static var cliMissingTitle: String { isTraditionalChinese ? "找不到 CLI 執行檔" : "CLI Not Found" }
    public static var unsupportedVersionTitle: String { isTraditionalChinese ? "CLI 版本不相容" : "CLI Version Incompatible" }
    public static var notAuthTitle: String { isTraditionalChinese ? "需要登入 CLI" : "Login Required" }
    public static var appServerUnavailableTitle: String { isTraditionalChinese ? "無法連接 App Server" : "App Server Unavailable" }
    public static var envErrorTitle: String { isTraditionalChinese ? "環境錯誤" : "Environment Error" }
}
