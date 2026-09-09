## Why

Menu Bar 的多 Provider 刷新目前雖使用 `async` API，仍以逐一 `await` 的方式依序查詢 Codex 與 Antigravity，使整批等待時間接近各 Provider 耗時總和。將彼此獨立的 Provider 查詢改為並行，可讓額度更快出現，並維持既有快取、錯誤隔離與單一 Provider 重試語意。

## What Changes

- Menu Bar 在需要更新多個已支援 Provider 時，同時啟動所有 Provider 查詢，不設定固定並行數量上限。
- 每個 Provider 內部仍依序執行環境檢查與額度查詢；Provider 間才進行並行。
- 任一 Provider 完成後立即更新自己的快照、最後更新時間、錯誤與載入狀態，不等待整批完成。
- 同一 Provider 已在查詢時，後續重複請求沿用既有去重語意，不取消或重啟該查詢；其他未在查詢的 Provider 仍可獨立開始。
- 刷新期間保留既有額度資料並顯示該 Provider 的更新狀態；失敗時保留舊畫面資料並只對該 Provider 顯示錯誤或過期語意。
- Popover 的全域刷新按鈕在任一 Provider 尚未完成時持續顯示載入狀態並停用，所有 Provider 結束後恢復。
- Popover 工作取消時，取消訊號隨結構化並行傳遞至未完成的子查詢；已完成並套用的結果保留，不建立背景常駐刷新服務。
- Smart Cache 行為維持不變：開啟 Popover 時立即套用新鮮快取，只對快取過期或缺少快取的 Provider 並行查詢；強制刷新則讓所有未在查詢中的 Provider 繞過 TTL。
- 新增可控制的並行測試，驗證查詢確實重疊、完成順序不受註冊順序限制、局部失敗互不影響，以及重複請求不會產生同 Provider 的第二次查詢；不採用固定秒數效能門檻。
- Desktop 單一 Provider 刷新與 Provider 專屬重試行為不變。

## Capabilities

### New Capabilities

無。

### Modified Capabilities

- `menu-bar-usage`：將多 Provider 刷新改為並行、漸進式套用結果，並明確定義去重、快取、失敗隔離、全域載入狀態與取消行為。

## Impact

- ViewModel：影響 `UsageMonitorViewModel.refreshMenuBar(force:)` 的批次刷新協調方式，並可能抽出只負責單一 Provider 工作結果的內部型別或輔助方法。
- UI：`MenuBarPopoverView` 維持現有版面，但全域與 Provider 個別載入狀態必須在並行完成順序下正確反映。
- Provider：不改變 `AgentProvider` 公開介面、Codex JSON-RPC 或 Antigravity CLI 查詢內容；各 Provider 的環境檢查與額度取得順序維持不變。
- Cache：沿用執行緒安全的 `SmartCacheManager`、既有 TTL 及每 Provider 快照；不新增快取層或設定項目。
- 測試：擴充 ViewModel／Smart Cache 測試，使用受控 Mock Provider 驗證結構化並行及狀態隔離，並執行完整 Swift 測試。
- 相依性與相容性：不新增第三方套件、不改資料格式、不變更 Desktop 行為，亦無破壞性 API 變更。
