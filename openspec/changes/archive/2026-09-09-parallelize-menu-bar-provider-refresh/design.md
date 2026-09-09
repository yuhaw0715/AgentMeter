## Context

現有 `UsageMonitorViewModel` 受 `@MainActor` 隔離，並以每 Provider 字典／集合保存快照、環境、錯誤、最後更新時間及刷新狀態。`refreshMenuBar(force:)` 會先逐一判斷 Smart Cache，再在 `for` 迴圈中 `await executeFetch`，因此 Provider 的非同步 I/O 仍按註冊順序串行。

`AgentProvider` 已符合 `Sendable` 並提供非同步環境檢查與額度查詢；`ProviderRegistry` 是初始化後唯讀的 `Sendable` 容器，`SmartCacheManager` 亦以鎖保護每 Provider 快照。這些既有邊界允許 Provider I/O 離開 Main Actor 並行，UI 狀態則繼續集中在 Main Actor 套用。行為契約見 `specs/menu-bar-usage/spec.md`。

## Goals / Non-Goals

**Goals:**

- 讓所有需要更新的 Menu Bar Provider 真正重疊執行非同步 I/O。
- 在 Main Actor 上安全且漸進地套用各 Provider 的完成結果。
- 以單一 Provider 為單位維持去重、錯誤、快取與載入狀態隔離。
- 使用可控制的同步點驗證並行，不依賴真實 CLI 速度或易波動的固定時間門檻。

**Non-Goals:**

- 不變更 Desktop 單一 Provider 刷新與 Provider 專屬重試的產品行為。
- 不平行化同一 Provider 內的環境檢查與額度查詢。
- 不建立背景排程器、長駐刷新服務、可設定並行上限或新的逾時政策。
- 不變更 Provider Protocol、CLI 指令、快取資料格式或 UI 版面。

## Decisions

### 1. 以結構化 Task Group 並行所有合格 Provider

`refreshMenuBar(force:)` 先在 Main Actor 建立本批工作清單：套用仍新鮮的快取、排除已在 `refreshingProviders` 中的 Provider，並將其餘 Provider 標記為刷新中。之後使用結構化 task group，為清單中的每個 Provider 建立一個子工作，不另設並行數量上限。

子工作只持有不可變且可傳送的 Provider 參考與本批輸入，依序執行 `checkEnvironment()` 及 `fetchRateLimits()`，再回傳型別化結果。task group 每收到一個結果，就回到 Main Actor 更新對應 Provider；不得等所有子工作完成後才一次提交。

替代方案是用 `async let` 固定列出 Codex 與 Antigravity，但這會把協調器綁死在兩種 Provider，新增 Provider 時必須修改程式。另一方案是建立無結構的 `Task` 並保存 handles，會增加生命週期、取消與記憶體管理負擔，因此不採用。

### 2. 將單一 Provider I/O 與 Main Actor 狀態提交分離

新增私有、`Sendable` 的刷新結果型別，至少可表達：成功快照、環境未就緒、查詢錯誤及取消。實際命名可於實作時依 Swift 版本調整，但結果不得攜帶非 `Sendable` 狀態。

Main Actor 負責三個階段：開始前標記、逐筆結果提交、結束或取消時清理。成功時更新快照、時間、快取並清除錯誤；環境未就緒時更新環境狀態；失敗時使該 Provider 快取失效並記錄錯誤，但保留 ViewModel 內最後快照供 UI 明確呈現舊資料；取消不轉換成使用者可見錯誤。所有路徑均須移除對應的刷新中標記。

單一 Provider 的 Desktop 刷新與重試可沿用 `executeFetch` 的公開行為；為避免兩套狀態語意漂移，可共用私有的「執行 I/O／提交結果」輔助方法，但不把 Desktop 改成批次刷新。

### 3. 以開始階段的原子式去重避免同 Provider 重入

每次建立工作前，Main Actor 先檢查 `refreshingProviders`，並在產生子工作前立即插入 Provider。由於判斷與插入都在同一 Actor 隔離區段完成，同時到達的 Popover 自動刷新、強制刷新或重試最多只有一個能啟動該 Provider；被去重的請求不取消既有工作，也不等待後再補跑一次。

替代方案是讓後來請求等待並共用既有 task handle。現有產品只需要避免重複 CLI 呼叫，沒有呼叫端必須取得同一回傳值的需求；維護共享 handle 反而增加狀態與清理風險，因此不採用。

### 4. 快取判斷先於並行工作，強制刷新只繞過 TTL

非強制刷新先逐 Provider 查詢 Smart Cache。命中新鮮快取者立即套用且不建立子工作；未命中者才加入 task group。強制刷新忽略 TTL，但仍尊重 `refreshingProviders` 去重，避免同一 Provider 出現重疊程序。

這保留現有 Smart Cache 契約，也讓「Codex 快取有效、Antigravity 過期」時只啟動 Antigravity。快取管理不搬入 Provider 子工作，以免分散 UI 與快取提交的順序控制。

### 5. 取消遵循呼叫端的結構化生命週期

task group 綁定 `refreshMenuBar` 的呼叫 Task。呼叫端取消時，群組取消未完成子工作；子工作在環境檢查前後與額度查詢前檢查取消，並依 Provider 既有的合作式取消能力結束。已經回傳並在 Main Actor 套用的結果不回滾，未完成 Provider 的刷新標記則由清理路徑移除。

本次不保證外部 CLI 程序能在取消瞬間被強制終止，也不新增 process-level kill 機制；若底層呼叫只能在既有逾時或回應後返回，仍不得把取消當成 Provider 錯誤或提交取消後取得的舊批次結果。

### 6. 以受控事件驗證重疊執行

測試使用 Mock Provider 的 actor／continuation 或等價同步閘門記錄「已開始」與控制「允許完成」。測試需在任一 Provider 獲准完成前觀察到所有合格 Provider 均已開始，並分別釋放工作以驗證完成順序、漸進提交及全域 spinner。這直接驗證並行性，避免使用固定 sleep 與真實秒數造成 CI 不穩定。

## Risks / Trade-offs

- **[風險] 多個 CLI 程序同時執行會短暫增加 CPU、記憶體與程序數** → 目前僅有兩個已支援 Provider，且每個 Provider 維持單一 in-flight 去重；未來 Provider 數量顯著增加時再評估上限。
- **[風險] 子工作完成順序不確定，可能暴露依賴註冊順序的隱性假設** → 所有狀態與快取均以 `ProviderType` 鍵控，測試刻意反轉完成順序。
- **[風險] 取消與錯誤路徑遺留 `refreshingProviders` 項目** → 使用涵蓋成功、未就緒、失敗與取消的集中提交／清理路徑，並逐一測試。
- **[風險] Main Actor 方法內建立 task group 時不慎讓 I/O 回到主執行緒** → 子工作僅捕獲 `Sendable` 值並執行 Provider 非同步 API；編譯時啟用現有 Swift concurrency 檢查，測試以重疊事件驗證實際行為。
- **[取捨] 不設定並行上限** → 換取目前及近期 Provider 數量下的最低延遲與最簡單行為；若支援數量大幅增加，需另提變更加入節流。

## Migration Plan

1. 建立單一 Provider 的型別化刷新結果與 Main Actor 提交／清理邊界，保持現有公開方法行為。
2. 將 Menu Bar 快取篩選與刷新中去重移至批次工作建立前，再以 task group 並行執行合格 Provider。
3. 補齊並行開始、反向完成、局部失敗、快取部分命中、重複請求、強制刷新與取消測試。
4. 執行完整 Swift 測試與 OpenSpec strict validation，並手動確認全域 spinner 與各 Provider 漸進狀態。

若需回退，可將 `refreshMenuBar(force:)` 恢復為逐一呼叫單一 Provider 刷新的迴圈；Provider Protocol、快取格式、設定與 UI 均無需遷移。
