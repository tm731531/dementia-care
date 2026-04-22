# health-drinks — Current State（2026-04-22）

## 現況：21 款飲品，持續擴充中

Tom + 藥師朋友共用。資料是 hardcode 在 `docs/data/drinks.js`，新增時手動拍標籤 + AI 輸入。

## 已完成里程碑

### 資料錄入原則穩定
- [x] 21 款飲品全部有完整營養成分（包含微量元素）
- [x] 容量範圍 180-280 ml 都支援
- [x] 每筆有 `image` 欄位指向 `docs/images/<name>.jpg`
- [x] 拍標籤 → AI 輸入的工作流成熟（不用 scraper）

### UI 功能
- [x] 比較矩陣（左欄 sticky + 右欄橫捲）
- [x] 篩選器（搜尋 / 排序 / 類別）
- [x] 排行榜（熱量 / 糖分 / 蛋白質）
- [x] Chart.js 4 營養比例圖
- [x] 每 100ml 換算（除以 volume_ml）
- [x] 顏色標記（好/中/差）
- [x] SVG emoji favicon 🧃

### 歷史修復
- [x] 比較矩陣 flex 高度問題（改用固定 height）
- [x] 所有圖片路徑補回（原本都是 null）
- [x] CSS 重複定義清除
- [x] 雙向捲動同步（左欄滑動帶動右欄）

## 進行中 / 待觀察

- [ ] 朋友（藥師）累積飲品需求清單 → 按優先序補
- [ ] 某些飲品標籤拍不清楚（字太小 / 反光）
- [ ] 最新規的 1-3 歲 vs 3 歲以上奶粉比對是否顯示清楚

## 優先序待決

### 🟡 加新飲品 workflow
1. 拍標籤照片
2. AI 輸入每一項成分（微量元素不可省）
3. 圖片放進 `docs/images/`
4. 更新 `docs/data/drinks.js` 加一筆
5. commit → push → GH Pages 自動部署

**不可自動化的部分**：
- 標籤拍照品質要人工判斷
- 成分判讀有醫療意義，不全信 OCR
- 新增時必須對照實體確認

### 🟢 Nice-to-have
- 分類新增（例：新增「素食蛋白」類）
- 各飲品標籤原照存 `docs/images/label-<id>.jpg`（目前沒有）
- 同品牌不同口味顯示 group

## 不做的事
- 不做爬蟲（標籤拍不準 / 隱私 / 廠商不認帳）
- 不做購買連結（商業利益衝突）
- 不做評比「哪個最好」（每個人需求不同）

## 下一次動工 Trigger
- 朋友新回饋 → 加飲品 or 修顯示
- 自己家用需求變（小孩長大換奶粉配方）
- 廠商配方改版（標籤日期更新）

## 快速進場指引
1. 加新飲品 **必讀** `~/.claude/projects/-home-tom/memory/brain/health-drinks-data-entry.md`
2. 拍標籤時涵蓋所有成分面（正面 + 側面）
3. 微量元素**全部**填，標籤有什麼就填什麼（不自行省略）
4. `"image"` 欄位必須指向真實檔案
5. commit 訊息格式：`feat: 新增 [品牌][口味]` / `fix: 修正 [品牌] [項目]`

## 外部依賴
- Google Fonts CDN (Noto Sans TC)
- Chart.js 4 CDN
- （離線不可用——這是 health-drinks 跟其他專案的差異）

## 檔案結構提醒
資料分兩個檔案，要同步：
- `docs/data/drinks.js` → JS array（網頁讀這個）
- `docs/data/drinks.json` → 歷史爬蟲輸出，**未被網頁使用**，可忽略或刪
