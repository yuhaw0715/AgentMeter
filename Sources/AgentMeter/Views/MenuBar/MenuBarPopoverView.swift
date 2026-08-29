import SwiftUI
import AgentMeterCore

/// Popover view shown when the Menu Bar extra icon is clicked.
public struct MenuBarPopoverView: View {
    @Bindable var viewModel: UsageMonitorViewModel
    public let onOpenMainWindow: () -> Void

    public init(viewModel: UsageMonitorViewModel, onOpenMainWindow: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onOpenMainWindow = onOpenMainWindow
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
                    if viewModel.isRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isRefreshing)
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

            // Main Content Area
            Group {
                if let error = viewModel.lastError {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                        Text(L10n.refreshError)
                            .font(.subheadline.weight(.semibold))
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button(L10n.retry) {
                            Task {
                                await viewModel.refreshMenuBar(force: true)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else if !viewModel.visibleLimits.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(viewModel.visibleLimits) { item in
                                RateLimitCardView(item: item, isCompact: true)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .frame(minHeight: 180, maxHeight: 320)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.regular)
                        Text(viewModel.isRefreshing ? L10n.fetchingQuota : L10n.noQuotaDataYet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .padding()
                }
            }

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
        .frame(width: 330)
        .task {
            await viewModel.refreshMenuBar(force: false)
        }
    }
}
