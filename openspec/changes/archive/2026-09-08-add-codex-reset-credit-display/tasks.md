## 1. Domain 模型與 Provider 解析

- [x] 1.1 新增型別化重置券明細與摘要模型，擴充 `RateLimitSnapshot` 的可選欄位，並以 Codable round-trip 測試驗證既有快照解碼相容及 `credits` 的 null／空陣列三態。
- [x] 1.2 擴充 Codex `account/rateLimits/read` 解析，保留官方明細欄位、以 `availableCount` 為權威總數並計算缺少明細數；以完整、截斷、只含總數、零張及缺少欄位 payload 測試驗證。
- [x] 1.3 實作最早到期優先、無到期時間置後的穩定排序與快取過期呈現狀態，並以固定時鐘單元測試驗證不會在本機扣除權威總數。
- [x] 1.4 驗證取得與刷新流程只送出 `account/rateLimits/read`，以 mock transport 測試確認不會呼叫 `account/rateLimitResetCredit/consume`。

## 2. 本地化與共用呈現元件

- [x] 2.1 新增重置券標題、可用張數、券編號、無到期資訊、其餘明細未提供、資訊未提供及已到期等待刷新等繁中／英文文案，並以語系切換測試驗證兩種語言與時間格式。
- [x] 2.2 建立可供不同密度畫面使用的唯讀券列呈現元件，並以預覽或 UI 組合測試驗證正常、無期限、缺少明細及已過期狀態均無使用按鈕。

## 3. Desktop 重置券資訊卡

- [x] 3.1 在 Codex Dashboard 額度卡片下方加入永遠顯示的獨立 Liquid Glass 重置券資訊卡，依 Desktop A 方案在同一標頭列左側呈現標題、右側呈現可用總數，下方呈現堆疊券列，並以預覽確認淺色、深色與長時間字串不截斷。
- [x] 3.2 串接零張、資訊未提供、明細差額與快取過期狀態，以 ViewModel／UI 組合測試確認重置券資料缺失不會遮蔽或破壞既有額度卡片。

## 4. Menu Bar 合併式 Codex 卡片

- [x] 4.1 依選定 A 方案將 Provider 標頭、額度列、水平分隔線與重置券列放入單一 Codex 外框，移除任何巢狀券卡片語意，並以 View hierarchy 或預覽檢查確認只有一個 Codex 外層容器。
- [x] 4.2 串接逐張完整 `yyyy-MM-dd HH:mm:ss` 到期時間、零張、未知、差額與過期狀態，並以緊湊寬度預覽確認所有文字可讀且下一個 Provider 位於 Codex 外框之後。
- [x] 4.3 驗證大量券明細與雙 Provider 同時顯示時沿用垂直捲動，以 UI 預覽或實機測試確認 Popover 不溢出且每筆期限可查看。

## 5. 整合驗證

- [x] 5.1 執行 `swift test`，確認新增與既有 13 大測試套件全部通過且 Provider 隔離、Smart Cache、設定與生命週期行為未回歸。
- [x] 5.2 執行 release build，並在 macOS 26 實機驗證 Desktop／Menu Bar 的淺色、深色、刷新、快取跨到期時間、舊版欄位缺失及跨 Provider 捲動情境。
- [x] 5.3 完成實作後撰寫繁體中文 walkthrough，記錄最終畫面、測試結果、官方 API 相容性與未納入的券消耗功能，再執行 OpenSpec strict validation。
