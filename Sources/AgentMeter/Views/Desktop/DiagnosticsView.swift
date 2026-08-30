import SwiftUI
import AgentMeterCore

/// Diagnostics screen displaying system state and sanitized report export for all providers.
public struct DiagnosticsView: View {
    @Bindable var viewModel: UsageMonitorViewModel
    @State private var isCopied: Bool = false

    public init(viewModel: UsageMonitorViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.diagnosticsTitle)
                            .font(.title.weight(.bold))
                        Text(L10n.diagnosticsSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        copySanitizedReport()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            Text(isCopied ? L10n.copied : L10n.copyDiagnosticReport)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Divider()

                // System info
                VStack(spacing: 12) {
                    DiagnosticRow(title: L10n.agentMeterVersion, value: AgentMeterCore.version)
                    DiagnosticRow(title: L10n.macOSVersion, value: ProcessInfo.processInfo.operatingSystemVersionString)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Codex Diagnostics
                GroupBox(L10n.codexTitle) {
                    VStack(spacing: 12) {
                        DiagnosticRow(title: L10n.codexCLIPath, value: resolvedCodexCliPath)
                        DiagnosticRow(title: L10n.environmentStatusText, value: "\(viewModel.environmentStatuses[.codex] ?? .healthy)")
                        DiagnosticRow(
                            title: L10n.lastRefreshTime,
                            value: viewModel.lastRefreshTimes[.codex].map { DateFormatterHelper.formatLastRefreshTime($0) } ?? L10n.never
                        )
                        DiagnosticRow(title: L10n.lastErrorText, value: viewModel.lastErrors[.codex] ?? L10n.none)
                    }
                    .padding(10)
                }

                // Antigravity Diagnostics
                GroupBox(L10n.antigravityTitle) {
                    VStack(spacing: 12) {
                        DiagnosticRow(title: L10n.antigravityCLIPath, value: resolvedAntigravityCliPath)
                        DiagnosticRow(title: L10n.environmentStatusText, value: "\(viewModel.environmentStatuses[.antigravity] ?? .healthy)")
                        DiagnosticRow(
                            title: L10n.lastRefreshTime,
                            value: viewModel.lastRefreshTimes[.antigravity].map { DateFormatterHelper.formatLastRefreshTime($0) } ?? L10n.never
                        )
                        DiagnosticRow(title: L10n.lastErrorText, value: viewModel.lastErrors[.antigravity] ?? L10n.none)
                    }
                    .padding(10)
                }
            }
            .padding(24)
        }
    }

    private var resolvedCodexCliPath: String {
        let detector = CodexEnvironmentDetector(
            customExecutablePath: viewModel.settingsManager.customCodexPath.isEmpty ? nil : viewModel.settingsManager.customCodexPath
        )
        return detector.resolveExecutablePath() ?? L10n.notFound
    }

    private var resolvedAntigravityCliPath: String {
        let detector = AntigravityEnvironmentDetector(
            customExecutablePath: viewModel.settingsManager.customAntigravityPath.isEmpty ? nil : viewModel.settingsManager.customAntigravityPath
        )
        return detector.resolveExecutablePath() ?? L10n.notFound
    }

    private func copySanitizedReport() {
        let report = ReportSanitizer.generateMultiProviderReport(
            appVersion: AgentMeterCore.version,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            codexPath: resolvedCodexCliPath,
            codexStatus: viewModel.environmentStatuses[.codex] ?? .healthy,
            codexLastRefresh: viewModel.lastRefreshTimes[.codex],
            codexLastError: viewModel.lastErrors[.codex],
            antigravityPath: resolvedAntigravityCliPath,
            antigravityStatus: viewModel.environmentStatuses[.antigravity] ?? .healthy,
            antigravityLastRefresh: viewModel.lastRefreshTimes[.antigravity],
            antigravityLastError: viewModel.lastErrors[.antigravity]
        )
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(report, forType: .string)

        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isCopied = false
        }
    }
}

private struct DiagnosticRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.body.weight(.medium))
                .frame(width: 180, alignment: .leading)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}
