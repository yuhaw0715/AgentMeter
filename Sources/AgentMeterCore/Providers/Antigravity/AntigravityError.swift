import Foundation

/// Errors that can occur when querying Google Antigravity rate limits.
public enum AntigravityError: LocalizedError, Sendable, Equatable {
    case cliMissing(path: String)
    case unsupportedVersion(current: String, required: String)
    case notAuthenticated(message: String)
    case unsupportedAPIKeyMode
    case timeout
    case processFailed(exitCode: Int32, output: String)
    case invalidOutput(details: String)
    case noGeminiBucketsFound

    public var errorDescription: String? {
        switch self {
        case .cliMissing(let path):
            return "Antigravity CLI (agy) not found at \(path)"
        case .unsupportedVersion(let current, let required):
            return "Antigravity CLI version \(current) is unsupported. Minimum required version is \(required)."
        case .notAuthenticated(let message):
            return "Antigravity CLI is not authenticated: \(message)"
        case .unsupportedAPIKeyMode:
            return "GEMINI_API_KEY authentication mode is not supported. Please log in with a Google account."
        case .timeout:
            return "Antigravity rate limit query timed out (10s limit exceeded)."
        case .processFailed(let exitCode, let output):
            return "Antigravity CLI exited with code \(exitCode): \(output)"
        case .invalidOutput(let details):
            return "Invalid Antigravity CLI output: \(details)"
        case .noGeminiBucketsFound:
            return "No valid Gemini Models quota buckets found."
        }
    }
}
