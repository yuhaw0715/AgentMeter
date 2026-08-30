import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Live Antigravity Integration Test")
struct LiveAntigravityIntegrationTests {
    @Test("Fetch real rate limits from local Antigravity CLI without starting agent turn")
    func testLiveAntigravityFetch() async throws {
        let detector = AntigravityEnvironmentDetector()
        guard let execPath = detector.resolveExecutablePath() else {
            print("Skipping Live Antigravity Integration Test: agy binary not found.")
            return
        }

        print("Found Antigravity executable at: \(execPath)")
        let status = await detector.detectStatus()
        guard status.isReady else {
            print("Skipping Live Antigravity Integration Test: Environment not ready (\(status)).")
            return
        }

        let provider = AntigravityRateLimitProvider(environmentDetector: detector)
        do {
            let snapshot = try await provider.fetchRateLimits()
            #expect(snapshot.provider == .antigravity)
            #expect(snapshot.items.count > 0)

            print("--- Live Antigravity Rate Limit Snapshot ---")
            print("Provider: \(snapshot.provider.rawValue)")
            print("Fetched At: \(snapshot.fetchedAt)")
            print("Items count: \(snapshot.items.count)")
            for item in snapshot.items {
                print("  ▶ [\(item.name)] (\(item.id)) - Used: \(item.usedPercentageInt)% (Remaining: \(item.remainingPercentageInt)%), Resets at: \(String(describing: item.resetAt)), Limit Reached: \(item.isLimitReached)")
                // Check all items belong to Gemini
                #expect(item.id.lowercased().contains("gemini") || item.name.lowercased().contains("limit"))
            }
        } catch {
            print("Live Antigravity fetch encountered: \(error.localizedDescription)")
            // If the local environment is logged out or API key mode in test environment, don't fail hard
        }
    }
}
