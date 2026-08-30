## Context

變更動機見 [proposal.md](proposal.md)。目前 `AgentMeterApp` 同時宣告一個 SwiftUI `Window` 與一個 `MenuBarExtra`，兩者共用同一個 process；`AppDelegate` 負責啟動與重新開啟視窗，但沒有明確宣告最後一個視窗關閉後的終止策略。既有 `menu-bar-usage` 主規格要求關閉主視窗後仍常駐，因此生命週期政策必須由 App 層明確保證，而不能依賴 SwiftUI／AppKit 的隱含預設值。

## Goals / Non-Goals

**Goals:**

- 將「關閉視窗不終止 App」設為明確、可驗證的 AppDelegate 政策。
- 主視窗關閉後移除 Dock 的 AgentMeter 執行中狀態，同時保留 Menu Bar Extra。
- 保留現有 Menu Bar 的 Quit 與系統 `Cmd-Q` 完全退出能力。
- 關閉後仍可從 Dock 或 Menu Bar 重新建立或顯示單一主視窗。
- 建立能防止生命週期行為回歸的驗證方式。

**Non-Goals:**

- 不拆分成獨立的主程式與 Menu Bar helper process。
- 不將 AgentMeter 改為僅選單列模式，也不修改 Dock 圖示資產或品牌外觀。
- 不修改 Provider、Smart Cache、Launch at Login 或額度呈現邏輯。

## Decisions

### 1. 由 AppDelegate 明確拒絕「最後視窗關閉即終止」

在 `AppDelegate` 實作 `applicationShouldTerminateAfterLastWindowClosed(_:)`，先將 `NSApplication` 的 activation policy 設為 `.accessory`，再固定回傳 `false`。`.accessory` 會移除 Dock 的執行中狀態而保留 Menu Bar Extra；此 callback 是 AppKit 對該生命週期決策的正式入口，意圖清楚，也同時涵蓋紅色關閉按鈕與 `Cmd-W`。

替代方案是只依賴 macOS AppKit 預設不終止行為；但目前實機結果已顯示行為不符合規格，而且 SwiftUI Scene 的生命週期可能隨系統版本或 Scene 組合而異，因此不採用隱含預設。

### 2. 保持單一 process 架構

主視窗與 `MenuBarExtra` 繼續由同一個 `AgentMeterApp` process 管理。視窗關閉只移除／隱藏視窗，不終止 process，所以 Menu Bar Extra 與共用 `UsageMonitorViewModel` 都能保留。

替代方案是增加 Login Item／XPC helper 專門承載 Menu Bar；這會增加簽署、更新、IPC 與狀態同步複雜度，對目前只需修正關閉行為的問題並不相稱。

### 3. 重新開啟主視窗時恢復一般 App 行為

既有 `openMainWindow()` 在尋找或建立主視窗前將 activation policy 設回 `.regular`，因此從 Menu Bar 重新開啟時會恢復 Dock 顯示與一般視窗的 activation 行為。

### 4. 明確退出沿用標準終止路徑

Popover 的 Quit 繼續呼叫 `NSApplication.terminate(_:)`，系統 App 選單的 Quit 與 `Cmd-Q` 也使用標準終止流程。`applicationShouldTerminateAfterLastWindowClosed` 只影響視窗關閉事件，不攔截明確終止請求。

### 5. 分層驗證生命週期

以自動化測試驗證最後視窗關閉時回傳 `false` 且 activation policy 切換為 `.accessory`，並以建置後 App 的手動驗收覆蓋 AppKit 實際事件：紅色關閉、`Cmd-W`、Dock 執行中狀態消失、從 Menu Bar 重新開啟、`Cmd-Q`。純單元測試無法完整證明 macOS 狀態列項目仍可見，因此保留最小必要的實機驗收。

## Risks / Trade-offs

- **[風險] 視窗關閉後仍有其他 SwiftUI Scene 觸發 process 終止** → 以實機驗收確認 process 與 Menu Bar 圖示持續存在，必要時再追查 Scene teardown，而非只依賴單元測試。
- **[風險] `.accessory` policy 使主視窗重新開啟時無法正常取得焦點** → `openMainWindow()` 在開啟前恢復 `.regular` 並啟用 App，透過實機驗收確認焦點與 Dock 狀態。
- **[風險] 關閉後重新開啟產生重複主視窗** → 沿用並測試現有「先尋找既有可成為主視窗的視窗，否則 `openWindow`」流程。
- **[取捨] App 在沒有主視窗時仍持續佔用少量資源** → 這是 Menu Bar 常駐工具的預期行為；資料刷新仍遵循既有 Smart Cache 與使用者操作。

## Migration Plan

1. 加入明確的最後視窗關閉終止政策與回歸測試。
2. 執行完整 Swift 測試與 release build 驗證。
3. 在建置後 App 依序驗收關閉、Menu Bar 常駐、重新開啟與明確退出。
4. 若發生回歸，可單獨回退 AppDelegate 生命週期政策；此變更不涉及資料格式或設定遷移。
