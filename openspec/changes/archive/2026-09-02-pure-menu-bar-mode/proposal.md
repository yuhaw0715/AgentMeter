## Why

目前 AgentMeter 於應用程式啟動時會以常規應用程式模式（`.regular`）開啟主視窗並在 Dock 顯示圖示，容易在使用者以 `Cmd + Tab` 切換視窗或整理 Dock 時被誤關或佔用 Dock 空間。

為了提供如 macOS 知名系統工具（如 Stats）般極簡、靜默且不干擾的體驗，AgentMeter 應改為預設以輔助模式（`.accessory`）常駐於 Menu Bar：啟動時不彈出主視窗且 Dock 全程不顯示圖示，使用者需要查看時再透過 Menu Bar Popover 或 Spotlight/Launchpad 喚起主視窗。

## What Changes

- **應用程式啟動行為**：
  - 應用程式啟動時（無論手動開啟或登入開機啟動）預設以 `.accessory` 輔助模式常駐於 Menu Bar。
  - 啟動時不再自動跳出主視窗，亦不在 Dock 顯示圖示。
- **全程無 Dock 圖示模式**：
  - 主視窗開啟時（透過 Menu Bar Popover 點擊「開啟主視窗」），主視窗直接置頂前台，但應用程式維持 `.accessory` 模式，**Dock 全程不出現圖示**。
  - 關閉主視窗時（點擊紅叉或 `Cmd + W`），主視窗正常關閉/隱藏，應用程式繼續在 Menu Bar 背景常駐。
- **二次點擊 / Reopen 行為**：
  - 當 AgentMeter 已在背景常駐時，若使用者從 Spotlight 或 Launchpad 再次點擊/開啟 AgentMeter，系統觸發 `applicationShouldHandleReopen` 並主動為使用者喚起並置頂主視窗（仍維持無 Dock 圖示）。
- **退出應用程式**：
  - 應用程式退出由 Menu Bar Popover 中的「結束 AgentMeter」（Quit AgentMeter）按鈕或明確的 Quit 選單項負責。

## Capabilities

### New Capabilities

無。

### Modified Capabilities

- `menu-bar-usage`: 更新應用程式生命週期與視窗管理規範，定義純 Menu Bar 模式（啟動時無 Dock 與無自動彈窗、主視窗開啟時維持無 Dock 狀態、Reopen 事件喚起主視窗、僅由 Menu Bar 專屬 Quit 控制項完全退出）。

## Impact

- `Sources/AgentMeter/App/AgentMeterApp.swift`：設定啟動時為 `.accessory` 模式且不主動開啟主視窗；開啟主視窗時維持 `.accessory`；優化 `applicationShouldHandleReopen` 與 `openMainWindow` 確保主視窗正確喚起與置頂。
- `Tests/AgentMeterTests/AppLifecycleTests.swift`：更新測試案例以驗證全程 `.accessory` 生命週期、主視窗關閉後維持常駐及 Reopen 行為。
