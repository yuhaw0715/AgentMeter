import Foundation

/// Supported UI languages in AgentMeter.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable, Codable {
    case system = "system"
    case zhHant = "zh-Hant"
    case en = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:
            return L10n.isTraditionalChinese ? "依系統語言 (System Default)" : "System Default"
        case .zhHant:
            return "繁體中文 (Traditional Chinese)"
        case .en:
            return "English"
        }
    }
}
