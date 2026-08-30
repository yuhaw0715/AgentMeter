import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Antigravity Cache & Settings Tests")
struct AntigravityCacheAndSettingsTests {
    @Test("Cache isolates Codex and Antigravity snapshots")
    func testMultiProviderCacheIsolation() {
        let cache = SmartCacheManager()

        let codexSnapshot = RateLimitSnapshot(
            provider: .codex,
            items: [RateLimitItem(id: "codex_5h", name: "5-Hour", usedPercentage: 10.0)]
        )
        let agySnapshot = RateLimitSnapshot(
            provider: .antigravity,
            items: [RateLimitItem(id: "gemini_weekly", name: "Gemini Weekly", usedPercentage: 30.0)]
        )

        cache.store(codexSnapshot)
        cache.store(agySnapshot)

        #expect(cache.currentSnapshot(for: .codex)?.items.first?.id == "codex_5h")
        #expect(cache.currentSnapshot(for: .antigravity)?.items.first?.id == "gemini_weekly")

        // Invalidate only Antigravity
        cache.invalidate(for: .antigravity)
        #expect(cache.currentSnapshot(for: .antigravity) == nil)
        #expect(cache.currentSnapshot(for: .codex)?.items.first?.id == "codex_5h")

        // Store and invalidate all
        cache.store(agySnapshot)
        cache.invalidate()
        #expect(cache.currentSnapshot(for: .antigravity) == nil)
        #expect(cache.currentSnapshot(for: .codex) == nil)
    }

    @Test("SettingsManager manages per-provider limit visibility")
    func testPerProviderSettings() {
        let userDefaults = UserDefaults(suiteName: "AntigravityTestSettings_\(UUID().uuidString)")!
        let settings = SettingsManager(userDefaults: userDefaults)

        let item1 = RateLimitItem(id: "g_5h", name: "Gemini 5h", usedPercentage: 5.0)
        let item2 = RateLimitItem(id: "g_weekly", name: "Gemini Weekly", usedPercentage: 20.0)

        // 1. Initial discovery: hasCustomizedLimits is false, all items are visible
        #expect(settings.hasCustomizedLimits(for: .antigravity) == false)
        let visibleInitial = settings.resolveVisibleLimits(from: [item1, item2], for: .antigravity)
        #expect(visibleInitial.count == 2)

        // 2. User customizes: only pin item1
        settings.setSelectedLimitIds(["g_5h"], for: .antigravity)
        #expect(settings.hasCustomizedLimits(for: .antigravity) == true)
        #expect(settings.selectedLimitIds(for: .antigravity) == ["g_5h"])

        let visibleCustom = settings.resolveVisibleLimits(from: [item1, item2], for: .antigravity)
        #expect(visibleCustom.count == 1)
        #expect(visibleCustom.first?.id == "g_5h")

        // Codex settings should remain unaffected
        #expect(settings.hasCustomizedLimits(for: .codex) == false)

        // 3. Restore defaults
        settings.restoreAutomaticDefaults(for: .antigravity)
        #expect(settings.hasCustomizedLimits(for: .antigravity) == false)
        let visibleRestored = settings.resolveVisibleLimits(from: [item1, item2], for: .antigravity)
        #expect(visibleRestored.count == 2)
    }
}
