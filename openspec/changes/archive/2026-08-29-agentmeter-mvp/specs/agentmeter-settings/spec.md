## Purpose

於本機管理使用者偏好設定，包含開機時自動啟動 (Launch at Login)、Smart Cache TTL、介面語言切換以及自訂執行檔路徑。

## ADDED Requirements

### Requirement: 僅儲存於本機之偏好設定
系統 SHALL 將所有設定與快取資料儲存於本機空間（如 UserDefaults/AppStorage），不使用 CloudKit 或任何雲端同步。

#### Scenario: 本機儲存設定且無雲端同步
- **WHEN** 使用者修改任何設定項目
- **THEN** 設定會立即持久化儲存至本機，並套用至執行階段行為

### Requirement: 一般設定區塊佈局與右對齊
一般設定區塊 SHALL 依序提供開機啟動、快取時間與介面語言選單，下拉選單皆對齊至右側邊緣。

#### Scenario: 選單順序與右對齊
- **WHEN** 使用者開啟 Settings 頁面
- **THEN** 一般設定區塊依序呈現「開機時自動啟動」、「Menu Bar 快取時間 (TTL)」與「介面語言」，兩組下拉選單寬度一致並右對齊

### Requirement: 快取 TTL 設定
系統 SHALL 允許使用者自訂 Smart Cache 的過期時間門檻。

#### Scenario: 調整 Smart Cache TTL
- **WHEN** 使用者在 Settings 中選擇新的快取 TTL 時間
- **THEN** 後續開啟 Menu Bar 時將依據新的 TTL 門檻判斷快取新鮮度

### Requirement: 開機時啟動 (Launch at Login) 設定
系統 SHALL 提供選項將 AgentMeter 註冊至或自 macOS 登入項目中移除。

#### Scenario: 啟用與停用開機啟動
- **WHEN** 使用者切換「開機時自動啟動」開關
- **THEN** 應用程式透過 SMAppService 相應地註冊或取消註冊
