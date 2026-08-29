import SwiftUI
import AgentMeterCore

/// Diagnostics screen displaying system state and sanitized report export.
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

                VStack(spacing: 12) {
                    DiagnosticRow(title: L10n.agentMeterVersion, value: AgentMeterCore.version)
                    DiagnosticRow(title: L10n.macOSVersion, value: ProcessInfo.processInfo.operatingSystemVersionString)
                    DiagnosticRow(title: L10n.codexCLIPath, value: resolvedCliPath)
                    DiagnosticRow(title: L10n.environmentStatusText, value: "\(viewModel.environmentStatus)")
                    DiagnosticRow(
                        title: L10n.lastRefreshTime,
                        value: viewModel.lastRefreshTime.map { DateFormatterHelper.formatLastRefreshTime($0) } ?? L10n.never
                    )
                    DiagnosticRow(title: L10n.lastErrorText, value: viewModel.lastError ?? L10n.none)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(24)
        }
    }

    private var resolvedCliPath: String {
        let detector = CodexEnvironmentDetector(
            customExecutablePath: viewModel.settingsManager.customCodexPath.isEmpty ? nil : viewModel.settingsManager.customCodexPath
        )
        return detector.resolveExecutablePath() ?? L10n.notFound
    }

    private func copySanitizedReport() {
        let report = ReportSanitizer.generateReport(
            appVersion: AgentMeterCore.version,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            cliPath: resolvedCliPath,
            environmentStatus: viewModel.environmentStatus,
            lastRefreshDate: viewModel.lastRefreshTime,
            lastError: viewModel.lastError
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
