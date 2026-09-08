# add-antigravity-ai-credits-display 實作結案總結

## 完成內容

- 新增 `AntigravityAICredits` 與 `AntigravityAICreditsStatus` 型別化模型，將已知餘額（含 0）、方案不支援、CLI 未提供欄位與資訊未知分開表示。
- `RateLimitSnapshot` 新增向後相容的可選 AI Credits 摘要；舊快照解碼不受影響。
- Antigravity Provider 維持單次 `agy -p "/usage" --output-format json` 唯讀查詢，只解析官方二進位結構可驗證的 `available_credits`／`availableCredits` 欄位名稱；缺少欄位時回傳 CLI 未提供狀態，格式不安全時局部降級為未知。
- AI Credits 不會混入 Gemini Models bucket，也不會觸發 `/credits` TUI、憑證存取、私人 API、購買、設定或消耗操作。
- AI Credits 隨 Antigravity Provider 快照共用刷新、觀測時間、Smart Cache TTL 與既有手動刷新流程。
- Desktop 新增獨立 Liquid Glass「AI 點數」卡片；Menu Bar 在單一 Antigravity 外框內以水平分隔線加入緊湊子區段。
- 新增繁中／英文標題、CLI 未提供、方案不支援、資訊未知、快取過期及更新時間文案，並以地區化整數格式顯示總數。

## 實機資料來源結果

- 本機官方 Antigravity CLI 版本：`1.1.27`。
- 實際執行官方 `/usage --output-format json` 後，輸出中沒有任何包含 `credit` 的欄位路徑。
- 因此目前實機採預期的相容行為：Gemini Models 額度正常顯示，AI 點數卡顯示「資訊未知」與「目前 CLI 版本未提供 AI Credits 資訊」。
- 以二進位字串檢查確認官方 schema 包含 `available_credits`／`availableCredits` 名稱；解析器只接受這兩個明確名稱及非負整數／十進位整數字串，不猜測其他欄位。

## UI 驗證

- 以 ad-hoc 簽署的暫存 App Bundle 在 macOS 實機啟動 release build。
- Desktop Antigravity Dashboard 已確認模型額度、獨立 AI 點數卡、中性 CLI 相容狀態及 `yyyy-MM-dd HH:mm:ss` 更新時間同時正常呈現。
- Menu Bar 程式結構已確認 AI 點數位於單一 Antigravity Provider 外框中、使用一條水平分隔線、共用同一呈現元件並沿用既有垂直捲動；macOS 狀態項目未暴露給 UI 自動化 accessibility tree，因此未以自動化點擊擷取 Popover 截圖。
- 暫存測試 App 已在檢查後正常結束，未覆寫 `/Applications/AgentMeter.app`。

## 驗證結果

- `swift test`：13 個測試套件、45 項測試全部通過。
- `swift build -c release`：成功。
- Live Codex integration：成功。
- Live Antigravity integration：測試依既有容錯設計接受 10 秒 timeout；另一次官方唯讀實機查詢成功確認現行 JSON 無 Credits 欄位。
- OpenSpec：`openspec validate add-antigravity-ai-credits-display --strict` 通過。

## 未納入範圍

- 不提供 AI Credits 購買、加值、自動加值或消耗。
- 不修改 `useG1Credits` 或 AI Credit Overages。
- 不顯示近期用量紀錄或逐筆到期資訊。
- 不解析互動式 `/credits` TUI，不讀取 OAuth／Keychain，不呼叫未公開後端 API。
