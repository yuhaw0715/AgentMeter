## ADDED Requirements

### Requirement: Menu Bar 在單一 Codex 卡片內顯示重置券

Menu Bar Popover SHALL 在單一 ChatGPT Codex Provider 外框內，於既有額度列之後以水平分隔線加入永遠可見的重置券子區段；系統 MUST NOT 為重置券建立第二個獨立外框或提供使用控制項。

#### Scenario: 顯示合併式 Codex 資訊
- **WHEN** 使用者開啟 Menu Bar Popover 且 Codex 快照可用
- **THEN** 同一個 Codex 外框依序包含 Provider 標頭、額度列、水平分隔線、重置券總數與逐張到期資訊，並在其後才呈現下一個 Provider

#### Scenario: 顯示每張券的完整有效期限
- **WHEN** 重置券明細包含一筆或多筆 `expiresAt`
- **THEN** Menu Bar 依最早到期優先顯示「券 N」與 `yyyy-MM-dd HH:mm:ss` 完整時間

#### Scenario: 明細缺少到期時間或筆數不足
- **WHEN** 某筆 `expiresAt` 為 `null`，或權威總數大於已取得明細數
- **THEN** Menu Bar 分別顯示「無到期資訊」與「其餘 N 張未提供明細」，不虛構券列

#### Scenario: 零張與資訊未提供
- **WHEN** 重置券狀態為已知零張或服務未提供
- **THEN** Menu Bar 在 Codex 外框內分別顯示「可用重置券 0 張」或「重置券資訊未提供」

#### Scenario: 快取券已過期
- **WHEN** Popover 顯示的快取券已超過 `expiresAt`
- **THEN** Menu Bar 保留該列並顯示「已到期，等待刷新」，不在本機變更權威總數

#### Scenario: 重置券內容增加 Popover 高度
- **WHEN** Codex 重置券明細使跨 Provider 內容超出 Popover 可用高度
- **THEN** Popover 沿用垂直捲動能力，且每筆券的完整到期時間仍可讀
