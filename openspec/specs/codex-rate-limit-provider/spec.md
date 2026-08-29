# Codex Rate Limit Provider Specification

## Purpose

透過官方 Codex CLI 的 app-server 整合取得、解析並正規化即時 rate-limit 快照，包含 `initialize` 握手與官方 `primary` / `secondary` 額度解析，無需自行快取憑證或呼叫私人端點。

## Requirements

### Requirement: 透過 JSON-RPC 連接 Codex app-server
系統 SHALL 啟動或連接官方 `codex app-server` 程序，發送 `initialize` 握手協議，並透過標準 stdio/socket 的 JSON-RPC 進行通訊。

#### Scenario: 成功執行握手並呼叫 JSON-RPC
- **WHEN** AgentMeter 對執行中或可啟動的 `codex app-server` 發起重新整理
- **THEN** 系統依序發送 `initialize` 握手封包與 `account/rateLimits/read`，並取得有效的 rate-limit 回傳資料

#### Scenario: App server 無法使用或啟動失敗
- **WHEN** `codex app-server` 無法啟動或發生執行錯誤
- **THEN** 系統捕捉該錯誤並呈現具描述性的連線失敗狀態，且不發生崩潰

### Requirement: 取得並正規化 Rate Limits
系統 SHALL 支援解析官方 `primary` (5-Hour Session Limit) 與 `secondary` (Weekly Limit) 結構，並保留動態解析通用 limit 模型的向下相容能力。

#### Scenario: 回傳官方 primary 與 secondary 額度
- **WHEN** Codex app-server 回傳官方 `rateLimits` 物件（含 `primary` 300 分鐘與 `secondary` 10080 分鐘及 `planType`）
- **THEN** 系統精確擷取 5 小時工作階段、每週額度、使用百分比、方案名稱與重置時間戳記至正規化模型中

#### Scenario: 回傳未知或動態額度類型
- **WHEN** Codex app-server 回傳新出現或未識別的 limit 項目
- **THEN** 系統動態以通用 limit 呈現，不發生解析失敗或靜默忽略

### Requirement: 處理額度計算與重置時間戳記
系統 SHALL 計算已使用/剩餘百分比，並使用系統語系格式化重置時間；若未提供重置時間則顯示備用標籤。

#### Scenario: 使用百分比計算與四捨五入
- **WHEN** 接收到原始使用量數據或百分比
- **THEN** 系統在 UI 顯示時將百分比格式化為整數，同時在資料層保留原始精度

#### Scenario: 未提供重置時間戳記
- **WHEN** Provider 回傳內容未包含該 limit 的重置時間戳記
- **THEN** 系統顯示本地化的「無法取得重置時間」標籤，不得自行推算或造假時間

#### Scenario: 達到使用上限指示
- **WHEN** 使用百分比達到 100%
- **THEN** 系統顯示本地化的「已達使用上限」狀態指示
