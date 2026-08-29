# 新增 Google Antigravity Gemini 額度顯示

## Why

AgentMeter MVP 已能透過官方 Codex CLI 顯示 ChatGPT Codex 額度，但使用者也需要在同一個 macOS 原生工具中查看 Google Antigravity 的 Gemini Models 額度。Google Antigravity CLI 自 1.1.11 起提供不啟動 Agent turn、且不消耗模型額度的非互動 `/usage` JSON 輸出，可作為官方且結構化的本機資料來源。

本變更將在不介入 Google OAuth、Keychain 或憑證管理的前提下，新增 Google Antigravity Provider、獨立 Dashboard、Menu Bar 分組顯示、環境設定與診斷能力。範圍只涵蓋 Google 帳號登入所提供的 Gemini Models 額度，不顯示 Claude/GPT 額度、AI Credits、Email 或訂閱方案。

## What Changes

- 新增 Google Antigravity Provider，最低支援 Antigravity CLI 1.1.11。
- 透過一次性短生命週期子行程執行 `agy -p "/usage" --output-format json`，逾時預設為 10 秒。
- 動態解析並顯示所有有效的 Gemini Models 額度 bucket；排除 Claude、GPT、其他第三方模型、停用 bucket 與 AI Credits。
- 支援自動搜尋官方預設位置 `~/.local/bin/agy`、常見安裝位置與 `PATH`，並允許使用者設定自訂執行檔路徑。
- 偵測 CLI 缺少、版本低於 1.1.11、未登入、查詢逾時、JSON 無效與後端查詢失敗等狀態。
- 新增獨立的 Google Antigravity Dashboard；無論環境是否就緒，側邊欄固定顯示 Provider。
- Desktop Dashboard 顯示所有有效 Gemini 額度，首次發現時於 Menu Bar 預設全部釘選。
- Menu Bar Popover 依 Provider 分組顯示 Codex 與 Antigravity，兩者具有獨立快照、載入與錯誤狀態。
- Antigravity 沿用現有 Smart Cache TTL；Desktop 前景重新整理與手動重新整理皆繞過 TTL。
- Settings 新增 Antigravity CLI 自訂路徑；Diagnostics 新增 Antigravity 環境與查詢狀態，匯出時繼續遮蔽敏感資訊。
- 補齊繁體中文與英文介面字串及錯誤訊息。

## Capabilities

### New Capabilities

- `antigravity-rate-limit-provider`：透過官方 Antigravity CLI 非互動 JSON 輸出，取得並正規化 Google 帳號的所有有效 Gemini Models 額度。

### Modified Capabilities

- `agent-provider-abstraction`：正式註冊 Google Antigravity Provider，並維持 Provider 狀態與快照隔離。
- `usage-dashboard`：側邊欄新增 Google Antigravity 與專屬額度 Dashboard。
- `menu-bar-usage`：依 Provider 分組顯示並支援 Antigravity 額度全部預設釘選。
- `agentmeter-settings`：新增 Antigravity CLI 自動偵測與自訂路徑設定。
- `agentmeter-diagnostics`：新增 Antigravity CLI、版本、登入與最近查詢診斷。

## Impact

- **程式架構**：新增 Antigravity Provider、程序執行與 JSON 解析元件，並擴充 Provider Registry、ViewModel 與 SwiftUI 導航。
- **外部依賴**：使用者需自行安裝 Antigravity CLI 1.1.11 以上並以 Google 帳號完成登入。
- **隱私與安全**：AgentMeter 不讀取、保存或修改 Google 憑證，不自動開啟 OAuth；所有查詢與快取維持本機處理。
- **相容性**：CLI 輸出採容錯與動態 bucket 解析；不解析互動式 TUI 文字畫面。
- **既有功能**：Codex Provider 的資料來源、Dashboard、設定與快取行為維持不變。

## Non-Goals

- 不支援 `GEMINI_API_KEY` 或 Gemini API 專案配額。
- 不顯示 Claude、GPT 或其他第三方模型額度。
- 不顯示、購買或管理 AI Credits。
- 不顯示 Google 帳號 Email 或訂閱方案。
- 不管理 Google 登入、OAuth、Keychain 或登出流程。
- 不保存 Antigravity 歷史用量或新增背景輪詢。
