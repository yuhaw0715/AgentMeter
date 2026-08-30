## MODIFIED Requirements

### Requirement: 診斷狀態收集
系統 SHALL 收集 Codex 與 Antigravity 各自的 CLI 路徑、版本／相容性、登入狀態、最近額度查詢結果與最後更新時間，以及 AgentMeter 與 macOS 版本。

#### Scenario: 呈現 Antigravity 環境診斷
- **WHEN** 使用者開啟 Diagnostics 頁面
- **THEN** 系統顯示 `agy` 路徑、CLI 版本、最低版本相容性、Google 帳號登入狀態、最近 `/usage` 查詢結果與更新時間

#### Scenario: 呈現目前環境診斷資訊表
- **WHEN** 使用者在桌面應用程式中切換至 Diagnostics 頁面
- **THEN** 系統清楚呈現 Codex 與 Antigravity 所有已收集的診斷屬性與狀態

### Requirement: 敏感資訊遮蔽之診斷匯出
系統 SHALL 在診斷報告中遮蔽 Codex 與 Antigravity 相關的 Email、Token、憑證、使用者私密路徑與其他敏感資訊。

#### Scenario: 匯出 Antigravity 錯誤摘要
- **WHEN** 診斷報告包含 Antigravity CLI 輸出或錯誤摘要
- **THEN** 潛在帳號與憑證資訊會先被遮蔽，再複製至剪貼簿

#### Scenario: 複製已遮蔽報告至剪貼簿
- **WHEN** 使用者點擊「複製診斷報告 (Copy Diagnostic Report)」
- **THEN** 一份包含多 Provider 環境中繼資料且去除敏感憑證的遮蔽報告被複製至系統剪貼簿
