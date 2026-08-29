## MODIFIED Requirements

### Requirement: 於 Desktop 主視窗顯示所有已偵測額度
桌面應用程式 SHALL 為 ChatGPT Codex 與 Google Antigravity 提供獨立 Dashboard；Antigravity Dashboard SHALL 顯示所有有效 Gemini Models 額度與 Menu Bar 釘選控制項。

#### Scenario: 開啟 Antigravity Dashboard
- **WHEN** 使用者在側邊欄選擇 Google Antigravity
- **THEN** 系統顯示所有有效 Gemini bucket 的名稱、已用／剩餘百分比、進度、重置時間與釘選控制項

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
切換至任一 Provider Dashboard 或將其叫到前景時，系統 SHALL 對該 Provider 發起不受 TTL 限制的重新整理。

#### Scenario: 切換至 Antigravity Dashboard
- **WHEN** 使用者選擇或重新叫出 Google Antigravity Dashboard
- **THEN** 系統立即查詢最新 Gemini 額度並顯示更新中狀態，不連帶強制更新 Codex

#### Scenario: 叫到前景觸發重新整理
- **WHEN** 使用者將焦點切換至目前 Provider Dashboard 或重新開啟視窗
- **THEN** AgentMeter 立即對該 Provider 發起重新整理並顯示「Refreshing…」指示器
