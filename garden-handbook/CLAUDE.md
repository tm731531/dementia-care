# garden-handbook — 家庭園藝手冊

## 專案簡介
一本**家庭可食 + 觀葉 + 觀花 + 根莖類種植手冊**,涵蓋陽台、窗邊、室內盆栽植物。每個 plant 一個 entry,統一 10-section 結構 + 5W1H 總覽 + 購物籃匯入功能。

**上位 mission**:repo 的「**讓整個家忙起來**」策略 —— 用植物讓家裡有生長中的東西、每天互動的動作、可採可賞的成果。對有失智長輩的家庭,種植是 behavior redirection 的有效工具。

## 技術架構
- **單一檔案**:`index.html`(所有內容 + JS + CSS,純靜態,~500KB)
- **純前端**:HTML + Vanilla CSS + Vanilla JS(no framework, no build)
- **離線可用**:所有資源 inline,字型系統 fallback
- **🔴 零外部 CDN 依賴**:不引用 Google Fonts / CDN / analytics,一切請求都來自使用者裝置
- **狀態**:localStorage(最愛 / 購物籃 / 規劃模式 / 照護級數 / memos),可匯出匯入 JSON
- **Favicon**:SVG inline emoji(🌱)

## 資料結構

### Plant Schema(強制,25 個 plants 都遵守)

```js
{
  id: 'xxx',             // 唯一 id(kebab-case)
  name: '中文名',
  emoji: '🌿',           // 首頁卡片圖(Unicode ≤ 10.0,相容性!)
  category: 'leafy' | 'herb' | 'fruit' | 'root' | 'foliage' | 'flower',
  meta: {
    difficulty: '低 ...',
    season: '...(人讀文字)',
    light: '...',
    location: '...',
    seasons: ['spring', 'summer', 'autumn', 'winter', 'all'],  // 粗分季節 tag
    bestStartMonths: [1..12],        // 最佳起手月份(規劃模式 filter 用)
    fit: {
      suitableFor: ['beginner', 'small_space', 'indoor', 'kid_friendly', 'low_maintenance'],
      warnings:    ['pet_toxic', 'strong_scent', 'pollen', 'needs_deep_pot', 'advanced', 'kid_caution'],
    },
    shoppingList: {
      propagation: { name, qty, source, priceMin, priceMax, freeFromKitchen? },
      containers:  [{ spec, qty, priceMin, priceMax }],
      soil:        { volumeL, type, priceMin, priceMax },
      fertilizer:  { product, shared:true, priceMin, priceMax },
      tools:       [...]
    }
  },
  sections: [
    { id, emoji, heading, html | byLevel },  // 10 section
  ]
}
```

### 10 Section 固定順序

| # | id | emoji | heading | 備註 |
|--|--|--|--|--|
| 1 | `why` | 💡 | 為什麼種 | 4-6 bullets |
| 2 | `obtain` | 🛒 | 取得方式 | **必含 Step 0 月份警告 + 新手包 3 步驟** |
| 3 | `pot-soil` | 🏺 | 盆器與土壤 | |
| 4 | `steps` | 🌳 | 種植步驟 | |
| 5 | `timing` | 📋 | 完整時程表 | **月份/節氣三級警告 + Day-by-Day SOP 表** |
| 6 | `fertilizer` | 🌾 | 施肥 | 好康多 1 號 預設 + 盆邊每 10cm = 3 粒 速查 |
| 7 | `harvest` | ✂️ / 🌱 | 採收 / 繁殖與分株(觀葉) | |
| 8 | `troubleshoot` | 🛡 | 失敗點與除錯 | |
| 9 | `dementia` | 🧠 | 失智照護 Notes | **byLevel: {mild, moderate, severe}** |
| 10 | `log` | 📓 | 實測紀錄 | |

### 完整 spec 文件
`/tmp/plant-entries/SPEC.md`(subagent 寫新 plant 時的參考)

## 關鍵功能(2026-04-23 狀態)

### 🎯 5 秒總覽(5W1H)
每個 plant 頁頂自動從 meta + sections 資料抽出 6 行摘要。
code: `renderPlantOverview(plant)` in index.html。

### 🎯 規劃模式
設定頁 toggle。開啟時 filter:
```js
showInPlanningMode(p) = bestStartMonths 落在本月+2 OR id 在 favorites[]
```

### 🛒 購物籃
- `STATE.cart = [plantIds]`
- `aggregateCart()` 依 source 分組 + 合併 soil/fertilizer/tools
- 匯出純文字清單(navigator.clipboard 或 fallback textarea)
- UI: `page-cart` page

### 🌾 施肥系統
- 預設固體緩釋肥(**好康多 1 號 NPK 14-11-13**)
- 用量公式:盆邊每 10 cm = 3 粒(3吋3/5吋5/7吋8/長方盆50cm=15 粒)
- 每 3 個月補一次
- 液肥降為進階折疊區

### 📅 24 節氣系統(通用知識頁)
- 關鍵 3 個記:**清明(4/4) / 立秋(8/7) / 立冬(11/7)**
- 每個 plant 的 Step 0 警告 table 用「月份 × 節氣雙軌」

### 🧠 失智照護級數連動
- 設定頁切換 mild/moderate/severe
- 每個 plant 的 dementia section 依當前級數 render
- `byLevel: { mild, moderate, severe }` 是 HTML 字串

## 目前 entries(25 個 plants)

| 類別 | Plants | 備註 |
|--|--|--|
| 🥬 葉菜(6) | 地瓜葉 · 韭菜 · 青江菜 · 蒜苗 · 茼蒿 · 豌豆苗 | 地瓜葉實測中(Day 8) |
| 🌿 香草(5) | 九層塔 · 薄荷 · 紫蘇 · 香菜 · 迷迭香 | |
| 🍅 果菜(4) | 小番茄 · 草莓 · 辣椒 · 小黃瓜 | |
| 🥕 根莖(4) | 薑 · 紅蘿蔔 · 白蘿蔔 · 洋蔥 | 薑只在春天種 |
| 🌳 觀葉(3) | 虎尾蘭 · 斑葉黃金葛 · 多肉 | |
| 🌸 花卉(3) | 桂花 · 向日葵 · 茉莉花 | 桂花/茉莉嗅覺記憶強 |

## 設計原則
- 文字繁體中文,第二人稱「你」不用「您」
- 大字、大行距(handbook 要能讀、能列印)
- 綠色 accent + 白底
- **可列印**(print stylesheet)
- 閱讀體驗 > 花俏 UI
- 母層 CLAUDE.md 的「零外部 CDN」絕對遵守

## 開發指引

### 加新 plant
1. 參考 `/tmp/plant-entries/SPEC.md` + 地瓜葉模板
2. 新 plant 加到 `PLANTS` array 末尾(加上 `// === X(類別)===` 註解)
3. meta **必填**:difficulty / season / light / location / seasons / bestStartMonths / fit / shoppingList
4. sections **必寫**:10 個(觀葉 plant 的 harvest 可改 propagation)
5. 確認 emoji 是 Unicode ≤ 10.0(見「踩過的坑」)

### 平行大量寫 plant(subagent pattern)
如果一次要加 5+ 個 plants:
- 寫一份 prompt spec(見 `/tmp/plant-entries/SPEC.md`)
- 派 N 個 general-purpose subagent(sonnet model)平行各寫一個
- 每個 subagent 寫到 `/tmp/plant-entries/new-<id>.js`
- 用 Python 整合腳本插入到 index.html 前 `];`
- 今天用這 pattern 一次上 9+5=14 個 plants,效率極高

### 修改既有 plant
直接編輯該 plant 的 object(grep `id: 'xxx'`),不要另開檔。

### 發佈前必跑的檢查
```bash
# 1. HTML parse
python3 -c "import html.parser;p=html.parser.HTMLParser();p.feed(open('index.html').read());print('OK')"

# 2. CDN leak check
grep -n -E 'https?://[^"]*\.(com|net|org|io)' index.html | grep -v 'tomting\|github\|data:'
# 應該沒輸出

# 3. Emoji 13.0+ 警告
grep -E "🫚|🫛|🫘|🪸|🪼|🪿|🫏|🪴|🪲|🪔|🪕|🪢" index.html
# 應該沒輸出
```

## 踩過的坑

### Emoji 相容性 — Unicode 14.0+ 會顯示豆腐框(□)
**原則:plant emoji 只用 Unicode ≤ 10.0(2017 前)**
- ✅ 安全:🍃 🌳 🍅 🍓 🌿 🌱 🥬 🌵 🌸 🥒 🍠 🌽 🥕 🥔 🐚 🐙 🦆 🐴 🌰 🥜
- ⚠️ 邊緣(13.0):🪴 🪲 🪐 🪑 🪔 🪕 🪢 — 新系統 OK,舊系統 fallback
- ❌ 避免(14.0+):🫚 🫛 🫘 🪸 🪼 🪿 🫏 🫎 🫏

**發佈新 plant entry 前必檢查**:
```bash
grep -E "^    emoji: '" index.html
```
用 https://emojipedia.org 查版本,或在最舊裝置實測。

### Object literal 尾逗號陷阱
往既有 array 批次插入新 entries,如果前一筆沒尾逗號 → 整個 script SyntaxError → 單檔 HTML 整頁空白。見母層 design-principles 的 brain file。

### 順序不能顛倒(新手包)
新手包告訴使用者順序 `盆土 → 下單種苗 → 立刻種`,順序顛倒 = 種苗到家沒地方插,在袋子裡悶死。已寫進全域 brain file。

### 照護者 handbook 的哲學(SOP-first)
照護者沒時間觀察植物,所以:
- 主推 SOP 時程表(照日期做,不照訊號做)
- 預設最安全方案(固體肥 vs 液肥)
- 記憶外包到 Google 行事曆 / 便利貼
- 失敗/禁忌條件要放顯眼處,不能當附註

全域 brain: `feedback_caregiver_handbook_sop_first.md`

## Domain Brain
從 `~/.claude/projects/-home-tom/memory/brain/` 選:
- `design-principles.md`(必讀 — 通用設計規則 + 新手包順序 + emoji 相容性)

## 檔案結構
```
garden-handbook/
  CLAUDE.md          # 本檔案(dev 指引)
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用者說明
  index.html         # 手冊主體(500KB,所有內容 + JS + CSS)
  docs/
    superpowers/
      plans/
        2026-04-22-current-state.md  # 早期狀態(歸檔)
        2026-04-23-current-state.md  # 本輪大改狀態
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/garden-handbook/`
- 純靜態,push main 自動部署(30-60 秒 build time)
- 部署狀態查:`gh api repos/tm731531/dementia-care/pages/builds/latest --jq '.status'`
