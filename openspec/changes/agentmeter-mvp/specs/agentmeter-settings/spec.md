## Purpose

於本機管理使用者偏好設定，包含 Menu Bar 顯示額度選取、Smart Cache TTL、自訂執行檔路徑以及開機時自動啟動 (Launch at Login)。

## ADDED Requirements

### Requirement: 僅儲存於本機之偏好設定
系統 SHALL 將所有設定與快取資料儲存於本機空間（如 UserDefaults/AppStorage），不使用 CloudKit 或任何雲端同步。

#### Scenario: 本機儲存設定且無雲端同步
- **WHEN** 使用者修改任何設定項目
- **THEN** 設定會立即持久化儲存至本機，並套用至執行階段行為

### Requirement: Menu Bar 額度偏好與重置
設定畫面 SHALL 允許使用者勾選顯示/隱藏各項額度、自訂排列順序，並提供恢復預設功能。

#### Scenario: 重新排序與切換額度
- **WHEN** 使用者在 Settings 中啟用/停用或拖曳調整額度排序
- **THEN** 變更會立即儲存並反映於 Menu Bar Popover 中

#### Scenario: 恢復自動預設值
- **WHEN** 使用者點擊「恢復自動預設值 (Restore Automatic Defaults)」
- **THEN** 系統將額度顯示清單與排序重置為推薦的預設配置

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
