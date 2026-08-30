# 新增 macOS 發布產物建置腳本

## Why

AgentMeter 目前以 Swift Package Manager 建置，但 `swift build -c release` 只會產生可執行檔與資源 bundle，不會建立 Homebrew Cask 可安裝的 `AgentMeter.app`。手動建立 App Bundle 容易遺漏 `Info.plist`、圖示、SwiftPM resources、執行權限、簽署或 ZIP 根目錄結構，造成 GitHub Release 產物無法啟動或無法由 Homebrew 正確安裝。

本變更將提供一個可重複執行的本機發布腳本，從乾淨建置開始，自動建立、簽署、驗證並壓縮 `AgentMeter.app`，產出可直接上傳 GitHub Release 的 `releases/AgentMeter-v<版本>.zip`。

## What Changes

- 新增 `scripts/build-release.sh`，使用 SwiftPM Release 組態建置 AgentMeter。
- 自動建立標準 macOS App Bundle 目錄，並複製 executable、`Info.plist`、`AppIcon.icns` 與 SwiftPM resource bundle。
- 檢查版本資訊、必要檔案、可執行權限與 Bundle 結構，缺少任何必要項目時立即失敗。
- 預設使用 ad-hoc 簽署並套用既有 entitlements；允許以環境變數指定 Developer ID identity，但不保存或管理憑證。
- 使用 `codesign`、`plutil` 與 `ditto` 驗證並產生帶版本號的 `releases/AgentMeter-v<版本>.zip`，確保 ZIP 第一層為 `AgentMeter.app`。
- 輸出 ZIP 的 SHA-256，供更新 Homebrew Cask 使用。
- 更新 README，記錄本機產物建置、GitHub Release 上傳與 Homebrew checksum 更新流程。

## Capabilities

### New Capabilities

無。

### Modified Capabilities

- `homebrew-distribution`：新增可重現的 macOS App Bundle 與 GitHub Release ZIP 產製流程，以及發布前的結構、簽署與 checksum 驗證要求。

## Impact

- **新增檔案**：`scripts/build-release.sh`。
- **文件**：更新 `README.md` 的發布說明。
- **建置輸出**：建置期間建立未納入版控的 `releases/AgentMeter.app`，驗證成功後移除中間 App Bundle，最終只保留 `releases/AgentMeter-v<版本>.zip`。
- **本機工具**：依賴 macOS 內建的 `codesign`、`ditto`、`plutil`、`shasum` 與 Swift toolchain。
- **安全性**：預設 ad-hoc 簽署不等同 Apple notarization；腳本不讀取或保存簽署憑證密碼。

## Non-Goals

- 不自動建立或推送 Git tag。
- 不自動建立、修改或發布 GitHub Release。
- 不自動修改或推送 `homebrew-tap`。
- 不新增 GitHub Actions、Developer ID 憑證管理或 Apple notarization。
- 不建立 DMG、PKG、Sparkle feed 或自動更新機制。
