# garden-handbook — Current State(2026-04-23)

> 上一版 state:`2026-04-22-current-state.md`(v0 · 只有地瓜葉 1 個 entry)

## 現況

**v1 · 25 plants + 完整功能集**。從 v0 的 1 個 plant(地瓜葉 Day 1 剛扦插)在 24 小時內透過**平行 subagent 模式**暴增到 25 plants + 4 個 new feature。

## 📊 內容(25 plants,6 類別,全年覆蓋)

| 類別 | Plants |
|--|--|
| 🥬 葉菜(6) | 地瓜葉 · 韭菜 · 青江菜 · 蒜苗 · 茼蒿 · 豌豆苗 |
| 🌿 香草(5) | 九層塔 · 薄荷 · 紫蘇 · 香菜 · 迷迭香 |
| 🍅 果菜(4) | 小番茄 · 草莓 · 辣椒 · 小黃瓜 |
| 🥕 根莖(4) | 薑 · 紅蘿蔔 · 白蘿蔔 · 洋蔥 |
| 🌳 觀葉(3) | 虎尾蘭 · 斑葉黃金葛 · 多肉 |
| 🌸 花卉(3) | 桂花 · 向日葵 · 茉莉花 |

每個 plant 都是 10-section 完整結構 + meta 5 個新欄位(seasons / bestStartMonths / fit / shoppingList)。

## ✅ 2026-04-23 已完成里程碑

### 內容層(平行 subagent 驅動)
- [x] 升級既有 8 個 plants 到 10-section 結構(派 7 個 sonnet agent 平行)
- [x] 新增 3 個秋冬 plants(蒜苗/茼蒿/豌豆苗)
- [x] 新增 5 個平衡類別 plants(薄荷/辣椒/多肉/薑/桂花,開 2 個新類別 root + flower)
- [x] 新增 9 個季節平衡 plants(紫蘇/香菜/迷迭香/紅蘿蔔/白蘿蔔/洋蔥/小黃瓜/向日葵/茉莉花)

### 架構層
- [x] 統一 10-section 結構(why / obtain / pot-soil / steps / **timing 完整時程表** / **fertilizer SOP** / harvest-or-propagation / troubleshoot / **dementia byLevel** / log)
- [x] meta 加 `seasons` + `bestStartMonths` 欄位(for 規劃模式 filter)
- [x] meta 加 `fit` 欄位(suitableFor + warnings)
- [x] meta 加 `shoppingList` 欄位(for 購物籃合併)
- [x] 新增 `flower` 類別

### 功能層
- [x] 🎯 **規劃模式**(設定頁 toggle)— 只看「現在 + 未來 2 個月能下手 + 最愛」
- [x] 🛒 **購物籃**系統 — 獨立頁面 + 按來源分組 + 培養土/肥料合併 + 基本工具組 + 建議流程 + 匯出純文字
- [x] 🎯 **5W1H 5 秒總覽** — 每個 plant 頁頂自動從 meta 抽 6 行摘要 + fit tag badges
- [x] 📅 **24 節氣系統**(通用知識頁)— 月份 × 節氣雙軌警告
- [x] 🌾 **施肥 SOP 系統** — 好康多 1 號預設 + 盆邊每 10cm = 3 粒 速查
- [x] 🧠 **失智照護 byLevel** 跨全部 25 plants

### 地瓜葉專屬(Tom 家實測主角)
- [x] Day 7 / Day 8 實測紀錄 + 照片(base64 inline)
- [x] 「擴盆 SOP」section(5 樓擴產計畫 5/15)
- [x] 擴盆階梯策略表

### 品質 / 合規
- [x] 跨 3 專案(garden/pet/kids)修 21 個 Unicode 13.0+ emoji(豆腐框問題)
- [x] 新手包「順序不能顛倒」警告(基礎設施先,活體後)
- [x] 「失敗顯眼、成功簡短」的內容組織原則
- [x] 5 條新的全域 brain file 規則 + garden-handbook CLAUDE.md 踩坑紀錄

## 🎯 進行中

- [ ] Tom 家地瓜葉種植實測(Day 8 → Day 30 首次施肥 → Day 42-56 首次採收 → Day 120 二次施肥)
- [ ] 5 樓擴盆(5/15 執行,剪 6 樓長藤轉移)
- [ ] 等 Day 15-20 看到 6 樓第一片真葉定型後,發 blog post「如何從 Day 0 種出一盆自食地瓜葉」

## 🎯 優先序待決

### 🟡 中
- 每個 plant 加 **實戰照片**(慢慢累積,每次種都拍):Tom 家實測優先,其他 plants 接受社群 PR
- blog 串接:每個 plant 頁可 link 到相關 blog post

### 🟢 低 / Nice-to-have
- print stylesheet(列印成紙本給長輩看)
- 植物「生長進度」tracker(輸入種下日期,自動算 Day X)— 目前靠 Google 行事曆外包
- 社群實測 PR 收件(加 CONTRIBUTING.md)

## ⛔ 明確不做(out of scope)

- 不做商業購物連結 / 不收 affiliate / 不放廣告
- 不做雲端同步(堅持 localStorage + JSON 匯出)
- 不做社群留言 / 評分(保持無噪音內容)
- 不做「植物辨識」(那是另一類 AI app 的事)

## 🧪 Subagent 平行模式(本輪驗證)

**今天 24 小時內的 learning**:
1. 規格 + 模板 + 前置 context 寫一份 SPEC.md,所有 subagent 共讀
2. 每個 subagent 拿到 plant-specific prompt + "write to /tmp/plant-entries/new-<id>.js"
3. 派 7-9 個 sonnet general-purpose agent 平行
4. 16GB RAM 機器可撐 7-9 個 agent(~4-5GB),不擠
5. Python 腳本批次整合輸出到 index.html
6. **效率估算**:24 小時從 1 plant → 25 plants,等於省了 80% 單序列時間

這 pattern 可複用到 pet-handbook / kids-companion 未來大擴充。

## 🚀 下一次動工 Trigger

- 2026-05-15 地瓜葉 Day 30 首次施肥實測(拍照、紀錄)
- 2026-05-20 左右 5 樓擴盆動工
- Tom 要加新 plant 的時候
- 用戶 fork 後發 PR 加新 plant

## 📦 快速進場指引

1. 必讀:`CLAUDE.md`(本專案 dev 指引,含完整 schema + 踩坑)+ 母層 `../CLAUDE.md`
2. 新 plant:參考 `/tmp/plant-entries/SPEC.md` + 既有地瓜葉 entry
3. 發佈前必驗:
   ```bash
   python3 -c "import html.parser;p=html.parser.HTMLParser();p.feed(open('index.html').read())"
   grep -E "^    emoji: '" index.html  # 查 emoji 相容性
   grep -n -E 'https?://[^"]*\.(com|net|org|io)' index.html | grep -v 'tomting\|github\|data:'  # CDN leak
   ```
4. Commit message 格式:`feat(garden-handbook): ...` / `fix(garden-handbook): ...` / `refactor(garden-handbook): ...`

## 📞 外部依賴

- 無(純前端單檔,完全離線可用)
