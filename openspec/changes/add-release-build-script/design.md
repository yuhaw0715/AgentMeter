# 技術設計：macOS 發布產物建置腳本

## Context

AgentMeter 使用 Swift Package Manager 的 executable target 與 `.process("Resources")`。Release build 會在 SwiftPM bin path 產生 `AgentMeter` executable，以及 target 對應的 resource bundle；Homebrew Cask 則要求下載的 ZIP 解開後包含可安裝的 `AgentMeter.app`。

發布腳本需要把 SwiftPM 產物轉換為標準 macOS App Bundle，維持既有 `Resources/Info.plist`、`Resources/AppIcon.icns` 與 `Resources/AgentMeter.entitlements` 為單一設定來源，並在壓縮前驗證最終產物。

## Goals / Non-Goals

**目標：**
- 一個指令產生可供 GitHub Release 與 Homebrew Cask 使用的 ZIP。
- 從專案根目錄以外的位置呼叫時仍能正確解析路徑。
- 任何必要建置產物缺失時清楚失敗，不生成不完整 ZIP。
- 支援 Apple Silicon 與 Intel Mac 的原生本機建置結果。
- 讓正式 Developer ID 簽署可以日後透過參數啟用，不把憑證資訊寫入版控。

**非目標：**
- 建立 universal binary 或交叉編譯另一個架構。
- 上傳 GitHub、更新 tap、notarize 或 staple。

## Decisions

### 1. 使用 Bash 腳本協調系統工具

- **決策**：新增具備嚴格模式的 `scripts/build-release.sh`，以 `swift build`、`ditto`、`plutil`、`codesign` 與 `shasum` 完成流程。
- **理由**：這些工具均為 macOS／Swift 開發環境既有工具，不需加入新的套件依賴。

### 2. 每次重建受控的 `dist` 產物

- **決策**：腳本只重建專案根目錄下明確的 `releases/AgentMeter.app` 與目前版本的 `releases/AgentMeter-v<版本>.zip`，不刪除其他版本或目錄。
- **理由**：避免舊 resources 或 executable 混入新版本，同時限制清理範圍。

### 3. 動態取得 SwiftPM bin path 與 resource bundle

- **決策**：以 `swift build -c release --show-bin-path` 取得架構相關路徑，並在該目錄尋找 AgentMeter target 產生的 resource bundle；要求恰好找到可辨識的 bundle，否則中止並顯示診斷。
- **理由**：避免硬編碼 `.build/arm64-apple-macosx/release`，使腳本可在不同架構與 SwiftPM 版本使用。

### 4. Bundle 內容與 metadata

- **決策**：建立 `Contents/MacOS` 與 `Contents/Resources`，複製 executable、`Info.plist`、icon 及完整 resource bundle；保留 `Info.plist` 的版本與 Bundle Identifier，並以 `plutil -lint` 驗證。封裝後的 App icon 從 `Bundle.main` 標準資源位置讀取，SwiftPM 直接執行模式則保留 `Bundle.module` fallback。
- **理由**：SwiftPM resource bundle 必須保留完整名稱與內容；封裝後不在 App 根目錄放置額外資源或連結，才能符合 macOS Bundle 及嚴格簽署規則。

### 5. 簽署策略

- **決策**：預設 identity 為 `-`（ad-hoc），可透過 `CODESIGN_IDENTITY` 指定 Developer ID；套用既有 entitlements，先簽內部 bundle 再簽最外層 App，最後執行 `codesign --verify --deep --strict`。
- **理由**：未 notarize 的 MVP 仍需具備一致簽章結構；正式憑證由操作者的 Keychain 提供，腳本不管理秘密。
- **限制**：Developer ID 簽署本身不代表已完成 notarization。

### 6. 可重現的 Cask ZIP 介面

- **決策**：以 `ditto -c -k --sequesterRsrc --keepParent` 壓縮 App，並檢查 archive 列表的應用程式內容只以 `AgentMeter.app/` 為頂層 App 路徑；允許 `ditto` 為延伸屬性產生的 `__MACOSX/` metadata。
- **理由**：Homebrew Cask 的 `app "AgentMeter.app"` 需要 archive 解開後能直接找到該 bundle。

## Validation Strategy

- `bash -n scripts/build-release.sh` 驗證語法。
- 執行 `swift test` 與完整發布腳本。
- 以 `plutil` 驗證最終 `Info.plist`。
- 以 `codesign --verify --deep --strict` 驗證簽署。
- 以 `unzip -l` 驗證 ZIP 頂層與必要檔案。
- 解壓至暫存目錄後確認 executable 權限與資源 bundle。
- 比對腳本輸出的 SHA-256 與 `shasum -a 256 releases/AgentMeter-v<版本>.zip`。

## Risks / Trade-offs

- **SwiftPM resource bundle 命名可能變動**：採動態尋找與唯一性驗證，無法明確辨識時失敗而非猜測。
- **ad-hoc 簽署仍可能觸發 Gatekeeper**：沿用既有 Cask 的範圍受限 quarantine 處理；正式解法留待 Developer ID 與 notarization 變更。
- **本機建置只包含當前架構**：在 README 明確記錄，universal binary 另案規劃。
- **簽署順序影響驗證**：先處理巢狀 bundle，再簽最外層 App，並以嚴格驗證作為壓縮門檻。

## Migration Plan

- 不影響既有開發用 `swift build` 與 `swift test`。
- 發布者改用 `scripts/build-release.sh` 產生 GitHub Release asset。
- 第一次成功產生 ZIP 後，以輸出的 SHA-256 取代 Homebrew Cask 的 `sha256 :no_check`。
