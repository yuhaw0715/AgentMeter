import Foundation

/// Date and time formatting utility that respects system locale, timezone, and user format preferences.
public struct DateFormatterHelper: Sendable {
    public init() {}

    /// Formats a reset date into localized short date and time string.
    public static func formatResetDate(
        _ date: Date,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formats timestamp in standard `yyyy-MM-dd HH:mm:ss` format.
    public static func formatLastRefreshTime(
        _ date: Date,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
