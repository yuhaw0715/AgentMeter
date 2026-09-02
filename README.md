# AgentMeter ⚡️

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2015%2B%20%7C%20Apple%20Silicon-lightgrey.svg)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)

**AgentMeter** 是一款專為 macOS 設計的原生、輕量級 AI Coding Agent 使用額度監控器。目前支援 **ChatGPT Codex** 與 **Google Antigravity**：分別透過 Codex CLI 的 `app-server` JSON-RPC 介面，以及 Antigravity CLI 的唯讀非互動 JSON 查詢取得即時額度快照。

---

## ✨ 核心特色 (Features)

- **極簡純選單列常駐（Stats 模式）**：純 SwiftUI 與 Swift 6 現代併發打造，預設以 macOS Accessory 輔助模式靜默常駐於 Menu Bar（右上角 AM 圖示）；全程不佔用 Dock 圖示、不干擾 Cmd+Tab 工作流程、杜絕誤關。需要時可隨時從 Menu Bar Popover 或 Spotlight/Launchpad 喚起完整桌面主視窗。
- **雙 Provider 官方 CLI 整合**：Codex 透過本機 `codex app-server` 的標準 JSON-RPC 2.0 通訊；Antigravity 透過 `agy -p "/usage" --output-format json` 唯讀查詢。全程不抓取瀏覽器 Cookie、不直接呼叫私有端點。
- **動態額度解析**：自動識別並正規化 Codex 的 5 小時／每週額度，以及 Antigravity 的 Gemini Models 動態 quota buckets，無須硬編碼模型清單。
- **多 Provider 狀態隔離**：各 Provider 的載入、錯誤、快取與 Menu Bar 顯示狀態彼此獨立，單一 CLI 異常不影響其他 Provider。
- **Smart Cache 智慧快取**：Menu Bar 點擊秒開，具備自訂 TTL（預設 5 分鐘）與過期主動更新機制，不佔用多餘系統資源與電量。
- **多語系與無障礙支援**：完整支援繁體中文（Traditional Chinese）與英文（English），自動遵循系統時區與 12/24 小時制，遵循系統外觀與 VoiceOver 語意導覽。

---

## 🛡️ 安全與隱私承諾 (Privacy & Security)

- **嚴格唯讀**：應用程式採嚴格唯讀設計，僅查詢本機 CLI 輸出的額度資訊，不提供任何未授權修改或寫入管道。
- **純記憶體處理**：額度資料僅暫存於記憶體中，絕不持久化儲存至本地資料庫或未經授權之磁碟空間。
- **零遙測與資料收集**：無任何遙測分析代碼 (Telemetry/Analytics)，不收集使用記錄，不回傳任何資訊至外部伺服器。
- **最小權限 App Sandbox**：嚴格於 macOS App Sandbox 內受限執行，僅申請必要權限。
- **本機偏好保存**：所有使用者自訂設定（自訂 CLI 路徑、快取 TTL、語系等）皆安全儲存於本地 `UserDefaults`；內建敏感資訊遮蔽的診斷報告匯出工具。

---

## 📦 安裝方式 (Installation)

### 1. 一鍵安裝 (推薦)

您可以透過自訂 Homebrew Tap 進行單行一鍵安裝：

```bash
brew install --cask yuhaw0715/tap/agentmeter
```

> [!NOTE]
> **首次啟動說明 (Gatekeeper)**：
> 首次啟動若 macOS 顯示「無法驗證開發者」提示，請前往 macOS **「系統設定」>「隱私權與安全性」**，在安全性區塊下方點擊 **「仍要打開」** 即可正常啟動。

---

### 2. 更新至最新版

當有新版本發佈時，可透過以下指令升級：

```bash
brew update
brew upgrade --cask agentmeter
```

---

### 3. 解除安裝 (Uninstall)

- **標準解除安裝**：
  ```bash
  brew uninstall --cask agentmeter
  ```

- **完整乾淨移除（清除快取與本機偏好設定檔）**：
  ```bash
  brew uninstall --zap --cask agentmeter
  ```
  > `--zap` 僅清除 AgentMeter 的快取與本機設定，不會變更您的 Codex CLI 或 Antigravity CLI 登入憑證。

- **（選用）移除 Tap 儲存庫**：
  ```bash
  brew untap yuhaw0715/tap
  ```

---

## 🏗️ 程式與專案架構 (Architecture)

AgentMeter 採用 Clean Architecture 與 MVVM 分層架構：

```text
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
    ├── Resources/               # AppIcon, Bundle 資源
    └── Views/                   # 雙 Provider Dashboard、Menu Bar、設定與診斷
```

---

## 🛠️ 開發、建置與測試 (Development & Testing)

### 系統需求
- **作業系統**：macOS 15.0+ (Sequoia) / macOS 26+
- **硬體架構**：Apple Silicon Mac (arm64)
- **開發工具**：Xcode 16.0+ 或 Swift 6.0+
- **CLI 工具**：
  - [Codex CLI](https://github.com/openai/codex)（監控 ChatGPT Codex 額度時需要）
  - [Antigravity CLI](https://github.com/google/antigravity) 1.1.11+（監控 Google Antigravity 額度時需要）

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

腳本會執行 Release build、組裝並以 ad-hoc identity 簽署 `AgentMeter.app`、驗證 Bundle 與 ZIP 結構，成功後移除中間 App Bundle，最後只保留發布產物：

```text
releases/AgentMeter-v1.0.0.zip
```

如需使用本機 Keychain 中的 Developer ID Application identity，可指定：

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./scripts/build-release.sh
```

> Developer ID 簽署不等同 Apple notarization；目前腳本不執行 notarize 或 staple。

建立與 `Resources/Info.plist` 版本一致的 Git tag 後，可將 ZIP 上傳至 GitHub Release：

```bash
gh release create v1.0.0 \
  releases/AgentMeter-v1.0.0.zip \
  --verify-tag \
  --title "AgentMeter 1.0.0" \
  --generate-notes
```

每次發布時，將腳本輸出的 SHA-256 同步至 `homebrew-tap/Casks/agentmeter.rb`，並確認 `version`、下載 URL 與 ZIP 檔名一致，再驗證安裝：

> Homebrew Cask 僅由獨立的 [`yuhaw0715/homebrew-tap`](https://github.com/yuhaw0715/homebrew-tap) 專案維護；AgentMeter repository 不保存 Cask 副本，避免版本與 checksum 漂移。

```bash
brew update
brew install --cask yuhaw0715/tap/agentmeter
```

---

## 📄 授權條款 (License)

本專案採用 [MIT License](LICENSE) 授權。

