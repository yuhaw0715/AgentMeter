## ADDED Requirements

### Requirement: 取得並正規化 Codex 重置券

系統 SHALL 從 `account/rateLimits/read` 的 `rateLimitResetCredits` 解析可用重置券總數與可選明細，並以 `availableCount` 作為可用總數的權威來源；每筆明細 SHALL 保留 opaque ID、reset type、狀態、取得時間、可空的到期時間、可空的標題與可空的描述。

#### Scenario: 回傳完整重置券資料
- **WHEN** Codex app-server 回傳 `availableCount` 與完整 `credits` 明細
- **THEN** 系統正規化總數與每筆明細，並依具有到期時間者最早到期優先、缺少到期時間者置後的順序輸出

#### Scenario: 明細少於權威總數
- **WHEN** `availableCount` 大於 `credits` 明細筆數
- **THEN** 系統保留權威總數、已取得明細及兩者差額，不自行建立不存在的券資料

#### Scenario: 服務只回傳總數
- **WHEN** `rateLimitResetCredits.credits` 為 `null`
- **THEN** 系統保留 `availableCount` 並將明細標記為未提供，不將其解讀為空陣列

#### Scenario: 沒有可用重置券
- **WHEN** `availableCount` 為 0 且 `credits` 為空陣列
- **THEN** 系統正規化為已知的零張狀態，而非資料未知狀態

#### Scenario: 服務未提供重置券欄位
- **WHEN** `account/rateLimits/read` 回應缺少 `rateLimitResetCredits` 或其值為 `null`
- **THEN** 系統將重置券狀態標記為資訊未提供，且仍成功回傳既有 Codex 額度資料

### Requirement: 重置券快照維持服務端權威狀態

系統 SHALL 將重置券資料與同次 Codex rate-limit 快照共同快取；本機時間超過券的 `expiresAt` 時 SHALL 提供過期呈現狀態，但 MUST NOT 自行減少服務端最後回傳的 `availableCount`。

#### Scenario: 快取券在下次刷新前到期
- **WHEN** 快取明細的 `expiresAt` 已早於目前時間且尚未取得新版快照
- **THEN** 系統將該明細標記為已到期等待刷新，保留該列與服務端最後回傳的總數

### Requirement: 重置券功能保持唯讀

系統 MUST NOT 因顯示重置券而呼叫 `account/rateLimitResetCredit/consume`，也 MUST NOT 對重置券執行使用、兌換或消耗操作。

#### Scenario: 使用者查看或刷新重置券
- **WHEN** 使用者開啟 Desktop、Menu Bar 或手動重新整理 Codex 資料
- **THEN** 系統僅透過 `account/rateLimits/read` 取得資料，不送出重置券消耗請求
