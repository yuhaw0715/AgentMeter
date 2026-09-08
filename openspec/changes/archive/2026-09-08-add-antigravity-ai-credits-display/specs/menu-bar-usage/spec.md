## ADDED Requirements

### Requirement: Menu Bar 在單一 Antigravity 卡片內顯示 AI 點數

Menu Bar Popover SHALL 在單一 Google Antigravity Provider 外框內，於既有 Gemini Models 額度列之後以水平分隔線加入永遠可見的 AI 點數子區段；系統 MUST NOT 為 AI 點數建立第二個外框，也 MUST NOT 提供購買、啟用、消耗或設定控制項。

#### Scenario: 顯示合併式 Antigravity 資訊
- **WHEN** 使用者開啟 Menu Bar Popover 且 Antigravity 快照可用
- **THEN** 同一個 Antigravity 外框依序包含 Provider 標頭、Gemini Models 額度列、水平分隔線、AI 點數總數與更新時間，並在其後才呈現下一個 Provider

#### Scenario: 顯示已知餘額或零點
- **WHEN** AI Credits 可用總數為任一已知非負整數
- **THEN** Menu Bar 點數列左側顯示「AI 點數」、右側顯示地區化整數，包含 0 時也不得隱藏該區段

#### Scenario: 顯示不支援或未知狀態
- **WHEN** AI Credits 狀態為方案不支援、CLI 未提供欄位或資訊未知
- **THEN** Menu Bar 在同一 Antigravity 外框內以緊湊中性文案呈現對應狀態，且既有 Gemini Models 額度維持可用

#### Scenario: 顯示過期快取
- **WHEN** Popover 顯示最後成功的 AI Credits 餘額且 Antigravity 快取已過期
- **THEN** Menu Bar 保留總數與原觀測時間並標示「快取已過期」，不將過期值冒充為最新資料

#### Scenario: AI 點數增加 Popover 高度
- **WHEN** 雙 Provider 與 AI 點數內容超出 Popover 可用高度
- **THEN** Popover 沿用既有垂直捲動能力，且 AI 點數總數及狀態仍可讀
