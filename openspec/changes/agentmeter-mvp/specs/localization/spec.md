## Purpose

依據 macOS 系統語系偏好提供繁體中文與英文的完整在地化介面支援，並支援符合使用者語系與時區之日期時間格式化。

## ADDED Requirements

### Requirement: 多國語言 UI 支援
Desktop App、Menu Bar、Settings 與 Diagnostics 的所有 UI 字串 SHALL 提供繁體中文與英文。

#### Scenario: 以繁體中文渲染介面
- **WHEN** macOS 系統偏好語言設為繁體中文（`zh-Hant` / `zh-TW` / `zh-HK`）
- **THEN** 所有 UI 標籤、提示、錯誤訊息與說明文字均以繁體中文顯示

#### Scenario: 以英文渲染介面
- **WHEN** macOS 系統偏好語言設為英文或其他未支援之語言
- **THEN** 所有 UI 字串預設以英文顯示

### Requirement: 語系感知之日期時間格式化
系統 SHALL 依照使用者的系統語系、時區與 12/24 小時制偏好來格式化重置時間戳記。

#### Scenario: 依使用者時區與 12/24 制格式化重置時間
- **WHEN** 顯示額度重置日期與時間
- **THEN** 格式化後之字串完全遵循使用者目前之系統語系、時區與時鐘格式設定
