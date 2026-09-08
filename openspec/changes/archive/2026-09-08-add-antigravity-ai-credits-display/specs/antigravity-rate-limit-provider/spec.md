## ADDED Requirements

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
