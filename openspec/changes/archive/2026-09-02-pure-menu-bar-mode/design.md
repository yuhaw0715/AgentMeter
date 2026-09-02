## Context

參見 `proposal.md`。

目前 AgentMeter 的生命週期中：
1. `Resources/Info.plist` 設定 `<key>LSUIElement</key><false/>`。
2. `AppDelegate.applicationDidFinishLaunching` 會執行 `NSApplication.shared.setActivationPolicy(.regular)`，導致啟動時在 Dock 顯示圖示並自動開啟桌面主視窗。
3. 關閉主視窗時切換為 `.accessory`（隱藏 Dock），但從 Popover 點擊「開啟主視窗」時又會切換回 `.regular`（顯示 Dock）。

為實現如 Stats 般的純選單列常駐小工具體驗，需將 App 生命週期改為全程 `.accessory` 輔助模式。

## Goals / Non-Goals

**Goals:**
- **純 Menu Bar 啟動**：啟動時不主動彈出主視窗，且 Dock 全程不顯示圖示。
- **全程無 Dock 模式**：開啟桌面主視窗時維持 `.accessory` 輔助模式，透過 `activate(ignoringOtherApps: true)` 與 `orderFrontRegardless` 正常在前台展示與互動，關閉主視窗時保留 Menu Bar。
- **Reopen 喚起主視窗**：背景常駐時若使用者從 Spotlight 或 Launchpad 再次啟動 App，透過 `applicationShouldHandleReopen` 直接喚起主視窗至最上層。
- **明確退出**：僅限由 Menu Bar Popover 之「結束 AgentMeter」（Quit AgentMeter）按鈕完全終止程式。

**Non-Goals:**
- 不變更任何 Provider 額度查詢、快取 TTL、多國語言或診斷分析邏輯。
- 不移除桌面主視窗功能，僅調整其啟動、展示與生命週期依附方式。

## Decisions

### 1. `Info.plist` 設定 `LSUIElement = true` 與 AppDelegate 原生輔助模式
- **決策**：在 `Resources/Info.plist` 中將 `LSUIElement` 設為 `<true/>`，並在 `AppDelegate.applicationDidFinishLaunching` 中明確設定 `NSApplication.shared.setActivationPolicy(.accessory)`。
- **理由**：`LSUIElement = true` 讓 macOS 在 Bundle 啟動初期即視為 Agent/Accessory App，避免 Dock 出現短暫閃爍；`setActivationPolicy(.accessory)` 則確保在 SwiftPM 直接執行（`swift run`）與打包後的 App Bundle 中行為一致。
- **替代方案**：僅依賴 Swift 代碼設定 `setActivationPolicy(.accessory)`。雖然可行，但在打包成 `.app` 啟動的最初瞬間可能會在 Dock 閃一下圖示。

### 2. 主視窗展示控制與啟動靜默化
- **決策**：
  1. 啟動時：在 `applicationDidFinishLaunching` 中若有 SwiftUI 自動實例化的主視窗，呼叫 `orderOut(nil)` 隱藏，保持靜默常駐。
  2. 開啟主視窗時：透過 `openMainWindow()` 取得主視窗，執行 `deminiaturize`、`setIsVisible(true)`、`makeKeyAndOrderFront(nil)`、`orderFrontRegardless()` 並呼叫 `NSApplication.shared.activate(ignoringOtherApps: true)`，全程**不切換為 `.regular`**。
  3. 關閉主視窗時：`applicationShouldTerminateAfterLastWindowClosed` 返回 `false`，保持 Menu Bar 常駐。
- **理由**：符合 Stats 的互動模型，既可查看完整桌面儀表板，又不會干擾 Dock 與 `Cmd + Tab` 工作流。

### 3. Reopen 事件處理
- **決策**：在 `applicationShouldHandleReopen` 中，當使用者從 Spotlight / Launchpad 再次點擊 App 時，主動呼叫 `openMainWindow()` 喚起主視窗至最前台。
- **理由**：提供最直覺的使用者體驗，使用者若習慣從 Spotlight 呼叫 App，即可快速調出主儀表板。

## Risks / Trade-offs

- **[無法使用 Cmd+Tab 切換至主視窗]** → 此為 macOS 系統對 `.accessory` / `LSUIElement` 模式的原生限制。使用者可透過 Menu Bar Popover 或 Spotlight 快速喚起主視窗，此取捨符合純選單列常駐工具（如 Stats）之設計預期。
- **[SwiftUI Scene 自動開啟 Window]** → 在 macOS SwiftUI 中，`Window` Scene 可能在啟動時預設建立視窗。透過在 `AppDelegate` 啟動階段將視窗 `orderOut`，可確保啟動時達到完全靜默常駐。
