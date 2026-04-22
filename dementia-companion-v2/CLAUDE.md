# 陪伴小幫手 v2 — 開發指引

## 專案簡介
失智症照護互動 app 的 **v2 實驗版本**，跟 v1（`dementia-companion/`）並存。
核心轉換：從「10 格自己挑」→「今天一起做這個好嗎？一鍵開始」。
目標使用者：內向、疲累、不擅長做選擇的照護者。

## 技術架構
- **單一檔案**：`index.html`（~3,300 行）
- **純前端**：無任何外部依賴，完全離線可用
- **狀態**：全域 `APP` + localStorage（key: `dementiaAppV2`，跟 v1 的 `dementiaApp` 完全獨立）
- **Favicon**：SVG inline emoji（✨）

## 與 v1 的關鍵差異

| 項目 | v1 | v2 |
|--|--|--|
| 首頁 | 10 格遊戲卡讓使用者挑 | 1 張推薦卡「今天一起做這個好嗎？」|
| 難度設定 | 頂部滑桿常駐 | 收進 modal |
| 遊戲數量 | 15 個 | 15 個全部移植過來 |
| 陪伴指南 | 無 | 每遊戲 3 條 × 15 = **45 條可說的話** |
| 每日摘要 | 無 | 一鍵複製 LINE 可貼的今日紀錄 |
| localStorage | `dementiaApp` | `dementiaAppV2`（獨立）|

## 推薦邏輯（核心）
`recommendActivity()` 依以下維度挑今天該玩什麼：
1. **時段**（`getTimeSlot()`）：早上 6-10 / 中午 10-14 / 下午 14-18 / 晚上 18-22 / 深夜
   - 每時段有對應的活動類型偏好（早上做認知訓練、晚上做放鬆呼吸）
2. **最近玩過的避免重複**：`APP.recentActivities` 保留最近 3 個，推薦時排除
3. **當前難度**：與 v1 相同的 `APP.level` 1-8，過濾遊戲庫符合範圍
4. **隨機 fallback**：若上述全空就隨機一個

次要選項（換一個 / 我想自己選）字級縮小、無底色，降低選擇癱瘓。

## 陪伴指南資料結構
每個遊戲 `GAME_GUIDES[gameId]` 有 3 條：
- `onStart`：進入時 banner 顯示 5 秒，之後收成右上 💬 icon
- `onCorrect`：答對時可以對長輩說的話
- `onComplete`：完成時可以說的話

照一個固定格式：`情境 → 可以直接說的話`。

## 每日摘要（LINE 分享）
- 完成活動後累加到 `APP.todayLog`
- 一鍵複製按鈕產生 LINE 可貼格式：
  ```
  媽媽今天（4/22）的陪伴紀錄 💕
  ・認字：答對 8 題
  ・顏色辨識：答對 6 題
  共玩了 18 分鐘
  ```

## 全域狀態
```javascript
const APP = {
  level: 4,                    // 1-8 難度
  soundEnabled: true,
  recentActivities: [],        // 最近 3 個玩過的 id
  todayLog: [],                // 今天完成的 {id, stats, time}
  todayDate: '',
  sessionStart: null,
  totalMinutesToday: 0
}
```

## 遊戲模組（從 v1 移植，難度範圍相同）
翻牌配對 / 認字 / 找不同 / 時鐘認讀 / 連連看 / 顏色辨識 / 形狀配對 / 看圖認物 /
認數字 / 大小排序 / 物品分類 / 數數練習 / 情緒辨識 / 呼吸練習 / 身體部位（共 15 個）

## 設計原則（沿用 v1）
- 純黑背景 + 純白卡片，最大對比度（適合低視力長輩）
- 大字體（基礎 20px）、大按鈕（最小 64px）
- 答對給予正向鼓勵，答錯溫柔提示，不扣分不計時
- 觸控友善，最小點擊區域 48x48px
- 所有文字繁體中文
- 語音：Web Speech API，zh-TW，rate: 0.7，pitch: 1.1

## 推薦卡首頁特色
- 「今天一起做這個好嗎？」+ 大圖示 + 活動名稱
- 主 CTA：「好，開始 →」橘色大按鈕
- 次要：「換一個」「我想自己選」小字，降低選擇壓力
- 完整清單隱藏在「我想自己選」之後

## 開發指引
- 所有功能維持在單一 `index.html`
- 修改推薦邏輯時，記得跑幾次 `recommendActivity()` 看時段分布
- 新遊戲移植過來時，**必須同步補 `GAME_GUIDES[newId]` 三條陪伴句**（否則進遊戲頂部 banner 是空的）
- 遊戲共用 `speak()`、`playCorrectSound()` 等工具（從 v1 移植）
- 完成活動記得呼叫 `addToTodayLog(id, stats)`（否則每日摘要少算）

## 踩過的坑
- **推薦邏輯若 recentActivities 清空會總是推第一個** — 需加隨機備援
- **LINE 摘要若包含 emoji 貼不進某些舊版 LINE** — 僅用文字 + `・` 符號

## 檔案結構
```
dementia-companion-v2/
  CLAUDE.md          # 本檔案
  README.md          # 使用手冊 + 差異說明
  index.html         # 應用主體
  docs/
    superpowers/
      specs/         # 設計討論（2026-04-20-caregiver-support-design.md）
      plans/         # 實作計畫（2026-04-20-caregiver-support.md）
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/dementia-companion-v2/`
- 跟 v1 並存，使用者可對照比較

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md` — 通用設計規則
