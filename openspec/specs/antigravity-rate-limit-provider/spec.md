# Capability: antigravity-rate-limit-provider

## Purpose

透過官方 Antigravity CLI 非互動 JSON 介面取得 Google 帳號的 Gemini Models 額度，並在不管理憑證的前提下正規化所有有效 bucket。

## Requirements

### Requirement: 使用官方 Antigravity CLI 查詢額度
系統 SHALL 使用 Antigravity CLI 1.1.11 以上版本，透過 `agy -p "/usage" --output-format json` 執行不啟動 Agent turn 的唯讀額度查詢。

#### Scenario: 成功執行非互動額度查詢
- **WHEN** 相容版本的 `agy` 已安裝且 Google 帳號已登入
- **THEN** 系統以一次性子行程取得結構化 `/usage` JSON，且不建立 Agent 對話或消耗模型額度

#### Scenario: CLI 版本不相容
- **WHEN** 偵測到的 `agy` 版本低於 1.1.11
- **THEN** 系統不解析互動式 TUI，並顯示目前版本、最低需求、升級指引與重新檢查控制項

#### Scenario: 查詢逾時
- **WHEN** `/usage` 查詢在 10 秒內未完成
- **THEN** 系統終止該次子行程並呈現可重試的逾時錯誤

### Requirement: 動態顯示所有有效 Gemini Models 額度
系統 SHALL 動態解析所有可判定屬於 Gemini Models 的有效額度 bucket，並排除非 Gemini、停用 bucket 與 AI Credits。

#### Scenario: 回傳多個 Gemini 額度 bucket
- **WHEN** CLI 回傳五小時、每週或其他新增的有效 Gemini Models bucket
- **THEN** 系統將每個 bucket 正規化並全部顯示，不硬編碼固定數量或名稱

#### Scenario: 回傳混合模型額度
- **WHEN** CLI 同時回傳 Gemini、Claude、GPT 或其他第三方模型 bucket
- **THEN** 系統只顯示 Gemini Models bucket，其他模型額度不出現在 Dashboard 或 Menu Bar

#### Scenario: 回傳停用或無法歸類的 bucket
- **WHEN** bucket 已停用或無法可靠判定屬於 Gemini Models
- **THEN** 系統忽略該 bucket，且不因未知欄位造成整次解析失敗

### Requirement: 正規化剩餘額度與重置時間
系統 SHALL 將官方剩餘比例轉換為共用額度模型的已用與剩餘百分比，並使用官方提供的重置時間。

#### Scenario: 解析剩餘比例
- **WHEN** bucket 提供 `remaining_fraction`
- **THEN** 系統保留原始精度並在 UI 以整數顯示已用與剩餘百分比

#### Scenario: 缺少重置時間
- **WHEN** 有效 Gemini bucket 未提供 `reset_time`
- **THEN** 系統顯示本地化的無法取得重置時間，不自行推算

### Requirement: 不管理 Google 憑證
系統 SHALL 僅使用 Antigravity CLI 既有的 Google 帳號登入工作階段，不讀取、保存或修改 OAuth Token、Keychain 或登入資料。

#### Scenario: 尚未登入 Google 帳號
- **WHEN** `agy` 已安裝但沒有有效登入工作階段
- **THEN** 系統顯示需要登入，指引使用者自行在 Terminal 執行 `agy`，且不自動開啟登入瀏覽器

#### Scenario: CLI 使用 Gemini API Key 模式
- **WHEN** 偵測到 `agy` 以 `GEMINI_API_KEY` Provider 模式執行
- **THEN** 系統顯示此登入模式不受支援，且不將 Gemini API 專案配額當成 Antigravity 額度

### Requirement: 從官方非互動輸出取得 AI Credits 總數

系統 SHALL 僅從 Antigravity 官方 CLI 非互動唯讀 JSON 輸出解析 AI Credits 可用總數，並將資料正規化為可區分已知餘額、方案不支援、CLI 未提供欄位及資訊未知的型別化摘要；系統 MUST NOT 為此解析互動式 `/credits` TUI、讀取 Google 憑證或呼叫未公開後端 API。

#### Scenario: 官方輸出提供正數餘額
- **WHEN** 官方非互動 JSON 提供可辨識的 AI Credits 可用總數且值大於 0
- **THEN** 系統保存該非負整數及同次觀測時間，並將狀態標記為已知餘額

#### Scenario: 官方輸出提供零點餘額
- **WHEN** 官方非互動 JSON 明確提供 AI Credits 可用總數為 0
- **THEN** 系統將狀態標記為已知零點，不將 0 解讀為缺少資料

#### Scenario: 方案明確不支援 AI Credits
- **WHEN** 官方非互動 JSON 明確表示目前方案不支援 AI Credits
- **THEN** 系統將狀態標記為方案不支援，且不自行建立零點餘額

#### Scenario: CLI 尚未提供 Credits 欄位
- **WHEN** 額度查詢成功但官方非互動 JSON 缺少可辨識的 AI Credits 欄位
- **THEN** 系統將狀態標記為 CLI 未提供欄位，並仍成功回傳既有 Gemini Models 額度

#### Scenario: Credits 欄位格式無法安全解析
- **WHEN** 官方輸出包含疑似 Credits 欄位但數值型別或結構無法安全辨識
- **THEN** 系統將 Credits 降級為資訊未知、保留有效 Gemini Models 額度，且不猜測或截取餘額

### Requirement: AI Credits 與 Antigravity 快照共用生命週期

系統 SHALL 將 AI Credits 摘要與同次 Antigravity 額度快照共同刷新及快取，並沿用既有 Provider TTL 與手動刷新行為；系統 SHALL NOT 建立 AI Credits 專屬 CLI 子行程、刷新按鈕或快取 TTL。

#### Scenario: 同次刷新取得額度與 Credits
- **WHEN** 系統執行 Antigravity 官方非互動額度查詢
- **THEN** Gemini Models 額度與 AI Credits 摘要來自同一次 CLI 觀測並寫入同一 Provider 快照

#### Scenario: 刷新失敗但有最後成功餘額
- **WHEN** 最新 Antigravity 刷新失敗且快取含有先前成功取得的 AI Credits 餘額
- **THEN** 系統保留最後成功餘額及其觀測時間，並將其標記為快取已過期，不冒充最新資料

#### Scenario: 從未成功取得餘額
- **WHEN** 刷新失敗且不存在曾成功取得的 AI Credits 餘額
- **THEN** 系統將 Credits 狀態呈現為資訊未知

### Requirement: AI Credits 功能保持唯讀

系統 MUST NOT 因顯示或刷新 AI Credits 而購買、加值、扣除或消耗點數，也 MUST NOT 修改 `useG1Credits`、AI Credit Overages 或其他帳號設定。

#### Scenario: 使用者查看或刷新 AI Credits
- **WHEN** 使用者開啟 Desktop、Menu Bar 或手動重新整理 Antigravity 資料
- **THEN** 系統只執行既有官方非互動唯讀查詢，不提供或觸發任何 Credits 管理操作
