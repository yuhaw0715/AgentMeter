import Foundation
import Testing
@testable import AgentMeterCore

@Suite("Usage Monitor Concurrent Refresh Tests")
struct UsageMonitorConcurrencyTests {
    @Test("Menu Bar starts all provider fetches before either one completes")
    @MainActor
    func menuBarFetchesProvidersConcurrentlyAndAppliesProgressively() async {
        let controller = FetchController()
        let codex = ControlledProvider(providerType: .codex, controller: controller)
        let antigravity = ControlledProvider(providerType: .antigravity, controller: controller)
        let viewModel = makeViewModel(providers: [codex, antigravity])

        let refresh = Task { await viewModel.refreshMenuBar(force: true) }
        await controller.waitUntilStarted([.codex, .antigravity])

        #expect(viewModel.refreshingProviders == [.codex, .antigravity])

        let antigravitySnapshot = makeSnapshot(provider: .antigravity, percentage: 20)
        await controller.complete(.antigravity, with: .success(antigravitySnapshot))
        #expect(await eventually { viewModel.snapshots[.antigravity] == antigravitySnapshot })
        #expect(viewModel.refreshingProviders == [.codex])
        #expect(viewModel.snapshots[.codex] == nil)

        let codexSnapshot = makeSnapshot(provider: .codex, percentage: 40)
        await controller.complete(.codex, with: .success(codexSnapshot))
        await refresh.value

        #expect(viewModel.snapshots[.codex] == codexSnapshot)
        #expect(viewModel.refreshingProviders.isEmpty)
    }

    @Test("Menu Bar uses fresh cache and only fetches providers that need updates")
    @MainActor
    func menuBarFiltersFreshCacheBeforeStartingTasks() async {
        let freshCodex = makeSnapshot(provider: .codex, percentage: 10)
        let cache = SmartCacheManager(initialSnapshot: freshCodex)
        let controller = FetchController()
        let codex = ControlledProvider(providerType: .codex, controller: controller)
        let antigravity = ControlledProvider(providerType: .antigravity, controller: controller)
        let viewModel = makeViewModel(providers: [codex, antigravity], cache: cache)

        let refresh = Task { await viewModel.refreshMenuBar(force: false) }
        await controller.waitUntilStarted([.antigravity])

        #expect(await controller.fetchCount(for: .codex) == 0)
        #expect(viewModel.snapshots[.codex] == freshCodex)
        #expect(viewModel.refreshingProviders == [.antigravity])

        let updated = makeSnapshot(provider: .antigravity, percentage: 30)
        await controller.complete(.antigravity, with: .success(updated))
        await refresh.value

        #expect(viewModel.snapshots[.antigravity] == updated)
        #expect(viewModel.refreshingProviders.isEmpty)
    }

    @Test("Duplicate refresh does not start a second fetch for an in-flight provider")
    @MainActor
    func menuBarDeduplicatesInFlightProviderFetches() async {
        let controller = FetchController()
        let codex = ControlledProvider(providerType: .codex, controller: controller)
        let antigravity = ControlledProvider(providerType: .antigravity, controller: controller)
        let viewModel = makeViewModel(providers: [codex, antigravity])

        let firstRefresh = Task { await viewModel.refreshMenuBar(force: true) }
        await controller.waitUntilStarted([.codex, .antigravity])
        await viewModel.refreshMenuBar(force: true)

        #expect(await controller.fetchCount(for: .codex) == 1)
        #expect(await controller.fetchCount(for: .antigravity) == 1)

        await controller.complete(.codex, with: .success(makeSnapshot(provider: .codex)))
        await controller.complete(.antigravity, with: .success(makeSnapshot(provider: .antigravity)))
        await firstRefresh.value

        #expect(viewModel.refreshingProviders.isEmpty)
    }

    @Test("One provider failure preserves its old snapshot and does not block another provider")
    @MainActor
    func menuBarIsolatesProviderFailures() async {
        let oldCodex = makeSnapshot(provider: .codex, percentage: 5)
        let cache = SmartCacheManager(initialSnapshot: oldCodex)
        let controller = FetchController()
        let codex = ControlledProvider(providerType: .codex, controller: controller)
        let antigravity = ControlledProvider(providerType: .antigravity, controller: controller)
        let viewModel = makeViewModel(providers: [codex, antigravity], cache: cache)

        let refresh = Task { await viewModel.refreshMenuBar(force: true) }
        await controller.waitUntilStarted([.codex, .antigravity])

        let newAntigravity = makeSnapshot(provider: .antigravity, percentage: 55)
        await controller.complete(.antigravity, with: .success(newAntigravity))
        #expect(await eventually { viewModel.snapshots[.antigravity] == newAntigravity })
        #expect(viewModel.refreshingProviders == [.codex])

        await controller.complete(.codex, with: .failure("Codex unavailable"))
        await refresh.value

        #expect(viewModel.snapshots[.codex] == oldCodex)
        #expect(viewModel.lastRefreshTimes[.codex] == oldCodex.fetchedAt)
        #expect(viewModel.lastErrors[.codex] == "Codex unavailable")
        #expect(cache.currentSnapshot(for: .codex) == nil)
        #expect(viewModel.snapshots[.antigravity] == newAntigravity)
        #expect(viewModel.lastErrors[.antigravity] == nil)
        #expect(viewModel.refreshingProviders.isEmpty)
    }

    @Test("Cancellation clears loading state without replacing data or showing an error")
    @MainActor
    func menuBarCancellationPreservesCompletedState() async {
        let oldCodex = makeSnapshot(provider: .codex, percentage: 15)
        let cache = SmartCacheManager(initialSnapshot: oldCodex)
        let probe = CancellationProbe()
        let provider = CancellationProvider(providerType: .codex, probe: probe)
        let viewModel = makeViewModel(providers: [provider], cache: cache)

        let refresh = Task { await viewModel.refreshMenuBar(force: true) }
        await probe.waitUntilStarted()
        #expect(viewModel.refreshingProviders == [.codex])

        refresh.cancel()
        await refresh.value

        #expect(await probe.wasCancelled())
        #expect(viewModel.snapshots[.codex] == oldCodex)
        #expect(viewModel.lastErrors[.codex] == nil)
        #expect(viewModel.refreshingProviders.isEmpty)
    }

    @Test("Desktop refresh keeps success, environment, and failure behavior")
    @MainActor
    func desktopRefreshUsesSharedResultApplication() async {
        let successSnapshot = makeSnapshot(provider: .codex, percentage: 65)
        let successViewModel = makeViewModel(providers: [
            ImmediateProvider(providerType: .codex, result: .success(successSnapshot))
        ])
        await successViewModel.refreshDesktop(provider: .codex)
        #expect(successViewModel.snapshots[.codex] == successSnapshot)
        #expect(successViewModel.environmentStatuses[.codex] == .healthy)
        #expect(successViewModel.refreshingProviders.isEmpty)

        let missing = EnvironmentStatus.cliMissing(expectedPath: "/usr/local/bin/codex")
        let missingViewModel = makeViewModel(providers: [
            ImmediateProvider(providerType: .codex, environmentStatus: missing)
        ])
        await missingViewModel.refreshDesktop(provider: .codex)
        #expect(missingViewModel.environmentStatuses[.codex] == missing)
        #expect(missingViewModel.lastErrors[.codex] == nil)
        #expect(missingViewModel.refreshingProviders.isEmpty)

        let failureViewModel = makeViewModel(providers: [
            ImmediateProvider(providerType: .codex, result: .failure("network failure"))
        ])
        await failureViewModel.retry(for: .codex)
        #expect(failureViewModel.environmentStatuses[.codex] == .healthy)
        #expect(failureViewModel.lastErrors[.codex] == "network failure")
        #expect(failureViewModel.refreshingProviders.isEmpty)
    }

    @MainActor
    private func makeViewModel(
        providers: [any AgentProvider],
        cache: SmartCacheManager = SmartCacheManager()
    ) -> UsageMonitorViewModel {
        let suiteName = "test.agentmeter.concurrent.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsManager(userDefaults: defaults)
        return UsageMonitorViewModel(
            providerRegistry: ProviderRegistry(providers: providers),
            cacheManager: cache,
            settingsManager: settings
        )
    }

    private func makeSnapshot(
        provider: ProviderType,
        percentage: Double = 25
    ) -> RateLimitSnapshot {
        RateLimitSnapshot(
            provider: provider,
            fetchedAt: Date(),
            items: [RateLimitItem(
                id: "\(provider.rawValue)-limit",
                name: "Test Limit",
                usedPercentage: percentage
            )]
        )
    }

    @MainActor
    private func eventually(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<1_000 {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }
}

private enum ControlledOutcome: Sendable {
    case success(RateLimitSnapshot)
    case failure(String)
}

private struct ControlledProviderError: LocalizedError, Sendable {
    let message: String
    var errorDescription: String? { message }
}

private actor FetchController {
    private var startedProviders: Set<ProviderType> = []
    private var callCounts: [ProviderType: Int] = [:]
    private var startWaiters: [(Set<ProviderType>, CheckedContinuation<Void, Never>)] = []
    private var resultContinuations: [ProviderType: CheckedContinuation<ControlledOutcome, Never>] = [:]

    func fetch(for provider: ProviderType) async -> ControlledOutcome {
        callCounts[provider, default: 0] += 1

        return await withCheckedContinuation { continuation in
            resultContinuations[provider] = continuation
            startedProviders.insert(provider)
            resumeSatisfiedStartWaiters()
        }
    }

    func waitUntilStarted(_ providers: Set<ProviderType>) async {
        guard !providers.isSubset(of: startedProviders) else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append((providers, continuation))
        }
    }

    func complete(_ provider: ProviderType, with outcome: ControlledOutcome) {
        resultContinuations.removeValue(forKey: provider)?.resume(returning: outcome)
    }

    func fetchCount(for provider: ProviderType) -> Int {
        callCounts[provider, default: 0]
    }

    private func resumeSatisfiedStartWaiters() {
        var remaining: [(Set<ProviderType>, CheckedContinuation<Void, Never>)] = []
        for (providers, continuation) in startWaiters {
            if providers.isSubset(of: startedProviders) {
                continuation.resume()
            } else {
                remaining.append((providers, continuation))
            }
        }
        startWaiters = remaining
    }
}

private struct ControlledProvider: AgentProvider {
    let providerType: ProviderType
    let controller: FetchController
    var environmentStatus: EnvironmentStatus = .healthy

    func checkEnvironment() async -> EnvironmentStatus {
        environmentStatus
    }

    func fetchRateLimits() async throws -> RateLimitSnapshot {
        switch await controller.fetch(for: providerType) {
        case let .success(snapshot):
            return snapshot
        case let .failure(message):
            throw ControlledProviderError(message: message)
        }
    }
}

private struct ImmediateProvider: AgentProvider {
    let providerType: ProviderType
    var environmentStatus: EnvironmentStatus = .healthy
    var result: ControlledOutcome = .success(
        RateLimitSnapshot(provider: .codex, items: [])
    )

    func checkEnvironment() async -> EnvironmentStatus {
        environmentStatus
    }

    func fetchRateLimits() async throws -> RateLimitSnapshot {
        switch result {
        case let .success(snapshot):
            return snapshot
        case let .failure(message):
            throw ControlledProviderError(message: message)
        }
    }
}

private actor CancellationProbe {
    private var started = false
    private var cancelled = false
    private var startWaiters: [CheckedContinuation<Void, Never>] = []

    func markStarted() {
        started = true
        let waiters = startWaiters
        startWaiters.removeAll()
        for waiter in waiters {
            waiter.resume()
        }
    }

    func waitUntilStarted() async {
        guard !started else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    func markCancelled() {
        cancelled = true
    }

    func wasCancelled() -> Bool {
        cancelled
    }
}

private struct CancellationProvider: AgentProvider {
    let providerType: ProviderType
    let probe: CancellationProbe

    func checkEnvironment() async -> EnvironmentStatus {
        .healthy
    }

    func fetchRateLimits() async throws -> RateLimitSnapshot {
        await probe.markStarted()
        do {
            try await Task.sleep(for: .seconds(3_600))
            return RateLimitSnapshot(provider: providerType, items: [])
        } catch is CancellationError {
            await probe.markCancelled()
            throw CancellationError()
        }
    }
}
