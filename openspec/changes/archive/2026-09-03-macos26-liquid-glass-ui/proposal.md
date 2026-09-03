## Why

目前 AgentMeter 的 Desktop 主視窗與 Menu Bar Popover 已具備完整的額度功能，但兩個介面的視覺語言仍偏向一般 SwiftUI 控制項，主程式與選單列之間缺少一致的品牌與操作層次。使用者已確認以「選項 1：原生側欄」作為更新方向，因此需要將該方向正式化為 macOS 26 風格的 UI/UX 需求。

macOS 26 Tahoe 的 Liquid Glass 設計強調半透明材質、浮動導覽、圓角層次與內容優先；本需求將這些原則套用到 AgentMeter 的額度監控情境，讓狀態、額度數字與重置時間保持清晰，同時讓主程式與 Menu Bar Popover 看起來屬於同一個產品。

## What Changes

- 更新 Desktop 主視窗為「原生側欄」佈局：以品牌區、Provider 導覽、狀態區與額度卡片建立清楚的資訊層次。
- 更新 Menu Bar Popover，使其沿用主視窗的品牌徽章、Provider 分組、額度卡片、色彩語意與圓角規則。
- 將 Liquid Glass 視覺限制在工具列、側欄、Menu Bar Popover 與主要操作控制項；額度百分比、進度條與錯誤文字維持高對比與可讀性。
- 保留既有雙 Provider 額度、釘選同步、Smart Cache、重新整理、錯誤重試、主視窗開啟與完全退出行為。
- 補充 UI 狀態與跨視窗同步的驗收測試，以及建置後的 macOS 實機檢查。

## Capabilities

### New Capabilities

無。

### Modified Capabilities

- `usage-dashboard`：新增 macOS 26 風格的側欄、工具列、額度卡片與狀態視覺需求。
- `menu-bar-usage`：新增與主視窗一致的 Popover 視覺、Provider 分組、釘選同步呈現與操作層次需求。

## Impact

- 受影響程式碼：`Sources/AgentMeter/Views/Desktop/MainDesktopContainerView.swift`、`Sources/AgentMeter/Views/Desktop/UsageDashboardView.swift`、`Sources/AgentMeter/Views/Components/RateLimitCardView.swift`、`Sources/AgentMeter/Views/MenuBar/MenuBarPopoverView.swift`，以及必要的共用視覺元件或樣式。
- 受影響測試：Desktop 佈局與狀態呈現測試、Menu Bar Popover 分組與釘選同步測試、現有 Swift 測試回歸驗證。
- 不修改 Provider 查詢協定、快取資料格式、設定鍵值、額度計算、生命週期政策或既有品牌資產。
- 不新增外部套件；使用 SwiftUI／AppKit 原生材質、控制項與既有 SF Symbols。
