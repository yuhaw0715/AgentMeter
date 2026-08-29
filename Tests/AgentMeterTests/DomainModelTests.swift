import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Domain Model & Provider Abstraction Tests")
struct DomainModelTests {
    @Test("RateLimitItem percentage rounding and limit reached check")
    func testRateLimitItemCalculations() {
        let item1 = RateLimitItem(
            id: "5h",
            name: "5-Hour Session",
            usedPercentage: 45.6,
            resetAt: Date().addingTimeInterval(3600)
        )
        #expect(item1.usedPercentageInt == 46)
        #expect(item1.remainingPercentageInt == 54)
        #expect(item1.isLimitReached == false)
        #expect(item1.hasResetTime == true)
        #expect(item1.progressRatio == 0.456)

        let reachedItem = RateLimitItem(
            id: "weekly",
            name: "Weekly Limit",
            usedPercentage: 100.0,
            resetAt: nil
        )
        #expect(reachedItem.usedPercentageInt == 100)
        #expect(reachedItem.remainingPercentageInt == 0)
        #expect(reachedItem.isLimitReached == true)
        #expect(reachedItem.hasResetTime == false)
    }

    @Test("RateLimitSnapshot lookup and initialization")
    func testSnapshotLookup() {
        let itemA = RateLimitItem(id: "limit_a", name: "Limit A", usedPercentage: 10.0)
        let itemB = RateLimitItem(id: "limit_b", name: "Limit B", usedPercentage: 80.0)
        let snapshot = RateLimitSnapshot(
            provider: .codex,
            items: [itemA, itemB],
            accountEmail: "user@example.com",
            accountPlan: "Team"
        )

        #expect(snapshot.provider == .codex)
        #expect(snapshot.accountEmail == "user@example.com")
        #expect(snapshot.items.count == 2)
        #expect(snapshot.item(withId: "limit_b")?.name == "Limit B")
        #expect(snapshot.item(withId: "non_existent") == nil)
    }

    @Test("ProviderType MVP support filtering")
    func testProviderTypeMVP() {
        #expect(ProviderType.codex.isSupportedInMVP == true)
        #expect(ProviderType.gemini.isSupportedInMVP == false)
        #expect(ProviderType.antigravity.isSupportedInMVP == false)
    }

    @Test("EnvironmentStatus readiness check")
    func testEnvironmentStatus() {
        #expect(EnvironmentStatus.healthy.isReady == true)
        #expect(EnvironmentStatus.cliMissing(expectedPath: "/usr/bin/codex").isReady == false)
        #expect(EnvironmentStatus.notAuthenticated(message: "Login required").isReady == false)
    }
}
