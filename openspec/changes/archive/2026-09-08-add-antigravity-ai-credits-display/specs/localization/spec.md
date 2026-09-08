## ADDED Requirements

### Requirement: Antigravity AI Credits 介面文案本地化

系統 SHALL 為 Desktop 與 Menu Bar 的 AI Credits 標題、資訊未知、CLI 未提供、方案不支援及快取已過期狀態提供繁體中文與英文文案；繁體中文標題 SHALL 為「AI 點數」，英文標題 SHALL 為「AI Credits」，並沿用現有即時語言切換行為。

#### Scenario: 切換 AI Credits 介面語言
- **WHEN** 使用者在繁體中文、英文或系統預設語言間切換
- **THEN** AI Credits 區段所有使用者可見文案立即切換至對應語言，最後更新時間維持 `yyyy-MM-dd HH:mm:ss` 格式

### Requirement: AI Credits 總數使用地區化整數格式

系統 SHALL 將已知 AI Credits 總數以目前語言環境的非負整數格式呈現，不附加未由官方定義的換算單位。

#### Scenario: 顯示四位數餘額
- **WHEN** 官方可用總數為 1000
- **THEN** 支援的繁體中文與英文介面依地區格式顯示 `1,000`

#### Scenario: 顯示零點餘額
- **WHEN** 官方可用總數為 0
- **THEN** 系統顯示 `0`，不以空字串或資訊未知取代
