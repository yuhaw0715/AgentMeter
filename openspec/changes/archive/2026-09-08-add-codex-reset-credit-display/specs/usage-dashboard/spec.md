## ADDED Requirements

### Requirement: Desktop 顯示 Codex 重置券資訊卡

ChatGPT Codex Dashboard SHALL 在既有額度卡片下方永遠顯示獨立的重置券資訊卡，並沿用 macOS 26 Liquid Glass 視覺語言；資訊卡 SHALL 採堆疊式券列，標頭同一行左側顯示重置券標題、右側顯示權威可用總數，下方顯示服務端已提供的逐張明細，且 SHALL NOT 提供使用或兌換控制項。

#### Scenario: 同一行顯示標題與可用總數
- **WHEN** Desktop 顯示 Codex 重置券資訊卡
- **THEN** 資訊卡標頭在同一水平列左側顯示「重置券」、右側顯示「N 張可用」，不得將可用總數另置於標題下方

#### Scenario: 顯示多張具有到期時間的券
- **WHEN** Codex 快照包含多筆可用重置券明細
- **THEN** Desktop 依最早到期優先顯示「重置券 N」及每張券的 `yyyy-MM-dd HH:mm:ss` 到期時間

#### Scenario: 券沒有到期時間
- **WHEN** 某筆重置券的 `expiresAt` 為 `null`
- **THEN** Desktop 在該券列顯示本地化的「無到期資訊」

#### Scenario: 明細遭截斷或未完整提供
- **WHEN** 權威可用總數大於已取得的明細數
- **THEN** Desktop 顯示已取得的每筆明細，並顯示本地化的「其餘 N 張未提供明細」

#### Scenario: 已知沒有可用券
- **WHEN** 重置券資料明確回傳可用總數為 0
- **THEN** Desktop 資訊卡顯示本地化的「可用重置券 0 張」

#### Scenario: 重置券資訊未提供
- **WHEN** Codex 快照將重置券狀態標記為未提供
- **THEN** Desktop 資訊卡顯示本地化的「重置券資訊未提供」，且既有額度卡片維持可用

#### Scenario: 快取券已超過到期時間
- **WHEN** 顯示中的快取券已超過 `expiresAt`
- **THEN** Desktop 保留該券列並顯示本地化的「已到期，等待刷新」，不在本機調整權威總數
