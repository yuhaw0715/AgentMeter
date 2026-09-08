# 實作結案總結：Codex 重置券顯示

## 實作內容

- 在 `RateLimitSnapshot` 加入可選的 `RateLimitResetCredits` 摘要與 `RateLimitResetCredit` 明細模型。
- 沿用 Codex app-server `account/rateLimits/read`，解析 `rateLimitResetCredits.availableCount`、明細欄位與三態明細語意。
- 以服務端 `availableCount` 作為權威總數；明細不足時顯示差額，不建立虛構券資料。
- 明細依最早到期時間穩定排序，無到期時間置後；快取明細過期只改變呈現狀態，不扣減服務端總數。
- 新增繁中／英文重置券文案與 `yyyy-MM-dd HH:mm:ss` 日期格式化。
- Desktop Codex 額度卡片下方新增永遠顯示的獨立堆疊式 Liquid Glass 重置券卡片。
- Menu Bar 將重置券置於同一個 Codex Provider 外框內，以水平分隔線與額度區段分隔，沿用既有垂直捲動。
- 顯示流程保持唯讀；測試確認只送出 `account/rateLimits/read`，沒有 `account/rateLimitResetCredit/consume`、使用、兌換或消耗操作。

## 狀態語意

- `resetCredits == nil`：服務未提供重置券資訊，介面顯示「重置券資訊未提供」。
- `credits == nil`：服務提供權威總數，但沒有提供明細，介面保留總數並顯示「重置券明細未提供」。
- `credits == []` 且 `availableCount == 0`：已知可用重置券為 0 張。
- `availableCount > credits.count`：顯示已取得明細及「其餘 N 張未提供明細」。
- `expiresAt` 已到期：保留券列並顯示「已到期，等待刷新」。

## 驗證結果

- `swift test`：13 個測試套件、41 項測試全部通過，包含新增的模型、Codex payload、三態明細、排序、快取過期、唯讀 transport 與本地化測試。
- `swift build -c release`：成功。
- `scripts/build-release.sh`：App Bundle、ad-hoc 簽署、`codesign --verify`、ZIP 結構與 checksum 驗證成功。
- 發布產物：`releases/AgentMeter-v1.0.1.zip`。
- SHA-256：`ad84105a683b46be11625ad968efdd468be0441d1b76fe7d02beae1720d3b528`。
- 以該 release App Bundle 在 macOS 26 執行 accessibility／畫面檢查；深色介面成功顯示 Codex 重置券標頭、權威總數與逐張完整到期時間。Menu Bar 仍沿用既有垂直捲動容器，程式結構確認重置券與額度共用單一 Codex 外框。
- OpenSpec strict validation：完成實作後再次驗證通過。

## 官方 API 相容性與刻意排除項目

本次沿用官方 `account/rateLimits/read` 的 `rateLimitResetCredits` 資料；`availableCount` 不會因本機時間或快取呈現而被改寫。官方 `account/rateLimitResetCredit/consume` 不在本次範圍內，程式與 UI 均未加入券消耗、兌換或使用功能。
