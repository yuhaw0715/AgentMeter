import SwiftUI
import AgentMeterCore

/// Setup and troubleshooting guide view displayed when environment status is not healthy.
public struct EnvironmentSetupView: View {
    public let status: EnvironmentStatus
    public let onRetry: () -> Void

    public init(status: EnvironmentStatus, onRetry: @escaping () -> Void) {
        self.status = status
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)

            Text(titleText)
                .font(.title2.weight(.bold))

            Text(descriptionText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            if let command = recommendedCommand {
                HStack {
                    Text(command)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(command, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(L10n.checkAgain) {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconName: String {
        switch status {
        case .healthy:
            return "checkmark.circle.fill"
        case .cliMissing:
            return "terminal.fill"
        case .notAuthenticated:
            return "person.crop.circle.badge.exclamationmark"
        case .appServerUnavailable, .error:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .healthy:
            return .green
        case .cliMissing, .notAuthenticated:
            return .orange
        case .appServerUnavailable, .error:
            return .red
        }
    }

    private var titleText: String {
        switch status {
        case .healthy:
            return L10n.envReadyTitle
        case .cliMissing:
            return L10n.cliMissingTitle
        case .notAuthenticated:
            return L10n.notAuthTitle
        case .appServerUnavailable:
            return L10n.appServerUnavailableTitle
        case .error:
            return L10n.envErrorTitle
        }
    }

    private var descriptionText: String {
        switch status {
        case .healthy:
            return L10n.isTraditionalChinese
                ? "Codex CLI 環境正常，可即時獲取額度。"
                : "Codex environment is healthy and ready to fetch quota."
        case .cliMissing(let path):
            return L10n.isTraditionalChinese
                ? "找不到 codex 執行檔。請安裝 Codex CLI 或至偏好設定指定自訂路徑。（檢查路徑：\(path)）"
                : "Could not find the codex binary. Please install the Codex CLI or configure a custom binary path in Settings. (Checked: \(path))"
        case .notAuthenticated(let message):
            return L10n.isTraditionalChinese
                ? "Codex CLI 已安裝但尚未登入。請透過下方指令進行登入：\(message)"
                : "Codex CLI is installed but not authenticated. Please log in using the command below: \(message)"
        case .appServerUnavailable(let reason):
            return L10n.isTraditionalChinese
                ? "無法連接至 codex app-server：\(reason)"
                : "Could not connect to codex app-server: \(reason)"
        case .error(let description):
            return description
        }
    }

    private var recommendedCommand: String? {
        switch status {
        case .cliMissing:
            return "npm install -g @openai/codex"
        case .notAuthenticated:
            return "codex login"
        default:
            return nil
        }
    }
}
