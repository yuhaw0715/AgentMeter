import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Antigravity Report Sanitizer Security Tests")
struct AntigravityReportSanitizerTests {
    @Test("Redacts Google API Keys and user directory from multi-provider report")
    func testRedactGoogleKeysAndReport() {
        let textWithKey = "Logged with key: AIzaSyD9xYZ1234567890ABCDEFGHijklmnopqrst"
        let sanitized = ReportSanitizer.sanitize(textWithKey)
        #expect(!sanitized.contains("AIzaSyD9xYZ1234567890ABCDEFGHijklmnopqrst"))
        #expect(sanitized.contains("AIza[REDACTED_KEY]"))

        let multiReport = ReportSanitizer.generateMultiProviderReport(
            appVersion: "1.0.0",
            osVersion: "macOS 15.0",
            codexPath: "/opt/homebrew/bin/codex",
            codexStatus: .healthy,
            codexLastRefresh: Date(),
            codexLastError: nil,
            antigravityPath: "/Users/username/.local/bin/agy",
            antigravityStatus: .healthy,
            antigravityLastRefresh: Date(),
            antigravityLastError: "Auth token Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9 expired"
        )

        #expect(multiReport.contains("### AgentMeter Diagnostic Report"))
        #expect(multiReport.contains("#### ChatGPT Codex"))
        #expect(multiReport.contains("#### Google Antigravity"))
        #expect(!multiReport.contains("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"))
        #expect(multiReport.contains("[REDACTED_TOKEN]"))
    }
}
