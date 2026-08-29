import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Live Codex Integration Test")
struct LiveCodexIntegrationTests {
    @Test("Fetch real rate limits from local Codex app-server")
    func testLiveCodexFetch() async throws {
        let detector = CodexEnvironmentDetector()
        guard let path = detector.resolveExecutablePath() else {
            print("Codex binary not found on PATH.")
            return
        }
        print("Found Codex executable at: \(path)")

        let provider = CodexRateLimitProvider(environmentDetector: detector)
        let status = await provider.checkEnvironment()
        print("Environment Status: \(status)")

        do {
            let snapshot = try await provider.fetchRateLimits()
            print("--- Live Codex Rate Limit Snapshot ---")
            print("Provider: \(snapshot.provider)")
            print("Plan: \(snapshot.accountPlan ?? "Unknown")")
            print("Fetched At: \(snapshot.fetchedAt)")
            print("Items count: \(snapshot.items.count)")
            for item in snapshot.items {
                print("  ▶ [\(item.name)] - Used: \(item.usedPercentageInt)% (Remaining: \(item.remainingPercentageInt)%), Resets at: \(item.resetAt?.description ?? "N/A"), Limit Reached: \(item.isLimitReached)")
            }
            #expect(snapshot.items.count > 0)
        } catch {
            print("Live fetch error: \(error)")
            #expect(Bool(false), "Live fetch failed: \(error)")
        }
    }
}
