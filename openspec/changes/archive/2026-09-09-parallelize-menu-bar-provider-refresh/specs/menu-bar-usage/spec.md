## ADDED Requirements

### Requirement: Menu Bar 多 Provider 並行刷新

Menu Bar SHALL 同時查詢所有需要更新且尚未在查詢中的已支援 Provider；每個 Provider SHALL 獨立完成、套用結果及呈現狀態，且不得因註冊順序或其他 Provider 的延遲與失敗而等待。

#### Scenario: 同時刷新多個過期 Provider

- **WHEN** Popover 開啟且兩個或更多 Provider 的快取皆過期或不存在
- **THEN** 系統同時啟動所有需要更新的 Provider 查詢，且整批等待時間由最慢的單一查詢主導，而非依序累加各查詢耗時

#### Scenario: 強制刷新所有 Provider

- **WHEN** 使用者按下 Menu Bar 全域刷新按鈕且沒有 Provider 正在查詢
- **THEN** 系統繞過所有已支援 Provider 的快取 TTL，並同時啟動其查詢

#### Scenario: 較快 Provider 先完成

- **WHEN** 並行查詢中的某個 Provider 早於其他 Provider 完成
- **THEN** 系統立即套用該 Provider 的最新快照、最後更新時間及完成狀態，不等待其他查詢結束

#### Scenario: 單一 Provider 查詢失敗

- **WHEN** 並行刷新中的某個 Provider 失敗而其他 Provider 成功
- **THEN** 系統立即呈現成功 Provider 的最新結果，只在失敗 Provider 顯示錯誤與重試狀態，並保留其既有資料但不得冒充為最新資料

#### Scenario: 同一 Provider 收到重複刷新請求

- **WHEN** 某個 Provider 尚在查詢中且系統再次收到包含該 Provider 的刷新請求
- **THEN** 系統不取消、不重啟且不建立該 Provider 的第二個查詢，而其他尚未查詢且需要更新的 Provider 仍可開始

#### Scenario: 並行刷新期間顯示既有資料

- **WHEN** 某個 Provider 已有快照且其新查詢尚未完成
- **THEN** Popover 保留該 Provider 的既有額度內容並同時顯示其刷新狀態，完成後再以新結果替換

#### Scenario: 全域與個別載入狀態

- **WHEN** 至少一個 Provider 尚在查詢中
- **THEN** Menu Bar 標頭的全域刷新按鈕持續顯示載入狀態並停用，而已完成的 Provider 區塊立即恢復自己的正常或錯誤狀態

#### Scenario: 所有 Provider 完成刷新

- **WHEN** 本批所有已啟動的 Provider 查詢皆已成功、失敗或取消
- **THEN** Menu Bar 標頭停止顯示全域載入狀態並恢復刷新按鈕

#### Scenario: Popover 刷新工作被取消

- **WHEN** Popover 生命週期在並行刷新完成前取消刷新工作
- **THEN** 系統將取消訊號傳遞至未完成的 Provider 子查詢、保留已完成且已套用的結果，且不為本次刷新建立脫離 Popover 的背景常駐工作

#### Scenario: 僅部分 Provider 需要更新

- **WHEN** 部分 Provider 快取仍有效而其他 Provider 快取過期或不存在
- **THEN** 系統立即呈現有效快取，只並行查詢需要更新且尚未在查詢中的 Provider
