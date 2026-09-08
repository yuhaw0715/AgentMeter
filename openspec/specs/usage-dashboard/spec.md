# Usage Dashboard Specification

## Purpose

提供 macOS SwiftUI Desktop 主視窗介面，完整查看所有已偵測到的 Codex 與 Antigravity 額度限制、狀態指示器、雙列標頭與左側 Menu Bar 釘選核取方塊。

## Requirements

### Requirement: 於 Desktop 主視窗顯示所有已偵測額度

桌面應用程式 SHALL 為 ChatGPT Codex 與 Google Antigravity 提供獨立 Dashboard；Dashboard SHALL 採用 macOS 26 風格的側欄、工具列、Provider 標頭與額度卡片，並完整顯示名稱、已用／剩餘百分比、進度、重置時間與 Menu Bar 釘選控制項。Liquid Glass 材質 SHALL 限於側欄、工具列與主要控制表面；額度資訊 SHALL 保持足夠不透明與高對比。

#### Scenario: 使用選項 1 側欄開啟 Provider Dashboard

- **WHEN** 使用者在 macOS 26 風格側邊欄選擇 ChatGPT Codex 或 Google Antigravity
- **THEN** 系統顯示帶有 AgentMeter 品牌區、Provider 導覽狀態、額度卡片與左側 Menu Bar 顯示勾選開關的 Dashboard

#### Scenario: 顯示可讀的額度卡片

- **WHEN** Provider 有有效額度資料
- **THEN** 每張額度卡片以一致的圓角、間距與進度條顯示名稱、已用百分比、剩餘量與 `yyyy-MM-dd HH:mm:ss` 重置時間，且文字在淺色、深色與系統外觀下維持清晰對比

#### Scenario: 顯示載入中或錯誤狀態

- **WHEN** Provider 正在重新整理或重新整理失敗
- **THEN** Dashboard 以一致的狀態標籤與錯誤表面呈現進度／錯誤描述，並保留可操作的重試控制，不以材質效果遮蔽額度內容

#### Scenario: 開啟 Antigravity Dashboard

- **WHEN** 使用者在側邊欄選擇 Google Antigravity
- **THEN** 系統顯示所有有效 Gemini bucket 的名稱、已用／剩餘百分比、進度、重置時間與 Menu Bar 釘選控制項

#### Scenario: Antigravity 環境尚未就緒

- **WHEN** `agy` 缺少、版本不相容、未登入或使用不支援的 API Key 模式
- **THEN** 側邊欄仍顯示 Google Antigravity，Dashboard 呈現對應的設定指引與重新檢查控制項

#### Scenario: 顯示可用額度清單與左側核取方塊

- **WHEN** 使用者開啟具有有效使用額度資料的 Provider Dashboard
- **THEN** 系統完整呈現該 Provider 所有可用 limits 的詳細資訊、進度條、重置時間，並在每張卡片左側提供 Menu Bar 顯示勾選開關

#### Scenario: 雙列標頭佈局與標準時間格式

- **WHEN** 顯示 Provider Dashboard 頂部資訊列
- **THEN** 第一列左側呈現 Provider 名稱、右側齊平呈現重新整理按鈕；第二列不要求 Antigravity 顯示 Email 或方案，右側呈現 `yyyy-MM-dd HH:mm:ss` 格式的最後更新時間

### Requirement: 前景視窗主動重新整理

切換至任一 Provider Dashboard 或將其叫到前景時，系統 SHALL 維持既有不受 TTL 限制的重新整理行為；重新整理控制項 SHALL 使用與側欄及額度卡片一致的 macOS 26 視覺語言。

#### Scenario: 切換 Provider 後重新整理

- **WHEN** 使用者在側欄切換至另一個 Provider
- **THEN** 系統立即只對該 Provider 發起查詢，並在主視窗顯示更新中狀態

#### Scenario: 切換至 Antigravity Dashboard

- **WHEN** 使用者選擇或重新叫出 Google Antigravity Dashboard
- **THEN** 系統立即查詢最新 Gemini 額度並顯示更新中狀態，不連帶強制更新 Codex

#### Scenario: 叫到前景觸發重新整理

- **WHEN** 使用者將焦點切換至目前 Provider Dashboard 或重新開啟視窗
- **THEN** AgentMeter 立即對該 Provider 發起重新整理並顯示「Refreshing…」指示器

### Requirement: 狀態與錯誤呈現
系統 SHALL 清晰區分載入中、成功與失敗狀態，並在取得失敗時提供重試機制。

#### Scenario: 正在重新整理中
- **WHEN** rate limit 請求正在執行中
- **THEN** UI 呈現進行中的重新整理狀態並標記最後更新時間

#### Scenario: 重新整理失敗並提供重試選項
- **WHEN** 主動重新整理失敗
- **THEN** UI 顯示錯誤描述與「重試」按鈕，而非將過期資料假裝為目前最新資料

### Requirement: Desktop 顯示 Codex 重置券資訊卡

ChatGPT Codex Dashboard SHALL 在既有額度卡片下方永遠顯示獨立的重置券資訊卡，並沿用 macOS 26 Liquid Glass 視覺語言；資訊卡 SHALL 採堆疊式券列，標頭同一行左側顯示重置券標題、右側顯示權威可用總數，下方顯示服務端已提供的逐張明細，且 SHALL NOT 提供使用或兌換控制項。

#### Scenario: 同一行顯示標題與可用總數
- **WHEN** Desktop 顯示 Codex 重置券資訊卡
- **THEN** 資訊卡標頭在同一水平列左側顯示「重置券」、右側顯示「N 張可用」，不得將可用總數另置於標題下方

#### Scenario: 顯示多張具有到期時間的券
- **WHEN** Codex 快照包含多筆可用重置券明細
- **THEN** Desktop 依最早到期優先顯示「重置券 N」及每張券的 `yyyy-MM-dd HH:mm:ss` 到期時間

#### Scenario: 券沒有到期時間
- **WHEN** 某筆重置券的 `expiresAt` 為 `null`
- **THEN** Desktop 在該券列顯示本地化的「無到期資訊」

#### Scenario: 明細遭截斷或未完整提供
- **WHEN** 權威可用總數大於已取得的明細數
- **THEN** Desktop 顯示已取得的每筆明細，並顯示本地化的「其餘 N 張未提供明細」

#### Scenario: 已知沒有可用券
- **WHEN** 重置券資料明確回傳可用總數為 0
- **THEN** Desktop 資訊卡顯示本地化的「可用重置券 0 張」

#### Scenario: 重置券資訊未提供
- **WHEN** Codex 快照將重置券狀態標記為未提供
- **THEN** Desktop 資訊卡顯示本地化的「重置券資訊未提供」，且既有額度卡片維持可用

#### Scenario: 快取券已超過到期時間
- **WHEN** 顯示中的快取券已超過 `expiresAt`
- **THEN** Desktop 保留該券列並顯示本地化的「已到期，等待刷新」，不在本機調整權威總數
