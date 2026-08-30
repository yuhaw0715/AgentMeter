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
                HStack(spacing: 7) {
                    Text("AM")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Text(L10n.appName)
                        .font(.headline)
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
            .background(Color(nsColor: .windowBackgroundColor))

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
                Button(L10n.openMainWindow) {
                    onOpenMainWindow()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)

                Spacer()

                Button(L10n.quit) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 350)
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
                Text(provider.displayName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            // Section Content
            if let error = error {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(L10n.refreshError)
                            .font(.caption.weight(.semibold))
                    }
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
                .background(Color.orange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            } else {
                Text(L10n.noQuotaDataYet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
        }
    }
}
