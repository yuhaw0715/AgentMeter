# Menu Bar Usage Specification

## Purpose

提供 macOS Menu Bar 狀態列圖示（極簡 AM Monogram）與互動式 Popover，用於快速查看選定的額度限制、智慧快取以及應用程式導航。

## Requirements

### Requirement: 狀態列圖示呈現
系統 SHALL 在 macOS 狀態列中顯示極簡粗體 `AM` 字樣圖示，Popover 標頭帶有品牌徽章。

#### Scenario: 呈現極簡 AM 狀態列項目
- **WHEN** AgentMeter 於背景執行
- **THEN** 系統選單列顯示符合 Apple 原生風格之粗體 `AM` 圖示

### Requirement: Smart Cache 與即時 Popover 顯示
點擊選單列圖示時，Popover SHALL 立即展開，在快取有效時呈現快照，快取過期時觸發背景重新整理。

#### Scenario: 快取有效時開啟 Popover
- **WHEN** 使用者點擊選單列圖示且目前快照時間仍在設定的 TTL 內（預設 5 分鐘）
- **THEN** Popover 立即開啟並呈現快取中的使用量，不重複呼叫 Provider

#### Scenario: 快取過期時開啟 Popover
- **WHEN** 使用者點擊選單列圖示且快取已過期
- **THEN** Popover 立即開啟，顯示重新整理中狀態並取得新的 rate-limit 快照

#### Scenario: 手動重新整理操作
- **WHEN** 使用者點擊 Popover 內的手動重新整理按鈕
- **THEN** 系統無視 TTL 立即強制向 Provider 請求最新資料

#### Scenario: 快取檢視時重新整理失敗
- **WHEN** 由 Popover 觸發的重新整理發生錯誤
- **THEN** UI 呈現錯誤資訊與重試按鈕，不把過期資料冒充為最新數據

### Requirement: 即時響應式選取額度清單
Popover SHALL 依據使用者在各 Agent 儀表板中勾選的項目即時同步呈現，無額度裁切或顯示異常。

#### Scenario: 即時同步勾選之可見額度
- **WHEN** 使用者在 Agent 儀表板中勾選或取消勾選特定額度
- **THEN** Popover 當下即時響應式更新，僅呈現選定的額度項目

#### Scenario: 額度數量超出 Popover 高度
- **WHEN** 選取的額度項目超出 Popover 顯示高度
- **THEN** 額度清單提供垂直捲動能力

### Requirement: 視窗管理與應用程式生命週期
Popover SHALL 提供導航控制項以開啟主視窗、開啟設定與完全退出應用程式。

#### Scenario: 從 Popover 開啟 Desktop App
- **WHEN** 使用者在 Popover 中點擊「Open AgentMeter…」
- **THEN** 桌面主視窗被開啟、解除最小化並置於最上層

#### Scenario: 關閉主視窗時保持 Menu Bar 工具執行
- **WHEN** 使用者關閉桌面主視窗
- **THEN** 應用程式繼續在 Menu Bar 背景常駐執行

#### Scenario: 明確退出指令
- **WHEN** 使用者選擇 Quit AgentMeter 或按下 Cmd-Q
- **THEN** 應用程式完全終止執行
