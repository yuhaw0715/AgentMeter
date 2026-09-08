# 🚀 AgentMeter 專案交接文件 (handoff.md)

本文件整理了 **AgentMeter** 專案的架構、目前最新實作成效、技術細節、規範以及開啟新對話時供下一位 AI Agent / 開發者快速銜接的交接 Prompt。

> [!IMPORTANT]
> 本文件以 **2026-09-08「Codex 重置券顯示」規劃狀態**為最新交接基準；下方既有發布紀錄屬已完成歷史背景。當兩者敘述不同時，以本段及第 7 節的新交接 Prompt 為準。

## 🆕 目前進行中：Codex 重置券顯示

- **OpenSpec change**：`add-codex-reset-credit-display`
- **位置**：`openspec/changes/add-codex-reset-credit-display/`
- **狀態**：Proposal、4 份 delta specs、Design、Tasks 均已建立；Desktop 與 Menu Bar 排版均已確認，尚未取得使用者實作核准，亦未修改 Swift 程式碼。
- **Git 狀態**：目前只有上述 change 目錄為未追蹤內容；未執行 commit 或 push。
- **官方資料來源**：[Codex App Server 官方文件](https://learn.chatgpt.com/docs/app-server)。

### 已確認的官方 API 與資料語意

- 沿用既有 JSON-RPC `account/rateLimits/read`；回應可包含 `rateLimitResetCredits`。
- `rateLimitResetCredits.availableCount` 是可用券總數的權威值。
- `credits` 可能為 `null`、空陣列或遭服務端截斷；明細可包含 `id`、`resetType`、`status`、`grantedAt`、`expiresAt`、`title`、`description`。
- 官方另提供 `account/rateLimitResetCredit/consume`，但本次已明確排除，不得加入使用、兌換或消耗功能。

### 使用者已確認的需求

1. 功能維持唯讀，只顯示重置券。
2. Desktop 與 Menu Bar 都要顯示。
3. `availableCount` 大於明細筆數時，顯示已取得明細及「其餘 N 張未提供明細」。
4. 券依最早到期優先排序，顯示 `yyyy-MM-dd HH:mm:ss`；`expiresAt == null` 顯示「無到期資訊」。
5. 明確區分已知 0 張與「資訊未提供」；新欄位缺失不得造成既有 Codex 額度刷新失敗。
6. Desktop 使用已確認的 A 堆疊式獨立重置券資訊卡；標頭同一行左側顯示「重置券」、右側顯示「N 張可用」，下方逐張顯示到期資訊。
7. Menu Bar 使用已確認的 A 方案：ChatGPT Codex 只有一個外框，額度列與重置券列置於同一容器，只以水平分隔線區隔，不建立巢狀卡片。
8. 重置券區段永遠顯示，不新增 Menu Bar 顯示開關。
9. UI 只顯示本地化券編號與到期時間；官方 `title`／`description` 保留於模型但不呈現。
10. 快取券超過到期時間時保留該列並標示「已到期，等待刷新」，不在本機扣除服務端權威總數。
11. 延續 macOS 26 Liquid Glass 視覺；示意圖只作設計參考。

### 設計附件

- `openspec/changes/add-codex-reset-credit-display/assets/desktop-reset-credit-variants.png`：Desktop A／B／C 比較用原始方案。
- `openspec/changes/add-codex-reset-credit-display/assets/desktop-reset-credit-selected-a.png`：Desktop 已確認的 A 最終版，標題與可用總數同列。
- `openspec/changes/add-codex-reset-credit-display/assets/menubar-integrated-reset-credit-variants.png`：Menu Bar 真正共用單一 Codex 外框的三案；使用者已選 A。

### 下一位 Agent 的首要工作

1. 先檢查 OpenSpec 文件與最終 Desktop／Menu Bar 示意圖，確認所有已定案內容一致。
2. 將 OpenSpec strict validation 結果與 proposal 交給使用者審閱。
3. 在使用者明確核准 proposal 前，不得實作 Swift 程式碼。

---

## 📌 1. 專案概況 (Project Overview)

- **專案名稱**：AgentMeter
- **定位**：macOS 原生（macOS 15+ / 26+）AI Agent 額度與用量即時監控工具（MenuBar 常駐 + Desktop 獨立視窗）。
- **遠端倉庫**：`https://github.com/yuhaw0715/AgentMeter.git`（主要分支：`main`）
- **目前進度**：
  - `agentmeter-mvp`（ChatGPT Codex 支援）已 100% 實作完成並歸檔。
  - `add-antigravity-usage`（Google Antigravity Gemini 支援）已 100% 實作完成並歸檔，12 大測試套件共 31 項測試全數通過。
  - `add-release-build-script`（macOS App Bundle、GitHub Release ZIP 與 Homebrew 發布流程）已 100% 實作、完成實機安裝驗證並歸檔。
  - GitHub Release `v0.1.0` 的 `AgentMeter-v0.1.0.zip` 已可由 `yuhaw0715/tap/agentmeter` 正確下載、通過 checksum 並安裝。

---

## 🏛️ 2. 系統架構與核心模組 (System Architecture)

採用 **Swift 6 + SwiftUI + Clean Architecture + MVVM** 架構：

```mermaid
graph TD
    UI[SwiftUI Views: Desktop & MenuBar Popover] --> VM[UsageMonitorViewModel @Observable @MainActor]
    VM --> Cache[SmartCacheManager Multi-Provider Isolation]
    VM --> Settings[SettingsManager]
    VM --> ProviderRegistry[ProviderRegistry]
    ProviderRegistry --> CodexProvider[CodexRateLimitProvider]
    ProviderRegistry --> AntigravityProvider[AntigravityRateLimitProvider]
    CodexProvider --> ProcessMgr[CodexProcessManager stdio JSON-RPC]
    CodexProvider --> EnvDetector[CodexEnvironmentDetector]
    AntigravityProvider --> AgyDetector[AntigravityEnvironmentDetector]
    AntigravityProvider --> AgyRunner[DefaultAntigravityCommandRunner]
    ProcessMgr --> HostCodex["codex app-server (/opt/homebrew/bin/codex)"]
    AgyRunner --> HostAgy["agy -p /usage --output-format json (~/.local/bin/agy)"]
```

### 核心模組分層：
1. **Domain Layer (`Sources/AgentMeterCore/Domain/`)**：
   - `RateLimitItem`：通用的額度項目模型（名稱、使用率、重置時間、已用/剩餘量等）。
   - `RateLimitSnapshot`：一次完整的額度快照。
   - `ProviderType`：支援的供應商枚舉（`.codex`、`.antigravity`、預留 `.gemini`）。
   - `EnvironmentStatus`：環境健康度（`.healthy`、`.cliMissing`、`.unsupportedVersion`、`.notAuthenticated` 等）。
   - `AgentProvider`：Provider 抽象通訊協定，具備解耦與多 Provider 擴充性。

2. **Provider Layer (`Sources/AgentMeterCore/Providers/`)**：
   - **Codex (`Codex/`)**：
     - `CodexProcessManager`：底層 JSON-RPC 2.0 stdio 串流處理器與握手協議。
     - `CodexRateLimitProvider`：精確解析 5h / Weekly 動態額度。
     - `CodexEnvironmentDetector`：自動掃描 `/opt/homebrew/bin/codex`、`PATH` 或使用者自訂路徑。
   - **Antigravity (`Antigravity/`)**：
     - `AntigravityRateLimitProvider`：一次性子行程與 10 秒硬性逾時，以 `agy -p "/usage" --output-format json` 唯讀查詢，精確過濾提取有效 Gemini Models bucket。
     - `AntigravityEnvironmentDetector`：自動掃描 `~/.local/bin/agy`、`PATH` 或自訂路徑，並進行 SemVer $\ge 1.1.11$ 判定。
     - `AntigravityError`：專屬錯誤分類與 Localized 錯誤訊息。

3. **Services & ViewModel Layer (`Sources/AgentMeterCore/Services/ & ViewModels/`)**：
   - `SmartCacheManager`：支援多 Provider 快取隔離與可自訂 TTL（預設 5 分鐘）。
   - `SettingsManager`：本機 `UserDefaults` 設定管理（雙 Provider 自訂路徑、開機啟動、語系、快取時間、每 Provider Menu Bar 顯示額度項目）。
   - `UsageMonitorViewModel`：Swift 6 `@Observable` 響應式狀態中心，多 Provider 狀態隔離、Desktop 前景切換強制更新與 Menu Bar 自適應同步。
   - `ReportSanitizer`：自動遮蔽 Email、API Token、Google Key、主目錄等隱私敏感資訊，生成診斷報告。

4. **UI Presentation Layer (`Sources/AgentMeter/`)**：
   - `AgentMeterApp`：整合 `Window`（單例主視窗）與 `MenuBarExtra`（常駐 Popover）。
   - `MainDesktopContainerView`：側邊欄導航（ChatGPT Codex、Google Antigravity、偏好設定、環境診斷）。
   - `UsageDashboardView`：即時額度卡片、雙列資訊標頭、左側即時 Menu Bar 釘選 Checkbox。
   - `MenuBarPopoverView`：自適應高度 Menu Bar 彈出卡片清單（依 Provider 分組）、快捷開啟主視窗與離開按鈕。
   - `EnvironmentSetupView`：環境未就緒指引、版本不相容升級指引與 Terminal 登入引導。
   - `SettingsView`：開機啟動、快取 TTL、介面語言與雙 Provider CLI 路徑設定。
   - `DiagnosticsView`：雙 Provider 系統狀態表格與一鍵複製去敏診斷報告。

5. **視覺資產 (`Resources/` & `Sources/AgentMeter/Resources/`)**：
   - **Menu Bar 圖示**：Concept 2（純粹極簡粗體 `AM` Monogram）。
   - **App 圖示**：Option B4（深炭灰霧面去背 Squircle + 純白粗體 `AM`）。

6. **在地化 (`Sources/AgentMeterCore/Localization/`)**：
   - `L10n`：動態切換繁體中文、英文與系統預設語系。
   - `DateFormatterHelper`：標準 `yyyy-MM-dd HH:mm:ss` 時間格式與語系時區格式化。

---

## 🧪 3. 測試與驗證現況 (Verification & Test Status)

- **既有單元與整合測試 (`swift test`)**：最近一次已完成基準為 **13 大測試套件共 35 項測試 100% 通過**；本次重置券變更仍在規劃階段，尚未新增或執行其實作測試。
- **正式發布編譯 (`swift build -c release`)**：0 警告、0 錯誤。
- **發布腳本 (`scripts/build-release.sh`)**：已通過 Shell 語法、App Bundle 結構、`plutil`、`codesign --verify --deep --strict`、ZIP 頂層結構與 SHA-256 驗證。
- **發布產物**：`releases/AgentMeter-v0.1.0.zip`（Apple Silicon `arm64`，約 3.8 MB），SHA-256 為 `3e6d91bde7f4167ca5571e39efa462dbd6d2a1c65cd50e1c02eb63b0a5eadbe2`。
- **Homebrew Cask**：已由 `brew install --cask yuhaw0715/tap/agentmeter` 完成實機安裝；支援範圍受限 quarantine 清理與 `--zap`。
- **OpenSpec**：`add-release-build-script` 已同步至主規格並歸檔為 `openspec/changes/archive/2026-08-30-add-release-build-script/`；歸檔後 strict validation 通過。

---

## 📦 4. 發布流程與儲存庫狀態 (Release Workflow & Repository Status)

### AgentMeter 發布產物

執行：

```bash
./scripts/build-release.sh
```

腳本會：

1. 以 SwiftPM Release 組態建置 AgentMeter。
2. 建立完整 `AgentMeter.app`，複製 Info.plist、AppIcon 與 SwiftPM resource bundle。
3. 預設以 ad-hoc identity 簽署；亦可透過 `CODESIGN_IDENTITY` 指定 Developer ID。
4. 驗證 App Bundle 與簽署後，產生 `releases/AgentMeter-v<版本>.zip`。
5. 驗證 ZIP 結構並輸出 SHA-256。
6. 全部成功後自動移除中間 `releases/AgentMeter.app`；失敗時保留供除錯。

`releases/` 已由 `.gitignore` 排除，發布二進位不納入 Git。

### GitHub Release 與 Homebrew Tap

- AgentMeter repository：`https://github.com/yuhaw0715/AgentMeter.git`
- Homebrew tap repository：`https://github.com/yuhaw0715/homebrew-tap.git`
- Release asset 命名：`AgentMeter-v#{version}.zip`
- Cask token／檔名：`agentmeter`／`Casks/agentmeter.rb`
- 安裝指令：`brew install --cask yuhaw0715/tap/agentmeter`
- Cask macOS 相依語法：`depends_on macos: :sequoia`

重要 commits：

- AgentMeter `3d9bff4`：新增 Homebrew 發布產物建置流程。
- AgentMeter `ab5c4f7`：完善發布產物清理、驗證、OpenSpec 與 AGENTS 狀態。
- homebrew-tap `69a2258`：新增 AgentMeter Homebrew Cask。
- homebrew-tap `8bbebcd`：更新 AgentMeter 發布套件 checksum。
- homebrew-tap `e50ec0f`：更新 macOS 相依語法。

### 下一步

1. 審閱 `add-codex-reset-credit-display` 最終文件與示意圖；取得使用者明確核准後才可進入實作。
2. 未經明確指示不得 commit／push；本次 change 亦不得提早歸檔。
3. 未來每次發布前更新 `Resources/Info.plist` 版本、重跑發布腳本、上傳確切 ZIP，並以該 ZIP 的 SHA-256 更新 tap。

---

## 📜 5. 協作規範與規則 (Collaboration Guidelines)

新對話中的 Agent **必須嚴格遵守以下規範**：
1. **Git 規範**：
   - ⚠️ **未經使用者明確指示，嚴禁自動執行 `git commit` 或 `git push`**。
   - 所有 Git Commit 訊息必須使用**繁體中文**撰寫（遵循語意化格式如 `feat:`、`fix:` 等）。
2. **語言規範**：
   - 所有的規劃文件（Implementation Plan、OpenSpec 規格、Design、Tasks、Handoff、Walkthrough）一律使用**繁體中文**撰寫。
3. **AGENTS.md 規範**：
   - 若需修改 `AGENTS.md`，必須先將變更差異（Diff）呈現給使用者審閱並獲得同意後方可寫入。
4. **規範驅動開發 (Spec-Driven)**：
   - 遵循 `openspec/` 流程管理需求變更。

---

## 🧭 6. 專案目錄結構 (Project Structure)

```text
AgentMeter/
├── AGENTS.md                  # Agent 協作規範與目前專案進度
├── handoff.md                 # 本交接文件
├── Package.swift              # Swift 6 SPM 配置（AgentMeterCore, AgentMeter, AgentMeterTests）
├── scripts/
│   └── build-release.sh       # App Bundle、簽署、ZIP、checksum 與中間產物清理
├── releases/                  # 本機發布產物（由 .gitignore 排除）
├── Resources/                 # 應用程式圖示 (AppIcon.icns, AppIcon.png) 與 Entitlements
├── Sources/
│   ├── AgentMeterCore/        # 核心商業邏輯（Domain, Providers, Services, ViewModels, Localization）
│   └── AgentMeter/            # SwiftUI 介面與 App 進入點（Desktop Views, MenuBar Views, Components）
├── Tests/
│   └── AgentMeterTests/       # 31 項單元與整合測試套件
└── openspec/                  # OpenSpec 規格資料夾
    ├── specs/                 # 已生效的主規格
    └── changes/
        └── archive/           # 已歸檔歷史變更（含 add-release-build-script）
```

---

## 🤝 7. 新對話交接 Prompt

```text
請接手 `/Users/yuhao/Projects/AgentMeter` 專案。先完整閱讀 `AGENTS.md`、`handoff.md` 與 `openspec/changes/add-codex-reset-credit-display/` 的全部規劃文件，並先以唯讀方式執行 `git status --short` 與 `openspec status --change add-codex-reset-credit-display`，不要覆蓋任何既有變更。

目前進行中的 OpenSpec change 是 `add-codex-reset-credit-display`。官方 Codex app-server 文件確認 `account/rateLimits/read` 可回傳 `rateLimitResetCredits`，其中 `availableCount` 是權威總數，`credits` 明細可能為 null、空陣列或遭截斷；官方也有 `account/rateLimitResetCredit/consume`，但本次需求已明確限定為唯讀，禁止加入使用或兌換功能。

已確認需求：Desktop 與 Menu Bar 都顯示重置券；逐張顯示 `yyyy-MM-dd HH:mm:ss` 到期時間並依最早到期排序；缺少期限顯示「無到期資訊」；明細不足顯示「其餘 N 張未提供明細」；區分 0 張與資訊未提供；快取券到期後保留並標示等待刷新；區段永遠顯示且不新增開關。Desktop 已確定採 A 堆疊式獨立資訊卡，標頭同一行左側顯示標題、右側顯示可用總數。Menu Bar 已確定採 A 方案：ChatGPT Codex 只有一個外框，額度與重置券共用容器，只以水平分隔線區隔。

所有產品排版決策均已確認。請先執行 `openspec validate add-codex-reset-credit-display --strict --no-interactive`，向我整理 proposal、最終示意圖與驗證結果，並詢問是否核准進入實作。未經我明確核准 proposal，不得開始 Swift 實作或歸檔 change。

未經我明確指示，不得執行 `git commit` 或 `git push`；所有 commit 訊息、OpenSpec 文件、實作計畫、handoff 與 walkthrough 均使用繁體中文。
```
