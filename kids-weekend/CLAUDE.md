# kids-weekend — 週末帶小孩去哪推薦工具

## 專案簡介
**週末帶小孩去哪玩**的決策工具。輸入今天天氣 / 季節 / 孩子年齡 / 出門範圍 → 推薦合適的景點 → 每筆有 Google Maps 一鍵導航。

## 為什麼做這個
每到週末家長煩惱「今天天氣這樣 / 這個季節 / 小孩這個年紀,該去哪?」。把好景點存起來分類好,下次不用每次重想。

## 主要使用者
- 北台灣家庭(雙北 / 桃園 / 宜蘭),孩子 0-6 歲
- v0 預設以新北土城為中心(範圍選項以此基準)

## 技術架構
- **單一 HTML**(`index.html`),純前端,離線可用
- **0 CDN**(隱私要求 — 字型用系統 fallback)
- localStorage key: `kidsWeekendState`
- Favicon: 🗺️
- 主色:橘色(#ff8c42)+ 海洋藍(#4a8fb8) — 跟其他子專案區隔

## 資料結構

### Wizard 4 問
1. **天氣**:晴 / 雨 / 不一定
2. **季節**:春 / 夏 / 秋 / 冬(系統會 hint 當下季節)
3. **孩子年齡**:0-2 / 2-3 / 3-6
4. **範圍**:住家附近 30 分(雙北)/ 1 小時車程(+ 桃園)/ 假日小旅行(+ 宜蘭)

### 景點 schema
```js
{
  id: 'sci-museum',
  name: '國立臺灣科學教育館',  // 用來 Google Maps 搜尋
  emoji: '🔬',
  area: '台北士林',                // 顯示用
  region: 'taipei',                 // 'taipei'|'newtaipei'|'taoyuan'|'yilan'
  indoor: true, outdoor: false,
  ages: ['2-3','3-6'],
  seasons: ['spring','summer','autumn','winter'],
  weathers: ['sunny','rainy'],
  types: ['室內','教育','文化'],
  note: '簡介好處',
  warning: '注意事項(可省略)',
}
```

### Google Maps 連結邏輯
```js
const url = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(name + ' ' + area)}`;
```
**不寫死座標**,改名字就好。手機點擊會直接開 Google Maps app。

## 功能

### 🏠 首頁 — Wizard 推薦
- 4 題答完 → 推薦清單
- 每筆景點:emoji + 名稱 + 地區 + 標籤(室內外、年齡、類型)+ 簡介 + 注意事項 + 我家評語(若有填) + Google Maps 按鈕

### 🔍 全景點瀏覽
- 5 個篩選:天氣 / 季節 / 年齡 / 類型 / 區域
- 不限的話顯示全部

### ❤️ 我的口袋
- 收藏景點(localStorage)
- 每個景點可寫「我家評語」(例如:「2025/3 去過,小孩很喜歡親水池」)

### 📖 關於 / 編輯資料
- 說明怎麼加新景點(改 PLACES array)
- 隱私說明

## 設計原則
- **景點資料寫死在 HTML**(只有 20 個,改起來容易;不像 care-handbook 有政府補助逐年變動的問題)
- **「我家評語」欄位空白**,讓使用者自己 localStorage 填(不替使用者瞎掰個人經驗)
- **0 CDN**:Google Maps 連結是使用者主動點擊,不算 CDN 違規(瀏覽器只在點擊時才連)
- **季節判斷**:Wizard Q2 系統會自動 hint 當下季節(月份判斷)

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/kids-weekend/`
- 純靜態,push main 自動部署

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md`(必讀 — 通用原則 + 0 CDN + emoji 相容性)

## 加新景點 SOP
1. 編輯 `index.html` 找 `const PLACES = [`
2. 複製一筆景點 object,改裡面內容
3. **每筆 object 後要有逗號**(尾逗號陷阱 — 整頁 blank)
4. push,30-60 秒後 GitHub Pages 自動更新
