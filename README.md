# AgentMeter ⚡️

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B%20%7C%2015%2B-lightgrey.svg)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

**AgentMeter** 是一款專為 macOS 設計的原生、輕量級 AI Coding Agent 使用額度監控器。MVP 版本聚焦於 **ChatGPT Codex**，透過官方 Codex CLI 的 `app-server` JSON-RPC 介面（`account/rateLimits/read`）獲取即時額度快照。

---

## ✨ 核心特色 (Features)

- **macOS 原生體驗**：純 SwiftUI 與 Swift 6 現代併發打造，提供 Desktop 完整儀表板與常駐 Menu Bar Popover。
- **官方 CLI 整合**：直接透過本地官方 `codex app-server` 的標準 JSON-RPC 2.0 通訊獲取額度，絕不抓取瀏覽器 Cookie、不爬取私有端點。
- **動態額度解析**：自動識別並動態正規化所有 Provider 額度項目（如 5 小時工作階段、每週額度、新額度類型），具備高容錯性。
- **Smart Cache 智慧快取**：Menu Bar 點擊秒開，具備自訂 TTL（預設 5 分鐘）與過期主動更新機制，不佔用多餘系統資源與電量。
- **隱私與安全至上**：零雲端同步（無 CloudKit/伺服器後端）、零資料收集（無 Telemetry/Analytics），內建敏感資訊遮蔽的診斷報告匯出工具。
- **雙語在地化**：完整支援繁體中文（Traditional Chinese）與英文（English），自動遵循系統時區與 12/24 小時制。

---

## 📦 安裝方式 (Installation)

### 透過 Homebrew 安裝

您可以透過自訂 Homebrew Tap 進行一行指令安裝：

```bash
brew install --cask yuhaw0715/tap/agentmeter
```

### 解除安裝 (Uninstall)

- 一般解除安裝：
  ```bash
  brew uninstall --cask agentmeter
  ```
- 完整清除應用程式快取與本機設定（`--zap` 不會變更您的 Codex CLI 登入憑證）：
  ```bash
  brew uninstall --zap --cask agentmeter
  ```

---

## 🛠️ 開發與建置 (Development & Testing)

### 系統需求
- macOS 15.0+ (Sequoia) / macOS 26+
- Swift 6.0+ / Xcode 16+

### 執行單元測試
```bash
swift test
```

### 編譯應用程式
```bash
swift build -c release
```

### 建立 GitHub Release 發布產物

`swift build` 只會產生 executable。若要建立 Homebrew Cask 可安裝的完整 App Bundle 與 ZIP，請執行：

```bash
./scripts/build-release.sh
```

腳本會執行 Release build、組裝並以 ad-hoc identity 簽署 `AgentMeter.app`、驗證 Bundle 與 ZIP 結構，成功後移除中間 App Bundle，最後只保留：

```text
releases/AgentMeter-v0.1.0.zip
```

如需使用本機 Keychain 中的 Developer ID Application identity，可指定：

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./scripts/build-release.sh
```

> Developer ID 簽署不等同 Apple notarization；目前腳本不執行 notarize 或 staple。

建立與 `Resources/Info.plist` 版本一致的 Git tag 後，可將 ZIP 上傳至 GitHub Release：

```bash
gh release create v0.1.0 \
  releases/AgentMeter-v0.1.0.zip \
  --verify-tag \
  --title "AgentMeter 0.1.0" \
  --generate-notes
```

腳本最後輸出的 SHA-256 必須填入 `homebrew-tap/Casks/agentmeter.rb`，取代暫時的 `sha256 :no_check`，再驗證安裝：

```bash
brew update
brew install --cask yuhaw0715/tap/agentmeter
```

---

## 🏗️ 架構分層 (Architecture)

AgentMeter 採用 Clean Architecture 與 MVVM 分層架構：

```
Sources/
├── AgentMeterCore/              # 核心領域、Provider 與業務邏輯庫
│   ├── Domain/                 # RateLimitItem, Snapshot, ProviderType, AgentProvider 協定
│   ├── Providers/Codex/        # CodexEnvironmentDetector, CodexProcessManager, CodexRateLimitProvider
│   ├── Services/               # SmartCacheManager, SettingsManager, ReportSanitizer
│   ├── ViewModels/             # UsageMonitorViewModel (@Observable)
│   └── Localization/           # L10n, DateFormatterHelper
└── AgentMeter/                 # macOS SwiftUI 應用程式 UI
    ├── App/                    # AgentMeterApp (WindowGroup + MenuBarExtra)
    └── Views/                  # Desktop Dashboard, MenuBar Popover, Settings, Diagnostics
```

---

## 📄 授權條款 (License)

本專案採用 [MIT License](LICENSE) 開源授權。
