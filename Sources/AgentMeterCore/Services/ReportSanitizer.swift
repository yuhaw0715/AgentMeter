import Foundation

/// Sanitizes diagnostic reports and environment strings to prevent leaking sensitive information.
public struct ReportSanitizer: Sendable {
    public init() {}

    /// Sanitizes a text string by redacting emails, tokens, and secret parameters.
    public static func sanitize(_ text: String) -> String {
        var result = text

        // 1. Redact email addresses (e.g. user@example.com -> u***@example.com)
        let emailRegex = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#
        if let regex = try? NSRegularExpression(pattern: emailRegex, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "[REDACTED_EMAIL]")
        }

        // 2. Redact OpenAI / Bearer / JWT / Hex tokens
        let bearerRegex = #"(Bearer\s+)[A-Za-z0-9_\-\.]{10,}"#
        if let regex = try? NSRegularExpression(pattern: bearerRegex, options: [.caseInsensitive]) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1[REDACTED_TOKEN]")
        }

        let skTokenRegex = #"sk-[A-Za-z0-9]{20,}"#
        if let regex = try? NSRegularExpression(pattern: skTokenRegex, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "sk-[REDACTED_KEY]")
        }

        // 3. Redact user home directory username (e.g. /Users/username/... -> /Users/[USER]/...)
        let homeDir = NSHomeDirectory()
        let pathComponents = homeDir.split(separator: "/")
        if pathComponents.count >= 2 && pathComponents[0] == "Users" {
            let username = String(pathComponents[1])
            result = result.replacingOccurrences(of: "/Users/\(username)", with: "/Users/[USER]")
        }

        return result
    }

    /// Generates a sanitized markdown formatted diagnostic report.
    public static func generateReport(
        appVersion: String,
        osVersion: String,
        cliPath: String?,
        environmentStatus: EnvironmentStatus,
        lastRefreshDate: Date?,
        lastError: String?
    ) -> String {
        let rawReport = """
        ### AgentMeter Diagnostic Report
        - **App Version**: \(appVersion)
        - **macOS Version**: \(osVersion)
        - **Codex CLI Path**: \(cliPath ?? "Not Found")
        - **Environment Status**: \(environmentStatus)
        - **Last Refresh Time**: \(lastRefreshDate?.description ?? "Never")
        - **Last Error**: \(lastError ?? "None")
        """
        return sanitize(rawReport)
    }
}
