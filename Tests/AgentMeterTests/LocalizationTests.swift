import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Localization & Formatting Tests")
struct LocalizationTests {
    @Test("DateFormatterHelper formats date with specific locale and timezone")
    func testDateFormatting() {
        let date = Date(timeIntervalSince1970: 1787990400)
        let localeEn = Locale(identifier: "en_US")
        let timeZoneUTC = TimeZone(identifier: "UTC")!

        let formatted = DateFormatterHelper.formatResetDate(date, locale: localeEn, timeZone: timeZoneUTC)
        #expect(!formatted.isEmpty)

        let formattedFull = DateFormatterHelper.formatLastRefreshTime(date, locale: localeEn, timeZone: timeZoneUTC)
        #expect(!formattedFull.isEmpty)
        #expect(formattedFull.contains("-") && formattedFull.contains(":"))
    }

    @Test("Dynamic language switching between English and Traditional Chinese")
    func testLanguageSwitching() {
        // Switch to Traditional Chinese
        SettingsManager.shared.appLanguage = .zhHant
        #expect(L10n.isTraditionalChinese == true)
        #expect(L10n.refresh == "重新整理")
        #expect(L10n.limitReached == "已達使用上限")
        #expect(L10n.openMainWindow == "開啟 AgentMeter…")
        #expect(L10n.localizedLimitName("5-Hour Session Limit") == "5 小時工作階段額度")
        #expect(L10n.localizedLimitName("Weekly Limit") == "每週額度")

        // Switch to English
        SettingsManager.shared.appLanguage = .en
        #expect(L10n.isTraditionalChinese == false)
        #expect(L10n.refresh == "Refresh")
        #expect(L10n.limitReached == "Limit reached")
        #expect(L10n.openMainWindow == "Open AgentMeter…")
        #expect(L10n.localizedLimitName("5-Hour Session Limit") == "5-Hour Session Limit")

        // Restore to system
        SettingsManager.shared.appLanguage = .system
    }
}
