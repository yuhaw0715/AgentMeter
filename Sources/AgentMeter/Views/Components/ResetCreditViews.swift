import SwiftUI
import AgentMeterCore

/// A read-only row for one reset credit. Server titles and descriptions are
/// intentionally not rendered; the ordinal and expiration are localized.
struct ResetCreditRowView: View {
    let credit: RateLimitResetCredit
    let ordinal: Int
    let isCompact: Bool
    let now: Date

    init(credit: RateLimitResetCredit, ordinal: Int, isCompact: Bool = false, now: Date = Date()) {
        self.credit = credit
        self.ordinal = ordinal
        self.isCompact = isCompact
        self.now = now
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: isCompact ? 8 : 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: isCompact ? 5 : 7))
                .foregroundStyle(credit.isExpired(at: now) ? AgentMeterTheme.warning : AgentMeterTheme.accent)
                .frame(width: isCompact ? 10 : 16)

            VStack(alignment: .leading, spacing: isCompact ? 0 : 2) {
                Text(L10n.resetCreditLabel(ordinal))
                    .font(isCompact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
                    .lineLimit(1)

                if !isCompact {
                    Text(L10n.resetCreditExpirationLabel)
                        .font(.caption)
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                }
            }

            Spacer(minLength: 8)

            Text(expirationText)
                .font((isCompact ? Font.caption : Font.subheadline).monospacedDigit())
                .foregroundStyle(credit.isExpired(at: now) ? AgentMeterTheme.warning : AgentMeterTheme.secondaryText)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, isCompact ? 2 : 14)
        .padding(.vertical, isCompact ? 5 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isCompact
                ? AnyShapeStyle(.clear)
                : AnyShapeStyle(AgentMeterTheme.contentBackground.opacity(0.72)),
            in: RoundedRectangle(cornerRadius: isCompact ? 0 : 12, style: .continuous)
        )
    }

    private var expirationText: String {
        if credit.isExpired(at: now) {
            return L10n.resetCreditExpiredWaiting
        }
        guard let expiresAt = credit.expiresAt else {
            return L10n.resetCreditNoExpiration
        }
        return DateFormatterHelper.formatResetCreditDate(expiresAt)
    }
}

/// Shared status/list rendering used by the Desktop card and Menu Bar section.
struct ResetCreditListView: View {
    let resetCredits: RateLimitResetCredits?
    let isCompact: Bool
    let now: Date

    init(resetCredits: RateLimitResetCredits?, isCompact: Bool = false, now: Date = Date()) {
        self.resetCredits = resetCredits
        self.isCompact = isCompact
        self.now = now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 2 : 7) {
            if let resetCredits {
                if let credits = resetCredits.credits {
                    ForEach(Array(credits.enumerated()), id: \.element.id) { index, credit in
                        ResetCreditRowView(
                            credit: credit,
                            ordinal: index + 1,
                            isCompact: isCompact,
                            now: now
                        )
                    }

                    if let missingCount = resetCredits.missingDetailCount, missingCount > 0 {
                        Label(
                            L10n.resetCreditMissingDetails(missingCount),
                            systemImage: "info.circle"
                        )
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                        .padding(.top, isCompact ? 3 : 5)
                    }
                } else {
                    Text(L10n.resetCreditDetailsUnavailable)
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text(L10n.resetCreditsInformationUnavailable)
                    .font(isCompact ? .caption2 : .caption)
                    .foregroundStyle(AgentMeterTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Standalone Desktop reset-credit card following the confirmed stacked layout.
struct ResetCreditsCardView: View {
    let resetCredits: RateLimitResetCredits?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label(L10n.resetCreditsTitle, systemImage: "arrow.clockwise.circle")
                    .font(.headline)
                    .foregroundStyle(AgentMeterTheme.primaryText)

                Spacer()

                if let resetCredits {
                    Text(L10n.availableResetCredits(resetCredits.availableCount))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                } else {
                    Text(L10n.resetCreditsInformationUnavailable)
                        .font(.caption)
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                }
            }

            ResetCreditListView(resetCredits: resetCredits)
        }
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
