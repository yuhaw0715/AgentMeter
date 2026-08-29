import SwiftUI
import AgentMeterCore

/// Main Desktop dashboard view showing all rate limits, refresh status, and inline Menu Bar display toggles for this Agent.
public struct UsageDashboardView: View {
    @Bindable var viewModel: UsageMonitorViewModel

    public init(viewModel: UsageMonitorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Info Banner
                VStack(spacing: 8) {
                    // Row 1: Left: Provider Title + Plan Badge; Right: Refresh Button
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Text(viewModel.selectedProvider.displayName)
                                .font(.title2.weight(.bold))

                            if let plan = viewModel.currentSnapshot?.accountPlan {
                                Text(plan)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.15))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                        }

                        Spacer()

                        Button {
                            Task {
                                await viewModel.refreshDesktop()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if viewModel.isRefreshing {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text(L10n.refreshing)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                    Text(L10n.refresh)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isRefreshing)
                    }

                    // Row 2: Left: Account Email; Right: Last Updated Timestamp
                    HStack(alignment: .center) {
                        if let email = viewModel.currentSnapshot?.accountEmail {
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let lastRefresh = viewModel.lastRefreshTime {
                            Text(L10n.updatedText(DateFormatterHelper.formatLastRefreshTime(lastRefresh)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Error State Banner
                if let error = viewModel.lastError {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.refreshFailed)
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(L10n.retry) {
                            Task {
                                await viewModel.retry()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Section: Real-time Quotas with Left-Aligned Menu Bar Checkboxes
                if let snapshot = viewModel.currentSnapshot, !snapshot.items.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.currentUsageSection)
                                    .font(.headline)
                                Text(L10n.currentUsageHint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if viewModel.settingsManager.hasCustomizedLimits {
                                Button(L10n.restoreDefaults) {
                                    viewModel.restoreDefaultLimits()
                                }
                                .buttonStyle(.plain)
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
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
                                                viewModel.isLimitVisible(id: item.id)
                                            },
                                            set: { isChecked in
                                                viewModel.setLimitVisibility(
                                                    id: item.id,
                                                    isVisible: isChecked,
                                                    allItems: snapshot.items
                                                )
                                            }
                                        )
                                    )
                                    .toggleStyle(.checkbox)
                                    .help(L10n.showInMenuBar)

                                    // Rate Limit Card View
                                    RateLimitCardView(item: item, isCompact: false)
                                }
                            }
                        }
                    }
                } else if !viewModel.isRefreshing {
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
            .padding(24)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}
