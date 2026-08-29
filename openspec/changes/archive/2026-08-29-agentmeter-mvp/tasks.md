# 實作檢查清單：AgentMeter MVP

## 1. 專案初始化與基礎架構

- [x] 1.1 初始化 macOS 26+ SwiftUI 專案結構與編譯設定
- [x] 1.2 設定 App Sandbox 權限、Info.plist 屬性與 Asset Catalog 應用程式圖示

## 2. 核心領域與 Provider 抽象層

- [x] 2.1 定義額度領域資料模型（`RateLimitItem`、`RateLimitSnapshot`、`ProviderType`、`EnvironmentStatus`）
- [x] 2.2 實作 `AgentProvider` 抽象協定與 Provider 註冊管理介面

## 3. Codex Provider 實作

- [x] 3.1 實作 `CodexEnvironmentDetector` 用於 CLI PATH 偵測與登入驗證狀態檢查
- [x] 3.2 實作 `CodexProcessManager` 用於啟動 `codex app-server` 與標準 stdio 之 JSON-RPC 2.0 通訊
- [x] 3.3 實作 `CodexRateLimitProvider` 負責發送 `account/rateLimits/read` 並動態正規化額度項目

## 4. 應用程式狀態與快取機制

- [x] 4.1 實作 `SmartCacheManager` 支援自訂 TTL、新鮮度檢查與過期判定
- [x] 4.2 實作 `SettingsManager` 處理本機 UserDefaults 偏好、額度勾選/排序與 `SMAppService` 開機自動啟動
- [x] 4.3 實作 `UsageMonitorViewModel` 統籌前景主動重新整理、載入中狀態與錯誤重試邏輯

## 5. Desktop 桌面端使用者介面

- [x] 5.1 實作主視窗容器與 Sidebar 導航列（ChatGPT Codex、Settings、Diagnostics）
- [x] 5.2 實作 `UsageDashboardView` 包含額度卡片、百分比進度條、重置時間戳記與重新整理/重試控制項
- [x] 5.3 實作 `EnvironmentSetupView` 提供未安裝 CLI 或未登入狀態之操作指引
- [x] 5.4 實作 `DiagnosticsView` 呈現環境各項狀態並提供敏感資訊遮蔽的「複製診斷報告」功能
- [x] 5.5 實作 `SettingsView` 支援額度顯示切換/排序、TTL 設定、自訂執行檔路徑與恢復預設值

## 6. Menu Bar 選單列介面

- [x] 6.1 實作 Menu Bar 狀態列項目，僅顯示圖示不帶文字
- [x] 6.2 實作 `MenuBarPopoverView` 提供秒開快取檢視、可捲動之自訂額度清單與手動重新整理按鈕
- [x] 6.3 實作視窗焦點管理（「Open AgentMeter…」）、視窗關閉常駐與乾淨退出邏輯

## 7. 在地化與格式化

- [x] 7.1 建立繁體中文（`zh-Hant`）與英文雙語字串資源表與在地化設定
- [x] 7.2 實作語系感知之日期時間格式化工具，自動遵循系統時區與 12/24 小時制偏好

## 8. 發布與文件

- [x] 8.1 建立 Homebrew Cask Formula，包含受限範圍之隔離屬性處理與 `--zap` 清理邏輯
- [x] 8.2 撰寫 README.md 提供一行式 Homebrew 安裝指令、使用教學與 MIT 授權條款說明
