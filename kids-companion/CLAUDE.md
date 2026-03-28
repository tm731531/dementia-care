# 小朋友學習樂園 — 開發指引

## 專案簡介
3–6 歲兒童平板學習 app，寓教於樂，親子兩用。
所有功能集中在單一 `index.html`，無需伺服器或建置工具。

## 技術架構
- **單一檔案**：所有 HTML + CSS + JS 在 `index.html`，嚴禁分拆成多個 JS/CSS 檔
- **純前端**：無任何外部依賴，完全離線可用
- **語音**：Web Speech API，`zh-TW` / `en-US` 可切換，rate: 0.85
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
  completedToday: []        // 今日完成的活動 ID 陣列
}
```

## 頁面系統
- 每個頁面是 `<div class="page" id="page-xxx">`
- 切換用 `navigateTo('page-xxx')`
- 完成畫面用 `.complete-screen` + `.classList.add('show')`

## 年齡組差異（ageGroup）

依台灣幼兒園分班：`toddler`（幼幼班）、`small`（小班）、`middle`（中班）、`large`（大班）

| | toddler | small | middle | large |
|--|---------|-------|--------|-------|
| 選項數 | 2 | 2–3 | 3–4 | 4–6 |
| 語音 | 題目＋選項，重複一次 | 題目＋選項 | 題目＋hover | 只朗讀題目 |
| 答錯 | 直接高亮 | 高亮 | 第2次才高亮 | 只提示 |
| 字體 | 140px | 120px | 100px | 80px |
| 拖拉 | 否 | 否 | 是 | 是 |

## 視覺風格（溫暖自然）
- 主色：暖橘 `#E8724A`
- 背景：米色 `#FFF8F0`
- 輔色：草綠 `#98D8C8`、暖黃 `#FFB347`
- 卡片：白色 `#FFFFFF`，圓角 20px，陰影柔和
- 字型：圓體優先（Nunito、蘋方、微軟正黑體）

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

## 遊戲化規則
- 每完成一個活動：+1 星星，解鎖對應貼紙
- 集滿 5 顆星：全屏慶祝動畫
- 當天完成全部選的活動：開啟神秘寶箱
- 連續天數：每次進 app 比對 lastPlayDate
- 搖一搖（devicemotion）：隨機跳一個活動

## 使用時長提醒
- junior（3–4 歲）建議上限 30 分鐘，senior（5–6 歲）45 分鐘
- 剩 5 分鐘：頂部橫幅提醒；達上限：全屏休息畫面
- 不強制中斷，家長可點「繼續玩」延長 10 分鐘
- APP 物件加入 `sessionStart`、`todayPlayMinutes`、`todayDate`
- 設定面板可關閉提醒

## 資料轉移
- 設定面板提供「匯出進度」（下載 JSON）和「匯入進度」（上傳 JSON）
- 匯出格式包含 `version: 1` 與完整 APP 狀態
- 匯入前顯示確認提示，驗證 `version` 欄位後整包覆蓋 localStorage
- 完全前端操作，不傳送任何資料到外部

## 開發指引
- 修改一個活動時，不得影響其他活動（避免改 A 壞 B）
- 新活動必須接入 ageGroup 系統（junior/senior 分支）
- 新活動完成後必須呼叫 `completeActivity(activityId)` 累加星星
- 語音函式統一用 `speak(text)` 與 `speakSequence(texts)`
- 拖拉操作使用 pointer events（同時支援滑鼠與觸控）

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
