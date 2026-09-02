# AgentMeter ⚡️

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B%20%7C%2015%2B-lightgrey.svg)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

**AgentMeter** 是一款專為 macOS 設計的原生、輕量級 AI Coding Agent 使用額度監控器。目前支援 **ChatGPT Codex** 與 **Google Antigravity**：分別透過 Codex CLI 的 `app-server` JSON-RPC 介面，以及 Antigravity CLI 的唯讀非互動 JSON 查詢取得即時額度快照。

---

## ✨ 核心特色 (Features)

- **極簡純選單列常駐（Stats 模式）**：純 SwiftUI 與 Swift 6 現代併發打造，預設以 macOS Accessory 輔助模式靜默常駐於 Menu Bar（右上角 AM 圖示）；全程不佔用 Dock 圖示、不干擾 Cmd+Tab 工作流程、杜絕誤關。需要時可隨時從 Menu Bar Popover 或 Spotlight/Launchpad 喚起完整桌面主視窗。
- **雙 Provider 官方 CLI 整合**：Codex 透過本機 `codex app-server` 的標準 JSON-RPC 2.0 通訊；Antigravity 透過 `agy -p "/usage" --output-format json` 唯讀查詢。全程不抓取瀏覽器 Cookie、不直接呼叫私有端點。
- **動態額度解析**：自動識別並正規化 Codex 的 5 小時／每週額度，以及 Antigravity 的 Gemini Models 動態 quota buckets，無須硬編碼模型清單。
- **多 Provider 狀態隔離**：各 Provider 的載入、錯誤、快取與 Menu Bar 顯示狀態彼此獨立，單一 CLI 異常不影響其他 Provider。
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
- Codex CLI（監控 ChatGPT Codex 額度時需要）
- Antigravity CLI 1.1.11+（監控 Google Antigravity 額度時需要）

### 執行單元測試
```bash
swift test
```

目前共 13 套測試、34 項測試，涵蓋雙 Provider 解析、環境偵測、快取隔離、設定、診斷遮蔽、App 生命週期與本機 CLI 整合。

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
releases/AgentMeter-v0.1.1.zip
```

如需使用本機 Keychain 中的 Developer ID Application identity，可指定：

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./scripts/build-release.sh
```

> Developer ID 簽署不等同 Apple notarization；目前腳本不執行 notarize 或 staple。

建立與 `Resources/Info.plist` 版本一致的 Git tag 後，可將 ZIP 上傳至 GitHub Release：

```bash
gh release create v0.1.1 \
  releases/AgentMeter-v0.1.1.zip \
  --verify-tag \
  --title "AgentMeter 0.1.1" \
  --generate-notes
```

每次發布時，必須將腳本最後輸出的 SHA-256 同步至 `homebrew-tap/Casks/agentmeter.rb`，並確認 `version`、下載 URL 與 ZIP 檔名一致，再驗證安裝：

> Homebrew Cask 僅由獨立的 [`yuhaw0715/homebrew-tap`](https://github.com/yuhaw0715/homebrew-tap) 專案維護；AgentMeter repository 不保存 Cask 副本，避免版本與 checksum 漂移。

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
│   ├── Domain/                  # RateLimitItem, Snapshot, ProviderType, AgentProvider 協定
│   ├── Providers/Codex/         # Codex JSON-RPC、額度解析與環境偵測
│   ├── Providers/Antigravity/   # agy 唯讀查詢、動態 bucket 解析與版本偵測
│   ├── Services/                # 多 Provider Smart Cache、設定與診斷遮蔽
│   ├── ViewModels/              # UsageMonitorViewModel (@Observable)
│   └── Localization/            # L10n, DateFormatterHelper
└── AgentMeter/                 # macOS SwiftUI 應用程式 UI
    ├── App/                     # AgentMeterApp (Window + MenuBarExtra)
    └── Views/                   # 雙 Provider Dashboard、Menu Bar、設定與診斷
```

---

## 📄 授權條款 (License)

本專案採用 [MIT License](LICENSE) 開源授權。
