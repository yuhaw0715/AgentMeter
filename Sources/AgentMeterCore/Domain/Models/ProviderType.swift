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
            return "Antigravity"
        }
    }

    /// In MVP, only ChatGPT Codex is exposed in UI.
    public var isSupportedInMVP: Bool {
        return self == .codex
    }
}
