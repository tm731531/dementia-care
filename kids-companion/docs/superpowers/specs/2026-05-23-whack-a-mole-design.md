# 打地鼠 動作偵測活動 設計文件

## 目標

新增「打地鼠」活動（`page-whack-mole`），讓 1-6 歲兒童透過**裝置攝影機體感**或**手指觸控**玩經典打地鼠遊戲。同時新建第 6 個 tab「💪 動一動」作為日後動作類遊戲的擴充容器（freeze dance / Simon Says / 模仿動作）。

這是 kids-companion 第一個動作偵測活動，主要動機:
- 讓女兒玩平板時也能「動起來」，避免久坐
- Tom 陪玩時自己也能跟著動，照護者 wellbeing 設計
- 為未來動作類擴充打底

## 不做（YAGNI 排除）

- 校準/baseline capture（只測有地鼠的 cell 已經夠準）
- 連擊倍數
- 最高分排行
- 音效（visual + Web Speech 就夠;之後想加再用 Web Audio API inline 生成）
- 雙人模式
- 限時模式、闖關制（已比較過，達標制最適合 kids-companion 一貫風格）
- 移動目標（蝴蝶/氣球）— pixel-diff 偵測難度高
- MediaPipe / TensorFlow.js / PoseNet（違反 monorepo 零 CDN 規則）

## 核心設計決策

| 決策 | 選擇 | 理由 |
|---|---|---|
| 動作範圍 | toddler/small 用手揮 / middle/large 全身動 | adaptive depth 自然延伸 |
| 視覺主題 | emoji 🐹 經典打地鼠 | 0 新資產、輕量、動畫順 |
| 結束條件 | 達標制（無時限） | 無壓力，符合 kids-companion |
| 擺放位置 | 新建 tab「💪 動一動」 | 預留未來動作類擴充 |
| 偵測技術 | 純 JS pixel-diff（無外部 lib） | 強制：CLAUDE.md 零 CDN 依賴 |
| Fallback | 自動切手指模式 | 沒相機/被拒/toddler 都能玩 |

## 架構

```
進入 page-whack-mole
   ↓
[首次進入]
   Modal「準備好玩打地鼠了嗎?」
      ├─ 📷 用相機體感玩（middle/large 預設）
      └─ 👆 用手指點（toddler/small 預設）
   ↓ 選後存 APP.whackMode + localStorage
   ↓
[體感模式]                       [手指模式]
   getUserMedia → video → canvas    純 DOM 互動
   每 frame pixel-diff 偵測 cell    pointerdown 在 mole 上 = 打中
   ↓                                ↓
   ┌─────── 共用 onHit(idx) ──────┐
   ↓
   打中 → 計分 + 動畫 + 檢查達標
   ↓
   達標 → 慶祝 → completeActivity → 星 + 貼紙
```

## 進入流程 + 相機授權 UX

### 首次進入

畫面中央 modal，兩個大按鈕（48×48px 以上）：
- **📷 用相機體感玩**（middle/large 預設高亮）
- **👆 用手指點**（toddler/small 預設高亮）

下方小字隱私說明：「相機畫面只在你裝置上，完全不會傳出去」

### 選了體感模式

```js
navigator.mediaDevices.getUserMedia({ video: { width: 320, height: 240 } })
  .then(stream => /* start game */)
  .catch(() => /* fallback to tap mode + show 友善訊息 */)
```

- 成功 → 進遊戲畫面，右上「🔴 LIVE」常駐
- 拒絕/沒硬體 → 切手指模式，顯示「相機沒打開，先用手指點玩好嗎?」
- 任何錯誤 → 同樣 fallback，不能讓 activity 死掉

### 進入後 UI（體感模式）

```
左上: ❌ 結束          右上: 🔴 LIVE
                       │
        [半透明 video feed 鋪滿背景, opacity 0.35, 水平鏡像]
                       │
              中上: 🐹 已打: 7 / 12
                       │
        ┌──────────────────────────────┐
        │   [洞]    [洞]    [洞]        │  ← 遊戲區 (grid)
        │           🐹                  │     地鼠 emoji 在前景
        │   [洞]    [洞]    [洞]        │     彈跳動畫
        └──────────────────────────────┘
                       │
        下方: 📏 大約一個手臂的距離（提示）
```

### 進入後 UI（手指模式）

同上，但**沒有 video 背景**、**沒有 🔴 LIVE**、**沒有距離提示**。背景用既有米白 `#FFF8F0`。

### 設定面板（`#SECTION:SETTINGS`）

在「年齡組 / 聲音 / 角色 / 語言」之後加：

```
🐹 打地鼠玩法: [📷 體感] [👆 手指]
```

不分年齡（任何 age 都可以選任一模式）。

## 體感偵測演算法

### 主要 loop（`requestAnimationFrame`, ~30fps）

```js
// 1. video → 隱藏 canvas (160×120 低解析度，效能極快)
ctx.drawImage(video, 0, 0, 160, 120)
const frame = ctx.getImageData(0, 0, 160, 120)

// 2. 對「目前有地鼠的 cell」算 pixel-diff
for (const hole of activeHoles) {
  const cellPixels = extractCell(frame, hole.gridX, hole.gridY)
  const diff = grayscaleDiff(cellPixels, prevCellPixels[hole.idx])
  const changedRatio = countChanged(diff, THRESHOLD_PIXEL) / cellPixels.length

  // 3. 變化 > 8% + 不在 cooldown → 打中
  if (changedRatio > THRESHOLD_CELL && !hole.cooldown) {
    onHit(hole.idx)
    hole.cooldown = 600  // ms
  }
}

prevFrame = frame
```

### 關鍵常數（檔案頂部，方便調）

```js
const WHACK_TUNING = {
  THRESHOLD_PIXEL: 25,    // 灰階差 > 25 算 changed (out of 255)
  THRESHOLD_CELL: 0.08,   // cell 內 > 8% pixels changed 算動了
  COOLDOWN_MS: 600,       // 打中後 cell 冷卻
  CANVAS_W: 160,
  CANVAS_H: 120,
  DEBUG_OVERLAY: false,   // 開啟顯示每格 diff% 即時數值
}
```

### 為什麼這樣設計

- **只測有地鼠的 cell**: 砍掉 90% 誤判（背景晃動/光線變化在 idle cell 都不影響）
- **160×120 低解析度**: 19200 pixels × 30fps = ~580k ops/sec，平板輕鬆跑
- **不做 calibration**: MVP 簡單就好，若 Tom 廚房光線測下來誤判太多再加
- **DEBUG_OVERLAY**: 開發/調參用，正式關掉

## 地鼠生命週期

| 階段 | 視覺 | 持續時間 |
|---|---|---|
| 待機 | ⚫ 黑色橢圓洞口 | — |
| 冒出 | 🐹 scale 0→1 with bounce easing (200ms) | — |
| 停留 | 輕微上下浮動 idle animation | toddler 4s / small 3s / middle 2.5s / large 2s |
| 打中 | 🐹 scale 1→1.3→0 (300ms) + 💨 塵土 emoji | 立刻 +1 |
| 超時 | 抖兩下 → 縮回洞 | 不扣分 |

### 出現邏輯

- 隨機間隔 1.0–1.8 秒生成下一隻
- 隨機挑「目前空著」的洞，**避免連兩次同一洞**
- middle: 20% 機率同時冒 2 隻
- large: 30% 機率 2 隻，10% 機率 3 隻
- 畫面上活著的地鼠不超過該 age 的同時上限

## 年齡分級（Adaptive Depth）

| | toddler (1-2) | small (3-4) | middle (4-5) | large (5-6) |
|---|---|---|---|---|
| 預設模式 | 👆 手指 | 👆 手指 | 📷 體感(手揮) | 📷 體感(全身) |
| 洞數 | 2 | 3 | 6 (2×3) | 9 (3×3) |
| 達標 | 5 | 8 | 12 | 20 |
| 地鼠停留 | 4s | 3s | 2.5s | 2s |
| 同時冒幾隻 | 1 | 1 | 1-2 | 1-3 |
| 鏡頭距離提示 | 不顯示 | 60cm | 100cm | 1.8m |

### 深度差異不只是數值

- **toddler（感知層）**: 大格大地鼠，任何點到都算打中，每隻冒 4 秒慢慢給她反應
- **small（理解層）**: 開始有「瞄準」概念，3 格但仍寬鬆
- **middle（分析層）**: 同時 2 隻挑戰分配注意力，開始體感
- **large（思辨層）**: 9 格 + 同時 3 隻 + 全身動，類運動量

## 接系統

### `ACTIVITY_LABELS` 新增

```js
'page-whack-mole': { zh: '打地鼠 🐹', en: 'Whack-a-mole 🐹' }
```

（漏加會讓「今日學習紀錄」顯示 raw id `page-whack-mole`，踩過坑）

### 貼紙獎勵

新增貼紙 `fitness-master`:「💪 體能達人」
- 達標當天首次完成 → 解鎖
- 進「🎴 貼紙簿」展示

### 完成定義

達標瞬間 → `completeActivity('page-whack-mole')`:
- 當天首次:+1 星 + 解鎖貼紙 + 紙屑慶祝
- 當天再玩:慶祝動畫照常，但不重複給星（沿用既有規則）

### Web Speech

- 進入頁面: **不**主動講（避免吵）
- 達標: `speak(i18n.whackComplete.replace('{N}', target))`，朗讀前先 `cancel()`

### i18n 字串

| key | zh | en |
|---|---|---|
| `whackTitle` | 打地鼠 | Whack-a-mole |
| `whackModeMotion` | 用相機體感玩 | Play with camera |
| `whackModeTap` | 用手指點 | Tap to play |
| `whackPrivacy` | 相機畫面只在你裝置上，完全不會傳出去 | Camera stays on your device, never uploaded |
| `whackLive` | 🔴 LIVE | 🔴 LIVE |
| `whackProgress` | 已打:{X} / {N} | Hit: {X} / {N} |
| `whackArmDist` | 📏 大約一個手臂的距離 | 📏 About arm's length |
| `whackComplete` | 太厲害!打到了 {N} 隻! | Awesome! You got {N}! |
| `whackPlayAgain` | 再玩一次 | Play again |
| `whackBackHome` | 回首頁 | Back home |
| `whackCameraDenied` | 相機沒打開，先用手指點玩好嗎? | Camera off — tap to play instead? |

## 結構變動

### Tab bar 5 → 6

```
現有: 📚 語言 / 🎨 創作 / 🧩 動腦 / 📖 故事 / 🔭 探索
變成: 📚 語言 / 🎨 創作 / 🧩 動腦 / 📖 故事 / 🔭 探索 / 💪 動一動
```

放最後 = 最少干擾既有 muscle memory。

### Tab bar overflow 處理

手機 6 個 tab 橫向會擠。對策:`.tab-bar` 加 `overflow-x: auto` + 無滾動條樣式（`scrollbar-width: none`）。

### 錨點規劃（CLAUDE.md 強制要求）

| 錨點 | 內容 | 預估行數 |
|---|---|---|
| `#SECTION:PAGE-WHACK-MOLE` | 整頁 HTML（modal + game area + HUD） | ~150 |
| `#SECTION:WHACK-LOGIC` | JS:pixel-diff / mole 生命週期 / hit handler / mode toggle | ~400 |
| `#SECTION:WHACK-STYLES`（子註解於 `#SECTION:CSS`） | mole 動畫 / video overlay / LIVE 指示 / hole 樣式 | ~80 |
| `#SECTION:STATE`（修改） | 加 `whackMode: null` | +1 |
| `#SECTION:SETTINGS`（修改） | 加打地鼠玩法 toggle | +10 |
| `#SECTION:NAV`（修改） | 離開 page-whack-mole 時 stop tracks | +5 |
| `ACTIVITY_LABELS`（修改） | 加 entry | +1 |
| `STICKERS`（修改） | 加 fitness-master 貼紙 | +1 |
| Landing tab bar + tab 內容（修改） | 加 💪 動一動 tab + 活動卡片 | +20 |

**總新增 ~700 行**，9MB 主檔案影響可忽略。

### CSS 合約檢查（踩坑預防）

- 新卡片用 `<span class="icon">💪</span>` ✅（不能用 `whack-icon` 等自創 class — 踩過坑 #2）
- 新 tab 單一卡片時 `.activity-grid` 要 `place-content: center`（踩過坑 #4 — 寬螢幕禁靠左）
- 插 `ACTIVITY_LABELS` 時檢查前一筆尾逗號 ✅（踩過坑 #1 — object literal blank screen）
- 插貼紙資料同樣檢查尾逗號 ✅

### 不會影響的部分（防回歸 audit）

- 既有 14 個 activity 程式碼 0 行修改
- mom-clinic / whiteboard-ocr-bot 不動（主軸資料閉環不影響）
- iDempiere REST API 不動
- 既有 5 個 tab 的 navigation / activity-grid 邏輯不動

## 隱私規格（COPPA / GDPR-K friendly）

### 四原則（modal + 隨頁顯示 + README 都寫明）

1. 相機畫面只進記憶體，**完全不存檔**
2. **不錄影、不截圖、不上傳**
3. 退出頁面立刻 `tracks.forEach(t => t.stop())` 釋放鏡頭
4. 任何時候按 ❌ 結束都關掉

### 實作要點

- `navigator.mediaDevices.getUserMedia` 只在「使用者按了 📷 體感」之後才呼叫（不在 page load）
- `<video>` 元素 `autoplay muted playsinline`（iOS 必須）
- 退出 navigateTo 任何地方 → 一律先 stop tracks（在 `#SECTION:NAV` 加 hook）
- video element src 永不寫進 DOM string，永不 toDataURL
- 右上「🔴 LIVE」常駐 + 紅點呼吸動畫，讓使用者**永遠**知道相機開著

## 實作順序

每一步都可獨立 ship，不留半成品:

| 步驟 | 內容 | 為什麼這順序 |
|---|---|---|
| 1 | 加 6th tab + 卡片 + 空白 page + 錨點骨架 | 可 navigate 進去就停，先驗證 tab bar overflow OK |
| 2 | 加 modal + mode state + **tap 模式** + mole 生命週期 + 計分 + 達標 + 慶祝 | tap mode 不需要相機，**整個遊戲已可玩** |
| 3 | 加 camera permission + video + pixel-diff + LIVE 指示 + exit cleanup | 把體感模式接上，複用 step 2 的 onHit |
| 4 | 加 ACTIVITY_LABELS + STICKERS + i18n + 設定面板 toggle | 接上 app 生態 |
| 5 | 4 ageGroups × 2 modes 手動測 + Playwright smoke + 平板實機測 | 驗收 |

關鍵:Step 2 結束後就是完整可玩的遊戲（只是只有 tap）。Step 3 是加值，不是 blocker。

## 測試策略

### Playwright smoke（CI 友善，不需相機）

1. Navigate 到 `#page-whack-mole`
2. Modal 出現 → click「👆 用手指點」
3. Mole emoji 出現 → click → counter 從 0 → 1
4. 重複到達標 → 慶祝動畫出現
5. ageGroup 切到 large → grid 變 3×3 → 同樣流程

### 手動測（需要相機 + 真人）

- Tom 拿平板放廚房真實環境，跑體感模式
- 驗:鏡頭距離 / 廚房光線 / 媽媽走過畫面誤判率 / 平板支架可行性
- 4 ageGroups 各跑一遍（女兒實測 toddler/small，Tom 跳 middle/large）

### 已知 Brain 風險檢查

| 坑 | 來源 | 本案防護 |
|---|---|---|
| Object literal 尾逗號 | design-principles.md, kids #1 | 插 `ACTIVITY_LABELS` / `STICKERS` 前先 grep 看前一筆有沒有 `,` |
| `.activity-card .icon` CSS 合約 | kids #2 | 統一用 `class="icon"` |
| `ACTIVITY_LABELS` 漏加 | kids #3 | 已在 spec 列入必改清單 |
| 寬螢幕 layout 靠左 | kids #4 | 新 tab 單卡用 `place-content: center` |
| id 重複 | kids #5 | grep `id:'page-whack-mole'` 確認唯一 |

## 完成定義

- [ ] 6th tab「💪 動一動」可從 landing 進入
- [ ] page-whack-mole 兩種模式都可玩通關
- [ ] 4 ageGroups 各自的 grid / target / timing 正確
- [ ] 達標後 +1 星、解鎖 💪 體能達人貼紙
- [ ] 設定面板可切換模式
- [ ] zh/en 雙語切換正常
- [ ] 退出頁面確實釋放鏡頭（DevTools 看不到 active stream）
- [ ] 既有 14 個活動回歸測無壞掉
- [ ] Playwright smoke 通過

## 不確定 / 上線後再 tune

- THRESHOLD_PIXEL / THRESHOLD_CELL 預設值在 Tom 廚房實際光線下會不會誤判太多 → 留 DEBUG_OVERLAY 隨時可調
- middle/large 同時冒 2-3 隻會不會太難 → 玩過再決定要不要砍
- 鏡頭距離提示會不會 patronizing → 上線後問 Tom 要不要砍
- toddler 預設 tap 是不是太保守 → 觀察女兒實際反應
