## Purpose

自動偵測 Codex CLI 執行檔、支援自訂路徑，並引導使用者完成必要的 CLI 登入，而不由 AgentMeter 直接接管憑證管理。

## ADDED Requirements

### Requirement: 偵測 Codex CLI 執行檔
系統 SHALL 在使用者環境的 PATH 中尋找 `codex` 執行檔，或使用使用者自訂指定的路徑。

#### Scenario: 於標準 PATH 中自動找到
- **WHEN** `codex` CLI 已安裝並可於 PATH 中解析
- **THEN** AgentMeter 標記 CLI 執行檔可用並採用該偵測到的路徑

#### Scenario: 設定自訂執行檔路徑
- **WHEN** 使用者在 Settings 中指定了自訂的 `codex` 執行檔路徑
- **THEN** AgentMeter 優先使用該自訂路徑而非自動偵測

### Requirement: 環境狀態偵測與引導
系統 SHALL 識別未安裝或未登入狀態，並提供可操作的引導，且在環境正常時不以引導精靈阻礙操作。

#### Scenario: 缺少 Codex CLI 執行檔
- **WHEN** 無法在 PATH 或自訂路徑中找到 `codex` 執行檔
- **THEN** AgentMeter 顯示「需要設定 (Setup Required)」畫面，包含安裝提示與「重新檢查 (Check Again)」按鈕

#### Scenario: 已安裝 Codex CLI 但尚未登入
- **WHEN** 已存在 `codex` CLI 但尚未登入驗證
- **THEN** AgentMeter 顯示「需要登入 (Sign-in Required)」畫面，提示使用者透過 `codex login` 完成登入

#### Scenario: 環境正常時略過引導精靈
- **WHEN** Codex CLI 存在且已完成登入驗證
- **THEN** AgentMeter 直接進入標準 Dashboard 畫面，不出現額外中介的初次引導精靈
