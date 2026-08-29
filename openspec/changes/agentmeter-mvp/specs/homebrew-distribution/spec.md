## Purpose

定義透過 GitHub Releases 與既有自訂 Homebrew tap 的發布套件與 Cask Formula，支援安裝、解除安裝與範圍受限的隔離屬性 (quarantine) 處理。

## ADDED Requirements

### Requirement: Homebrew Cask 安裝
系統 SHALL 可透過 Homebrew Cask Formula 直接下載並安裝來自 GitHub Releases 的發布產物。

#### Scenario: 透過自訂 Tap 進行單行指令安裝
- **WHEN** 使用者執行 `brew install --cask <tap>/agentmeter`
- **THEN** Homebrew 下載應用程式壓縮檔並將 `AgentMeter.app` 安裝至 `/Applications`

### Requirement: 範圍受限之隔離屬性處理
安裝 Formula 或 post-install 腳本 SHALL 僅針對特定的 `AgentMeter.app` 套件清除隔離屬性 (`xattr -d com.apple.quarantine`)，嚴格禁止變更其他應用程式或全域目錄。

#### Scenario: 僅針對 AgentMeter.app 清除隔離屬性
- **WHEN** 透過 Homebrew 安裝未簽名的 MVP 發布產物
- **THEN** 隔離屬性僅專屬針對 `AgentMeter.app` 進行移除，不對系統造成廣泛修改

### Requirement: 乾淨解除安裝與 Zap
Formula SHALL 支援標準解除安裝以及 `--zap` 操作，可在不更動 Codex CLI 憑證或設定的前提下完整移除應用程式快取、記錄檔與設定。

#### Scenario: 標準解除安裝保留 CLI 資料
- **WHEN** 使用者執行 `brew uninstall --cask agentmeter`
- **THEN** 應用程式 Bundle 被移除，而使用者設定與 Codex CLI 狀態均保持完整

#### Scenario: Zap 解除安裝完整清除 App 狀態且不修改 Codex 憑證
- **WHEN** 使用者執行 `brew uninstall --zap --cask agentmeter`
- **THEN** AgentMeter 的偏好設定、快取與 Application Support 目錄被完整清除，而 Codex CLI 設定與憑證完全不受影響
