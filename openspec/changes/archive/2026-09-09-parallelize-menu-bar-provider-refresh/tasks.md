## 1. 單一 Provider 刷新邊界

- [x] 1.1 建立可傳送的單一 Provider 刷新結果，分離背景環境檢查／額度取得與 Main Actor 狀態提交，並以既有 ViewModel 測試驗證成功、環境未就緒及錯誤狀態未改變。
- [x] 1.2 集中處理開始、成功、失敗與取消時的 `refreshingProviders` 清理，並以單元測試驗證所有終止路徑都不會遺留刷新狀態。
- [x] 1.3 讓 Desktop 單一 Provider 刷新與重試沿用共用內部流程但維持既有公開行為，並執行相關 ViewModel／Provider 測試確認無回歸。

## 2. Menu Bar 結構化並行刷新

- [x] 2.1 在 Main Actor 上建立 Menu Bar 批次工作清單，先套用新鮮快取、排除正在查詢的 Provider 並原子式標記其餘工作，透過快取部分命中與重複請求測試驗證篩選及去重。
- [x] 2.2 使用結構化 task group 同時執行所有合格 Provider，逐筆提交先完成的結果，並以受控 Mock Provider 驗證所有查詢在任一查詢完成前均已開始且反向完成順序可立即更新畫面狀態。
- [x] 2.3 保持強制刷新繞過全部 Provider TTL 但不重啟 in-flight 查詢，並以 Mock 呼叫次數驗證每個 Provider 最多只有一個進行中工作。
- [x] 2.4 實作呼叫端取消的傳遞與集中清理，保留已提交結果且不將取消呈現為 Provider 錯誤，並以可控制取消點的測試驗證未完成工作不提交結果。

## 3. 狀態與錯誤隔離驗證

- [x] 3.1 驗證並行刷新時既有快照持續顯示、各 Provider 個別載入狀態依完成順序解除，並以 ViewModel 狀態斷言確認漸進更新。
- [x] 3.2 驗證單一 Provider 失敗只使其快取失效並顯示錯誤，其他 Provider 仍立即提交成功快照，且舊快照不被標記為本次最新結果。
- [x] 3.3 驗證 Menu Bar 全域刷新按鈕在任一 Provider 查詢中維持 spinner 與停用狀態，全部終止後恢復，並手動檢查 Popover 的 Provider 區塊狀態切換。

## 4. 完整驗證與交付

- [x] 4.1 執行完整 `swift test`，確認所有既有與新增測試通過且無 Swift concurrency 警告或資料競爭診斷。
- [x] 4.2 執行 `openspec validate parallelize-menu-bar-provider-refresh --strict --no-interactive`，確認 proposal、design、tasks 與 `menu-bar-usage` spec delta 全部通過嚴格驗證。
- [x] 4.3 完成實作後以繁體中文撰寫 walkthrough，記錄並行時序證據、測試結果、手動 UI 驗證與未納入範圍。
