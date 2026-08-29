# Agent Provider Abstraction Specification

## Purpose

建立具備可擴充性的 Agent 使用量 Provider 架構邊界，以利未來支援其他 Provider，並在 MVP 介面中僅暴露 Codex。

## Requirements

### Requirement: 模組化 Provider 抽象層
核心領域層 SHALL 定義使用量 Provider 的 Protocol 抽象，將額度快照資料模型與獲取機制自特定 CLI 實作中解耦。

#### Scenario: 於標準介面後隔離 Provider 專屬協定
- **WHEN** UI 向目前啟用的 Provider 請求使用量快照
- **THEN** Provider 抽象層提供正規化快照資料，不論底層 JSON-RPC/API 之具體細節

### Requirement: MVP 階段的 Provider UI 隔離
使用者介面 SHALL 專屬呈現 Codex Provider，並隱藏尚未實作的 Provider（如 Gemini 或 Antigravity）。

#### Scenario: Desktop 與 Menu Bar UI 僅呈現 Codex Provider
- **WHEN** 使用者在桌面應用程式或 Popover 中瀏覽 Provider 或導航選單
- **THEN** 僅有 ChatGPT Codex 會被列出且可供存取
