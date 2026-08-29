import SwiftUI
import AgentMeterCore

/// Settings view managing preferences, TTL, custom paths, and UI language.
public struct SettingsView: View {
    @Bindable var viewModel: UsageMonitorViewModel

    @State private var cacheTTL: Double
    @State private var customPath: String
    @State private var launchAtLogin: Bool
    @State private var appLanguage: AppLanguage

    public init(viewModel: UsageMonitorViewModel) {
        self.viewModel = viewModel
        _cacheTTL = State(initialValue: viewModel.settingsManager.cacheTTLSeconds)
        _customPath = State(initialValue: viewModel.settingsManager.customCodexPath)
        _launchAtLogin = State(initialValue: viewModel.settingsManager.isLaunchAtLoginEnabled)
        _appLanguage = State(initialValue: viewModel.settingsManager.appLanguage)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.settingsTitle)
                        .font(.title2.weight(.bold))
                    Text(L10n.settingsSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // General Preferences
                GroupBox(L10n.generalSection) {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(L10n.launchAtLoginOption, isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, newValue in
                                viewModel.settingsManager.setLaunchAtLogin(enabled: newValue)
                            }

                        HStack(alignment: .center) {
                            Text(L10n.cacheTTLOption)
                            Spacer()
                            Picker("", selection: $cacheTTL) {
                                Text(L10n.isTraditionalChinese ? "1 分鐘" : "1 Minute").tag(60.0)
                                Text(L10n.isTraditionalChinese ? "3 分鐘" : "3 Minutes").tag(180.0)
                                Text(L10n.isTraditionalChinese ? "5 分鐘 (預設)" : "5 Minutes (Default)").tag(300.0)
                                Text(L10n.isTraditionalChinese ? "10 分鐘" : "10 Minutes").tag(600.0)
                                Text(L10n.isTraditionalChinese ? "15 分鐘" : "15 Minutes").tag(900.0)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 240, alignment: .trailing)
                            .onChange(of: cacheTTL) { _, newValue in
                                viewModel.settingsManager.cacheTTLSeconds = newValue
                            }
                        }

                        HStack(alignment: .center) {
                            Text(L10n.languageOption)
                            Spacer()
                            Picker("", selection: $appLanguage) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Text(lang.displayName).tag(lang)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 240, alignment: .trailing)
                            .onChange(of: appLanguage) { _, newValue in
                                viewModel.settingsManager.appLanguage = newValue
                            }
                        }
                    }
                    .padding(10)
                }

                // Codex CLI Path
                GroupBox(L10n.codexConfigSection) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.customExecutablePath)
                            .font(.subheadline.weight(.medium))

                        HStack {
                            TextField("/opt/homebrew/bin/codex", text: $customPath)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: customPath) { _, newValue in
                                    viewModel.settingsManager.customCodexPath = newValue
                                }

                            Button(L10n.browse) {
                                selectCustomExecutable()
                            }
                        }

                        Text(L10n.autoDetectHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                }
            }
            .padding(24)
        }
    }

    private func selectCustomExecutable() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.isTraditionalChinese ? "選取 Codex 執行檔" : "Select Codex Executable"

        if panel.runModal() == .OK, let url = panel.url {
            customPath = url.path
            viewModel.settingsManager.customCodexPath = url.path
        }
    }
}
