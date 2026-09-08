## ADDED Requirements

### Requirement: 重置券介面文案本地化

系統 SHALL 為 Desktop 與 Menu Bar 的重置券標題、可用張數、券編號、明細不足、無到期資訊、資訊未提供及已到期等待刷新狀態提供繁體中文與英文文案，並沿用現有即時語言切換行為。

#### Scenario: 切換重置券介面語言
- **WHEN** 使用者在繁體中文、英文或系統預設語言間切換
- **THEN** 重置券區段所有使用者可見文案立即切換至對應語言，券到期時間維持 `yyyy-MM-dd HH:mm:ss` 格式
