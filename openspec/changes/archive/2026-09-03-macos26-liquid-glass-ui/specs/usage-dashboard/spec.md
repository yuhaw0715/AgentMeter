## MODIFIED Requirements

### Requirement: 於 Desktop 主視窗顯示所有已偵測額度

桌面應用程式 SHALL 為 ChatGPT Codex 與 Google Antigravity 提供獨立 Dashboard；Dashboard SHALL 採用 macOS 26 風格的側欄、工具列、Provider 標頭與額度卡片，並完整顯示名稱、已用／剩餘百分比、進度、重置時間與 Menu Bar 釘選控制項。Liquid Glass 材質 SHALL 限於側欄、工具列與主要控制表面；額度資訊 SHALL 保持足夠不透明與高對比。

#### Scenario: 使用選項 1 側欄開啟 Provider Dashboard

- **WHEN** 使用者在 macOS 26 風格側邊欄選擇 ChatGPT Codex 或 Google Antigravity
- **THEN** 系統顯示帶有 AgentMeter 品牌區、Provider 導覽狀態、額度卡片與左側 Menu Bar 顯示勾選開關的 Dashboard

#### Scenario: 顯示可讀的額度卡片

- **WHEN** Provider 有有效額度資料
- **THEN** 每張額度卡片以一致的圓角、間距與進度條顯示名稱、已用百分比、剩餘量與 `yyyy-MM-dd HH:mm:ss` 重置時間，且文字在淺色、深色與系統外觀下維持清晰對比

#### Scenario: 顯示載入中或錯誤狀態

- **WHEN** Provider 正在重新整理或重新整理失敗
- **THEN** Dashboard 以一致的狀態標籤與錯誤表面呈現進度／錯誤描述，並保留可操作的重試控制，不以材質效果遮蔽額度內容

#### Scenario: 開啟 Antigravity Dashboard

- **WHEN** 使用者在側邊欄選擇 Google Antigravity
- **THEN** 系統顯示所有有效 Gemini bucket 的名稱、已用／剩餘百分比、進度、重置時間與 Menu Bar 釘選控制項

#### Scenario: Antigravity 環境尚未就緒

- **WHEN** `agy` 缺少、版本不相容、未登入或使用不支援的 API Key 模式
- **THEN** 側邊欄仍顯示 Google Antigravity，Dashboard 呈現對應的設定指引與重新檢查控制項

#### Scenario: 顯示可用額度清單與左側核取方塊

- **WHEN** 使用者開啟具有有效使用額度資料的 Provider Dashboard
- **THEN** 系統完整呈現該 Provider 所有可用 limits 的詳細資訊、進度條、重置時間，並在每張卡片左側提供 Menu Bar 顯示勾選開關

#### Scenario: 雙列標頭佈局與標準時間格式

- **WHEN** 顯示 Provider Dashboard 頂部資訊列
- **THEN** 第一列左側呈現 Provider 名稱、右側齊平呈現重新整理按鈕；第二列不要求 Antigravity 顯示 Email 或方案，右側呈現 `yyyy-MM-dd HH:mm:ss` 格式的最後更新時間

### Requirement: 前景視窗主動重新整理

切換至任一 Provider Dashboard 或將其叫到前景時，系統 SHALL 維持既有不受 TTL 限制的重新整理行為；重新整理控制項 SHALL 使用與側欄及額度卡片一致的 macOS 26 視覺語言。

#### Scenario: 切換 Provider 後重新整理

- **WHEN** 使用者在側欄切換至另一個 Provider
- **THEN** 系統立即只對該 Provider 發起查詢，並在主視窗顯示更新中狀態

#### Scenario: 切換至 Antigravity Dashboard

- **WHEN** 使用者選擇或重新叫出 Google Antigravity Dashboard
- **THEN** 系統立即查詢最新 Gemini 額度並顯示更新中狀態，不連帶強制更新 Codex

#### Scenario: 叫到前景觸發重新整理

- **WHEN** 使用者將焦點切換至目前 Provider Dashboard 或重新開啟視窗
- **THEN** AgentMeter 立即對該 Provider 發起重新整理並顯示「Refreshing…」指示器
