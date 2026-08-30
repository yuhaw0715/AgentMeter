# 實作檢查清單：macOS 發布產物建置腳本

## 1. 發布腳本

- [x] 1.1 新增嚴格模式的 `scripts/build-release.sh`，解析專案根目錄、必要工具與輸出路徑
- [x] 1.2 執行 SwiftPM Release build，動態取得 executable 與 AgentMeter resource bundle
- [x] 1.3 建立標準 `AgentMeter.app/Contents` 結構並複製 Info.plist、icon、executable 與 resources
- [x] 1.4 驗證版本 metadata、必要檔案、目錄結構與 executable 權限
- [x] 1.5 實作預設 ad-hoc 與可選 Developer ID identity 的簽署及嚴格驗證
- [x] 1.6 使用 `ditto` 產生 `releases/AgentMeter-v<版本>.zip`，驗證 archive 頂層並輸出 SHA-256
- [x] 1.7 ZIP 與 checksum 驗證成功後移除中間 `releases/AgentMeter.app`，失敗時保留供除錯

## 2. 專案與文件設定

- [x] 2.1 確認 `releases/` 由 `.gitignore` 排除，避免發布二進位被誤提交
- [x] 2.2 更新 README，記錄建置、GitHub Release 上傳、checksum 與 Homebrew tap 更新步驟

## 3. 驗證

- [x] 3.1 執行 shell 語法與靜態檢查
- [x] 3.2 執行完整 `swift test`
- [x] 3.3 執行發布腳本並驗證 App Bundle、簽署、ZIP 結構與 SHA-256
- [x] 3.4 確認既有開發用 `swift build -c release` 流程不受影響
- [x] 3.5 將版本化 ZIP 上傳 GitHub Release、同步 Cask checksum，並由使用者完成 `brew install --cask yuhaw0715/tap/agentmeter` 實機安裝驗證
