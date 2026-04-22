# 小朋友學習樂園 — 開發指引

## 專案簡介
1-6 歲兒童平板學習 app，寓教於樂，親子兩用，中英文可切換。
所有功能集中在單一 `index.html`，無需伺服器或建置工具，完全離線可用。

**設計哲學（核心）**：自適應深度（Adaptive Depth）—— 同一內容，不同年齡，不同深度。
4 個年齡層都有各自版本（toddler/small/middle/large），從感知層 → 思辨層。
詳見 `~/.claude/projects/-home-tom/memory/project_kids_companion_philosophy.md`。

## 技術架構
- **單一檔案**：所有 HTML + CSS + JS 在 `index.html`（~15,000 行，gzipped 約 6.6 MB），嚴禁分拆
- **純前端**：無任何外部依賴，完全離線可用
- **圖片**：所有照片以 base64 data URL inline 存在 `IMG` 物件（檔案尾端）
- **語音**：Web Speech API，`zh-TW` / `en-US` 可切換，rate: 0.85，pitch: 1.2
- **狀態**：全域 `APP` 物件 + localStorage（key: `kidsCompanion`）
- **Favicon**：SVG data URL inline emoji（🦊）

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
  completedToday: [],       // 今日完成的活動 ID
  companionTitle: '陪伴者',
  sessionStart: null,
  todayPlayMinutes: 0,
  todayDate: '',
  soundEnabled: true,
  timerEnabled: true,
  chestOpenedToday: false,
  favorites: []             // [{id, icon, label}] — 長按活動卡拖進最愛區
}
```

## 年齡組差異（ageGroup）— Adaptive Depth

| | toddler（幼幼班 1-2 歲） | small（小班 3-4 歲） | middle（中班 4-5 歲） | large（大班 5-6 歲） |
|--|--|--|--|--|
| 選項數 | 2 | 2-3 | 3-4 | 4-6 |
| 語音 | 題目＋選項重複 | 題目＋選項 | 題目＋hover | 只朗讀題目 |
| 答錯 | 直接高亮正確答案 | 高亮正確答案 | 第 2 次才高亮 | 只提示再試 |
| 目標字字體 | 140px | 120px | 100px | 80px |
| 拖拉操作 | 否（點選） | 否 | 是 | 是 |
| 單局輪數 | 3-4 | 4-5 | 5-6 | 6-8 |

**深度原則**：每個活動的 4 層必須給出不同深度內容，不只是難度高低：
- toddler：感知層（認識形狀/聲音/顏色）
- small：理解層（知道發生了什麼）
- middle：分析層（為什麼會這樣）
- large：思辨層（道理/隱喻/選擇）

## 活動列表（tab × 活動）

### 📚 語言 tab（4）
| id | 名稱 | 備註 |
|--|--|--|
| page-chinese | 認中文字 🐼 | configs 4 層齊備 |
| page-abc | 英文字母 🦜 | toddler 只看 emoji / large 大小寫 |
| page-counting | 數數 🐘 | maxNum 3→5→10→20，large 加法 |
| page-vocab | 詞彙學習 🦁 | VOCAB_DATA[ageGroup] |

### 🎨 創作 tab（4）
| id | 名稱 | 備註 |
|--|--|--|
| page-colors-shapes | 顏色形狀 🦋 | Color 3→4→6→8 / Shape 2→3→4→6 |
| page-music | 音樂節奏 🐸 | mode: free→follow1→follow2→simon |
| page-draw | 塗鴉畫板 ✏️ | 調色盤 5/6/8/10 色，middle/large 有主題 |
| page-sound-match | 聲音配對 🎧 | speechSynthesis 發動物叫聲，2/3/4/6 選 |

### 🧩 動腦 tab（3）
| id | 名稱 | 備註 |
|--|--|--|
| page-puzzle | 拼圖 🐢 | 2x2→2x2→2x3→3x3 |
| page-memory | 記憶翻牌 🐬 | pairs 3→3→5→6 |
| page-sort | 排序分類 🐝 | size→size→mixed→category |

### 📖 故事 tab（5）
| id | 名稱 | 備註 |
|--|--|--|
| page-story | 互動繪本 🦉 | story.pages[ageGroup] |
| page-rhymes | 童謠 🎵 | **按 ageGroups 過濾**，large 有古詩＋詩人＋小故事 |
| page-riddles | 猜謎 🐾 | 題數 8→9→11→13 |
| page-story-choice | 故事選擇題 📖 | STORY_QUIZ_DATA[ageGroup] |
| page-dubbing | 配音遊戲 🎤 | 2→3→4→5 場景，hint 強度遞減 |

### 🔭 探索 tab（9）
| id | 名稱 | 備註 |
|--|--|--|
| page-weather | 天氣觀察站 🌤️ | toddler 4 題 → large 8 題深入推理（水循環/溫室效應）|
| page-social | 情境小劇場 🤝 | toddler 情緒→small 情境→middle/large 複雜情景 |
| page-money | 理財小學堂 💰 | 3 階段內容遞進 |
| page-zoo | 動物園 🦁 | **9 類別 × ~15-20 隻 = 166 隻，全部真圖**，有搜尋 |
| page-food | 食物原型 🍎 | 6 類 × ~18 種 = 108 種，全部真圖，有搜尋 |
| page-math | 數學樂園 🔢 | maxNum 3→5→10→20，large 加法 |
| page-plate | 餐盤設計 🍽️ | 3 模式：free / task / grid |
| page-scene | 場景佈置 🎨 | itemCount 8→10→12→12 |
| page-story-build | 故事拼組 📖 | free mode → structured → ending column |

### 動物園類別（9）
africa(20) / grassland(20) / home(20) / taiwan(20) / birds(20) / ocean(20) / insects(16) / polar(15) / dinosaurs(15)

## 首頁結構（非 tab 內容）
- 頂列：🦊 角色 + 「午安」問候 + ⭐⭐⭐⭐⭐ stars + ⚙️ 設定 + 🎴 貼紙簿
- **最愛區塊** `#favorites-section`：長按活動卡拖進來（最多 6 個），點卡片直接導航。長按 600ms 進編輯模式（顯示 × 按鈕，卡片 wiggle）
- Tab bar（5 個）
- Tab 內容（每個 tab 的 `.activity-grid`）
- 今日學習紀錄 `#today-progress`：tag 形式顯示 `ACTIVITY_LABELS[id]`

## 設定面板（⚙️）
年齡組 / 聲音 / 更換角色 / **語言切換**（2026-04 從 header 搬進來）

## 視覺風格（溫暖自然）
- 主色：暖橘 `#E8724A`
- 背景：米白 `#FFF8F0`
- 卡片：白色 `#FFFFFF`，圓角 20px
- **禁用高飽和霓虹色**；**禁止快速閃爍**（< 3 次/秒）
- `.activity-grid`：手機 2 欄 / 平板（≥720px）3 欄，`max-width:900px` 置中，孤兒卡用 `grid-column:2/3` 放中間欄等寬對齊

## 圖示原則
- 小動物優先：所有活動卡片用動物/主題 emoji
- **`.activity-card .icon` 是 CSS 合約**：新增活動卡務必用 `<span class="icon">` 不可自創 class（踩過坑，詳見下方）
- 活動對應：見活動列表

## 遊戲化規則
- 每完成一個活動：+1 星星，解鎖對應貼紙
- 集滿 5 顆星：全屏慶祝動畫（紙屑）
- 當天完成 3 個以上活動：開啟神秘寶箱
- 搖一搖（devicemotion, acc > 15）：隨機跳一個活動
- **已移除**：praise buttons（好讚/稱讚按鈕）2026-04 全部拿掉

## 使用時長提醒
- toddler/small：上限 30 分；middle/large：45 分
- 剩 5 分鐘：頂部橫幅
- 達上限：全屏休息畫面，可延長 10 分鐘

## 兒童友善硬性規定
- **配色**：禁用純紅/純綠高飽和；背景不用純白
- **聲音**：禁突然大音量；錯誤提示用低沉溫和音
- **動畫**：慶祝用緩緩飄落紙屑，不用爆炸式
- **語氣**：答錯說「哎呀，再試一次！」不說「錯了！」
- **內容**：禁骷髏、怪物、黑暗場景

## 語音規則
- 發音前必須 `speechSynthesis.cancel()` 再 `speak()`，避免聲音疊加
- 選項間隔 600ms；超過 15 字的句子拆兩次朗讀（中間停頓 400ms）
- 朗讀前清除 emoji 和標點符號
- 統一用 `speak(text)` 與 `speakSequence(texts)`

## 開發指引
- 修改一個活動時，不得影響其他活動
- 新活動必須接入 ageGroup 四層分支
- 新活動完成後呼叫 `completeActivity(activityId)` 累加星星
- **新增活動時同步更新 `ACTIVITY_LABELS` map**（否則今日學習紀錄會顯示 raw page id 如「page-zoo」）
- 拖拉操作用 pointer events（同時支援滑鼠 + 觸控）

## 踩過的坑（lesson learned）

### 1. Object literal 尾逗號陷阱（2026-04-21 整頁 blank）
批次插入新 entries 進既有 object literal 時，若前一筆沒有結尾逗號 → 整個 script SyntaxError → 頁面空白。
**Rule**：插入資料前一律先檢查前一筆是否 `',` 結尾，沒有就補上。base64 圖很長肉眼看不出斷點。

### 2. `.activity-card .icon` CSS 合約（2026-04-21 修）
活動卡的 `<span>` 必須用 `class="icon"`，不能用 `activity-icon` 等自創 class。後者沒有對應 CSS → silent fallback 到 inline 預設字體大小 16px，跟其他 48px 卡片視覺落差超明顯但不會噴錯。

### 3. ACTIVITY_LABELS 漏加 → 今日學習紀錄顯示 raw id
新增活動時若忘記加入 `ACTIVITY_LABELS` map，完成後「今日學習紀錄」tag 會顯示 `page-zoo` 而不是「動物園 🦁」。
**Rule**：新活動要 grep `ACTIVITY_LABELS\|PAGE_ICONS` 等 map name 做 audit。

### 4. 動物 id 跨類別重複（orca、puffin）
orca 原本在 ocean，puffin 原本在 birds。我新加極地類時又放一次，造成搜尋「虎鯨」出現 2 筆結果 + IMG 互相覆蓋。
**Rule**：新增動物前 grep `id:'xxx'` 確認 id 唯一。

## 錨點規範（維護性關鍵）

`index.html` 是 15,000 行單檔。**沒有錨點，任何修改都需要讀取整個檔案**，耗時又容易出錯。
有了錨點，精準定位只需 1 秒：

```bash
grep -n "#SECTION:PAGE-ZOO" index.html
# → 2864:<div class="page" id="page-zoo"><!-- #SECTION:PAGE-ZOO -->
```

**硬性規定**：每個新增到 `index.html` 的區塊必須包在錨點內。沒有錨點的新增 = 技術債，必須拒絕。

### 錨點格式
HTML/CSS：`<!-- #SECTION:名稱 -->` ... `<!-- #END:名稱 -->`
JS：`// <!-- #SECTION:名稱 -->` ... `// <!-- #END:名稱 -->`

### 強制錨點清單（節選，實際檔案隨時會增長）
| 錨點 | 位置 |
|--|--|
| `#SECTION:CSS` | 所有樣式 |
| `#SECTION:STATE` | APP 物件 + localStorage |
| `#SECTION:VOICE` | speak / speakSequence |
| `#SECTION:NAV` | navigateTo + 頁面切換 |
| `#SECTION:GAMIFICATION` | 星星/貼紙/連續/慶祝動畫 |
| `#SECTION:TIMER` | 使用時長計時 |
| `#SECTION:SETTINGS` | 設定面板 HTML |
| `#SECTION:PAGE-HOME` | 首頁 HTML |
| `#SECTION:PAGE-XXX` | 每個活動頁面（23 個）|
| `#SECTION:IMAGES-CURRENCY` (×2) | 硬幣圖 |
| `#SECTION:IMAGES-ZOO` | 動物園照片（166 張）|
| `#SECTION:IMAGES-FOOD` | 食物照片（108 張）|

### 圖片資料禁忌
圖片 base64 資料**全部集中在檔案末尾**（`</script>` 前）：
```bash
grep -n "#SECTION:IMAGES" index.html
# 禁止讀取 #SECTION:IMAGES-* 的實際資料區塊 — 每行含數十 KB base64
```
新增圖片時直接在對應 `Object.assign(IMG, {...})` 區塊末尾附加 key-value，勿整塊讀取。

### 標準維護工作流程
```bash
grep -n "#SECTION:PAGE-ZOO" index.html      # 找起始
grep -n "#END:PAGE-ZOO" index.html           # 找結束
# 只讀該範圍,而非 15000 行
```

## Domain Brain
- `~/.claude/projects/-home-tom/memory/project_kids_companion_philosophy.md` — 自適應深度哲學
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md` — 通用設計規則（含本專案踩坑）

## 檔案結構
```
kids-companion/
  CLAUDE.md          # 本檔案（開發指引）
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用手冊（給家長）
  index.html         # 應用程式主體（單一檔案 ~15k 行）
  docs/
    design.md        # UI/UX 設計規格
    features.md      # 功能規格書
    superpowers/
      specs/         # 設計討論稿
      plans/         # 實作計畫（歷史記錄）
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/kids-companion/`
- 推 main 後 CDN 約 30-60s 更新
- 單檔 9 MB（gzipped 6.6 MB），首次載入約 1-5s 視網路而定
