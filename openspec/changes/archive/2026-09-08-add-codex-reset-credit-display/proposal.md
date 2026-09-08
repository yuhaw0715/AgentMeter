## Why

Codex app-server 的 `account/rateLimits/read` 已能回傳 earned rate-limit reset credits，但 AgentMeter 目前只解析 `rateLimits`，使用者無法在既有 Desktop 與 Menu Bar 額度監控流程中查看可用重置券及其到期時間。現在補上唯讀顯示，可沿用官方資料來源與 Smart Cache，在不增加兌換風險的前提下提供完整的 Codex 額度狀態。

## What Changes

- 擴充 Codex rate-limit 快照，解析 `rateLimitResetCredits.availableCount` 與可選的 `credits` 明細；可用總數以 `availableCount` 為權威來源。
- 逐張保留 opaque ID、reset type、狀態、取得時間、可空的到期時間、標題與描述，並依最早到期優先排序；官方標題與描述本次僅保留於資料模型，不直接呈現。
- Desktop Codex Dashboard 在額度卡片下方新增獨立的 Liquid Glass 重置券資訊卡；採用已確認的 A 堆疊式排版，標頭同一行左側顯示「重置券」、右側顯示可用總數，下方逐張顯示券編號及 `yyyy-MM-dd HH:mm:ss` 到期時間。
- Menu Bar 將重置券合併於單一 ChatGPT Codex Provider 外框內，置於額度列之後並以水平分隔線區隔，不建立第二張重置券卡片。
- 當明細少於總數時顯示「其餘 N 張未提供明細」；`expiresAt` 缺失時顯示「無到期資訊」。
- 明確區分零張與服務未提供資料；重置券欄位缺失不得使既有 Codex 額度刷新失敗。
- 快取中的券超過到期時間時保留該列並標示「已到期，等待刷新」，且不在本機改寫服務端最後回傳的權威總數。
- Desktop 與 Menu Bar 永遠顯示重置券區塊，不新增顯示開關。
- 本次維持唯讀：不呼叫 `account/rateLimitResetCredit/consume`，不提供使用、兌換或消耗重置券的操作。

## Capabilities

### New Capabilities

無。

### Modified Capabilities

- `codex-rate-limit-provider`：新增官方 `rateLimitResetCredits` 的容錯解析、正規化、排序與快取語意。
- `usage-dashboard`：新增 Desktop Codex 重置券獨立資訊卡及完整狀態呈現。
- `menu-bar-usage`：新增合併於單一 Codex Provider 卡片內的重置券總數與逐張到期時間。
- `localization`：新增重置券、資料未提供、明細不足、無到期資訊及已到期等待刷新等繁中／英文文案。

## Impact

- API：沿用既有官方 Codex app-server JSON-RPC `account/rateLimits/read`；不新增網路服務、不直接呼叫私人 REST endpoint，也不使用 `account/rateLimitResetCredit/consume`。
- Domain／Provider：影響 `RateLimitSnapshot`、Codex Provider 解析器及必要的新重置券模型；Smart Cache 仍以 Provider 快照為單位。
- UI：影響 Desktop `UsageDashboardView`、Menu Bar `MenuBarPopoverView`、共用視覺元件與本地化字串。
- 相容性：舊版 CLI 或服務未回傳 `rateLimitResetCredits` 時，既有額度仍正常顯示，重置券區塊呈現「資訊未提供」。
- 測試：新增 Provider payload、明細截斷、零張／null、排序、過期快取、Desktop 與 Menu Bar 呈現語意測試，並執行完整 Swift 測試。
- 相依性：不新增第三方套件；示意圖僅作設計參考，不作為執行期資產。
