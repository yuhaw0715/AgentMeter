## Why

Antigravity 在基礎模型額度耗盡後可使用 AI Credits 延續服務，官方 CLI 也提供 `/credits` 介面查看餘額；AgentMeter 目前刻意從 Gemini Models 額度中排除 AI Credits，使用者因此無法在既有 Desktop 與 Menu Bar 監控流程中查看可用點數。新增唯讀顯示能補足 Antigravity 的兩層額度資訊，同時維持 AgentMeter 不購買、不啟用、不消耗 Credits 的安全邊界。

## What Changes

- 擴充 Antigravity 快照，僅從官方 CLI 已提供的非互動唯讀 JSON 輸出解析 AI Credits 可用總數；不解析互動式 `/credits` TUI、不讀取憑證，也不呼叫未公開後端 API。
- 將已知餘額（含 0）、方案明確不支援、CLI 尚未提供欄位與一般資訊未知分別建模，Credits 欄位缺失不得使既有 Gemini Models 額度刷新失敗。
- Desktop Antigravity Dashboard 在模型額度卡片下方新增獨立 Liquid Glass「AI 點數」資訊卡；同一標頭列左側顯示圖示與標題、右側顯示可用總數，下方顯示更新時間。
- Menu Bar 在單一 Google Antigravity Provider 外框內，於模型額度列後以水平分隔線加入「AI 點數」子區段，不建立第二個外框。
- AI Credits 與 Antigravity 模型額度共用同一次刷新、手動刷新入口、Provider 快照與 Smart Cache TTL。
- 取得失敗時保留最後一次成功餘額並標示「快取已過期」；從未成功取得時顯示「資訊未知」。官方 CLI 尚未提供欄位時顯示「目前 CLI 版本未提供 AI Credits 資訊」，不要求升級、不隱藏功能。
- 繁體中文使用「AI 點數」，英文使用「AI Credits」；總數以整數及地區化千分位顯示，例如 `1,000`。
- 本次只顯示總數與更新時間，不顯示近期紀錄、逐筆到期資訊、購買連結或任何管理控制項。

## Capabilities

### New Capabilities

無。

### Modified Capabilities

- `antigravity-rate-limit-provider`：新增官方非互動 JSON 中 AI Credits 總數的容錯解析、狀態正規化、唯讀限制與快取語意。
- `usage-dashboard`：新增 Desktop Antigravity AI 點數獨立資訊卡及正常、零點、方案不支援、CLI 未提供、資訊未知與快取過期狀態。
- `menu-bar-usage`：在單一 Antigravity Provider 外框內加入以水平線分隔的 AI 點數摘要。
- `localization`：新增 AI 點數及各種可用性／快取狀態的繁中與英文文案，以及地區化整數格式。

## Impact

- API／CLI：沿用既有 `agy -p "/usage" --output-format json` 官方唯讀流程，或同一官方非互動輸出未來新增的 Credits 欄位；不得啟動 Agent turn、解析 TUI、讀取 OAuth／Keychain 或直接呼叫私人 endpoint。
- Domain／Provider：影響 `RateLimitSnapshot` 或等價的 Provider 快照、Antigravity parser 與 AI Credits 型別化摘要；既有 Gemini bucket 過濾規則維持不變。
- Cache：AI Credits 與 Antigravity 快照共同保存及失效，不新增第二套 TTL 或刷新流程。
- UI：影響 Desktop `UsageDashboardView`、Menu Bar `MenuBarPopoverView`、共用視覺元件與本地化字串。
- 相容性：CLI 未提供 Credits 欄位時，既有額度繼續正常顯示，AI 點數區塊呈現明確的相容狀態。
- 測試：新增已知正數、零點、方案不支援、缺少欄位、格式錯誤、快取過期及兩種介面呈現測試，並執行完整 Swift 測試。
- 相依性：不新增第三方套件；確認後的示意圖只作設計參考，不作為執行期資產。
