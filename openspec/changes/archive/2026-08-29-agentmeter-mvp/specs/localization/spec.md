## Purpose

提供繁體中文、英文與依系統語言（.system、.zhHant、.en）之多國語言切換，並支援 `yyyy-MM-dd HH:mm:ss` 標準時間格式化。

## ADDED Requirements

### Requirement: 多國語言 UI 支援與即時切換
Desktop App、Menu Bar、Settings 與 Diagnostics 的所有 UI 字串 SHALL 提供繁體中文與英文，並支援使用者在設定中即時手動切換或依系統預設。

#### Scenario: 手動切換至繁體中文
- **WHEN** 使用者在 Settings 中選取「繁體中文 (Traditional Chinese)」
- **THEN** 所有 UI 標籤、提示、錯誤訊息與額度名稱立即以繁體中文顯示

#### Scenario: 手動切換至英文
- **WHEN** 使用者在 Settings 中選取「English」
- **THEN** 所有 UI 字串立即以英文顯示

#### Scenario: 依系統語言設定
- **WHEN** 使用者選取「依系統語言 (System Default)」
- **THEN** 系統依 macOS 偏好語系（`zh-Hant` / `en`）自動呈現對應文字

### Requirement: 標準日期時間格式化
系統 SHALL 提供 `yyyy-MM-dd HH:mm:ss` 格式之最後更新時間呈現，並依使用者語系呈現重置時間。

#### Scenario: 格式化最後更新時間
- **WHEN** 顯示最後更新時間
- **THEN** 輸出格式固定為 `yyyy-MM-dd HH:mm:ss`（例如：`2026-08-29 13:47:48`）
