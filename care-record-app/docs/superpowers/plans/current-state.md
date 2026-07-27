# care-record-app — Current State（2026-07-23）

## 現況
剛起步。設計 spec 已定案（`../specs/2026-07-23-family-app-design.md`），尚未寫任何 Flutter 程式。
下一步是 writing-plans 開實作計畫。

## 已完成里程碑
- [x] Brainstorming 完成：確認方向、硬約束、輸入/輸出/合併/安全全設計（2026-07-23）
- [x] 實測證據落地：OCR 61-67% 錯在關鍵詞（PP-OCRv6）、語音 small 模型日常詞近乎全對（faster-whisper）
- [x] Sub-project scaffold + index 卡片 + roadmap 索引 + 規則1 override 紀錄（2026-07-23）

## 進行中
- [ ] 使用者 review spec
- [ ] writing-plans 開實作計畫

## 優先序待決
### 🔴 高
- 實作計畫（plan）：拆出可驗證的里程碑（語音轉字 → 結構點選 → 儲存加密 → 匯出/匯入合併 → 醫生輸出 → 解鎖）

### 🟡 中
- whisper.cpp 端側實機準度驗證（spec §3.2 是桌面 faster-whisper，需在真機 small 量化模型再測一次）
- Flutter 專案 scaffold（pubspec / lib / ios / android）

### 🟢 低 / Nice-to-have
- 選配 ZIP 加密開關
- 醫生輸出的 HTML/PDF 版型

## 不做的事（明確 out of scope，見 spec §4.7）
- 手寫 OCR（實測 6 成、錯在臨床關鍵詞）
- 雲端 / 同步伺服器 / 帳號系統
- 複雜多人衝突合併引擎（v1 靠資料模型 union + 新者勝即可）
- 現場 KEY 密碼、每筆手動搬檔

## 下一次動工 Trigger
- 使用者 review spec 通過 → 進 writing-plans

## 快速進場指引
1. 動工前讀：本專案 CLAUDE.md + spec（權威設計依據）+ 母層 CLAUDE.md 白內障對比 frame
2. 改完驗：語音轉字 / 匯出匯入合併 / 生物辨識解鎖三條主線 smoke test
3. commit：英文、`feat:/fix:` 前綴，在 dev 分支

## 外部依賴
- 無雲端、無 API key。端側：whisper.cpp（bundle）、camera plugin、本地加密儲存。
