import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Smart Cache & Settings Tests")
struct SmartCacheTests {
    @Test("Cache stores and validates TTL freshness")
    func testCacheFreshness() {
        let baseDate = Date()
        let snapshot = RateLimitSnapshot(
            provider: .codex,
            fetchedAt: baseDate,
            items: [RateLimitItem(id: "limit_1", name: "Session Limit", usedPercentage: 40.0)]
        )

        let cache = SmartCacheManager(initialSnapshot: snapshot)

        // 1. Within TTL (e.g. after 60s with 300s TTL) -> Fresh
        let after1Min = baseDate.addingTimeInterval(60)
        let freshResult = cache.getFreshSnapshot(ttl: 300, currentDate: after1Min)
        #expect(freshResult != nil)
        #expect(freshResult?.items.first?.id == "limit_1")

        // 2. Beyond TTL (e.g. after 301s with 300s TTL) -> Expired
        let after6Min = baseDate.addingTimeInterval(301)
        let expiredResult = cache.getFreshSnapshot(ttl: 300, currentDate: after6Min)
        #expect(expiredResult == nil)

        // 3. Invalidate removes snapshot
        cache.invalidate()
        #expect(cache.currentSnapshot == nil)
    }

    @Test("SettingsManager visible limit resolution and default restore")
    func testSettingsLimitResolution() {
        let suiteName = "test.agentmeter.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsManager(userDefaults: defaults)

        let item1 = RateLimitItem(id: "5h", name: "5-Hour", usedPercentage: 20)
        let item2 = RateLimitItem(id: "weekly", name: "Weekly", usedPercentage: 50)
        let item3 = RateLimitItem(id: "extra", name: "Extra", usedPercentage: 80)
        let allItems = [item1, item2, item3]

        // Initially no customization -> returns all items
        let initialVisible = settings.resolveVisibleLimits(from: allItems)
        #expect(initialVisible.count == 3)

        // Customize selection. Presentation order follows the provider
        // snapshot, matching the Desktop dashboard.
        settings.selectedLimitIds = ["weekly", "5h"]
        let customized = settings.resolveVisibleLimits(from: allItems)
        #expect(customized.count == 2)
        #expect(customized[0].id == "5h")
        #expect(customized[1].id == "weekly")

        // Restore defaults
        settings.restoreAutomaticDefaults()
        #expect(settings.hasCustomizedLimits == false)
        let restored = settings.resolveVisibleLimits(from: allItems)
        #expect(restored.count == 3)
    }

    @Test("UsageMonitorViewModel reactive limit visibility toggling")
    @MainActor
    func testViewModelLimitVisibilityToggle() {
        let suiteName = "test.agentmeter.vm.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsManager(userDefaults: defaults)

        let item1 = RateLimitItem(id: "item1", name: "Limit 1", usedPercentage: 10)
        let item2 = RateLimitItem(id: "item2", name: "Limit 2", usedPercentage: 20)
        let items = [item1, item2]

        let snapshot = RateLimitSnapshot(provider: .codex, fetchedAt: Date(), items: items)
        let cache = SmartCacheManager(initialSnapshot: snapshot)

        let vm = UsageMonitorViewModel(cacheManager: cache, settingsManager: settings)
        #expect(vm.visibleLimits.count == 2)
        #expect(vm.isLimitVisible(id: "item1") == true)
        #expect(vm.isLimitVisible(id: "item2") == true)

        // Uncheck item1
        vm.setLimitVisibility(id: "item1", isVisible: false, allItems: items)
        #expect(vm.isLimitVisible(id: "item1") == false)
        #expect(vm.isLimitVisible(id: "item2") == true)
        #expect(vm.visibleLimits.count == 1)
        #expect(vm.visibleLimits.first?.id == "item2")

        // Restore defaults
        vm.restoreDefaultLimits()
        #expect(vm.isLimitVisible(id: "item1") == true)
        #expect(vm.visibleLimits.count == 2)
    }
}
