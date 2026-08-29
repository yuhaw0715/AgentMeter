# AgentMeter MVP：Codex 使用額度監控器

## Why

AI Coding Agent 的使用額度通常分散在各自的 CLI、Desktop App 或服務介面中，缺乏一個適合 macOS、能快速查看目前額度狀態的原生工具。對經常使用 Codex 的開發者而言，最常見的需求不是保存長期統計，而是快速知道「目前用了多少、還剩多少、何時重置」，並在需要時取得更完整的診斷資訊。

AgentMeter 將提供一個輕量、原生、低背景活動的 macOS SwiftUI 應用程式。MVP 聚焦 ChatGPT Codex，使用 Codex 官方 CLI 的 `app-server` 介面取得目前帳號的 rate limits，不自行管理登入、不抓取瀏覽器 Cookie、不呼叫私人後端 API，也不建立 AgentMeter 自有後端。

本變更的目標是建立可實際發布與日常使用的 AgentMeter MVP，同時保留未來擴充 Gemini、Antigravity 等 Agent provider 的架構空間，但不讓尚未完成的 provider 出現在 MVP 使用者介面中。

## What Changes

- 建立名為 **AgentMeter** 的 macOS 26+ SwiftUI 應用程式，採 MIT License 並以 GitHub 開源發布。
- MVP 僅支援 **ChatGPT Codex**；Gemini 與 Antigravity 不顯示於 MVP UI，但資料層需保留可擴充的 Agent/provider abstraction。
- 提供兩個主要操作介面：
  - Desktop App：完整查看 Codex 所有目前可取得的 usage limits、設定與 Diagnostics。
  - Menu Bar：快速查看使用者選定的 limits，並可開啟 AgentMeter 主視窗、Settings 或退出程式。
- 不實作 WidgetKit/Desktop Widget。
- Codex 資料來源採 CLI-first：啟動或連接官方 `codex app-server`，透過 JSON-RPC 呼叫 `account/rateLimits/read` 取得官方目前提供的 rate-limit snapshot。
- 不解析 `/status` 的文字 UI 作為主要資料來源，也不宣稱與 Codex Desktop Usage 頁面所有欄位完全一致；AgentMeter 僅呈現官方 app-server 實際暴露的資料。
- 動態解析 provider 回傳的 limits，不硬編碼固定只有「5-hour」或「Weekly」。若未來出現新的 limit 類型，AgentMeter 應以 generic limit 呈現，而不是解析失敗或靜默忽略。
- 每個可用 limit 顯示：
  - Used percentage。
  - Remaining percentage。
  - Progress indicator，以 used percentage 為填充基準。
  - Reset 絕對日期/時間；遵循 macOS locale、timezone 與 12/24 小時制。
  - Provider 未提供 reset time 時，顯示本地化的「Reset time unavailable / 無法取得重置時間」，不得自行推算。
  - 達到使用上限時，額外顯示「Limit reached / 已達使用上限」。
- UI 百分比顯示為整數；資料層可保留 provider 回傳的原始精度。
- Desktop App 每次被開啟/叫到前景時，主動取得最新 Codex usage，不以 TTL 阻止此次 refresh；UI 顯示 `Refreshing…` 與最後更新狀態。
- Menu Bar 採 Smart Cache：
  - 預設 TTL 為 5 分鐘，使用者可在 Settings 調整。
  - 點擊 Menu Bar 圖示時 Popover 必須立即出現。
  - Cache 尚新鮮時直接顯示 snapshot，不重新呼叫 Codex。
  - Cache 已過期時顯示 refreshing 狀態並取得新 snapshot。
  - 手動 Refresh 永遠 bypass TTL。
  - Refresh 失敗後不得把 stale usage 當成目前資料繼續呈現；應顯示目前錯誤狀態與 Retry。
- Menu Bar status item 本身只顯示 icon，不直接顯示百分比文字。
- Menu Bar Popover 的 limit 顯示支援：
  - 自動預設重要 limits。
  - 使用者自行勾選/取消顯示的 limits。
  - 使用者自行排序。
  - 不限制選擇數量；超出 Popover 可用高度時可捲動。
  - 新 discover 的 limits 可出現在設定選項中，但不得擅自改變使用者已自訂的選擇；提供 Restore Automatic Defaults。
- Desktop App 使用 Sidebar 導航；MVP 中只顯示已支援的 Codex，不顯示 disabled/coming-soon 的 Gemini 或 Antigravity。
- Menu Bar Popover 提供 `Open AgentMeter…`，可叫出/bring-to-front Desktop App 主視窗；另提供 Settings 與 Quit。
- 關閉 Desktop App 主視窗不退出 AgentMeter，Menu Bar utility 繼續執行；使用 Quit AgentMeter 或 Cmd-Q 才真正退出。
- 支援 Launch at Login，並在 Settings 提供開關。
- AgentMeter 不管理 Codex 身分驗證：
  - 自動偵測 `codex` executable。
  - PATH 偵測失敗時允許使用者指定自訂 Codex executable path。
  - Codex CLI 不存在時顯示 Setup Required 與 Check Again。
  - Codex CLI 存在但尚未登入時顯示 Sign-in Required 指引。
  - AgentMeter 不實作 OAuth、不儲存 Codex token/password，也不修改 Codex credentials。
  - MVP 僅使用目前 Codex CLI 已登入的單一帳號，不支援 multi-account 切換。
- 不提供固定的首次啟動 onboarding wizard；環境正常時直接進入 Dashboard，只有環境有問題時才顯示 setup/error state。
- 提供 Diagnostics 頁面，至少能檢查/呈現：
  - Codex CLI 是否找到及實際 executable path。
  - `codex app-server` 是否可用。
  - Codex authentication 狀態。
  - `account/rateLimits/read` 最近一次是否成功。
  - 最近 refresh 時間。
  - AgentMeter 版本與 macOS 版本。
- Diagnostics 提供 `Copy Diagnostic Report`，輸出必須適合貼至 GitHub Issue，並遮蔽 token、credential、敏感帳號資料等資訊。
- Settings 與 cache 僅儲存在本機，不使用 iCloud/CloudKit。
- 不保存 usage 歷史紀錄，不建立歷史資料庫、不提供趨勢圖。
- MVP 不提供低額度或其他系統通知，也不為通知加入背景 polling。
- MVP 不提供 Global Hotkey。
- MVP 不包含 Telemetry、Analytics 或第三方 crash reporting；AgentMeter 不主動上傳 Codex usage、帳號資訊或 diagnostics。
- MVP 不內建 Sparkle 或其他 App 自動更新機制；更新交由 GitHub Release/Homebrew 流程處理。
- UI 同時支援 English 與繁體中文，依 macOS localization 設定呈現。
- 發布方式：
  - GitHub Release 提供 AgentMeter App 發布產物。
  - 使用既有的 custom Homebrew tap 發布 Cask。
  - MVP 可採 unsigned app；Cask 安裝流程僅針對 AgentMeter.app 處理必要的 quarantine attribute，不得對 `/Applications` 或其他 App 做廣泛修改。
  - README 提供一行式 Homebrew 安裝方式與 uninstall 指令。
  - Cask 支援 `--zap` 完整移除 AgentMeter 自己的本機資料；`--zap` 不得刪除或修改 Codex CLI 的設定、登入狀態或 credentials。
  - Developer ID signing/notarization 可作為後續發布改善，不是 MVP 阻塞條件。

## Capabilities

### New Capabilities

- `codex-rate-limit-provider`：透過官方 Codex CLI `app-server` 與 `account/rateLimits/read` 取得目前登入帳號的 rate-limit snapshot，將 provider 回傳內容正規化成 AgentMeter 可使用的動態 limit model，並能容忍未知/新增的 limit 類型。
- `usage-dashboard`：提供 macOS SwiftUI Desktop Dashboard，顯示所有 discover 到的 Codex limits、used/remaining percentage、reset time、limit reached 與 refresh/error 狀態。
- `menu-bar-usage`：提供常駐 Menu Bar 的快速 usage Popover，具 Smart Cache、手動 refresh、可自訂/排序 limits、捲動及開啟主 App 等能力。
- `codex-environment-setup`：自動偵測 Codex CLI、支援 custom executable path，並處理 CLI missing、not authenticated、app-server unavailable 等 setup/error states，而不接管 Codex authentication。
- `agentmeter-settings`：提供本機 Settings，包括 Menu Bar limits、排序、Smart Cache TTL、Codex executable path、Launch at Login，以及 Restore Automatic Defaults。
- `agentmeter-diagnostics`：提供 Codex CLI/app-server/auth/rate-limit request 與 AgentMeter/macOS 狀態診斷，並產生經敏感資訊遮蔽的可複製 diagnostic report。
- `agent-provider-abstraction`：建立可擴充的 Agent usage provider 邊界，使未來 Gemini、Antigravity 或 OpenAI 正式外部 usage API 可以新增為 provider，而不需重寫主要 UI；MVP 只註冊並顯示 Codex provider。
- `localization`：MVP 提供 English 與繁體中文 UI localization，並使用系統 locale/timezone 格式化日期時間。
- `homebrew-distribution`：建立 GitHub Release + 既有 custom Homebrew tap 的發布方式，支援單行安裝、一般 uninstall 與 `--zap`，並限制 quarantine workaround 只作用於 AgentMeter.app。

### Modified Capabilities

- 無。此變更建立全新的 AgentMeter 專案與 MVP capabilities。

## Impact

- **平台**：macOS 26+。
- **UI 技術**：SwiftUI，包含 Desktop Window、Menu Bar Popover、Settings 與 Diagnostics。
- **外部依賴**：使用者需自行安裝並登入官方 Codex CLI；AgentMeter 不負責安裝 Codex CLI。
- **外部協定**：依賴官方 Codex `app-server` JSON-RPC 的 `account/rateLimits/read`。實作應將 Codex-specific protocol 隔離在 provider layer，以降低未來 protocol 變更對 UI 的影響。
- **資料與隱私**：usage snapshot、cache 與設定僅在本機處理；不保存歷史、不使用雲端同步、不提供 telemetry、不建立 AgentMeter backend。
- **效能與耗電**：MVP 不做持續背景 quota polling。Desktop App 開啟時主動 refresh；Menu Bar 依 Smart Cache/使用者互動 refresh，以降低不必要的 app-server 呼叫與背景活動。
- **錯誤可信度**：AgentMeter 不自行推測 provider 未提供的 quota/reset 資料；refresh 失敗時不將 stale snapshot 冒充為最新資訊。
- **發布**：GitHub 開源、MIT License、GitHub Release、既有 custom Homebrew tap；MVP 不內建 updater。
- **MVP 明確非目標**：Gemini/Antigravity 實際支援、WidgetKit、usage history/trends、notifications、Global Hotkey、multi-account、iCloud/CloudKit、Telemetry、內建 auto-update、AgentMeter 自有 OAuth/credential management，以及與 Codex Desktop Usage UI 的所有欄位完全等價。
