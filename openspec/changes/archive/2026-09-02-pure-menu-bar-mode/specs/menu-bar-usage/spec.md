## MODIFIED Requirements

### Requirement: 視窗管理與應用程式生命週期
系統 SHALL 預設採用純選單列輔助模式（`.accessory`）常駐運作，全程不在 Dock 顯示圖示；Popover SHALL 提供導航控制項以開啟主視窗、開啟設定與完全退出應用程式。

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
- **WHEN** 使用者由 Popover 點擊「Quit AgentMeter」或「結束 AgentMeter」
- **THEN** 應用程式完全終止執行
