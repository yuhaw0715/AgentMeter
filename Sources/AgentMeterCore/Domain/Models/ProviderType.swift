import Foundation

/// Represents the supported AI Agent providers.
public enum ProviderType: String, CaseIterable, Identifiable, Sendable, Codable {
    case codex = "codex"
    case gemini = "gemini"
    case antigravity = "antigravity"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .codex:
            return "ChatGPT Codex"
        case .gemini:
            return "Google Gemini"
        case .antigravity:
            return "Google Antigravity"
        }
    }

    /// Returns whether the provider is currently supported in the app.
    public var isSupported: Bool {
        return self == .codex || self == .antigravity
    }

    /// Retained for backwards compatibility with earlier MVP checks.
    public var isSupportedInMVP: Bool {
        return isSupported
    }
}
