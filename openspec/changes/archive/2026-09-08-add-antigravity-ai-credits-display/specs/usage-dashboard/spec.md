## ADDED Requirements

### Requirement: Desktop 顯示 Antigravity AI 點數資訊卡

Google Antigravity Dashboard SHALL 在既有 Gemini Models 額度卡片下方永遠顯示獨立的 AI 點數資訊卡，並沿用 macOS 26 Liquid Glass 視覺語言；資訊卡 SHALL 在同一標頭列左側顯示圖示與標題、右側顯示可用總數，下方顯示最後更新時間，且 SHALL NOT 提供購買、啟用、消耗或設定控制項。

#### Scenario: 顯示可用 AI 點數
- **WHEN** Antigravity 快照包含已知的 AI Credits 餘額
- **THEN** Desktop 在標頭左側顯示「AI 點數」、右側以地區化整數顯示總數，並在下方顯示 `yyyy-MM-dd HH:mm:ss` 更新時間

#### Scenario: 顯示已知零點
- **WHEN** AI Credits 可用總數明確為 0
- **THEN** Desktop 資訊卡顯示 `0`，不隱藏資訊卡或顯示資訊未知

#### Scenario: 顯示方案不支援
- **WHEN** AI Credits 狀態為方案不支援
- **THEN** Desktop 以中性色顯示本地化的「目前方案不支援」，且既有 Gemini Models 額度維持可用

#### Scenario: 顯示 CLI 尚未提供資訊
- **WHEN** AI Credits 狀態為 CLI 未提供欄位
- **THEN** Desktop 以中性色顯示「資訊未知」及本地化的「目前 CLI 版本未提供 AI Credits 資訊」，不要求升級 CLI

#### Scenario: 顯示過期快取
- **WHEN** Desktop 正在顯示最後成功的 AI Credits 餘額且該 Provider 快取已過期
- **THEN** 資訊卡保留該總數與原觀測時間並標示「快取已過期」，不得將其呈現為最新值
