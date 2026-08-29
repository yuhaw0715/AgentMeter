# 技術設計：AgentMeter MVP

## Context

請參閱 [proposal.md](proposal.md) 了解背景與動機。
AgentMeter 是一個專為 macOS 26+ 設計的原生、輕量化 SwiftUI 應用程式，旨在監控 AI Coding Agent 的使用額度，MVP 聚焦於透過官方 Codex CLI 的 `app-server` JSON-RPC 介面（`account/rateLimits/read`）取得 ChatGPT Codex 額度。

## Goals / Non-Goals

**目標 (Goals):**
- 提供清晰模組化的 macOS SwiftUI 應用程式架構，劃分 Domain、Provider、Application State 與 UI 層。
- 建立具可擴充性的 `AgentProvider` 抽象協定，但在 MVP 執行階段與 UI 呈現上嚴格僅暴露 ChatGPT Codex。
- 實作穩健的 `codex app-server` 子行程生命週期管理與 stdio JSON-RPC 2.0 通訊，避免常駐背景輪詢。
- 透過本機 Smart Cache 快取機制與使用者自訂 TTL，提供點擊即開的 Menu Bar Popover 即時響應體驗。
- 提供完整繁體中文與英文在地化支援，以及去除敏感資訊的環境診斷報告匯出。
- 建立支援 GitHub Releases 與自訂 Homebrew Cask 的發布流程。

**非目標 (Non-Goals):**
- 在 MVP 中實作 Gemini 或 Antigravity 的具體邏輯（僅保留架構介面）。
- 儲存長期歷史使用紀錄、資料庫或趨勢圖。
- 低額度系統推播通知或全域快速鍵 (Global Hotkey)。
- 帳號憑證/Token 儲存或 OAuth 登入管理（完全交由 Codex CLI 負責）。
- macOS WidgetKit 桌面小工具。

## Decisions

### 1. 架構模式：Clean Architecture + MVVM + Swift 併發 (Swift Concurrency)
- **決策**：將專案結構劃分為 `Domain`、`Providers`、`Services`、`ViewModels` 與 `Views`。全面採用 Swift 6 async/await 與 `@Observable` / 現代 SwiftUI 語法。
- **理由**：將 Codex 專屬的行程調用與 JSON-RPC 細節自 UI 層徹底解耦；未來擴充新 Provider（如 Gemini、Antigravity）時只需實作 `AgentProvider` 協定即可。
- **替代方案評估**：
  - *ViewModel 直接調用系統 Process*：導致緊密耦合、難以進行單元測試與擴充。

### 2. Codex 整合：基於 `codex app-server` 的 JSON-RPC
- **決策**：透過標準輸入/輸出 (stdin/stdout) 啟動或連接 `codex app-server` 子行程，發送 JSON-RPC 2.0 請求調用 `account/rateLimits/read`。
- **理由**：這是官方支援的介面，可直接取得結構化 JSON 額度快照，避免文字終端機畫面（如 `/status`）字串解析的脆弱性。
- **替代方案評估**：
  - *解析 `codex /status` 終端輸出*：極易因文字格式或多國語系變更而損壞。
  - *擷取瀏覽器 Cookie / 私人 API*：高安全性風險、違反服務條款且隨時可能失效。

### 3. 動態額度解析與通用正規化模型
- **決策**：將 Provider 回傳的 JSON 項目正規化為通用 `RateLimitItem`（包含 `id`、`name`、`usedPercent`、`resetAt` 與 `status`），不硬編碼固定只有「5-hour」與「Weekly」。
- **理由**：Provider 額度類型可能隨版本更新或方案調整，動態正規化使新額度類型無需更新客戶端即可自動顯示。

### 4. Smart Cache 與視窗生命週期驅動重新整理
- **決策**：
  - **Desktop 主視窗**：每次開啟或喚醒至前景時，主動發起全新請求，不受快取 TTL 阻擋。
  - **Menu Bar**：採用 Smart Cache（預設 5 分鐘 TTL）。快取新鮮時立即呈現快照；快取過期時顯示重新整理狀態並背景拉取；手動刷新則強制穿透快取。
- **理由**：徹底消除無效的常駐輪詢與電量消耗，同時確保使用者每次刻意檢視時皆能秒開 Popover 並獲得最新數據。

### 5. 敏感資訊遮蔽之診斷報告
- **決策**：提供 `ReportSanitizer` 工具，在將系統診斷資訊複製至剪貼簿前，自動去除授權 Token、電子郵件、私密路徑等敏感資訊。
- **理由**：讓使用者能安全地將診斷報告貼至公開的 GitHub Issue 進行排查，無需擔心個資外洩。

### 6. 打包與發布：GitHub Release + 自訂 Homebrew Tap
- **決策**：透過 GitHub Releases 提供未簽章/Ad-hoc 簽章之發布產物，並於自訂 Homebrew tap 提供專屬 Cask Formula，以受限範圍的 `xattr -d com.apple.quarantine` 僅處理 `AgentMeter.app`。
- **理由**：在 MVP 階段為開發者提供便捷的單行安裝與更新體驗，且不需要立即綁定付費的 Apple Developer ID。

## Risks / Trade-offs

- **[風險] macOS GUI 應用程式中的 `codex` PATH 變數差異** → *緩解措施*：主動搜尋常見安裝路徑（`/opt/homebrew/bin`、`/usr/local/bin`、`~/.cargo/bin`、`~/.local/bin`、shell PATH），並在 Settings 中提供自訂路徑覆寫選項。
- **[風險] `codex app-server` 行程卡死或回應緩慢** → *緩解措施*：實作嚴格的請求超時機制（如 5–10 秒）並妥善處理子行程終止。
- **[風險] 網路或 CLI 失敗時呈現過期資料造成誤導** → *緩解措施*：刷新失敗時明確將過期快照標記為失效，改呈現錯誤訊息與重試按鈕，絕不靜默呈現陳舊數據。

## Migration Plan

- 初次發布：全新專案建置。
- Cask Formula 提供標準解除安裝以及包含 `~/Library/Preferences/com.agentmeter.*` 與 `~/Library/Caches/com.agentmeter.*` 的 `--zap` 清理定義。
