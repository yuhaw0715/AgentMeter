# Localization Specification

## Purpose

提供繁體中文、英文與依系統語言（.system、.zhHant、.en）之多國語言切換，並支援 `yyyy-MM-dd HH:mm:ss` 標準時間格式化。

## Requirements

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

### Requirement: 重置券介面文案本地化

系統 SHALL 為 Desktop 與 Menu Bar 的重置券標題、可用張數、券編號、明細不足、無到期資訊、資訊未提供及已到期等待刷新狀態提供繁體中文與英文文案，並沿用現有即時語言切換行為。

#### Scenario: 切換重置券介面語言
- **WHEN** 使用者在繁體中文、英文或系統預設語言間切換
- **THEN** 重置券區段所有使用者可見文案立即切換至對應語言，券到期時間維持 `yyyy-MM-dd HH:mm:ss` 格式

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
