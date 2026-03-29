# 小朋友學習樂園 — 開發指引

## 專案簡介
2–6 歲兒童平板學習 app，寓教於樂，親子兩用，中英文可切換。
所有功能集中在單一 `index.html`，無需伺服器或建置工具，完全離線可用。

## 技術架構
- **單一檔案**：所有 HTML + CSS + JS 在 `index.html`，嚴禁分拆成多個 JS/CSS 檔
- **純前端**：無任何外部依賴，完全離線可用
- **語音**：Web Speech API，`zh-TW` / `en-US` 可切換，rate: 0.85，pitch: 1.2
- **狀態**：全域 `APP` 物件 + localStorage（key: `kidsCompanion`）

## 全域狀態結構
```javascript
const APP = {
  language: 'zh',           // 'zh' | 'en'
  ageGroup: 'small',        // 'toddler'|'small'|'middle'|'large'
  character: '🦊',          // 選定的角色 emoji
  stars: 0,                 // 今日累積星星
  stickers: [],             // 已解鎖的貼紙 ID 陣列
  streak: 0,                // 連續天數
  lastPlayDate: '',         // 'YYYY-MM-DD'
  completedToday: [],       // 今日完成的活動 ID 陣列
  companionTitle: '陪伴者', // 給讚時顯示的稱謂
  sessionStart: null,       // Date.now()，每次開啟 app 設定
  todayPlayMinutes: 0,      // 今日累積分鐘數
  todayDate: ''             // 'YYYY-MM-DD'，用於每日重置
}
// localStorage key: 'kidsCompanion'
```

## 頁面系統
- 每個頁面是 `<div class="page" id="page-xxx">`
- 切換用 `navigateTo('page-xxx')`
- 完成畫面用 `.complete-screen` + `.classList.add('show')`

## 年齡組差異（ageGroup）

依台灣幼兒園分班：

| | toddler（幼幼班） | small（小班） | middle（中班） | large（大班） |
|--|------------------|--------------|---------------|--------------|
| 選項數 | 2 | 2–3 | 3–4 | 4–6 |
| 語音 | 題目＋選項，重複一次 | 題目＋選項 | 題目＋hover念 | 只朗讀題目 |
| 答錯 | 直接高亮正確答案 | 高亮正確答案 | 第2次才高亮 | 只提示再試 |
| 字體（目標字） | 140px | 120px | 100px | 80px |
| 拖拉操作 | 否（點選） | 否 | 是 | 是 |
| 單局輪數 | 4 | 5 | 6 | 8 |

## 圖示原則
- **小動物優先**：所有圖示、獎勵、引導元素優先使用動物 emoji
- **清晰可辨**：圖示 48px 以上必須一眼辨識
- 各活動對應動物：認中文字🐼、英文字母🦜、數數🐘、詞彙🦁、顏色形狀🦋、音樂🐸、拼圖🐢、記憶翻牌🐬、排序分類🐝、互動繪本🦉
- 慶祝用🐥、休息提醒用🦉、神秘寶箱用🐿️
- 禁用蟲類、恐怖動物、細節複雜圖形

## 視覺風格（溫暖自然）
- 主色：暖橘 `#E8724A`
- 背景：米白 `#FFF8F0`
- 輔色：草綠 `#98D8C8`、暖黃 `#FFB347`
- 卡片：白色 `#FFFFFF`，圓角 20px，陰影柔和
- 字型：Nunito → 蘋方 → 微軟正黑體（圓體優先）
- **禁用高飽和霓虹色**；**禁止快速閃爍**（< 3次/秒）

## 活動列表

| 活動 ID | 名稱 | Tab |
|---------|------|-----|
| page-chinese | 認中文字 | 📚 語言 |
| page-abc | 英文字母 | 📚 語言 |
| page-counting | 數數 | 📚 語言 |
| page-vocab | 詞彙學習 | 📚 語言 |
| page-colors-shapes | 顏色形狀 | 🎨 創作 |
| page-music | 音樂節奏 | 🎨 創作 |
| page-puzzle | 拼圖 | 🧠 思維 |
| page-memory | 記憶翻牌 | 🧠 思維 |
| page-sort | 排序分類 | 🧠 思維 |
| page-story | 互動繪本 | 📖 故事 |

## 陪伴者類型
app 的陪伴者包含：家長、保母、幼教員、教保員、幼兒園老師、兒童醫生。
- 設定面板提供稱謂選擇：爸爸 / 媽媽 / 老師 / 阿姨 / 醫師 / 陪伴者
- 給讚按鈕顯示「[稱謂] 說你好棒！❤️」
- 介面必須自說明（2 步以內可開始使用，適合任何陪伴者）
- 無需帳號，適合診間臨時評估

## 遊戲化規則
- 每完成一個活動：+1 星星，解鎖對應貼紙
- 集滿 5 顆星：全屏慶祝動畫（五彩紙屑，非爆炸式）
- 當天完成 3 個以上活動：開啟神秘寶箱（今日小知識）
- 連續天數：每次進 app 比對 lastPlayDate
- 搖一搖（devicemotion，加速度 > 15）：隨機跳一個活動

## 使用時長提醒
- toddler/small：建議上限 30 分鐘；middle/large：45 分鐘
- 剩 5 分鐘：頂部橫幅提醒（溫和語氣）
- 達上限：全屏休息畫面，家長可點「繼續玩」延長 10 分鐘
- 不強制中斷，設定面板可關閉提醒

## 資料轉移
- 設定面板「匯出進度」→ 下載 `kids-companion-backup-YYYYMMDD.json`
- 設定面板「匯入進度」→ 上傳 JSON，驗證 `version` 欄位，確認後整包覆蓋
- 完全前端操作，不傳送任何資料到外部

## 兒童友善硬性規定
- **配色**：禁用純紅 `#FF0000`、純綠 `#00FF00` 等高飽和色；背景不用純白
- **聲音**：禁止突然大音量；錯誤提示用低沉溫和音，不用尖銳蜂鳴
- **動畫**：慶祝用緩緩飄落紙屑，不用爆炸式；禁止每秒超過 3 次閃爍
- **語氣**：答錯說「哎呀，再試一次！」不說「錯了！」「不對！」
- **內容**：禁用骷髏、怪物、黑暗場景

## 語音規則
- 發音前必須 `speechSynthesis.cancel()` 再 `speak()`，避免聲音疊加
- 選項間隔 600ms；超過 15 字的句子拆兩次朗讀（中間停頓 400ms）
- 朗讀前清除 emoji 和標點符號
- 語音函式統一用 `speak(text)` 與 `speakSequence(texts)`

## 開發指引
- 修改一個活動時，不得影響其他活動（避免改 A 壞 B）
- 新活動必須接入 ageGroup 系統（四個等級分支）
- 新活動完成後必須呼叫 `completeActivity(activityId)` 累加星星
- 拖拉操作使用 pointer events（同時支援滑鼠與觸控）

## 錨點規範（維護性關鍵）

### 為什麼錨點是必要的

`index.html` 是 6800+ 行的單一大檔案，且會持續增長。**沒有錨點，任何修改都需要讀取整個檔案**，既耗時又容易出錯。有了錨點，精準定位只需 1 秒：

```bash
grep -n "#SECTION:PAGE-MEMORY" index.html
# → 3241:<!-- #SECTION:PAGE-MEMORY -->
```

這讓你直接 Read 第 3241–3350 行（110 行），而不是 6800 行。

### 硬性規定：所有新增內容必須有錨點

**每一個新增到 `index.html` 的程式碼區塊，必須包在錨點內。無例外。** 這包括：
- 新活動頁面（HTML）
- 新活動的 JS 邏輯
- 新增的 CSS 區塊（若內聯加入）
- 任何工具函式群組

沒有錨點的新增程式碼 = 不可維護的技術債，**必須拒絕合併**。

### 錨點格式

HTML/CSS 區塊：
```html
<!-- #SECTION:名稱 -->
...內容...
<!-- #END:名稱 -->
```

JS 區塊（在 `<script>` 標籤內）：
```javascript
// <!-- #SECTION:名稱 -->
...內容...
// <!-- #END:名稱 -->
```

### 命名規範

| 類型 | 格式 | 範例 |
|------|------|------|
| 活動頁面 HTML | `PAGE-{活動名稱}` | `PAGE-WEATHER`, `PAGE-SOCIAL` |
| 活動頁面 JS | `PAGE-{活動名稱}-JS` | `PAGE-WEATHER-JS`, `PAGE-SOCIAL-JS` |
| 系統區塊 | 固定名稱（見下表） | `CSS`, `STATE`, `VOICE` |

### 強制錨點清單

| 錨點名稱 | 位置 |
|----------|------|
| `#SECTION:CSS` | 所有樣式 |
| `#SECTION:STATE` | APP 物件 + localStorage 存取函式 |
| `#SECTION:VOICE` | speak() + speakSequence() |
| `#SECTION:NAV` | navigateTo() + 頁面切換邏輯 |
| `#SECTION:GAMIFICATION` | 星星、貼紙、連續天數、慶祝動畫 |
| `#SECTION:TIMER` | 使用時長計時與提醒 |
| `#SECTION:SETTINGS` | 設定面板 HTML |
| `#SECTION:SETTINGS-JS` | 設定面板 JS 邏輯 |
| `#SECTION:PAGE-HOME` | 首頁 HTML |
| `#SECTION:PAGE-CHINESE` | 認中文字活動 |
| `#SECTION:PAGE-ABC` | 英文字母活動 |
| `#SECTION:PAGE-COUNTING` | 數數活動 |
| `#SECTION:PAGE-VOCAB` | 詞彙學習活動 |
| `#SECTION:PAGE-COLORS` | 顏色形狀活動 |
| `#SECTION:PAGE-MUSIC` | 音樂節奏活動 |
| `#SECTION:PAGE-PUZZLE` | 拼圖活動 |
| `#SECTION:PAGE-MEMORY` | 記憶翻牌活動 |
| `#SECTION:PAGE-SORT` | 排序分類活動 |
| `#SECTION:PAGE-STORY` | 互動繪本活動 |
| `#SECTION:PAGE-ZOO` | 動物園活動 |
| `#SECTION:PAGE-FOOD` | 食物原型活動 |
| `#SECTION:PAGE-FOOD-DATA` | 食物資料（6 類 110 種） |
| `#SECTION:PAGE-FOOD-JS` | 食物活動 JS 邏輯 |
| `#SECTION:PAGE-MATH` | 數學樂園活動 |
| `#SECTION:PAGE-MATH-JS` | 數學樂園 JS 邏輯（算術 + 時鐘） |
| `#SECTION:PAGE-PLATE` | 餐盤設計活動 |
| `#SECTION:PAGE-PLATE-JS` | 餐盤設計 JS 邏輯 |
| `#SECTION:IMAGES-CURRENCY` (×2) | 硬幣圖片（檔案頭部空宣告 + 檔案末尾實際資料） |
| `#SECTION:IMAGES-ZOO` | 動物園照片（120 張，緊接 IMAGES-CURRENCY 之後，檔案末尾） |
| `#SECTION:IMAGES-FOOD` | 食物照片（108 張，緊接 IMAGES-ZOO 之後，檔案末尾） |

新增活動時，在此表格補充對應行。

### 圖片資料說明（重要：避免 token 浪費）

圖片 base64 資料**全部集中在檔案末尾**（`</script>` 前）：

```bash
# 找到目前實際行數（隨開發增長，永遠用 grep 查，不要記死行數）
grep -n "#SECTION:IMAGES" index.html
# 範例輸出：
# 2007:// <!-- #SECTION:IMAGES-CURRENCY -->   ← 空宣告（只有3行，可安全讀取）
# 10368:// <!-- #SECTION:IMAGES-CURRENCY -->  ← 實際硬幣圖資料
# 10376:// <!-- #SECTION:IMAGES-ZOO -->       ← 實際動物圖資料（120張）
```

**禁止讀取 `#SECTION:IMAGES-*` 的實際資料區塊**（每行含數十 KB base64，讀一行 = 數萬 token）。
新增圖片時，直接在對應 `Object.assign(IMG, {...})` 區塊末尾附加 key-value，勿整塊讀取。

### 標準維護工作流程

```bash
# Step 1: 找目標區塊的起始行
grep -n "#SECTION:PAGE-SOCIAL" index.html
# → 1453:<!-- #SECTION:PAGE-SOCIAL -->

# Step 2: 找區塊結束行
grep -n "#END:PAGE-SOCIAL" index.html
# → 1510:<!-- #END:PAGE-SOCIAL -->

# Step 3: 只讀取該範圍（58 行，而非 6800 行）
# Read lines 1453–1510

# 列出所有錨點，快速瀏覽結構
grep -n "#SECTION:" index.html
```

**禁止整包讀取 `index.html`。** 任何修改前必須先定位錨點。

## 檔案結構
```
kids-companion/
  CLAUDE.md          # 開發指引（本檔案）
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用手冊（給家長）
  index.html         # 應用程式主體
  docs/
    design.md        # UI/UX 設計規格
    features.md      # 功能規格書
    superpowers/
      specs/         # 設計討論稿
      plans/         # 實作計畫
```
