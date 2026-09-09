# Parallelize Menu Bar Provider Refresh 實作結案

## 完成摘要

Menu Bar 的多 Provider 刷新已由循序 `await` 改為結構化並行。系統會先在 Main Actor 套用仍有效的快取並原子式保留需要查詢的 Provider，再以 task group 同時執行 Codex 與 Antigravity 的環境檢查／額度查詢。每個子工作完成後立即提交自己的結果，不再等待其他 Provider。

Desktop 單一 Provider 刷新與 Provider 專屬重試仍維持原有產品行為，但與 Menu Bar 共用相同的型別化結果提交流程，避免成功、環境未就緒、失敗與取消的狀態語意分歧。

## 實作內容

- 新增私有且符合 `Sendable` 的 `ProviderFetchResult`，涵蓋成功、環境未就緒、錯誤與取消。
- 將 Provider I/O 移入 `nonisolated` 非同步工作；ViewModel 字典、Smart Cache 與載入集合仍只由 Main Actor 修改。
- `refreshMenuBar(force:)` 使用 task group 啟動所有合格 Provider，並依實際完成順序逐筆套用結果。
- 建立 Main Actor 原子式 `beginFetch` 去重，重複刷新不會取消、重啟或建立同 Provider 的第二個工作。
- 非強制刷新只查詢快取過期或不存在的 Provider；強制刷新繞過 TTL，但仍遵守 in-flight 去重。
- 失敗只清除該 Provider 的快取新鮮度並保留 ViewModel 中最後畫面資料；取消不顯示成錯誤，也不提交取消後的查詢結果。
- 所有成功、未就緒、失敗與取消路徑都會清除對應 `refreshingProviders` 項目。

## 並行與狀態驗證

新增 `Usage Monitor Concurrent Refresh Tests`，以 actor 與 continuation 控制 Provider 的開始和完成順序，不使用固定 sleep 作為效能門檻：

1. 在任一 Provider 獲准完成前，測試已同時觀察到 Codex 與 Antigravity 進入 fetch，證明查詢重疊而非循序。
2. 先釋放 Antigravity 時，其快照立即出現且載入狀態解除，Codex 仍維持刷新中，證明結果漸進提交。
3. 新鮮 Codex 快取不會啟動查詢，只有過期的 Antigravity 進入背景工作。
4. 刷新進行中再次強制刷新，兩個 Provider 的 fetch 次數仍各為一次。
5. Codex 失敗時保留舊快照、清除其 Smart Cache 並顯示錯誤；Antigravity 成功結果不受影響。
6. 取消會傳遞至子工作、清除全域／個別載入來源，保留舊資料且不新增錯誤。
7. Desktop 成功、環境未就緒與失敗流程均通過回歸驗證。

`MenuBarPopoverView` 的標頭 spinner 與停用狀態既有實作直接取決於 `refreshingProviders.isEmpty`，Provider 區塊則讀取同一集合中的個別項目；新增測試已驗證一個 Provider 完成後集合仍保留其他工作，所有工作終止後才清空。因此 UI 不需修改即可反映已確認的全域及個別載入行為。

曾建立臨時 ad-hoc App bundle 嘗試以 macOS 輔助功能直接觀察 Popover；由於純 Menu Bar `.accessory` App 在此自動化環境未暴露可控制視窗，無法取得可靠畫面。未使用已安裝舊版本替代驗證；最終以 ViewModel 狀態測試及 UI 的直接資料繫結完成可重現驗證。

## 測試結果

- `swift test`：14 套件、51 項測試全部通過（原 45 項加新增 6 項）。
- Live Codex integration：通過。
- Live Antigravity integration：通過。
- Swift 6 編譯：通過，未出現 concurrency 警告。
- `git diff --check`：通過。
- `openspec validate parallelize-menu-bar-provider-refresh --strict --no-interactive`：通過。

## 未納入範圍

- 未改變 Desktop 為多 Provider 批次刷新。
- 未平行化同一 Provider 內的環境檢查與額度查詢。
- 未新增背景常駐刷新服務、並行數量設定、額外逾時或 CLI 強制終止機制。
- 未修改 Provider protocol、CLI 指令、Smart Cache 資料格式、設定或 Menu Bar 版面。
