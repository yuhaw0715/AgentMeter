import SwiftUI
import AgentMeterCore

/// Popover view shown when the Menu Bar extra icon is clicked, dynamically sizing to content and grouped by Provider.
public struct MenuBarPopoverView: View {
    @Bindable var viewModel: UsageMonitorViewModel
    public let onOpenMainWindow: () -> Void

    public init(viewModel: UsageMonitorViewModel, onOpenMainWindow: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onOpenMainWindow = onOpenMainWindow
    }

    private var isAnyRefreshing: Bool {
        !viewModel.refreshingProviders.isEmpty
    }

    private var supportedProviders: [ProviderType] {
        let list = viewModel.providerRegistry.supportedProviders.map { $0.providerType }
        return list.isEmpty ? [.codex, .antigravity] : list
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with AM Monogram badge
            HStack {
                HStack(spacing: 9) {
                    AgentMeterBrandMark(size: 29)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(L10n.appName)
                            .font(.headline.weight(.semibold))
                        Text(L10n.isTraditionalChinese ? "額度速覽" : "Usage at a glance")
                            .font(.caption2)
                            .foregroundStyle(AgentMeterTheme.secondaryText)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.refreshMenuBar(force: true)
                    }
                } label: {
                    if isAnyRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(isAnyRefreshing)
                .help(L10n.refresh)

                Button {
                    onOpenMainWindow()
                } label: {
                    Image(systemName: "macwindow")
                }
                .buttonStyle(.borderless)
                .help(L10n.openMainWindow)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AgentMeterTheme.glassMaterial)

            Divider()

            // Main Grouped Content Area (dynamically adapts height to item count, up to 620pt)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(supportedProviders) { provider in
                        providerSection(for: provider)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 620)
            .fixedSize(horizontal: false, vertical: true)

            Divider()

            // Footer
            HStack {
                Button {
                    onOpenMainWindow()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "macwindow")
                        Text(L10n.openMainWindow)
                    }
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AgentMeterTheme.accent)

                Spacer()

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                        Text(L10n.quit)
                    }
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(AgentMeterTheme.secondaryText)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AgentMeterTheme.glassMaterial)
        }
        .frame(width: 350)
        .background(AgentMeterTheme.glassMaterial)
        .task {
            await viewModel.refreshMenuBar(force: false)
        }
    }

    @ViewBuilder
    private func providerSection(for provider: ProviderType) -> some View {
        let isRefreshing = viewModel.refreshingProviders.contains(provider)
        let error = viewModel.lastErrors[provider]
        let items = viewModel.visibleLimits(for: provider)

        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            HStack {
                Image(systemName: provider == .codex ? "terminal" : "sparkles")
                    .foregroundStyle(AgentMeterTheme.accent)
                    .font(.caption.weight(.semibold))

                Text(provider.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AgentMeterTheme.primaryText)

                Spacer()

                if isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                } else if error == nil {
                    AgentMeterStatusPill(
                        title: L10n.isTraditionalChinese ? "已連線" : "Connected",
                        tint: AgentMeterTheme.success
                    )
                }
            }

            // Section Content
            if let error = error {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AgentMeterTheme.warning)
                            .font(.caption)
                        Text(L10n.refreshError)
                            .font(.caption.weight(.semibold))
                    }
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                        .multilineTextAlignment(.center)

                    Button(L10n.retry) {
                        Task {
                            await viewModel.executeFetch(for: provider, bypassCache: true)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(AgentMeterTheme.warning.opacity(0.10), in: RoundedRectangle(cornerRadius: AgentMeterTheme.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AgentMeterTheme.cornerRadius, style: .continuous)
                        .stroke(AgentMeterTheme.warning.opacity(0.25), lineWidth: 0.7)
                }
            } else if !items.isEmpty {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        RateLimitCardView(item: item, isCompact: true)
                    }
                }
            } else if isRefreshing {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(provider == .codex ? L10n.fetchingCodexQuota : L10n.fetchingAntigravityQuota)
                        .font(.caption)
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            } else {
                Text(L10n.noQuotaDataYet)
                    .font(.caption)
                    .foregroundStyle(AgentMeterTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
    }
}
