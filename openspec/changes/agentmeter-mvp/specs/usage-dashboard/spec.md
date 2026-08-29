## Purpose

提供 macOS SwiftUI Desktop 主視窗介面，完整查看所有已偵測到的 Codex 額度限制、狀態指示器以及重新整理/錯誤狀態。

## ADDED Requirements

### Requirement: 於 Desktop 主視窗顯示所有已偵測額度
桌面應用程式 SHALL 呈現目前啟用中 Provider 的所有已發現 rate limits，包含名稱、已用/剩餘百分比、依已用比例填充的進度條以及重置時間戳記。

#### Scenario: 顯示可用額度清單
- **WHEN** 使用者開啟具有有效使用額度資料的 Desktop Dashboard
- **THEN** 系統完整呈現所有可用 limits 之詳細資訊、進度條與重置時間

### Requirement: 前景視窗主動重新整理
當主視窗被開啟或叫到前景時，系統 SHALL 主動發起 rate limits 重新整理，不受快取 TTL 限制。

#### Scenario: 叫到前景觸發重新整理
- **WHEN** 使用者將焦點切換至 Desktop 視窗或重新開啟視窗
- **THEN** AgentMeter 立即發起重新整理並顯示「Refreshing…」指示器

### Requirement: 狀態與錯誤呈現
系統 SHALL 清晰區分載入中、成功與失敗狀態，並在取得失敗時提供重試機制。

#### Scenario: 正在重新整理中
- **WHEN** rate limit 請求正在執行中
- **THEN** UI 呈現進行中的重新整理狀態並標記最後更新時間

#### Scenario: 重新整理失敗並提供重試選項
- **WHEN** 主動重新整理失敗
- **THEN** UI 顯示錯誤描述與「重試」按鈕，而非將過期資料假裝為目前最新資料
