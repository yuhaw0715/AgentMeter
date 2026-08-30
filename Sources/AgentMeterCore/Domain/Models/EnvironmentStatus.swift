import Foundation

/// Represents the environmental readiness status of a provider.
public enum EnvironmentStatus: Equatable, Sendable {
    case healthy
    case cliMissing(expectedPath: String)
    case unsupportedVersion(current: String, required: String)
    case notAuthenticated(message: String)
    case appServerUnavailable(reason: String)
    case error(description: String)

    public var isReady: Bool {
        if case .healthy = self {
            return true
        }
        return false
    }
}
