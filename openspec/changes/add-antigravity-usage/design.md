# 技術設計：Google Antigravity Gemini 額度顯示

## Context

AgentMeter 已以 `AgentProvider`、`ProviderRegistry`、`UsageMonitorViewModel` 與 `SmartCacheManager` 建立 Codex 額度監控流程。本變更在相同架構邊界內新增 Google Antigravity，但只讀取官方 Antigravity CLI 的 Google 帳號 Gemini Models 額度。

官方 Antigravity CLI 1.1.11 起支援以 `agy -p "/usage" --output-format json` 非互動查詢額度，不會啟動 Agent turn、消耗模型額度或建立對話。此介面優於解析互動式 TUI，且可在 macOS GUI App 中以受控子行程整合。

## Goals / Non-Goals

**目標：**
- 在既有 Provider 抽象後新增可測試的 Antigravity Provider。
- 動態顯示所有有效 Gemini Models bucket，並排除非 Gemini 與停用項目。
- 維持 Desktop 主動更新、Menu Bar Smart Cache 與手動強制更新語意。
- 讓 Codex 與 Antigravity 的快照、載入及錯誤狀態互不影響。
- 提供明確的安裝、升級、登入與診斷指引。

**非目標：**
- Gemini API Key、AI Credits、第三方模型額度、帳號與方案資訊。
- 互動式登入、TUI 畫面解析、常駐 CLI 行程或背景輪詢。

## Decisions

### 1. 官方 CLI 非互動 JSON 作為唯一資料來源

- **決策**：只執行 `agy -p "/usage" --output-format json`，最低版本為 1.1.11。
- **理由**：官方已保證此模式為唯讀查詢，不啟動 Agent turn；JSON 適合穩健解析與測試。
- **替代方案**：不解析互動式 `/usage` TUI、不讀取內部快取或私有後端 API。

### 2. 一次性子行程與嚴格逾時

- **決策**：每次實際重新整理建立一次 `agy` 子行程，取得完整 stdout 後終止，預設逾時 10 秒；逾時或取消時妥善終止子行程。
- **理由**：避免常駐背景活動、行程洩漏與跨 Provider 生命週期耦合。

### 3. 動態 Gemini bucket 過濾與正規化

- **決策**：解析結構化輸出時保留未知欄位容錯，僅將可判定屬於 Gemini Models 且有效的 bucket 正規化為 `RateLimitItem`。以 `remaining_fraction` 推導剩餘與已用百分比，使用官方 `reset_time`；缺少時間時不自行推算。
- **理由**：Google 可能調整模型分組、bucket 名稱與數量，不能硬編碼只有五小時與每週兩項。
- **安全邊界**：無法可靠判定為 Gemini 的 bucket 不顯示，避免誤將 Claude/GPT 額度納入。

### 4. Provider 狀態與快取隔離

- **決策**：Codex 與 Antigravity 各自保存 snapshot、last refresh、loading 與 error；共用使用者設定的 TTL 值，但不共用快取內容或失敗狀態。
- **理由**：任一 CLI 暫時故障時，另一 Provider 仍應保持可用。

### 5. CLI 偵測與登入邊界

- **決策**：自訂路徑優先，其次搜尋 `~/.local/bin/agy`、常見位置與 GUI 可取得的 `PATH`。先驗證執行檔與版本，再查詢用量。未登入時只顯示要求使用者在 Terminal 執行 `agy` 的指引。
- **理由**：macOS GUI 的 PATH 與互動 shell 不一致；AgentMeter 不應觸碰 Google 憑證或主動發起 OAuth。

### 6. UI 導航與 Menu Bar 分組

- **決策**：側邊欄固定顯示 Google Antigravity。Dashboard 顯示全部有效 Gemini bucket；首次探索到的 Antigravity bucket 全部加入 Menu Bar 自動預設。使用者自訂後，新 bucket 不擅自加入，除非恢復自動預設。
- **理由**：Setup 狀態應可被發現，且 Menu Bar 行為需延續既有使用者選擇語意。

## Error Mapping

- 找不到執行檔 → `cliMissing`。
- 版本低於 1.1.11 → `unsupportedVersion`，顯示目前與最低版本。
- CLI 回報無有效帳號工作階段 → `notAuthenticated`。
- 超過 10 秒 → `requestTimedOut`。
- 非零退出碼、無效 JSON、缺少可解析 payload → 描述性 Provider 錯誤。
- 查詢成功但沒有有效 Gemini bucket → 顯示空狀態，不改顯示第三方 bucket。

所有錯誤不得用過期 Antigravity snapshot 冒充最新資料。

## Testing Strategy

- CLI 路徑優先順序、版本解析與最低版本判定單元測試。
- `/usage` JSON fixture：五小時、每週、多個 Gemini bucket、停用 bucket、Claude/GPT 混合、未知欄位、缺少 reset、空集合與格式錯誤。
- 子行程成功、非零退出、逾時、取消與未登入錯誤測試。
- Provider 快取隔離、前景強制更新、Menu Bar TTL 與手動更新測試。
- 首次全部釘選、使用者自訂後不自動加入新 bucket、恢復預設測試。
- 中英文 UI 與 Diagnostics 去敏報告測試。
- 在已登入且版本相容的本機 `agy` 上進行選擇性整合測試；測試不得觸發 Agent turn。

## Risks / Trade-offs

- **CLI JSON schema 變更**：採寬鬆解碼、動態鍵處理與 fixture 覆蓋；無法安全判定的資料不顯示。
- **登入偵測可能依 CLI 錯誤文字變動**：優先依退出狀態與結構化錯誤分類，未知錯誤保留去敏摘要。
- **查詢可能受網路影響**：10 秒逾時、可取消操作與獨立錯誤狀態避免阻塞其他 Provider。
- **多 Provider UI 高度增加**：Popover 依 Provider 分組並沿用可捲動內容區。

## Migration Plan

- 現有 Codex 設定與 Menu Bar 選擇保持原值。
- 新增 Antigravity 自訂路徑與選擇狀態時提供安全預設。
- 第一次取得 Antigravity snapshot 後建立自動選擇，預設包含全部有效 Gemini bucket。
- 不需要資料庫或歷史資料遷移。
