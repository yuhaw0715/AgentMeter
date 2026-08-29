import SwiftUI
import AgentMeterCore

/// Reusable card view displaying a single rate limit's progress and metadata.
public struct RateLimitCardView: View {
    public let item: RateLimitItem
    public let isCompact: Bool

    public init(item: RateLimitItem, isCompact: Bool = false) {
        self.item = item
        self.isCompact = isCompact
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 5 : 8) {
            HStack(alignment: .center) {
                Text(L10n.localizedLimitName(item.name))
                    .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                    .lineLimit(1)

                Spacer()

                if item.isLimitReached {
                    Text(L10n.limitReached)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(Color.red)
                        .clipShape(Capsule())
                }

                Text("\(item.usedPercentageInt)%")
                    .font(isCompact ? .subheadline.monospacedDigit().weight(.bold) : .title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(progressColor)
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: isCompact ? 5 : 8)

                    Capsule()
                        .fill(progressColor)
                        .frame(
                            width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(item.progressRatio))),
                            height: isCompact ? 5 : 8
                        )
                }
            }
            .frame(height: isCompact ? 5 : 8)

            HStack {
                Text(L10n.remainingText(item.remainingPercentageInt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let resetAt = item.resetAt {
                    Text(L10n.resetsText(formatResetDate(resetAt)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(L10n.resetTimeUnavailable)
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, isCompact ? 12 : 16)
        .padding(.vertical, isCompact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
    }

    private var progressColor: Color {
        if item.usedPercentage >= 90.0 {
            return .red
        } else if item.usedPercentage >= 70.0 {
            return .orange
        } else {
            return .accentColor
        }
    }

    private func formatResetDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}
