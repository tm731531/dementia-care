# garden-handbook — Current State(2026-04-22)

## 現況
**剛起步 · v0 發布**。從 `_template` scaffold 出來,第一個 entry 是地瓜葉(Tom 家實測中,枝條剛種下 1 週)。

## 已完成里程碑
- [x] 2026-04-22:scaffold 完成,index.html 包含地瓜葉第一個 entry
- [x] 2026-04-22:加進母層 landing + monorepo roadmap 索引

## 進行中
- [ ] Tom 家地瓜葉種植實測(Day 7,等首次採收需 4-6 週)
- [ ] 媽媽的澆花 ritual 導入(等 5 樓那批穩定後啟動)

## 優先序待決
### 🔴 高
- 第一個 entry(地瓜葉)內容由 Tom 確認後更新

### 🟡 中
- 加第二個 entry(建議候選:空心菜、九層塔 — 都是新手友善 + 可持續採收)
- 新增「貢獻指南」section,讓 fork 者知道怎麼加自己家實測的植物

### 🟢 低 / Nice-to-have
- 加 print stylesheet(讓 handbook 可以列印成紙本,對老人家友善)
- 加搜尋(當 entries > 5 時)
- 加跨 entry 的「難度 / 季節 / 光線」三維過濾器

## 不做的事(明確 out of scope)
- 不做 growth tracker(那是另一個專案的事 — 可能是「陽台種植日誌」獨立專案)
- 不做購物連結 / 不收錄商業產品
- 不做社群功能(留言、評分等)
- 不做不可食植物(觀賞植物、多肉、花卉 — 本手冊聚焦**可食**)

## 下一次動工 Trigger
- Tom 家地瓜葉採收第一波(預計 2026-05 下旬 ~ 6 月初)— 會補「採收實測紀錄」到地瓜葉 entry
- Tom 要新增第二個 entry 的時候
- 用戶 fork 後發 PR 加新植物

## 快速進場指引
1. 動工前必讀:`CLAUDE.md`(本專案)+ 母層 `../CLAUDE.md`(共用設計原則)
2. 改完要驗:`grep -n -E 'https?://[^"]*\.(com|net|org|io)' index.html | grep -v 'tomting\|github\|data:'` 應無輸出(CDN 檢查)
3. Commit 訊息格式:`feat(garden): 新增 X 植物 entry` / `docs(garden): 補地瓜葉採收紀錄` / `fix(garden): ...`

## 外部依賴
- 無(純前端單檔,完全離線可用)
