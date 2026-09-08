## 1. Domain 模型與官方 CLI 解析

- [x] 1.1 新增型別化 AI Credits 摘要與可用性狀態，擴充 Antigravity Provider 快照，並以 Codable round-trip 測試驗證舊快照解碼相容及已知 0 不會被視為未知。
- [x] 1.2 蒐集並固定官方非互動 CLI 的實際 JSON fixture；只在官方結構化欄位可辨識時解析可用總數，並涵蓋正數、零點、方案不支援、缺少欄位與格式錯誤測試。
- [x] 1.3 驗證 Credits 局部解析失敗不會使有效 Gemini Models 額度刷新失敗，且 AI Credits 不會重新進入既有 Gemini bucket 清單。
- [x] 1.4 以 mock process 驗證刷新只執行官方非互動唯讀命令，不啟動 `/credits` TUI、不存取憑證、不送出購買、設定或消耗操作。

## 2. Smart Cache 與狀態語意

- [x] 2.1 將 AI Credits 摘要與同次 Antigravity 快照共同寫入、讀取與失效，沿用 Provider 共用 TTL、Desktop 前景刷新、Popover 開啟刷新及手動刷新流程。
- [x] 2.2 以固定時鐘測試最後成功值、快取過期、從未成功、成功回應缺少欄位及方案不支援狀態，確認過期資料不會冒充最新資料。

## 3. 本地化與格式化

- [x] 3.1 新增「AI 點數」／`AI Credits`、資訊未知、CLI 未提供、方案不支援及快取已過期等繁中／英文文案，並驗證 `.system`、`.zhHant`、`.en` 即時切換。
- [x] 3.2 新增地區化非負整數顯示並以 `0`、`1,000` 與大數值測試驗證；最後更新時間沿用 `yyyy-MM-dd HH:mm:ss`。

## 4. Desktop AI 點數資訊卡

- [x] 4.1 依確認稿在 Antigravity 額度卡片下方加入永遠顯示的獨立 Liquid Glass 資訊卡，同一標頭列左側顯示圖示與標題、右側顯示總數，下方顯示更新時間。
- [x] 4.2 串接已知正數、零點、方案不支援、CLI 未提供、資訊未知及快取過期狀態，並以預覽確認未知狀態採中性色且沒有購買、設定、刷新或升級控制項。
- [x] 4.3 驗證淺色、深色、繁中、英文及大數值版面，確保標頭、總數與更新時間不截斷。

## 5. Menu Bar 合併式 Antigravity 卡片

- [x] 5.1 依確認稿將 AI 點數放入單一 Antigravity Provider 外框，在 Gemini Models 額度後以水平分隔線區隔，確認沒有巢狀點數卡片或第二個外框。
- [x] 5.2 串接所有可用性與快取狀態，並以窄寬度、雙 Provider 及內容超高情境驗證既有垂直捲動與可讀性。

## 6. 整合驗證與結案

- [x] 6.1 執行 `swift test`，確認新增與既有測試全部通過，且 Provider 隔離、Gemini bucket 過濾、Smart Cache、設定與應用程式生命週期沒有回歸。
- [x] 6.2 執行 release build，並在 macOS 26 實機驗證 Desktop／Menu Bar 淺色、深色、刷新、快取過期、CLI 欄位缺失及方案不支援情境。
- [x] 6.3 完成實作後撰寫繁體中文 walkthrough，記錄最終畫面、官方 CLI 欄位相容性、測試結果與未納入的 Credits 管理功能，再執行 OpenSpec strict validation。
