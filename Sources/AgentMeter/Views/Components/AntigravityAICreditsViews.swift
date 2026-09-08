import SwiftUI
import AgentMeterCore

/// Shared read-only AI Credits content used by Desktop and Menu Bar.
struct AntigravityAICreditsContentView: View {
    let credits: AntigravityAICredits?
    let isCompact: Bool
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 4 : 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(L10n.aiCreditsTitle, systemImage: "creditcard.circle")
                    .font(isCompact ? .caption.weight(.semibold) : .headline)
                    .foregroundStyle(AgentMeterTheme.primaryText)

                Spacer()

                Text(primaryValue)
                    .font((isCompact ? Font.caption : Font.headline).weight(.semibold).monospacedDigit())
                    .foregroundStyle(valueTint)
            }

            if let detailText {
                Label(detailText, systemImage: "info.circle")
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundStyle(AgentMeterTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let observedAt = credits?.observedAt {
                HStack(spacing: 5) {
                    Text(L10n.lastUpdated)
                    Text(DateFormatterHelper.formatLastRefreshTime(observedAt))
                        .monospacedDigit()
                }
                .font(isCompact ? .caption2 : .caption)
                .foregroundStyle(AgentMeterTheme.secondaryText)
            }
        }
    }

    private var primaryValue: String {
        guard let credits else { return L10n.aiCreditsInformationUnknown }
        if credits.status == .available, let count = credits.availableCount {
            return L10n.formattedAICredits(count)
        }
        return L10n.aiCreditsInformationUnknown
    }

    private var detailText: String? {
        if isStale, credits?.status == .available {
            return L10n.cacheExpired
        }
        guard let status = credits?.status else {
            return L10n.aiCreditsInformationUnknown
        }
        switch status {
        case .available:
            return nil
        case .unsupportedPlan:
            return L10n.aiCreditsUnsupportedPlan
        case .cliFieldUnavailable:
            return L10n.aiCreditsCLIUnavailable
        case .unknown:
            return L10n.aiCreditsInformationUnknown
        }
    }

    private var valueTint: Color {
        credits?.status == .available ? AgentMeterTheme.accent : AgentMeterTheme.secondaryText
    }
}

/// Standalone Desktop card matching the confirmed stacked layout.
struct AntigravityAICreditsCardView: View {
    let credits: AntigravityAICredits?
    let isStale: Bool

    var body: some View {
        AntigravityAICreditsContentView(credits: credits, isCompact: false, isStale: isStale)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AgentMeterTheme.cornerRadius, style: .continuous)
                    .fill(AgentMeterTheme.contentBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AgentMeterTheme.cornerRadius, style: .continuous)
                    .stroke(AgentMeterTheme.divider.opacity(0.8), lineWidth: 0.6)
            }
    }
}
