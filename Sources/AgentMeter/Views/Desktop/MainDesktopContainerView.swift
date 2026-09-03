import SwiftUI
import AgentMeterCore

public enum NavigationSection: String, Hashable, CaseIterable {
    case codex = "codex"
    case antigravity = "antigravity"
    case settings = "settings"
    case diagnostics = "diagnostics"

    public var title: String {
        switch self {
        case .codex:
            return L10n.codexTitle
        case .antigravity:
            return L10n.antigravityTitle
        case .settings:
            return L10n.settingsTitle
        case .diagnostics:
            return L10n.diagnosticsTitle
        }
    }

    public var iconName: String {
        switch self {
        case .codex:
            return "gauge.with.needle"
        case .antigravity:
            return "sparkles"
        case .settings:
            return "gearshape"
        case .diagnostics:
            return "waveform.path.ecg"
        }
    }
}

/// Main desktop window container with sidebar navigation.
public struct MainDesktopContainerView: View {
    @Bindable var viewModel: UsageMonitorViewModel
    @State private var selectedSection: NavigationSection? = .codex

    public init(viewModel: UsageMonitorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    AgentMeterBrandMark(size: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.appName)
                            .font(.headline.weight(.semibold))
                        Text(L10n.isTraditionalChinese ? "你的 AI 額度，一目瞭然。" : "Your AI usage at a glance.")
                            .font(.caption)
                            .foregroundStyle(AgentMeterTheme.secondaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 12)

                List(selection: $selectedSection) {
                    Section(L10n.providers) {
                        NavigationLink(value: NavigationSection.codex) {
                            Label {
                                Text(NavigationSection.codex.title)
                            } icon: {
                                Image(systemName: NavigationSection.codex.iconName)
                            }
                        }

                        NavigationLink(value: NavigationSection.antigravity) {
                            Label {
                                Text(NavigationSection.antigravity.title)
                            } icon: {
                                Image(systemName: NavigationSection.antigravity.iconName)
                            }
                        }
                    }

                    Section(L10n.application) {
                        NavigationLink(value: NavigationSection.settings) {
                            Label(NavigationSection.settings.title, systemImage: NavigationSection.settings.iconName)
                        }
                        NavigationLink(value: NavigationSection.diagnostics) {
                            Label(NavigationSection.diagnostics.title, systemImage: NavigationSection.diagnostics.iconName)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.sidebar)

                HStack(spacing: 7) {
                    Circle()
                        .fill(AgentMeterTheme.success)
                        .frame(width: 7, height: 7)
                    Text(L10n.isTraditionalChinese ? "本機額度監控" : "Local usage monitor")
                        .font(.caption)
                        .foregroundStyle(AgentMeterTheme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(AgentMeterTheme.sidebarMaterial)
            .tint(AgentMeterTheme.accent)
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 250)
        } detail: {
            Group {
                switch selectedSection ?? .codex {
                case .codex:
                    let status = viewModel.environmentStatuses[.codex] ?? .healthy
                    if !status.isReady {
                        EnvironmentSetupView(provider: .codex, status: status) {
                            Task {
                                await viewModel.refreshDesktop(provider: .codex)
                            }
                        }
                    } else {
                        UsageDashboardView(viewModel: viewModel, provider: .codex)
                    }

                case .antigravity:
                    let status = viewModel.environmentStatuses[.antigravity] ?? .healthy
                    if !status.isReady {
                        EnvironmentSetupView(provider: .antigravity, status: status) {
                            Task {
                                await viewModel.refreshDesktop(provider: .antigravity)
                            }
                        }
                    } else {
                        UsageDashboardView(viewModel: viewModel, provider: .antigravity)
                    }

                case .settings:
                    SettingsView(viewModel: viewModel)
                case .diagnostics:
                    DiagnosticsView(viewModel: viewModel)
                }
            }
            .frame(minWidth: 480, minHeight: 400)
            .background(AgentMeterTheme.pageBackground)
        }
        .onChange(of: selectedSection) { _, newSection in
            if let section = newSection {
                if section == .codex {
                    viewModel.selectedProvider = .codex
                    Task { await viewModel.refreshDesktop(provider: .codex) }
                } else if section == .antigravity {
                    viewModel.selectedProvider = .antigravity
                    Task { await viewModel.refreshDesktop(provider: .antigravity) }
                }
            }
        }
        .task {
            await viewModel.refreshDesktop(provider: .codex)
            await viewModel.refreshDesktop(provider: .antigravity)
        }
    }
}
