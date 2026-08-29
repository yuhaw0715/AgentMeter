import SwiftUI
import AgentMeterCore

public enum NavigationSection: String, Hashable, CaseIterable {
    case codex = "codex"
    case settings = "settings"
    case diagnostics = "diagnostics"

    public var title: String {
        switch self {
        case .codex:
            return L10n.codexTitle
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
            List(selection: $selectedSection) {
                Section(L10n.providers) {
                    NavigationLink(value: NavigationSection.codex) {
                        Label {
                            Text(NavigationSection.codex.title)
                        } icon: {
                            Image(systemName: NavigationSection.codex.iconName)
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
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            Group {
                switch selectedSection ?? .codex {
                case .codex:
                    if !viewModel.environmentStatus.isReady {
                        EnvironmentSetupView(status: viewModel.environmentStatus) {
                            Task {
                                await viewModel.refreshDesktop()
                            }
                        }
                    } else {
                        UsageDashboardView(viewModel: viewModel)
                    }
                case .settings:
                    SettingsView(viewModel: viewModel)
                case .diagnostics:
                    DiagnosticsView(viewModel: viewModel)
                }
            }
            .frame(minWidth: 480, minHeight: 400)
        }
        .task {
            await viewModel.refreshDesktop()
        }
    }
}
