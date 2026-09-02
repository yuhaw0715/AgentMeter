## 1. 應用程式配置與生命週期調整

- [x] 1.1 更新 `Resources/Info.plist` 將 `LSUIElement` 設為 `true`，使應用程式預設作為輔助 Agent 常駐
- [x] 1.2 修改 `Sources/AgentMeter/App/AgentMeterApp.swift` 中的 `AppDelegate` 與 `AgentMeterApp`，啟動時設為 `.accessory` 輔助模式並隱藏初始視窗，保持純 Menu Bar 靜默常駐
- [x] 1.3 更新 `openMainWindow` 與 `applicationShouldHandleReopen` 邏輯，確保由 Popover 點擊或 Spotlight/Launchpad 二次啟動時能正確喚起主視窗置頂前台，且全程維持 `.accessory` 模式（Dock 不顯示圖示）

## 2. 測試與驗證

- [x] 2.1 更新 `Tests/AgentMeterTests/AppLifecycleTests.swift` 單元測試，驗證全程 `.accessory` 模式、主視窗關閉後維持常駐以及 Reopen 事件喚起
- [x] 2.2 執行完整測試套件 (`swift test`) 確保所有 13 個測試套件均 100% 通過
- [x] 2.3 執行發布腳本驗證 (`scripts/build-release.sh`) 確保 App Bundle 正確打包與驗證通過
