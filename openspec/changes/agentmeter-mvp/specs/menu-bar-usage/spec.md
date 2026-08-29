## Purpose

提供 macOS Menu Bar 狀態列圖示與互動式 Popover，用於快速查看選定的額度限制、智慧快取以及應用程式導航。

## ADDED Requirements

### Requirement: 狀態列圖示呈現
系統 SHALL 在 macOS 狀態列中僅顯示圖示，不直接在狀態列呈現百分比文字。

#### Scenario: 呈現純圖示狀態列項目
- **WHEN** AgentMeter 於背景執行
- **THEN** 系統選單列僅顯示應用程式圖示

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

### Requirement: 自訂與可捲動的額度清單
Popover SHALL 允許使用者選取、排序並捲動檢視所呈現的額度項目。

#### Scenario: 使用者選取並排序可見額度
- **WHEN** 使用者在 Settings 中調整額度清單
- **THEN** Popover 僅呈現使用者選定的額度項目，並依照指定的順序排列

#### Scenario: 偵測到新額度且不破壞使用者自訂配置
- **WHEN** Provider 偵測到新的額度類型且使用者先前已自訂過清單
- **THEN** 新額度會出現在 Settings 選項中供勾選，但不會擅自變更使用者既有的選擇

#### Scenario: 額度數量超出 Popover 高度
- **WHEN** 選取的額度項目超出 Popover 顯示高度
- **THEN** 額度清單提供垂直捲動能力

### Requirement: 視窗管理與應用程式生命週期
Popover SHALL 提供導航控制項以開啟主視窗、開啟設定與完全退出應用程式。

#### Scenario: 從 Popover 開啟 Desktop App
- **WHEN** 使用者在 Popover 中點擊「Open AgentMeter…」
- **THEN** 桌面主視窗被開啟並置於最上層

#### Scenario: 關閉主視窗時保持 Menu Bar 工具執行
- **WHEN** 使用者關閉桌面主視窗
- **THEN** 應用程式繼續在 Menu Bar 背景常駐執行

#### Scenario: 明確退出指令
- **WHEN** 使用者選擇 Quit AgentMeter 或按下 Cmd-Q
- **THEN** 應用程式完全終止執行
