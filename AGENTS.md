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
   - 專案已建立 [`.gitignore`](.gitignore)，涵蓋作業系統隱藏檔（如 `.DS_Store`）、敏感資訊（`.env`、私鑰）、相依套件（`node_modules/`、`venv/`）以及常見編輯器暫存檔。

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

- **進行中變更 (Active Change)**：`agentmeter-mvp`（位於 [`openspec/changes/agentmeter-mvp/`](openspec/changes/agentmeter-mvp/)）
- **目前階段**：MVP 實作與各項 UI / 視覺微調全數完成（19 項測試 100% 通過，包含本機 Codex app-server 實測連線）。
- **MVP 支援範圍**：
  - 核心平台：macOS 26+ SwiftUI 原生應用程式（Desktop 視窗 + Menu Bar 圖示 Popover）。
  - 視覺設計：Menu Bar 採用 Concept 2（極簡粗體 AM Monogram），App 圖示採用 Option B4（深炭灰去背 Squircle 滿版圖示）。
  - Provider：支援 **ChatGPT Codex**（透過官方 CLI `app-server` JSON-RPC `initialize` 握手與 `account/rateLimits/read`）。
  - 9 大 Capabilities：
    1. `codex-rate-limit-provider`：Codex app-server JSON-RPC 握手與 5h / Weekly 動態額度解析。
    2. `usage-dashboard`：Desktop 完整額度儀表板、雙列標頭、左側即時 Menu Bar 釘選核取方塊。
    3. `menu-bar-usage`：Menu Bar 常駐 AM 圖示 Popover、Smart Cache 與即時響應式項目同步。
    4. `codex-environment-setup`：CLI PATH 偵測與引導。
    5. `agentmeter-settings`：本機偏好設定、快取 TTL、開機啟動與右對齊選單。
    6. `agentmeter-diagnostics`：環境診斷與敏感資訊遮蔽報告。
    7. `agent-provider-abstraction`：Provider 抽象層解耦。
    8. `localization`：繁體中文、英文與系統預設之即時多國語言切換，以及 yyyy-MM-dd HH:mm:ss 時間格式。
    9. `homebrew-distribution`：GitHub Releases + Homebrew Cask 發布與 `--zap`。
