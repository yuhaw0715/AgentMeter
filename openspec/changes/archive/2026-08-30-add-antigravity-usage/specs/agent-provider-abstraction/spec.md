## MODIFIED Requirements

### Requirement: MVP 階段的 Provider UI 隔離
使用者介面 SHALL 僅呈現已完成支援的 Provider；加入本變更後 SHALL 顯示 ChatGPT Codex 與 Google Antigravity，並繼續隱藏尚未實作的 Provider（如 Gemini CLI）。

#### Scenario: Desktop 與 Menu Bar 呈現已支援 Provider
- **WHEN** 使用者瀏覽側邊欄或 Menu Bar Popover
- **THEN** 系統可存取 ChatGPT Codex 與 Google Antigravity，且不列出尚未實作的 Provider

#### Scenario: Desktop 與 Menu Bar UI 僅呈現 Codex Provider
- **WHEN** 使用者在桌面應用程式或 Popover 中瀏覽 Provider 或導航選單
- **THEN** 原 MVP 階段僅列出 ChatGPT Codex；套用本變更後則由「已完成支援」規則納入 Google Antigravity

### Requirement: Provider 執行狀態隔離
每個已註冊 Provider SHALL 具有獨立的快照、載入、錯誤與最後更新狀態。

#### Scenario: 單一 Provider 更新失敗
- **WHEN** Codex 或 Antigravity 其中一個 Provider 更新失敗
- **THEN** 錯誤只影響該 Provider，另一 Provider 的有效狀態與操作維持可用
