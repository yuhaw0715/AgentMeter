# AgentMeter Diagnostics Specification

## Purpose

評估系統健康狀態、Codex CLI 可用性、登入驗證狀態，並產生遮蔽敏感資訊的診斷報告以供問題排查。

## Requirements

### Requirement: 診斷狀態收集
系統 SHALL 收集包含 CLI 路徑、app-server 響應狀況、登入驗證狀態、最後一次 rate-limit 查詢結果、最後更新時間戳記與 OS/App 版本等診斷屬性。

#### Scenario: 呈現目前環境診斷資訊表
- **WHEN** 使用者在桌面應用程式中切換至 Diagnostics 頁面
- **THEN** 系統清楚呈現所有收集到的診斷屬性與狀態

### Requirement: 敏感資訊遮蔽之診斷匯出
系統 SHALL 產生 Markdown 格式的診斷報告，將潛在授權 Token、電子郵件及敏感資訊自動遮蔽，適合直接貼至公開 Issue 討論區。

#### Scenario: 複製已遮蔽報告至剪貼簿
- **WHEN** 使用者點擊「複製診斷報告 (Copy Diagnostic Report)」
- **THEN** 一份包含環境中繼資料且去除敏感憑證的遮蔽報告被複製至系統剪貼簿
