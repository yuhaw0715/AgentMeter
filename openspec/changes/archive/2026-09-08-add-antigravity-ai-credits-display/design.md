## Context

現有 `AntigravityRateLimitProvider` 透過官方 `agy -p "/usage" --output-format json` 執行唯讀查詢，動態解析 Gemini Models 額度並排除 AI Credits。Antigravity 官方另有互動式 `/credits` 面板，但目前未保證所有 CLI 版本都會在非互動 JSON 中提供對應餘額。此變更必須在不放寬安全邊界的情況下，預留官方結構化欄位出現時的解析與顯示能力。

Desktop 與 Menu Bar 共用 `UsageMonitorViewModel` 的 Provider 快照，因此 AI Credits 應在 Provider 層完成正規化，並與同次 Antigravity 額度觀測一同快取。兩個 View 不得各自解析原始 JSON，也不得為取得 Credits 額外執行互動式 CLI。

## Goals / Non-Goals

**Goals:**

- 僅從官方非互動唯讀 CLI 輸出取得 AI Credits 可用總數。
- 明確區分已知正數、已知零點、方案不支援、CLI 未提供與一般資訊未知。
- 讓 Desktop 與 Menu Bar 從同一份 Antigravity 快照呈現一致數值及新鮮度。
- 讓新增欄位局部容錯並向後相容，不影響既有 Gemini Models 額度。
- 延續已確認的 macOS 26 Liquid Glass 視覺與雙 Provider 資訊架構。

**Non-Goals:**

- 不購買、加值、啟用、停用、扣除或消耗 AI Credits。
- 不修改 `useG1Credits` 或 AI Credit Overages 設定。
- 不顯示近期增減紀錄、消耗明細或逐筆到期資訊。
- 不解析 `/credits` TUI 文字、不讀取 OAuth／Keychain，也不呼叫 CLI 使用的未公開後端 API。
- 不新增 AI 點數專屬刷新按鈕、TTL、通知或顯示偏好。

## Decisions

### 1. 使用型別化 AI Credits 摘要保存資料與可用性

在 Antigravity Provider 快照加入可選的型別化摘要，至少保存狀態、可用總數與觀測時間。狀態需能表達 `available`、`unsupportedPlan`、`cliFieldUnavailable` 與 `unknown`；`available` 可包含 0，避免將「已知沒有點數」誤判成「沒有資料」。

替代方案是將 AI Credits 偽裝成 `RateLimitItem`。該模型以使用百分比、剩餘比例及重置時間為核心，無法準確描述可消耗點數，且可能被 Gemini bucket 排序與 Menu Bar 釘選邏輯誤處理，因此不採用。

### 2. 僅信任官方非互動結構化輸出

Provider 只解析既有官方唯讀命令同次回應中可辨識的 Credits 欄位。欄位缺失時回傳 `cliFieldUnavailable`；欄位存在但格式無法安全辨識時降級成 `unknown`，同時保留有效 Gemini 額度。解析器必須以 fixture 鎖定實際官方欄位名稱後才將狀態標成 `available`，不得猜測數字或從畫面文字擷取。

替代方案包括驅動 `/credits` TUI 或重放內部網路請求。前者易受終端寬度、本地化與渲染版本影響，後者會跨越目前不管理憑證及不使用私人 API 的安全邊界，因此均不採用。

### 3. AI Credits 與模型額度共用刷新及快取生命週期

同一次 Antigravity 查詢產生一份包含 Gemini Models 與 AI Credits 摘要的快照。Desktop 前景刷新、Popover 開啟刷新、手動刷新及 TTL 判斷完全沿用既有 Provider 流程，不啟動第二個子行程。

若刷新整體失敗且存在最後一次成功的 Credits 餘額，UI 保留該值並依既有快取新鮮度標示「快取已過期」；從未成功取得數值則顯示「資訊未知」。如果刷新成功但 CLI 明確沒有欄位，顯示 `cliFieldUnavailable`，不得把先前餘額冒充為本次官方結果。

### 4. Desktop 採獨立資訊卡

Antigravity Dashboard 在所有 Gemini 額度卡片之後顯示永遠存在的 AI 點數卡。標頭同一行左側放置中性的點數圖示與「AI 點數」，右側顯示地區化總數；更新時間置於下方次要資訊列。未知或不支援狀態以中性色呈現，不使用錯誤紅色，也不加入升級、重試、購買或設定操作。

已確認示意圖：

- [Desktop 正常餘額](assets/desktop-ai-credits-available.png)
- [Desktop CLI 尚未提供資訊](assets/desktop-ai-credits-unavailable.png)

### 5. Menu Bar 採單一 Antigravity 外框

Menu Bar 在同一個 Google Antigravity Provider 外框中，依序呈現 Provider 標頭、Gemini Models 額度列、水平分隔線及 AI 點數摘要。點數列左側顯示圖示與標題、右側顯示總數，下方以緊湊次要文字顯示更新時間。不得建立巢狀卡片或第二個 Provider 外框。

已確認示意圖：[Menu Bar 正常餘額](assets/menubar-ai-credits-available.png)。

### 6. 文案及數字格式遵循使用者語言

繁體中文標題固定為「AI 點數」，英文為「AI Credits」。已知數值使用地區化整數格式且不附加虛構單位，例如繁中與英文皆可顯示 `1,000`。狀態文案涵蓋「目前方案不支援」、「目前 CLI 版本未提供 AI Credits 資訊」、「資訊未知」及「快取已過期」。最後更新時間沿用 `yyyy-MM-dd HH:mm:ss`。

## Risks / Trade-offs

- **[風險] 現行 CLI 尚未在非互動 JSON 公開 Credits 欄位** → 先提供穩定的 `cliFieldUnavailable` 狀態及解析擴充點，不用脆弱方法偽造功能。
- **[風險] 未來官方欄位名稱或型別變動** → 使用局部容錯 decoder 與版本化 fixture，格式錯誤只降級 Credits，不破壞 Gemini 額度。
- **[風險] Google One 與 Antigravity 可能共用 Credits，餘額在其他產品被消耗** → 將數值標示為觀測快照並顯示更新時間，不宣稱是 Antigravity 專屬配置。
- **[取捨] 永遠顯示尚不可取得的資訊會占用畫面空間** → 換取功能可發現性與清楚的版本相容狀態。
- **[取捨] 不採用 TUI 或私人 API 可能延後實際餘額支援** → 維持官方、唯讀、免憑證管理的產品邊界及長期穩定性。

## Migration Plan

1. 加入可選 AI Credits 摘要模型及向後相容的 Codable 預設行為。
2. 以實際官方非互動 JSON fixture 擴充 Antigravity parser；未提供欄位時先產生明確相容狀態。
3. 讓摘要隨既有 Antigravity 快照進入 Smart Cache，補齊失敗與過期狀態測試。
4. 新增本地化文案、地區化整數格式與 Desktop 獨立資訊卡。
5. 更新 Menu Bar 單一 Antigravity 外框，加入分隔線及緊湊點數摘要。
6. 執行 Provider、快取、ViewModel、完整 Swift 測試，以及 macOS 26 淺／深色與窄寬度檢查。

若需回退，可移除可選摘要欄位與兩個 UI 區段；既有 Gemini Models 解析、快取 TTL 與設定資料不需遷移。
