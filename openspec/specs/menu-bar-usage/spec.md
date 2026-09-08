# Menu Bar Usage Specification

## Purpose

提供 macOS Menu Bar 狀態列圖示（極簡 AM Monogram）與互動式 Popover，用於快速查看選定的額度限制、智慧快取以及應用程式導航。

## Requirements

### Requirement: 狀態列圖示呈現

系統 SHALL 在 macOS 狀態列中顯示極簡粗體 `AM` 字樣圖示；Popover 標頭 SHALL 使用與 Desktop 主視窗相同的品牌徽章、Provider 色彩、圓角與狀態標籤，並以 macOS 26 風格的適度 Liquid Glass 表面承載快速資訊。

#### Scenario: 呈現一致的 AM 狀態列入口

- **WHEN** AgentMeter 於背景執行且使用者點擊狀態列圖示
- **THEN** 系統顯示符合 Apple 原生風格的粗體 `AM` 圖示與與主視窗一致的 Popover 品牌標頭

#### Scenario: 呈現極簡 AM 狀態列項目

- **WHEN** AgentMeter 於背景執行
- **THEN** 系統選單列顯示符合 Apple 原生風格之粗體 `AM` 圖示

### Requirement: Smart Cache 與即時 Popover 顯示
每個 Provider SHALL 使用獨立快照並依共用 TTL 設定判斷新鮮度；手動重新整理 SHALL 繞過相應 Provider 的 TTL。

#### Scenario: Provider 快取新鮮度不同
- **WHEN** Popover 開啟時 Codex 快取有效而 Antigravity 快取過期
- **THEN** 系統立即顯示 Codex 快照，並只對 Antigravity 顯示更新中及發起查詢

#### Scenario: 快取有效時開啟 Popover
- **WHEN** 使用者點擊選單列圖示且 Provider 快照仍在設定的 TTL 內
- **THEN** Popover 立即開啟並呈現該 Provider 快取中的使用量，不重複呼叫 Provider

#### Scenario: 快取過期時開啟 Popover
- **WHEN** 使用者點擊選單列圖示且某 Provider 快取已過期
- **THEN** Popover 立即開啟，對該 Provider 顯示重新整理中狀態並取得新快照

#### Scenario: 手動重新整理操作
- **WHEN** 使用者對 Provider 執行手動重新整理
- **THEN** 系統無視該 Provider 的 TTL 並立即請求最新資料

#### Scenario: 快取檢視時重新整理失敗
- **WHEN** 由 Popover 觸發的 Provider 重新整理發生錯誤
- **THEN** 對應 Provider 區塊呈現錯誤資訊與重試按鈕，不把過期資料冒充為最新數據

### Requirement: 即時響應式選取額度清單

Popover SHALL 依 Provider 分組呈現使用者選取的 Codex 與 Antigravity 額度，沿用 Desktop 額度卡片的資訊語意與狀態色，並以緊湊密度支援垂直捲動；各 Provider SHALL 維持獨立載入與錯誤狀態。

#### Scenario: 同時顯示兩個 Provider

- **WHEN** 使用者釘選 Codex 與 Antigravity 額度
- **THEN** Popover 以「ChatGPT Codex」與「Google Antigravity」分組顯示一致樣式的額度列，且超出高度時可垂直捲動

#### Scenario: 主程式勾選即時同步

- **WHEN** 使用者在 Desktop 額度卡片勾選或取消勾選項目
- **THEN** Popover 立即只顯示相同的已選取項目，並保持與主程式相同的百分比、進度條與重置時間呈現

#### Scenario: Popover 更新失敗

- **WHEN** Popover 觸發的 Provider 重新整理發生錯誤
- **THEN** 對應 Provider 區塊顯示可辨識的錯誤狀態與重試按鈕，且其他 Provider 區塊維持可用

#### Scenario: Antigravity 更新失敗

- **WHEN** Antigravity 額度更新失敗但 Codex 快照仍有效
- **THEN** Antigravity 區塊顯示錯誤與重試，Codex 區塊繼續顯示有效資料

#### Scenario: 即時同步勾選之可見額度

- **WHEN** 使用者在任一 Provider Dashboard 中勾選或取消勾選特定額度
- **THEN** Popover 當下即時響應式更新，僅呈現選定的額度項目

#### Scenario: 額度數量超出 Popover 高度

- **WHEN** 選取的跨 Provider 額度項目超出 Popover 顯示高度
- **THEN** 額度清單提供垂直捲動能力

### Requirement: 視窗管理與應用程式生命週期

Popover SHALL 保留導航控制項以開啟主視窗、開啟設定與完全退出應用程式；macOS 26 視覺更新 SHALL 不改變既有純選單列常駐、關閉主視窗後持續執行與明確 Quit 終止政策。

#### Scenario: 從一致風格 Popover 開啟主視窗

- **WHEN** 使用者在 Popover 中點擊「開啟主視窗」
- **THEN** 桌面主視窗被開啟、置於最上層且仍使用同一套側欄與額度卡片視覺

#### Scenario: 應用程式啟動時靜默常駐選單列

- **WHEN** 應用程式手動啟動或開機自動啟動
- **THEN** 系統以 `.accessory` 模式常駐於 Menu Bar，不主動彈出主視窗且 Dock 不顯示圖示

#### Scenario: 從 Popover 開啟 Desktop App

- **WHEN** 使用者在 Popover 中點擊「Open AgentMeter…」或「開啟主視窗」
- **THEN** 桌面主視窗被開啟、解除最小化並置於最上層，且 Dock 維持不顯示圖示

#### Scenario: 背景常駐時由外部再次觸發開啟（Reopen）

- **WHEN** 應用程式已在背景常駐，使用者由 Spotlight 或 Launchpad 再次點擊開啟 AgentMeter
- **THEN** 系統觸發 Reopen 事件並主動將桌面主視窗解除最小化並置於最上層，且 Dock 維持不顯示圖示

#### Scenario: 關閉主視窗時保持 Menu Bar 工具執行

- **WHEN** 使用者關閉桌面主視窗（點擊紅叉或按下 Cmd-W）
- **THEN** 桌面主視窗關閉，應用程式繼續在 Menu Bar 背景常駐執行

#### Scenario: 明確退出指令

- **WHEN** 使用者由 Popover 點擊「結束 AgentMeter」
- **THEN** 應用程式沿用既有標準終止流程完全停止執行

### Requirement: Menu Bar 在單一 Codex 卡片內顯示重置券

Menu Bar Popover SHALL 在單一 ChatGPT Codex Provider 外框內，於既有額度列之後以水平分隔線加入永遠可見的重置券子區段；系統 MUST NOT 為重置券建立第二個獨立外框或提供使用控制項。

#### Scenario: 顯示合併式 Codex 資訊
- **WHEN** 使用者開啟 Menu Bar Popover 且 Codex 快照可用
- **THEN** 同一個 Codex 外框依序包含 Provider 標頭、額度列、水平分隔線、重置券總數與逐張到期資訊，並在其後才呈現下一個 Provider

#### Scenario: 顯示每張券的完整有效期限
- **WHEN** 重置券明細包含一筆或多筆 `expiresAt`
- **THEN** Menu Bar 依最早到期優先顯示「券 N」與 `yyyy-MM-dd HH:mm:ss` 完整時間

#### Scenario: 明細缺少到期時間或筆數不足
- **WHEN** 某筆 `expiresAt` 為 `null`，或權威總數大於已取得明細數
- **THEN** Menu Bar 分別顯示「無到期資訊」與「其餘 N 張未提供明細」，不虛構券列

#### Scenario: 零張與資訊未提供
- **WHEN** 重置券狀態為已知零張或服務未提供
- **THEN** Menu Bar 在 Codex 外框內分別顯示「可用重置券 0 張」或「重置券資訊未提供」

#### Scenario: 快取券已過期
- **WHEN** Popover 顯示的快取券已超過 `expiresAt`
- **THEN** Menu Bar 保留該列並顯示「已到期，等待刷新」，不在本機變更權威總數

#### Scenario: 重置券內容增加 Popover 高度
- **WHEN** Codex 重置券明細使跨 Provider 內容超出 Popover 可用高度
- **THEN** Popover 沿用垂直捲動能力，且每筆券的完整到期時間仍可讀
