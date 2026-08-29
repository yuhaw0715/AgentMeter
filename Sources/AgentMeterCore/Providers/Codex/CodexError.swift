import Foundation

/// Errors specific to the Codex Provider.
public enum CodexError: Error, LocalizedError, Sendable {
    case invalidExecutablePath
    case appServerLaunchFailed(String)
    case transportError(String)
    case invalidRequestPayload
    case rpcError(String)
    case noResponse
    case timeout
    case parseError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidExecutablePath:
            return "Codex executable was not found."
        case .appServerLaunchFailed(let reason):
            return "Failed to launch Codex app-server: \(reason)"
        case .transportError(let msg):
            return "Transport error communicating with Codex app-server: \(msg)"
        case .invalidRequestPayload:
            return "Invalid JSON-RPC request payload."
        case .rpcError(let msg):
            return "Codex RPC Error: \(msg)"
        case .noResponse:
            return "No response received from Codex app-server."
        case .timeout:
            return "Request to Codex app-server timed out."
        case .parseError(let msg):
            return "Failed to parse rate limits: \(msg)"
        }
    }
}
