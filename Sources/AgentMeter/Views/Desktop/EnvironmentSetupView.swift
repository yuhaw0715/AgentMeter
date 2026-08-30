import SwiftUI
import AgentMeterCore

/// Setup and troubleshooting guide view displayed when environment status is not healthy.
public struct EnvironmentSetupView: View {
    public let provider: ProviderType
    public let status: EnvironmentStatus
    public let onRetry: () -> Void

    public init(provider: ProviderType = .codex, status: EnvironmentStatus, onRetry: @escaping () -> Void) {
        self.provider = provider
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
                .frame(maxWidth: 440)

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
        case .unsupportedVersion:
            return "arrow.triangle.2.circlepath.circle.fill"
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
        case .cliMissing, .unsupportedVersion, .notAuthenticated:
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
        case .unsupportedVersion:
            return L10n.unsupportedVersionTitle
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
                ? "\(provider.displayName) CLI 環境正常，可即時獲取額度。"
                : "\(provider.displayName) environment is healthy and ready to fetch quota."
        case .cliMissing(let path):
            if provider == .antigravity {
                return L10n.isTraditionalChinese
                    ? "找不到 agy 執行檔。請安裝 Antigravity CLI 或至偏好設定指定自訂路徑。（檢查路徑：\(path)）"
                    : "Could not find the agy binary. Please install Antigravity CLI or configure a custom binary path in Settings. (Checked: \(path))"
            }
            return L10n.isTraditionalChinese
                ? "找不到 codex 執行檔。請安裝 Codex CLI 或至偏好設定指定自訂路徑。（檢查路徑：\(path)）"
                : "Could not find the codex binary. Please install the Codex CLI or configure a custom binary path in Settings. (Checked: \(path))"
        case .unsupportedVersion(let current, let required):
            return L10n.isTraditionalChinese
                ? "目前 \(provider.displayName) CLI 版本為 \(current)，需要 \(required) 以上版本。請升級 CLI。"
                : "Current \(provider.displayName) CLI version is \(current), but \(required) or higher is required. Please update the CLI."
        case .notAuthenticated(let message):
            if provider == .antigravity {
                return L10n.isTraditionalChinese
                    ? "Antigravity CLI 已安裝但尚未登入 Google 帳號。請在 Terminal 執行下方指令完成登入："
                    : "Antigravity CLI is installed but not logged into a Google account. Please run the command below in Terminal:"
            }
            return L10n.isTraditionalChinese
                ? "Codex CLI 已安裝但尚未登入。請透過下方指令進行登入：\(message)"
                : "Codex CLI is installed but not authenticated. Please log in using the command below: \(message)"
        case .appServerUnavailable(let reason):
            return L10n.isTraditionalChinese
                ? "無法連接至 \(provider.displayName) 服務：\(reason)"
                : "Could not connect to \(provider.displayName) service: \(reason)"
        case .error(let description):
            return description
        }
    }

    private var recommendedCommand: String? {
        switch status {
        case .cliMissing:
            if provider == .antigravity {
                return "npm install -g @google/antigravity"
            }
            return "npm install -g @openai/codex"
        case .notAuthenticated:
            if provider == .antigravity {
                return "agy"
            }
            return "codex login"
        case .unsupportedVersion:
            if provider == .antigravity {
                return "npm install -g @google/antigravity@latest"
            }
            return nil
        default:
            return nil
        }
    }
}
