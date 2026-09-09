# AgentMeter - Agent 開發與協作規範 (AGENTS.md)

本文件定義 AI Agent 在本專案中運作、開發及協作時需遵循的規範與環境資訊。

---

## 1. 專案資訊 (Project Info)

- **專案名稱**：AgentMeter
- **遠端倉庫**：[https://github.com/yuhaw0715/AgentMeter.git](https://github.com/yuhaw0715/AgentMeter.git)
- **主要分支**：`main`

---

## 2. Git 操作規範 (Git Guidelines)

> [!IMPORTANT]
> **未經使用者明確指示，AI Agent 不得自動執行 `git commit` 或 `git push`。**

1. **Commit 訊息語言**：
   - 所有的 Git Commit 訊息必須使用**繁體中文**撰寫。
   - 格式建議遵循語意化提交（如：`feat: ...`、`fix: ...`、`docs: ...`、`refactor: ...` 等），並在後續說明具體改動內容。

2. **提交與推送流程**：
   - 嚴格禁止自動執行 `git commit` 與 `git push`。
   - 在完成代碼或設定修改後，僅做狀態檢查或提醒使用者進行審閱與提交。
   - 若使用者明確要求執行 commit 或 push，方可代為執行相應指令。

3. **Git 忽略規則**：
   - 專案已建立 [`.gitignore`](.gitignore)，涵蓋作業系統隱藏檔（如 `.DS_Store`）、敏感資訊（`.env`、私鑰）、相依套件（`node_modules/`、`venv/`）、發布產物（`releases/`）以及常見編輯器暫存檔。

---

## 3. 開發與工作流程 (Workflow & Specifications)

1. **規範驅動開發 (Spec-Driven)**：
   - 專案採用 OpenSpec 規範進行功能變更與規格管理（位於 [`openspec/`](openspec/) 目錄）。
   - 進行複雜改動前，先遵循規劃流程（Implementation Plan / OpenSpec Propose），經使用者核准後再行實作。
   - **文件與計畫語言**：所有實作計畫（Implementation Plan）、OpenSpec 規劃文件（Proposals、Specs、Design、Tasks）及實作結案總結（Walkthrough）一律使用**繁體中文**撰寫。

2. **代碼品質與維護**：
   - 保持現有註解與說明文件的完整性。
   - 每次修改後需進行相應的驗證與測試。

---

## 4. 目前專案規格與進度 (Current Specs & Status)

- **已歸檔變更**：`agentmeter-mvp`（位於 [`openspec/changes/archive/2026-08-29-agentmeter-mvp/`](openspec/changes/archive/2026-08-29-agentmeter-mvp/)）、`add-antigravity-usage`（位於 [`openspec/changes/archive/2026-08-30-add-antigravity-usage/`](openspec/changes/archive/2026-08-30-add-antigravity-usage/)）、`add-release-build-script`（位於 [`openspec/changes/archive/2026-08-30-add-release-build-script/`](openspec/changes/archive/2026-08-30-add-release-build-script/)）、`keep-menu-bar-running-after-window-close`（位於 [`openspec/changes/archive/2026-08-30-keep-menu-bar-running-after-window-close/`](openspec/changes/archive/2026-08-30-keep-menu-bar-running-after-window-close/)）、`pure-menu-bar-mode`（位於 [`openspec/changes/archive/2026-09-02-pure-menu-bar-mode/`](openspec/changes/archive/2026-09-02-pure-menu-bar-mode/)）、`macos26-liquid-glass-ui`（位於 [`openspec/changes/archive/2026-09-03-macos26-liquid-glass-ui/`](openspec/changes/archive/2026-09-03-macos26-liquid-glass-ui/)）、`add-codex-reset-credit-display`（位於 [`openspec/changes/archive/2026-09-08-add-codex-reset-credit-display/`](openspec/changes/archive/2026-09-08-add-codex-reset-credit-display/)）、`add-antigravity-ai-credits-display`（位於 [`openspec/changes/archive/2026-09-08-add-antigravity-ai-credits-display/`](openspec/changes/archive/2026-09-08-add-antigravity-ai-credits-display/)）、`parallelize-menu-bar-provider-refresh`（位於 [`openspec/changes/archive/2026-09-09-parallelize-menu-bar-provider-refresh/`](openspec/changes/archive/2026-09-09-parallelize-menu-bar-provider-refresh/)）。
- **目前變更**：無。`parallelize-menu-bar-provider-refresh` 已完成實作、驗證並歸檔。
- **最近完成的 Antigravity AI Credits 功能**：
  - 僅使用 Antigravity 官方 CLI 已提供的非互動唯讀 JSON 輸出；不解析互動式 `/credits` TUI、不讀取憑證，也不呼叫未公開後端 API。
  - 僅顯示 AI Credits 可用總數與更新時間，不購買、不啟用、不消耗 Credits，也不修改 `useG1Credits` 或 AI Credit Overages 設定。
  - Desktop 採已確認的獨立「AI 點數」資訊卡，標頭同一行左側顯示圖示與標題、右側顯示可用總數。
  - Menu Bar 採已確認的合併方案：模型額度與 AI 點數共用單一 Antigravity 外框，只以水平分隔線區隔。
  - 與 Antigravity 模型額度共用刷新流程、手動刷新入口、Provider 快照及 Smart Cache TTL。
  - 區分已知餘額（含 0）、方案不支援、CLI 尚未提供欄位、資訊未知及快取過期狀態；CLI 尚未提供欄位時不要求升級且不影響既有 Gemini Models 額度。
  - 繁體中文顯示「AI 點數」，英文顯示「AI Credits」，總數使用地區化整數格式。
- **最近完成的 Codex 重置券功能**：
  - 沿用官方 Codex app-server `account/rateLimits/read` 取得 `rateLimitResetCredits`。
  - 僅顯示，不呼叫 `account/rateLimitResetCredit/consume`，不提供使用或兌換功能。
  - Desktop 採已確認的 A 堆疊式獨立資訊卡，標頭同一行左側顯示重置券標題、右側顯示可用總數。
  - Menu Bar 採使用者已確認的 A 方案：額度與重置券共用單一 Codex 外框，只以水平分隔線區隔。
  - 顯示服務端權威總數、逐張到期時間、明細不足、資訊未知與快取過期狀態。
- **最近完成的 Menu Bar 非同步刷新功能**：
  - Codex 與 Antigravity 等需要更新的 Provider 會並行查詢，先完成者立即套用結果。
  - 保留每個 Provider 的快取、載入、錯誤與最後更新狀態隔離；同一 Provider 的重複刷新會去重。
  - Popover 關閉時沿用結構化取消，已完成的結果保留，未完成查詢不建立背景常駐工作。
- **目前階段**：ChatGPT Codex 與 Google Antigravity 雙 Provider 額度監控、唯讀 Codex 重置券顯示、唯讀 Antigravity AI Credits 顯示與 CLI 相容狀態、Menu Bar Provider 非同步並行刷新、純選單列常駐（Stats 模式，全程無 Dock 圖示、啟動靜默、Spotlight Reopen 喚起主視窗、專屬 Quit 控制項）、macOS 26 Liquid Glass 主程式／Menu Bar 一致視覺、主程式與 Menu Bar 額度排序一致、版本化 GitHub Release ZIP 建置流程及 Homebrew Cask 實機安裝均已完成；9 項變更已同步至主規格並完成歸檔，10 份主規格均通過 OpenSpec strict validation；14 大測試套件共 51 項測試 100% 通過。
- **支援範圍**：
  - 核心平台：macOS 26+ SwiftUI 原生應用程式（Desktop 視窗 + Menu Bar 圖示 Popover）。
  - 視覺設計：Desktop 主程式採選項 1 原生側欄與額度卡片，新開視窗預設尺寸為 `760 × 640pt` 且可自由縮放；Menu Bar Popover 共用 macOS 26 Liquid Glass 材質、品牌徽章、Provider 分組與狀態色；Menu Bar 圖示採用極簡粗體 AM Monogram，App 圖示採用 Option B4（深炭灰去背 Squircle 滿版圖示）。
  - Provider：
    1. **ChatGPT Codex**：官方 CLI `app-server` JSON-RPC 握手、5h / Weekly 動態額度解析，以及唯讀重置券總數、明細、排序與過期狀態。
    2. **Google Antigravity**：官方 Antigravity CLI 1.1.11+ 唯讀非互動 JSON 查詢、Gemini Models 額度動態解析，以及 AI Credits 總數與 CLI 欄位相容狀態。
  - 10 大 Capabilities：
    1. `codex-rate-limit-provider`：Codex app-server JSON-RPC 握手、5h / Weekly 動態額度解析，以及唯讀重置券解析、排序與快取語意。
    2. `antigravity-rate-limit-provider`：Antigravity CLI 唯讀 JSON 查詢、Gemini Models 動態 bucket 解析過濾，以及 AI Credits 型別化摘要、相容狀態與共用快取語意。
    3. `usage-dashboard`：Desktop 雙 Provider 額度儀表板、雙列標頭、左側即時 Menu Bar 釘選核取方塊，以及 Codex 重置券與 Antigravity AI 點數獨立資訊卡。
    4. `menu-bar-usage`：Menu Bar 常駐 AM 圖示 Popover、Smart Cache、Provider 間非同步並行刷新、先完成先顯示、同 Provider 請求去重、依 Provider 分組自適應高度、額度排序與主程式一致、單一 Provider 外框內的 Codex 重置券／Antigravity AI 點數、開啟／結束操作圖示，以及純選單列常駐（Stats 模式，全程無 Dock 圖示、啟動靜默、Spotlight Reopen 喚起主視窗、專屬 Quit 控制項）。
    5. `codex-environment-setup`：CLI PATH 偵測與引導。
    6. `agentmeter-settings`：本機偏好設定、雙 Provider 自訂 CLI 路徑、快取 TTL、開機啟動與右對齊選單。
    7. `agentmeter-diagnostics`：環境診斷與敏感資訊遮蔽報告。
    8. `agent-provider-abstraction`：Provider 抽象層解耦與多 Provider 狀態隔離。
    9. `localization`：繁體中文、英文與系統預設之即時多國語言切換，以及 yyyy-MM-dd HH:mm:ss 時間格式。
    10. `homebrew-distribution`：以 `scripts/build-release.sh` 建立、ad-hoc／Developer ID 簽署及驗證 `releases/AgentMeter-v<版本>.zip`，成功後自動移除中間 App Bundle；支援 GitHub Releases、Homebrew Cask 安裝、checksum 驗證與 `--zap`。
