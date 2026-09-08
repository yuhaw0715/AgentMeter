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

        let formattedCredit = DateFormatterHelper.formatResetCreditDate(date, locale: localeEn, timeZone: timeZoneUTC)
        #expect(formattedCredit == "2026-08-29 08:00:00")
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
        #expect(L10n.resetCreditsTitle == "重置券")
        #expect(L10n.availableResetCredits(0) == "可用重置券 0 張")
        #expect(L10n.resetCreditLabel(2) == "重置券 2")
        #expect(L10n.resetCreditNoExpiration == "無到期資訊")
        #expect(L10n.resetCreditMissingDetails(1) == "其餘 1 張未提供明細")
        #expect(L10n.resetCreditsInformationUnavailable == "重置券資訊未提供")
        #expect(L10n.resetCreditExpiredWaiting == "已到期，等待刷新")
        #expect(L10n.aiCreditsTitle == "AI 點數")
        #expect(L10n.aiCreditsCLIUnavailable == "目前 CLI 版本未提供 AI Credits 資訊")
        #expect(L10n.formattedAICredits(1_000) == "1,000")

        // Switch to English
        SettingsManager.shared.appLanguage = .en
        #expect(L10n.isTraditionalChinese == false)
        #expect(L10n.refresh == "Refresh")
        #expect(L10n.limitReached == "Limit reached")
        #expect(L10n.openMainWindow == "Open AgentMeter…")
        #expect(L10n.localizedLimitName("5-Hour Session Limit") == "5-Hour Session Limit")
        #expect(L10n.resetCreditsTitle == "Reset credits")
        #expect(L10n.availableResetCredits(0) == "0 reset credits available")
        #expect(L10n.resetCreditLabel(2) == "Reset Credit 2")
        #expect(L10n.resetCreditNoExpiration == "No expiration information")
        #expect(L10n.resetCreditMissingDetails(1) == "1 additional credit has no details.")
        #expect(L10n.resetCreditsInformationUnavailable == "Reset credit information unavailable")
        #expect(L10n.resetCreditExpiredWaiting == "Expired, waiting for refresh")
        #expect(L10n.aiCreditsTitle == "AI Credits")
        #expect(L10n.aiCreditsCLIUnavailable == "The current CLI version does not provide AI Credits information")
        #expect(L10n.formattedAICredits(1_000) == "1,000")

        // Restore to system
        SettingsManager.shared.appLanguage = .system
    }
}
