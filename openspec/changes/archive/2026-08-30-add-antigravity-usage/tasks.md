# 實作檢查清單：Google Antigravity Gemini 額度顯示

## 1. 領域模型與 Provider 註冊

- [x] 1.1 擴充 Provider 狀態，使 Codex 與 Antigravity 具有獨立 snapshot、loading、error 與 last refresh
- [x] 1.2 正式註冊 Google Antigravity Provider 並加入固定側邊欄導航

## 2. Antigravity CLI 環境偵測

- [x] 2.1 實作 `agy` 自訂路徑、`~/.local/bin/agy`、常見位置與 PATH 搜尋順序
- [x] 2.2 實作 CLI 版本取得、語意版本解析與最低 1.1.11 判定
- [x] 2.3 建立 CLI 缺少、版本不相容、未登入與重新檢查狀態

## 3. Antigravity 額度 Provider

- [x] 3.1 實作一次性 `agy -p "/usage" --output-format json` 子行程與 10 秒逾時／取消處理
- [x] 3.2 實作寬鬆 JSON 解碼、有效 Gemini Models bucket 過濾與 `RateLimitItem` 正規化
- [x] 3.3 排除 Claude、GPT、其他第三方模型、停用 bucket 與 AI Credits
- [x] 3.4 實作無重置時間、空 Gemini 集合、非零退出與格式錯誤處理

## 4. 快取與應用程式狀態

- [x] 4.1 建立 Antigravity 獨立快取並共用現有 TTL 設定值
- [x] 4.2 實作 Dashboard 前景強制更新、Popover TTL 更新與手動繞過快取
- [x] 4.3 確保單一 Provider 失敗不影響另一 Provider 的有效狀態

## 5. Desktop 與 Menu Bar UI

- [x] 5.1 建立 Google Antigravity Dashboard，顯示全部有效 Gemini 額度與 Setup／空／錯誤狀態
- [x] 5.2 Menu Bar 依 Provider 分組顯示 Codex 與 Antigravity，並維持可捲動高度
- [x] 5.3 Antigravity 首次發現的所有 bucket 預設釘選，使用者自訂後不擅自加入新 bucket
- [x] 5.4 Settings 新增 Antigravity CLI 自訂路徑與恢復自動預設行為

## 6. Diagnostics 與在地化

- [x] 6.1 Diagnostics 新增 `agy` 路徑、版本、相容性、登入、最近查詢與更新時間
- [x] 6.2 擴充診斷報告去敏規則與 Antigravity 錯誤摘要
- [x] 6.3 補齊繁體中文與英文 Provider、設定、Setup、空狀態與錯誤字串

## 7. 驗證

- [x] 7.1 新增環境偵測、版本、JSON fixture、過濾與錯誤映射單元測試
- [x] 7.2 新增多 Provider 快取隔離、全部預設釘選與使用者自訂行為測試
- [x] 7.3 執行完整 `swift test` 與 `swift build -c release`
- [x] 7.4 在相容且已登入的本機 `agy` 執行不耗用 Agent 額度的選擇性整合測試
