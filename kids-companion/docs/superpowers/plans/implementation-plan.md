# kids-companion 實作計畫

## 專案背景
單一 `index.html` 的兒童平板學習 App（2–6 歲），完全離線，無外部依賴。
規格詳見：`CLAUDE.md`（開發指引）、`docs/design.md`（UI/UX 規格）。

## 核心設計哲學（2026-03-29 確立）

**自適應深度（Adaptive Depth）**：同一個活動，4 個年齡層拿到不同深度的內容。

> 類比：圓周率——幼幼班知道「圓圓的東西有個神奇的數字」，大班理解無理數。

| ageGroup | 深度層次 | 設計原則 |
|----------|----------|----------|
| toddler | 感知層 | 認識符號/聲音，大圖，純體驗，2選項 |
| small | 理解層 | 知道發生什麼，簡單因果，2-3選項 |
| middle | 分析層 | 為什麼，有推理，3-4選項 |
| large | 思辨層 | 道理、隱喻、情感、複雜選擇，4-6選項 |

這個哲學適用於**所有活動**，不只是故事。

---

## 錨點規範（所有任務必須遵守）
每個區塊用錨點包住：
```html
<!-- #SECTION:NAME --> ... <!-- #END:NAME -->
```
用 `grep -n "#SECTION:" index.html` 定位，**禁止整包讀取 index.html**。

---

## ✅ 已完成任務（Tasks 1–17）

| Task | 內容 | 狀態 |
|------|------|------|
| 1 | 基礎架構（HTML骨架、CSS、STATE、VOICE、NAV、GAMIFICATION、TIMER、SETTINGS） | ✅ |
| 2 | 認中文字（#SECTION:PAGE-CHINESE） | ✅ |
| 3 | 英文字母（#SECTION:PAGE-ABC） | ✅ |
| 4 | 數數（#SECTION:PAGE-COUNTING） | ✅ |
| 5 | 詞彙學習（#SECTION:PAGE-VOCAB） | ✅ |
| 6 | 顏色形狀（#SECTION:PAGE-COLORS-SHAPES） | ✅ |
| 7 | 音樂節奏（#SECTION:PAGE-MUSIC） | ✅ |
| 8 | 拼圖（#SECTION:PAGE-PUZZLE） | ✅ |
| 9 | 記憶翻牌（#SECTION:PAGE-MEMORY） | ✅ |
| 10 | 排序分類（#SECTION:PAGE-SORT） | ✅ |
| 11 | 互動繪本（#SECTION:PAGE-STORY）— 7個故事 | ✅ |
| 12 | 遊戲化系統（彩紙屑、貼紙書、神秘寶箱、連續天數） | ✅ |
| 13 | 整合收尾 | ✅ |
| 14 | 故事選擇題（#SECTION:PAGE-STORY-CHOICE）— 4年齡組，看故事答問題 | ✅ |
| 15 | 故事選擇題審查 | ✅ |
| 16 | 配音遊戲（#SECTION:PAGE-DUBBING）— MediaRecorder，完成後回放全部 | ✅ |
| 17 | 配音遊戲審查 | ✅ |
| 18 | 童謠（#SECTION:PAGE-RHYMES）— 5首童謠 + Web Audio 旋律，點開即播 | ✅ |
| 19 | 猜謎（#SECTION:PAGE-RIDDLES）— 4年齡組謎語 | ✅ |

---

## 🚧 進行中任務

### Task 20：探索 Tab 架構 + 天氣觀察站（進行中）

**目標**：新增第 5 個 Tab「🌍 探索」，放自然科學與人文活動。

**完成部分**：
- 🌍 探索 Tab 按鈕與 tab-explore 內容區塊
- 🌤️ 天氣觀察站（#SECTION:PAGE-WEATHER）
  - toddler：認識天氣符號（☀️🌧️⛅❄️），2選項
  - small：天氣 + 對應行為配對，3選項
  - middle：季節因果分析，4選項
  - large：水循環、溫室效應、氣候科學，4-6選項

---

## 📋 待完成任務

### Task 21：情境小劇場（人文 + 理財）

**錨點**：`#SECTION:PAGE-SOCIAL`

**核心哲學**：人文不只是待人處事，也包含生活中的理財概念。從感知（辨識情緒）到思辨（複雜社交決策 + 金錢觀念），跟著年齡加深。

**4 個年齡層設計**：

| Age | 深度 | 主題 |
|-----|------|------|
| toddler | 感知層 | 表情辨識（😊😢😡😨），認識基本情緒；認識硬幣外觀 |
| small | 理解層 | 簡單情境（朋友跌倒怎麼做？）；錢可以買東西的概念，區分「需要」vs「想要」 |
| middle | 分析層 | 換位思考（為什麼他難過？）；存錢概念，延遲滿足（存夠才能買玩具） |
| large | 思辨層 | 複雜社交情境（公平/分享/解決衝突）；預算概念（有限的錢怎麼分配？） |

**理財知識具體題目方向**：
- toddler：認識硬幣（1元/5元/10元外觀），「這是錢嗎？」
- small：「你有10元，買了3元的糖，還剩幾元？」簡單找零；需要 vs 想要
- middle：「小明有50元零用錢，想買80元的玩具，還差多少？要存幾天？」
- large：「你有100元，朋友說要一起買150元的東西，你該怎麼決定？」含機會成本概念

**SOCIAL_DATA 結構**：
```js
var SOCIAL_DATA = {
  toddler: [ { type: 'emotion', emoji:'😊', ... }, { type: 'money', ... } ],
  small:   [ { type: 'situation', ... }, { type: 'money', ... } ],
  middle:  [ { type: 'empathy', ... }, { type: 'money', ... } ],
  large:   [ { type: 'dilemma', ... }, { type: 'budget', ... } ]
};
```

---

### Task 22：互動繪本自適應深度重構

**目標**：把 STORIES 的 `pages` 從單一陣列改為 4 個年齡層版本。

**現況**：每本故事只有一個版本（通常是 large 深度）。

**目標結構**：
```js
{
  id: 'three-kingdoms',
  category: 'classic',   // 'classic' | 'tale'
  pages: {
    toddler: [/* 3頁：認識角色，大圖大字 */],
    small:   [/* 4頁：知道故事大概 */],
    middle:  [/* 6頁：理解策略衝突 */],
    large:   [/* 8頁：完整情節+道理 */]
  }
}
```

**書架分區（方案A）**：
- 童話故事區：農夫和鬼怪、三隻小豬、烏鴉喝水、龜兔賽跑、北風與太陽、小熊找蜂蜜
- 🌟 經典故事區：三國演義、西遊記（加星星標示，但所有年齡都能看）

**renderStoryPage 改動**：
```js
// 舊
var page = story.pages[pageIdx];
// 新
var agePages = Array.isArray(story.pages) ? story.pages : (story.pages[APP.ageGroup] || story.pages.small);
var page = agePages[pageIdx];
```

注意：向後兼容，沒有 pagesByAge 的故事繼續用原本 pages 陣列。

---

### Task 23：故事選擇題擴充

**目標**：每個年齡層有 3–5 個故事輪替（目前只有 1 個）。

**故事方向**（受文化部動畫繪本啟發）：
- 自然主題：小雨滴的旅行（水循環）、小種子的故事（植物生長）
- 生活主題：阿嬤家（代際情感）、等一下的故事（延遲滿足）
- 品格主題：雨傘和好朋友（分享）、說對不起（道歉修復關係）

---

### Task 24：童謠擴充 + 循環播放

**目標**：
- 新增 3-5 首童謠（目前 5 首）
- 旋律可循環（播完一遍再來一遍，直到手動停止）
- 考慮加入簡單的動作提示（「拍拍手」「跺跺腳」）

---

## 執行順序

```
Task 20（完成天氣觀察站）
→ Task 21（情境小劇場）
→ Task 22（互動繪本重構）
→ Task 23（故事選擇題擴充）
→ Task 24（童謠擴充）
→ 整合測試
```

每個任務完成後：spec reviewer → quality reviewer → 再進下一個。

---

## 活動清單（含新增）

| 活動 ID | 名稱 | Tab | 狀態 |
|---------|------|-----|------|
| page-chinese | 認中文字 | 📚 語言 | ✅ |
| page-abc | 英文字母 | 📚 語言 | ✅ |
| page-counting | 數數 | 📚 語言 | ✅ |
| page-vocab | 詞彙學習 | 📚 語言 | ✅ |
| page-colors-shapes | 顏色形狀 | 🎨 創作 | ✅ |
| page-music | 音樂節奏 | 🎨 創作 | ✅ |
| page-puzzle | 拼圖 | 🧠 思維 | ✅ |
| page-memory | 記憶翻牌 | 🧠 思維 | ✅ |
| page-sort | 排序分類 | 🧠 思維 | ✅ |
| page-story | 互動繪本 | 📖 故事 | ✅（待重構） |
| page-rhymes | 童謠 | 📖 故事 | ✅ |
| page-riddles | 猜謎 | 📖 故事 | ✅ |
| page-story-choice | 故事選擇題 | 📖 故事 | ✅（待擴充） |
| page-dubbing | 配音遊戲 | 📖 故事 | ✅ |
| page-weather | 天氣觀察站 | 🌍 探索 | 🚧 |
| page-social | 情境小劇場 | 🌍 探索 | 📋 待做 |
