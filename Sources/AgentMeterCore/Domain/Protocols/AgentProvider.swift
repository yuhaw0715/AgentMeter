import Foundation

/// Protocol that all AI Agent usage providers must conform to.
public protocol AgentProvider: Sendable {
    /// The unique type identifying this provider.
    var providerType: ProviderType { get }

    /// Checks environment readiness (e.g. CLI path, authentication, server responsiveness).
    func checkEnvironment() async -> EnvironmentStatus

    /// Fetches the latest rate limits from the provider.
    func fetchRateLimits() async throws -> RateLimitSnapshot
}

/// Registry managing active and supported Agent Providers.
public final class ProviderRegistry: Sendable {
    public static let shared = ProviderRegistry()

    private let providers: [ProviderType: any AgentProvider]

    public init(providers: [any AgentProvider] = []) {
        var map: [ProviderType: any AgentProvider] = [:]
        for provider in providers {
            map[provider.providerType] = provider
        }
        self.providers = map
    }

    /// Returns the provider for a specific type, if registered.
    public func provider(for type: ProviderType) -> (any AgentProvider)? {
        return providers[type]
    }

    /// Returns all registered providers that are supported in the current MVP.
    public var supportedProviders: [any AgentProvider] {
        return providers.values.filter { $0.providerType.isSupportedInMVP }
    }
}
