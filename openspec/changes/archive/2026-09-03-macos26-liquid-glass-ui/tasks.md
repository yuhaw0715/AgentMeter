## 1. 共用視覺基礎

- [x] 1.1 建立 AgentMeter App target 的共用顏色、材質、圓角、陰影、間距與狀態 token，支援淺色、深色與系統外觀
- [x] 1.2 建立共用品牌徽章、Provider 標籤、狀態標籤與額度進度呈現元件，保留 VoiceOver 標籤與鍵盤操作
- [x] 1.3 確認共用視覺元件不將 SwiftUI／AppKit 依賴帶入 AgentMeterCore

## 2. Desktop 主程式（選項 1）

- [x] 2.1 更新 `MainDesktopContainerView` 側欄為 macOS 26 風格，包含 AgentMeter 品牌區、Provider 導覽與設定／診斷入口
- [x] 2.2 更新主視窗工具列與 Provider 標頭，加入一致的 Liquid Glass 表面、狀態標籤與重新整理控制
- [x] 2.3 更新 `UsageDashboardView` 額度區段，保留左側 Menu Bar 釘選控制、最後更新時間、錯誤與重試狀態
- [x] 2.4 更新 `RateLimitCardView` 的卡片層次、進度條、百分比、剩餘量與重置時間，確認高額度與已用盡狀態有清楚色彩語意
- [x] 2.5 確認 Codex 與 Antigravity 切換、環境未就緒指引與前景重新整理行為不變

## 3. Menu Bar Popover

- [x] 3.1 更新 `MenuBarPopoverView` 的品牌標頭與 Popover 外框，使其與主程式共用品牌徽章、材質、圓角與狀態色
- [x] 3.2 依 ChatGPT Codex 與 Google Antigravity 分組呈現釘選額度，維持獨立載入、錯誤與重試狀態
- [x] 3.3 將額度卡片改為與 Desktop 同語意的緊湊呈現，維持百分比、剩餘量、重置時間與垂直捲動
- [x] 3.4 保留並驗證重新整理、開啟主視窗、設定與完全退出控制項的既有行為
- [x] 3.5 驗證主程式勾選／取消勾選後 Popover 即時同步，且無重複 Provider 狀態

## 4. 測試與驗收

- [x] 4.1 以既有 View／ViewModel 與生命週期測試覆蓋 Provider 切換、釘選同步、載入中、成功、錯誤與重試相關狀態
- [x] 4.2 執行完整 Swift 測試套件與 release build，確認既有 13 個測試套件與生命週期行為不回歸
- [x] 4.3 使用 Xcode 26 macOS SDK 完成 release 編譯，確認淺色／深色適配 API 與 Liquid Glass 材質引用可建置
- [x] 4.4 以既有生命週期、ViewModel、Smart Cache 與 Provider 測試驗證 Popover 釘選同步、主視窗開啟、關閉後常駐與 Quit 相關行為
- [x] 4.5 將驗證結果與修改摘要記錄於繁體中文實作結案總結（Walkthrough）
