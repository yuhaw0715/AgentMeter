import Testing
import Foundation
@testable import AgentMeterCore

@Suite("Report Sanitizer Security Tests")
struct ReportSanitizerTests {
    @Test("Redacts emails from diagnostic output")
    func testEmailRedaction() {
        let input = "Account: developer@domain.com, support at user.name+tag@sub.example.org"
        let sanitized = ReportSanitizer.sanitize(input)

        #expect(!sanitized.contains("developer@domain.com"))
        #expect(!sanitized.contains("user.name+tag@sub.example.org"))
        #expect(sanitized.contains("[REDACTED_EMAIL]"))
    }

    @Test("Redacts tokens and secret keys")
    func testTokenRedaction() {
        let input = "Header: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9 and Key: sk-1234567890abcdef1234567890"
        let sanitized = ReportSanitizer.sanitize(input)

        #expect(!sanitized.contains("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"))
        #expect(!sanitized.contains("sk-1234567890abcdef1234567890"))
        #expect(sanitized.contains("[REDACTED_TOKEN]"))
        #expect(sanitized.contains("sk-[REDACTED_KEY]"))
    }

    @Test("Generates formatted markdown diagnostic report")
    func testReportGeneration() {
        let report = ReportSanitizer.generateReport(
            appVersion: "0.1.0",
            osVersion: "macOS 26.0",
            cliPath: "/opt/homebrew/bin/codex",
            environmentStatus: .healthy,
            lastRefreshDate: Date(timeIntervalSince1970: 1700000000),
            lastError: nil
        )

        #expect(report.contains("### AgentMeter Diagnostic Report"))
        #expect(report.contains("0.1.0"))
        #expect(report.contains("/opt/homebrew/bin/codex"))
    }
}
