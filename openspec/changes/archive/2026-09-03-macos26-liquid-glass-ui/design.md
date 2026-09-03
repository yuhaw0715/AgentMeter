## Context

使用者已確認以 Demo 選項 1 為基礎：主程式採側欄導覽與額度卡片，Menu Bar Popover 與主程式共用同一套視覺語言。現有 `MainDesktopContainerView` 使用標準 `NavigationSplitView` 與 `List`，`UsageDashboardView` 和 `RateLimitCardView` 則以個別的 `Color`、圓角與陰影呈現；`MenuBarPopoverView` 另有一套緊湊版卡片。若只調整單一畫面，品牌徽章、Provider 狀態、釘選控制與錯誤狀態會在兩個入口間產生差異。

macOS 26 的 Liquid Glass 應用應集中於最上層導覽與重要控制項，不能讓半透明背景降低額度數字或錯誤訊息的辨識度。因此本變更先建立明確的設計 token 與元件責任，再逐一替換現有視圖的外觀。

## Goals / Non-Goals

**Goals:**

- 讓 Desktop 主視窗以側欄清楚區分 ChatGPT Codex、Antigravity、設定與診斷。
- 讓主程式與 Menu Bar Popover 共用品牌徽章、Provider 色彩、狀態標籤、卡片圓角、進度條與間距規則。
- 將 Liquid Glass 材質套用在工具列、側欄、Popover 與主要操作控制項，支援淺色、深色與系統外觀。
- 保持額度卡片的百分比、剩餘量、重置時間、錯誤與重新整理狀態易讀且可存取。
- 確認主程式勾選釘選後，Popover 立即反映相同項目；Popover 的重新整理、開啟主視窗與退出仍遵守既有行為。

**Non-Goals:**

- 不重新設計 Provider 查詢、Smart Cache、額度計算、設定資料或 App lifecycle。
- 不新增獨立 Menu Bar helper process，不改變純選單列常駐模式。
- 不新增外部 UI framework、遠端字型、圖示套件或新的品牌圖示資產。
- 不在同一次變更中修改本地化文案內容；新增字串若必要，沿用既有繁中／英文／系統語系架構。

## Decisions

### 1. 建立共用 AgentMeter 視覺 token

在 AgentMeter App target 建立集中管理的顏色、材質、間距、圓角、陰影與狀態色定義，讓 Desktop 與 Menu Bar 只引用共用 token。淺色、深色與系統外觀使用 SwiftUI `ShapeStyle`／`Material` 的系統適配能力；額度百分比與進度條使用高對比的藍、橙、紅狀態色。

替代方案是於每個 View 內直接寫 `Color` 與 `RoundedRectangle` 參數，實作較快但容易使兩個入口日後再次分叉，因此不採用。

### 2. 主程式採側欄＋內容區的固定資訊層次

沿用 `NavigationSplitView` 作為骨架，側欄加入 AgentMeter 品牌徽章、Provider 分組與應用程式項目；內容區以工具列、Provider 標頭、狀態與額度卡片呈現。Provider 切換維持現有重新整理觸發，不將導覽與資料查詢耦合。

### 3. Menu Bar Popover 沿用主程式卡片，但採緊湊密度

Popover 使用相同的品牌徽章、Provider 標題、狀態色與進度條，透過較小的間距與字級顯示釘選項目。兩個 Provider 按既有規格分組，各自保留載入中、成功、錯誤與重試狀態；內容超出高度時維持垂直捲動。

### 4. Liquid Glass 只放在層級較高的表面

工具列、側欄、Popover 外框與主要按鈕使用系統材質或半透明表面，額度卡片使用不透明或足夠不透明的內容表面，避免背景穿透造成數字與進度條對比不足。錯誤狀態保留明確的橙／紅色語意與重試入口。

### 5. 保留既有行為並以狀態驅動呈現

視覺元件只接收既有 ViewModel 的 snapshot、refreshing、error、last refresh 與 visibility 狀態，不新增第二份 Provider 狀態。釘選控制繼續透過 `UsageMonitorViewModel` 更新，Popover 直接讀取相同的可見性狀態，避免跨入口不同步。

### 6. 分層驗證

先以 Swift 測試驗證 ViewModel 狀態轉換與釘選同步未回歸，再執行完整測試與 release build。建置後在 macOS 26 實機檢查淺色／深色外觀、主視窗側欄、Popover 高度與捲動、重新整理、錯誤重試、開啟主視窗與 Quit；特別確認材質效果不遮蔽額度文字。

## Risks / Trade-offs

- **[風險] Material 在不同 macOS 26 子版本或視窗背景下透明度不同** → 使用不透明內容表面承載額度資訊，並以淺／深色實機檢查對比。
- **[風險] Popover 內容增加品牌與 Provider 層級後高度變大** → 保留現有垂直捲動與緊湊版卡片，避免壓縮主要數字至不可讀。
- **[風險] 共用 token 牽涉 App target 與 Core target 邊界** → 視覺 token 僅放在 App target；Core 維持 UI 無關的 Domain／ViewModel。
- **[取捨] 導覽與卡片增加少量間距與材質層次** → 以額度可讀性優先，接受畫面比現有版本稍有更多視覺層次。

## Migration Plan

1. 新增共用視覺 token 與必要的 App target 元件。
2. 先更新主程式側欄、工具列、Provider 標頭與額度卡片。
3. 將相同元件語意套用至 Menu Bar Popover，保留緊湊密度與捲動。
4. 補充狀態、釘選同步與可存取性測試。
5. 執行 `swift test`、release build 與 macOS 26 實機驗收；若需回退，可獨立回退 App target 視覺層，不影響 Provider 與資料層。
