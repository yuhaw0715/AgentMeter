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

    @Test("Reset credit model preserves detail availability and legacy snapshot decoding")
    func testResetCreditModelAndCodableCompatibility() throws {
        let expiration = Date(timeIntervalSince1970: 1_800_000_000)
        let credit = RateLimitResetCredit(
            id: "opaque-credit-id",
            resetType: "five_hour",
            status: "available",
            grantedAt: Date(timeIntervalSince1970: 1_700_000_000),
            expiresAt: expiration,
            title: "Server title",
            description: "Server description"
        )
        let summary = RateLimitResetCredits(availableCount: 2, credits: [credit])
        #expect(summary.detailsProvided == true)
        #expect(summary.missingDetailCount == 1)
        #expect(summary.isKnownZero == false)

        let snapshot = RateLimitSnapshot(
            provider: .codex,
            items: [],
            resetCredits: summary
        )
        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(RateLimitSnapshot.self, from: encoded)
        #expect(decoded == snapshot)
        #expect(decoded.resetCredits?.credits?.first?.title == "Server title")

        let legacySnapshot = RateLimitSnapshot(provider: .codex, items: [RateLimitItem(id: "legacy", name: "Legacy", usedPercentage: 1)])
        let legacyData = try JSONEncoder().encode(legacySnapshot)
        let legacyDecoded = try JSONDecoder().decode(RateLimitSnapshot.self, from: legacyData)
        #expect(legacyDecoded.resetCredits == nil)
        #expect(legacyDecoded.item(withId: "legacy") != nil)

        let emptySummary = RateLimitResetCredits(availableCount: 0, credits: [])
        #expect(emptySummary.detailsProvided == true)
        #expect(emptySummary.missingDetailCount == 0)
        #expect(emptySummary.isKnownZero == true)

        let unavailableSummary = RateLimitResetCredits(availableCount: 4, credits: nil)
        #expect(unavailableSummary.detailsProvided == false)
        #expect(unavailableSummary.missingDetailCount == nil)
    }

    @Test("Reset credit expiration is presentation-only")
    func testResetCreditExpirationState() {
        let expiration = Date(timeIntervalSince1970: 1_000)
        let credit = RateLimitResetCredit(id: "credit", expiresAt: expiration)
        #expect(credit.isExpired(at: Date(timeIntervalSince1970: 999)) == false)
        #expect(credit.isExpired(at: expiration) == true)
        #expect(credit.isExpired(at: Date(timeIntervalSince1970: 1_001)) == true)
        #expect(RateLimitResetCredit(id: "undated").isExpired(at: Date(timeIntervalSince1970: 10_000)) == false)
    }

    @Test("ProviderType support filtering")
    func testProviderTypeSupport() {
        #expect(ProviderType.codex.isSupported == true)
        #expect(ProviderType.antigravity.isSupported == true)
        #expect(ProviderType.gemini.isSupported == false)
    }

    @Test("EnvironmentStatus readiness check")
    func testEnvironmentStatus() {
        #expect(EnvironmentStatus.healthy.isReady == true)
        #expect(EnvironmentStatus.cliMissing(expectedPath: "/usr/bin/codex").isReady == false)
        #expect(EnvironmentStatus.notAuthenticated(message: "Login required").isReady == false)
    }
}
