## Why

目前使用者關閉 AgentMeter 桌面主視窗後，Menu Bar 工具會一併消失，與既有 `menu-bar-usage` 規格「關閉主視窗時保持 Menu Bar 工具執行」的要求不符。這使使用者無法將主視窗收起後繼續從選單列查看額度，因此需要修正應用程式生命週期行為。

## What Changes

- 明確區分「關閉桌面主視窗」與「完全退出 AgentMeter」兩種操作。
- 關閉主視窗（包含紅色關閉按鈕與 `Cmd-W`）後，維持應用程式 process 與 Menu Bar Extra 執行。
- 關閉主視窗後隱藏 Dock 的 AgentMeter 執行中狀態；從 Menu Bar 重新開啟時恢復一般 Dock App 行為。
- 僅在使用者選擇 Quit AgentMeter、Popover 的 Quit 或按下 `Cmd-Q` 時終止應用程式。
- 補充生命週期自動化測試與手動驗收，涵蓋關閉、重新開啟及明確退出流程。

## Capabilities

### New Capabilities

無。

### Modified Capabilities

無。既有 `menu-bar-usage` 主規格已完整定義所需行為，本變更屬於修正實作使其符合現有規格，因此設定 `skip_specs: true`。

## Impact

- 受影響程式碼：`Sources/AgentMeter/App/AgentMeterApp.swift` 的 AppDelegate、activation policy、SwiftUI Scene 與主視窗生命週期管理。
- 受影響測試：新增或調整 App 生命週期測試，並確認既有 Menu Bar、主視窗重新開啟與 Quit 行為不回歸。
- 不新增外部相依套件，不改變 Provider、快取格式或使用者設定資料。
