## ADDED Requirements

### Requirement: Antigravity CLI 路徑設定
系統 SHALL 自動搜尋 Antigravity CLI，並允許使用者設定自訂 `agy` 執行檔路徑。

#### Scenario: 自動找到官方預設位置
- **WHEN** `agy` 安裝於官方預設的 `~/.local/bin/agy`
- **THEN** 系統將該路徑識別為可用的 Antigravity CLI

#### Scenario: 使用自訂 Antigravity CLI 路徑
- **WHEN** 使用者設定有效的自訂 `agy` 路徑
- **THEN** 系統優先使用自訂路徑，並重新檢查版本與環境狀態

### Requirement: Antigravity Menu Bar 自動預設
系統 SHALL 在首次成功取得 Antigravity 額度時將所有有效 Gemini bucket 預設釘選至 Menu Bar。

#### Scenario: 首次探索 Gemini bucket
- **WHEN** 使用者尚未自訂 Antigravity 選擇且首次取得有效額度
- **THEN** 所有有效 Gemini bucket 皆預設顯示於 Menu Bar

#### Scenario: 自訂後發現新 bucket
- **WHEN** 使用者已自訂 Antigravity 選擇且後續發現新 Gemini bucket
- **THEN** 系統不擅自變更既有選擇，除非使用者恢復自動預設
