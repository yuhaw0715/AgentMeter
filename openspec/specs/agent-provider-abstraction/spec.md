# Agent Provider Abstraction Specification

## Purpose

建立具備可擴充性的 Agent 使用量 Provider 架構邊界，以利支援多 Provider 並維持狀態隔離。

## Requirements

### Requirement: 模組化 Provider 抽象層
核心領域層 SHALL 定義使用量 Provider 的 Protocol 抽象，將額度快照資料模型與獲取機制自特定 CLI 實作中解耦。

#### Scenario: 於標準介面後隔離 Provider 專屬協定
- **WHEN** UI 向目前啟用的 Provider 請求使用量快照
- **THEN** Provider 抽象層提供正規化快照資料，不論底層 JSON-RPC/API 之具體細節

### Requirement: 已支援 Provider 的 UI 呈現
使用者介面 SHALL 僅呈現已完成支援的 Provider；顯示 ChatGPT Codex 與 Google Antigravity，並繼續隱藏尚未實作的 Provider（如 Gemini CLI）。

#### Scenario: Desktop 與 Menu Bar 呈現已支援 Provider
- **WHEN** 使用者瀏覽側邊欄或 Menu Bar Popover
- **THEN** 系統可存取 ChatGPT Codex 與 Google Antigravity，且不列出尚未實作的 Provider

### Requirement: Provider 執行狀態隔離
每個已註冊 Provider SHALL 具有獨立的快照、載入、錯誤與最後更新狀態。

#### Scenario: 單一 Provider 更新失敗
- **WHEN** Codex 或 Antigravity 其中一個 Provider 更新失敗
- **THEN** 錯誤只影響該 Provider，另一 Provider 的有效狀態與操作維持可用
