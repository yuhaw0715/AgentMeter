# 實作結案總結：關閉主視窗後維持 Menu Bar 常駐

## 修改摘要

- 在 `Sources/AgentMeter/App/AgentMeterApp.swift` 的 `AppDelegate` 新增 `applicationShouldTerminateAfterLastWindowClosed(_:)`，固定回傳 `false`。
- 最後一個主視窗關閉時將 activation policy 設為 `.accessory`，移除 Dock 執行中圓點但保留 Menu Bar Extra；重新開啟主視窗前既有流程會恢復 `.regular`。
- 保留既有 `MenuBarExtra` 與單一 `mainWindow` 架構；關閉最後一個桌面主視窗不會終止 App process。
- 將 `AgentMeter` executable target 加入測試 target 依賴，新增 `AppLifecycleTests`，直接驗證 AppKit 終止政策。
- Popover Quit、系統選單 Quit 與 `Cmd-Q` 仍沿用 `NSApplication.terminate(_:)` 的標準終止流程，未修改 Provider、快取或設定邏輯。

## 驗證結果

- `swift test`：13 個測試套件、32 項測試全部通過。
- `swift build -c release`：成功產出 Release executable。
- OpenSpec strict validation：通過。
- 實機 UI 驗收：
  - 紅色關閉按鈕與 `Cmd-W` 關閉主視窗後，`AgentMeter` process 仍維持執行。
  - 關閉後 Dock 的執行中圓點消失；Menu Bar Extra 維持可用。
  - 從 Menu Bar 重新開啟回到單一 `mainWindow`，未產生重複視窗，並恢復 Dock 顯示。
  - 系統選單 Quit 與 `Cmd-Q` 等待終止完成後，`AgentMeter` process 正確停止。

## 備註

測試環境的 SwiftPM sandbox 預設無法使用使用者快取目錄，因此驗證時將 Clang 與 Swift module cache 指向 `/private/tmp`；不影響專案檔案或執行結果。
