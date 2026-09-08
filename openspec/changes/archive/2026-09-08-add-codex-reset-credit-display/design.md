## Context

詳見 [proposal.md](proposal.md) 的動機。現有 `CodexRateLimitProvider` 已呼叫官方 `account/rateLimits/read`，但只將 `rateLimits` 正規化為 `RateLimitSnapshot.items`；同一回應新提供的 `rateLimitResetCredits` 尚未進入 Domain、Smart Cache 或 UI。Desktop 與 Menu Bar 共用 `UsageMonitorViewModel` 的 Provider 快照，因此新資料應維持單一來源，不能在兩個 View 各自解析原始 JSON。

官方文件定義 `availableCount` 為權威總數，而 `credits` 可能為 `null`、空陣列或遭截斷。設計必須保存這三種不同語意，也必須讓舊版 CLI 缺少新欄位時不影響既有額度解析。

## Goals / Non-Goals

**Goals:**

- 以型別化 Domain 模型保存重置券總數、明細完整性與逐張資料。
- 讓 Desktop 與 Menu Bar 從同一份 Codex 快照呈現一致狀態。
- 保持 `availableCount` 的服務端權威性，同時根據本機時間標示已到期的快取明細。
- 讓新增欄位具向後相容與局部容錯能力。

**Non-Goals:**

- 不實作 `account/rateLimitResetCredit/consume`、確認對話框或 idempotency key 管理。
- 不新增通知、到期提醒或重置券 Menu Bar 顯示偏好。
- 不顯示服務端 `title` 與 `description`，也不將其作為本地化來源。
- 不變更 Antigravity Provider 或一般 `RateLimitItem` 的額度語意。

## Decisions

### 1. 在 Codex 快照加入可空的型別化重置券摘要

新增 Codable／Equatable／Sendable 的重置券明細與摘要模型，並由 `RateLimitSnapshot` 以可空欄位承載。摘要保留 `availableCount`、`credits` 的三態資訊及差額計算；明細保留官方全部欄位，即使本次 UI 只使用編號與到期時間。

替代方案是把每張券偽裝成 `RateLimitItem`。該模型以百分比與額度重置視窗為核心，會混淆「額度限制」和「可消耗券」，也會被既有釘選與排序邏輯誤處理，因此不採用。

### 2. 在既有 `account/rateLimits/read` 解析流程一次完成正規化

Provider 對同一 JSON-RPC 回應同時解析額度與重置券，不新增第二次 CLI 程序或請求。若重置券欄位、單筆明細或可選欄位格式不完整，只降級該部分資料；有效的 rate-limit 資料仍建立快照。

替代方案是在 ViewModel 或 View 解析原始 JSON，會破壞 Provider 抽象並造成兩個入口行為分歧，因此不採用。

### 3. 總數與明細採不同權威層級

顯示總數永遠使用 `availableCount`；逐張清單只顯示服務端實際提供的明細。`max(availableCount - credits.count, 0)` 用於「其餘 N 張未提供明細」，但不合成缺少的券物件。`credits == nil` 表示明細未提供，`credits == []` 表示服務已查詢且沒有可用明細。

### 4. 排序與到期判斷維持確定性

具有 `expiresAt` 的明細按時間升冪排列，無到期時間者置後；相同到期時間以原始回傳順序穩定排序。View 以目前時間判斷快取明細是否已過期，只改變狀態文字，不刪除明細或扣除 `availableCount`。取得新快照後完全採用服務端新版資料。

### 5. Desktop 與 Menu Bar 採不同密度、相同資料語意

Desktop 採使用者確認的 A 堆疊式方案，在額度卡片下方使用獨立資訊卡，標頭同一行左側放置重置券標題、右側放置可用總數，下方以寬鬆的堆疊列呈現逐張期限。Menu Bar 採使用者選定的 A 方案：重置券直接放入單一 Codex Provider 外框，在 Weekly 額度後以水平分隔線分組，券列不使用 pill、巢狀卡片或第二個外框。兩者都永遠呈現該區段，且不加入操作按鈕。

設計比較附件：

- [Desktop 三種排版](assets/desktop-reset-credit-variants.png)；比較用原始方案。
- [Desktop 最終確認版 A](assets/desktop-reset-credit-selected-a.png)；標題與可用總數同列、下方使用堆疊式券列。
- [Menu Bar 真正合併的三種排版](assets/menubar-integrated-reset-credit-variants.png)；使用者已選定 A 的單純分隔線方案。

### 6. Smart Cache 不新增第二套生命週期

重置券隨 Codex `RateLimitSnapshot` 一起寫入、讀取與失效，沿用既有 TTL、Desktop 前景刷新、Popover 開啟刷新及手動繞過 TTL 行為。這可確保額度與重置券來自同一次服務端觀測。

## Risks / Trade-offs

- **[風險] 舊版 Codex CLI 不回傳新欄位** → 將狀態呈現為「資訊未提供」，額度解析與連線成功狀態不受影響。
- **[風險] 明細被服務端截斷，畫面列數小於總數** → 顯示權威總數與差額提示，不虛構資料。
- **[風險] 快取跨越券到期時間** → 即時標示「已到期，等待刷新」，但保留服務端最後總數直到刷新。
- **[風險] Menu Bar 因逐張到期時間變高** → 使用緊湊純文字列與既有垂直捲動，不縮短完整時間或隱藏券。
- **[取捨] 永遠顯示零張或未知狀態會占用少量空間** → 換取使用者能分辨零張、未知與載入失敗。
- **[取捨] 保留但不呈現官方標題與描述** → 避免未翻譯或不穩定文案破壞介面，同時保留未來擴充能力。

## Migration Plan

1. 加入可選重置券 Domain 模型與向後相容的 Codable 預設行為。
2. 擴充 Codex Provider parser 與單元測試，再讓資料隨既有快照進入 Smart Cache。
3. 新增本地化字串與 Desktop A 方案獨立資訊卡，並將標題與可用總數置於同一行。
4. 依 A 方案更新 Menu Bar 單一 Codex 外框與捲動呈現。
5. 執行 Provider、快取、ViewModel、完整 Swift 測試及 macOS 26 淺／深色實機檢查。

若需回退，可移除可選快照欄位與兩個 UI 區段；既有 `rateLimits` 解析、設定鍵值與快取 TTL 不需資料遷移。
