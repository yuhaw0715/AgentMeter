import SwiftUI
import AgentMeterCore

/// Main Desktop dashboard view showing all rate limits, refresh status, and inline Menu Bar display toggles.
public struct UsageDashboardView: View {
    @Bindable var viewModel: UsageMonitorViewModel
    public let provider: ProviderType

    public init(viewModel: UsageMonitorViewModel, provider: ProviderType = .codex) {
        self.viewModel = viewModel
        self.provider = provider
    }

    private var snapshot: RateLimitSnapshot? {
        viewModel.snapshots[provider]
    }

    private var isRefreshing: Bool {
        viewModel.refreshingProviders.contains(provider)
    }

    private var lastError: String? {
        viewModel.lastErrors[provider]
    }

    private var lastRefreshTime: Date? {
        viewModel.lastRefreshTimes[provider]
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: provider == .codex ? "terminal" : "sparkles")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AgentMeterTheme.accent)
                        .frame(width: 42, height: 42)
                        .background(AgentMeterTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(provider.displayName)
                            .font(.title2.weight(.bold))

                        HStack(spacing: 7) {
                            if provider == .codex, let plan = snapshot?.accountPlan {
                                Text(plan)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AgentMeterTheme.accent)
                            }

                            if provider == .codex, let email = snapshot?.accountEmail {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(AgentMeterTheme.secondaryText)
                            }
                        }
                    }

                    Spacer(minLength: 12)

                    AgentMeterStatusPill(
                        title: isRefreshing ? L10n.refreshing : (lastError == nil ? (L10n.isTraditionalChinese ? "已連線" : "Connected") : L10n.refreshFailed),
                        tint: lastError == nil ? (isRefreshing ? AgentMeterTheme.warning : AgentMeterTheme.success) : AgentMeterTheme.destructive
                    )
                }

                HStack {
                    if let lastRefresh = lastRefreshTime {
                        Label(
                            L10n.updatedText(DateFormatterHelper.formatLastRefreshTime(lastRefresh)),
                            systemImage: "clock"
                        )
                    }

                    Spacer()

                    Button {
                        Task {
                            await viewModel.refreshDesktop(provider: provider)
                        }
                    } label: {
                        Label(isRefreshing ? L10n.refreshing : L10n.refresh, systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AgentMeterTheme.accent)
                    .controlSize(.regular)
                    .disabled(isRefreshing)
                }
                .font(.caption)
                .foregroundStyle(AgentMeterTheme.secondaryText)

                // Error State Banner
                if let error = lastError {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AgentMeterTheme.warning)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.refreshFailed)
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(AgentMeterTheme.secondaryText)
                        }

                        Spacer()

                        Button(L10n.retry) {
                            Task {
                                await viewModel.retry(for: provider)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .background(AgentMeterTheme.warning.opacity(0.10), in: RoundedRectangle(cornerRadius: AgentMeterTheme.cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: AgentMeterTheme.cornerRadius, style: .continuous)
                            .stroke(AgentMeterTheme.warning.opacity(0.25), lineWidth: 0.7)
                    }
                }

                // Section: Real-time Quotas with Left-Aligned Menu Bar Checkboxes
                if let snapshot = snapshot, !snapshot.items.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.currentUsageSection)
                                    .font(.headline)
                                Text(L10n.currentUsageHint)
                                    .font(.caption)
                                    .foregroundStyle(AgentMeterTheme.secondaryText)
                            }

                            Spacer()

                            if viewModel.settingsManager.hasCustomizedLimits(for: provider) {
                                Button(L10n.restoreDefaults) {
                                    viewModel.restoreDefaultLimits(for: provider)
                                }
                                .buttonStyle(.plain)
                                .font(.caption)
                                .foregroundStyle(AgentMeterTheme.accent)
                            }
                        }

                        VStack(spacing: 12) {
                            ForEach(snapshot.items) { item in
                                HStack(alignment: .center, spacing: 12) {
                                    // Checkbox on the left of the card
                                    Toggle(
                                        "",
                                        isOn: Binding(
                                            get: {
                                                viewModel.isLimitVisible(id: item.id, provider: provider)
                                            },
                                            set: { isChecked in
                                                viewModel.setLimitVisibility(
                                                    id: item.id,
                                                    isVisible: isChecked,
                                                    allItems: snapshot.items,
                                                    provider: provider
                                                )
                                            }
                                        )
                                    )
                                    .toggleStyle(.checkbox)
                                    .help(L10n.showInMenuBar)
                                    .tint(AgentMeterTheme.accent)

                                    // Rate Limit Card View
                                    RateLimitCardView(item: item, isCompact: false)
                                }
                            }
                        }
                    }
                } else if !isRefreshing {
                    VStack(spacing: 12) {
                        Image(systemName: "gauge")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text(L10n.noDataAvailable)
                            .font(.headline)
                        Text(L10n.clickRefreshHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(28)
        }
        .background(AgentMeterTheme.pageBackground)
        .frame(minWidth: 500, minHeight: 400)
    }
}
