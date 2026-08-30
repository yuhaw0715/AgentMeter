# Homebrew Distribution Specification

## Purpose

定義透過 GitHub Releases 與既有自訂 Homebrew tap 的發布套件與 Cask Formula，支援安裝、解除安裝與範圍受限的隔離屬性 (quarantine) 處理。

## Requirements

### Requirement: Homebrew Cask 安裝
系統 SHALL 提供可重現的本機發布建置流程，將 SwiftPM Release 產物組裝為標準 `AgentMeter.app`，並產生可上傳 GitHub Releases、由 Homebrew Cask 下載安裝且檔名帶有版本號的 ZIP。

#### Scenario: 建立 GitHub Release ZIP
- **WHEN** 發布者在相容的 macOS 與 Swift toolchain 執行發布建置腳本
- **THEN** 系統執行 Release build，建立包含 executable、有效 `Info.plist`、App icon 與 SwiftPM resource bundle 的 `releases/AgentMeter.app`
- **AND** 系統依 `CFBundleShortVersionString` 產生頂層為 `AgentMeter.app` 的 `releases/AgentMeter-v<版本>.zip`
- **AND** 系統輸出該 ZIP 的 SHA-256，供 Homebrew Cask 驗證下載內容
- **AND** ZIP 結構與 checksum 驗證成功後，系統移除中間 `releases/AgentMeter.app`，最終只保留版本化 ZIP

#### Scenario: 發布產物缺少必要內容
- **WHEN** executable、`Info.plist`、App icon、entitlements 或 SwiftPM resource bundle 任一缺失或無法驗證
- **THEN** 發布建置 SHALL 以非零狀態中止
- **AND** SHALL NOT 將不完整產物視為可發布 ZIP
- **AND** 若中間 `AgentMeter.app` 已建立，SHALL 保留供發布者診斷

#### Scenario: 透過自訂 Tap 進行單行指令安裝
- **WHEN** GitHub Release 的版本化 ZIP 與 Cask 的 `version`、下載 URL 及 SHA-256 一致
- **AND** 使用者執行 `brew install --cask <tap>/agentmeter`
- **THEN** Homebrew SHALL 通過下載檔案的 checksum 驗證
- **AND** Homebrew 將 `AgentMeter.app` 安裝至 `/Applications`

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

### Requirement: 發布產物簽署驗證
發布建置流程 SHALL 在壓縮前簽署並驗證 `AgentMeter.app`；預設允許 ad-hoc identity，並可由發布者顯式指定本機 Keychain 中的 Developer ID identity。

#### Scenario: 預設本機發布建置
- **WHEN** 發布者未指定簽署 identity
- **THEN** 系統以 ad-hoc identity 簽署 App Bundle
- **AND** 以嚴格簽署驗證通過後才建立 ZIP

#### Scenario: 指定 Developer ID identity
- **WHEN** 發布者透過受支援的環境變數指定 Developer ID identity
- **THEN** 系統使用該 identity 與既有 entitlements 簽署 App Bundle
- **AND** 腳本不保存憑證、私鑰或密碼至專案與發布產物
