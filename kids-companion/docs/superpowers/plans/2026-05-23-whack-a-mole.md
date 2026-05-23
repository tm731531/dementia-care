# 打地鼠 動作偵測活動 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增「打地鼠」活動(`page-whack-mole`)到 kids-companion,並建立第 6 個 tab「💪 動一動」作為動作類遊戲擴充容器。雙模式:📷 相機體感(pixel-diff 純 JS 偵測)+ 👆 手指觸控 fallback。

**Architecture:** 全部加在現有單一檔案 `kids-companion/index.html` 中,沿用既有 anchor + activity 模式。共用 `onHit(idx)` 函式讓兩種輸入模式接同一遊戲核心。相機畫面 100% 本機(getUserMedia + canvas pixel-diff),不外傳、不錄影、不存檔。

**Tech Stack:** Vanilla HTML/CSS/JS、`navigator.mediaDevices.getUserMedia`、Canvas 2D `getImageData`、`requestAnimationFrame`、Web Speech API(沿用既有 `speak()`)、localStorage(沿用既有 `APP` + `saveState()`)。

**Reference spec:** `docs/superpowers/specs/2026-05-23-whack-a-mole-design.md`

**Single file under modification:** `kids-companion/index.html` (16,314 行)

---

## 任務拆分總覽

| Task | 內容 | 預估時間 | 結束時可玩? |
|---|---|---|---|
| 1 | 6th tab + 活動卡 + 貼紙格 | 15min | 進 tab 看得到卡片 |
| 2 | page-whack-mole 骨架 + STATE 欄位 | 20min | 點卡片進空白頁 |
| 3 | CSS(modal/holes/mole/video/LIVE) | 30min | 樣式 ready 但無互動 |
| 4 | WHACK_CONFIG + mode 選擇 modal + tap 模式 spawn | 40min | tap 模式可冒地鼠 |
| 5 | onHit + 動畫 + 計分 + 達標 → completeActivity | 30min | **tap 模式完整可玩** |
| 6 | 相機 mode:getUserMedia + video + pixel-diff loop | 50min | 體感模式可玩 |
| 7 | LIVE 指示 + ❌ 結束 + navigateTo 加 cleanup hook | 20min | 退出確實釋放鏡頭 |
| 8 | ACTIVITY_LABELS + 設定面板 toggle + tab bar overflow CSS | 20min | 接上 app 生態 |
| 9 | 4 ageGroups × 2 modes 手動驗收 + Brain 坑檢查 | 30min | 上線就緒 |

---

## Task 1: 6th tab 結構 + 活動卡 + 貼紙格

**Files:**
- Modify: `kids-companion/index.html`

### Anchors to touch
- Tab bar (~line 2757)
- Tab content list (~line 2766 onwards)
- Sticker book (~line 2918)

### Steps

- [ ] **Step 1.1: 在 tab-bar 加第 6 個按鈕**

定位:`grep -n 'data-tab="tab-explore"' index.html` 找到既有探索 tab 按鈕(約 line 2762)。

在那行**之後**新增一行:

```html
    <button class="tab-btn" data-tab="tab-move" onclick="switchTab('tab-move', this)">💪<br><span class="tab-label">動一動</span></button>
```

- [ ] **Step 1.2: 找到 tab-explore content 結束位置,加新 tab-content 區塊**

`grep -n 'id="tab-explore"' index.html` 找到 explore tab content 起點,從那邊往下讀到 `</div>` 配對結束。

在 `</div><!-- end tab-explore -->`(或對應的關閉位置)**之後**加:

```html
  <!-- Tab: Move (動一動) -->
  <div class="tab-content" id="tab-move">
    <div class="activity-grid" style="place-content:center">
      <div class="activity-card" onclick="navigateTo('page-whack-mole')">
        <span class="icon">🐹</span>
        <span class="label">打地鼠</span>
      </div>
    </div>
  </div>
```

注意:`place-content:center` 是踩過坑 #4 的防護(寬螢幕單卡禁靠左)。

- [ ] **Step 1.3: 貼紙書加新格子**

`grep -n 'data-sticker="page-story-build"' index.html` 找到貼紙書最後一個格子(~line 2944)。

在那行**之後**加:

```html
    <div class="sticker-slot locked" data-sticker="page-whack-mole">💪</div>
```

- [ ] **Step 1.4: 瀏覽器手動驗證**

```bash
xdg-open index.html  # 或拖進瀏覽器
```

檢查:
- 點 home 後看到 6 個 tab(語言/創作/動腦/故事/探索/動一動)
- 點 💪 動一動 → 看到 🐹 打地鼠卡片置中顯示
- 點貼紙書 → 看到 💪 灰色 locked 格子
- 開 DevTools console **無 error**

- [ ] **Step 1.5: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 加第 6 個 tab 💪 動一動 + 打地鼠卡片骨架

新建 tab-move + page-whack-mole 活動卡(尚未實作頁面) + 貼紙書加 💪 格子。
單卡用 place-content:center 防寬螢幕靠左(踩坑 #4)。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: page-whack-mole 骨架 + STATE 欄位

**Files:**
- Modify: `kids-companion/index.html`

### Anchors to touch
- 新建 `#SECTION:PAGE-WHACK-MOLE` (放在 `#SECTION:PAGE-MONEY` 之後,`#SECTION:SETTINGS` 之前)
- `#SECTION:STATE` (line 3829-3849)

### Steps

- [ ] **Step 2.1: 找到 PAGE-MONEY 結束位置**

```bash
grep -n "#END:PAGE-MONEY\|#SECTION:SETTINGS" index.html | head -5
```

找到 `#SECTION:SETTINGS` 起始位置(line ~3757,**注意:SETTINGS 比 MONEY 還早**)。實際插入點是**在最後一個 page-section 結束之後**,例如 `page-money` 結束處 — 用 `grep -n "PAGE-MONEY" index.html` 定位。

- [ ] **Step 2.2: 加 page-whack-mole 骨架 HTML**

在 `<!-- #END:PAGE-MONEY -->`(若有)或最後一個 page 結束處後,加:

```html
<!-- #SECTION:PAGE-WHACK-MOLE -->
<div class="page" id="page-whack-mole">
  <!-- ❌ 結束按鈕 -->
  <button class="back-btn whack-exit-btn" onclick="exitWhack()">❌</button>

  <!-- 🔴 LIVE 指示(只體感模式顯示) -->
  <div class="whack-live" id="whack-live" style="display:none">
    <span class="live-dot"></span> LIVE
  </div>

  <!-- Mode 選擇 modal(首次進入) -->
  <div class="whack-modal" id="whack-modal">
    <div class="whack-modal-card">
      <h2 id="whack-modal-title">準備好玩打地鼠了嗎?</h2>
      <button class="whack-mode-btn" id="whack-mode-motion" onclick="selectWhackMode('motion')">
        📷 <span id="whack-mode-motion-label">用相機體感玩</span>
      </button>
      <button class="whack-mode-btn" id="whack-mode-tap" onclick="selectWhackMode('tap')">
        👆 <span id="whack-mode-tap-label">用手指點</span>
      </button>
      <div class="whack-privacy" id="whack-privacy-text">
        相機畫面只在你裝置上,完全不會傳出去
      </div>
    </div>
  </div>

  <!-- Video feed(只體感模式可見,鋪滿背景) -->
  <video id="whack-video" autoplay muted playsinline style="display:none"></video>
  <canvas id="whack-canvas" width="160" height="120" style="display:none"></canvas>

  <!-- HUD -->
  <div class="whack-hud" id="whack-hud" style="display:none">
    <span class="whack-progress" id="whack-progress">🐹 已打: 0 / 0</span>
  </div>

  <!-- 遊戲區(holes grid) -->
  <div class="whack-game-area" id="whack-game-area" style="display:none">
    <div class="whack-grid" id="whack-grid"></div>
    <div class="whack-distance-hint" id="whack-distance-hint" style="display:none"></div>
  </div>

  <!-- 達標慶祝畫面 -->
  <div class="complete-screen" id="whack-complete">
    <div class="complete-content">
      <div style="font-size:80px">🐹</div>
      <h2 id="whack-complete-title">太厲害!</h2>
      <p id="whack-complete-sub" style="font-size:20px;color:#666"></p>
      <button class="btn btn-primary" onclick="navigateTo('page-home')" id="whack-back-btn">回首頁</button>
      <button class="btn btn-secondary" onclick="startWhackGame()" id="whack-again-btn">再玩一次</button>
    </div>
  </div>
</div>
<!-- #END:PAGE-WHACK-MOLE -->
```

- [ ] **Step 2.3: 在 APP 物件加 whackMode 欄位**

`grep -n "parentCompanionMode" index.html` 定位(~line 3848)。

把:

```js
  parentCompanionMode: false  // 開啟後互動活動退化成「家長帶著做」模式
};
```

改成:

```js
  parentCompanionMode: false,  // 開啟後互動活動退化成「家長帶著做」模式
  whackMode: null  // 'motion' | 'tap' | null(尚未選過)
};
```

注意尾逗號(踩坑 #1 防護)— 原本最後一筆沒尾逗號,改成中間筆要補上。

- [ ] **Step 2.4: 瀏覽器驗證**

開 index.html,DevTools console 打:

```js
navigateTo('page-whack-mole')
APP.whackMode  // → null
```

預期:看到 modal「準備好玩打地鼠了嗎?」+ 兩個按鈕(尚未綁 handler,點下去 console 會 ReferenceError — 預期內,下個 task 才接)。

console **不能有其他 error**。

- [ ] **Step 2.5: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): page-whack-mole HTML 骨架 + APP.whackMode state

加 #SECTION:PAGE-WHACK-MOLE:modal / video / canvas / HUD / grid / 慶祝畫面
全部 DOM 結構就位,還沒接 JS。APP 加 whackMode 欄位(null/motion/tap)。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: CSS — modal / holes / mole 動畫 / video overlay / LIVE 指示

**Files:**
- Modify: `kids-companion/index.html`

### Anchors to touch
- `#SECTION:CSS` (line 77 起,~3600 行 CSS)

### Steps

- [ ] **Step 3.1: 找 CSS 結束位置**

```bash
grep -n "#END:CSS\|</style>" index.html | head -5
```

CSS 區塊結尾是 `</style>` 標籤前。在 `</style>` 前插入新樣式。

- [ ] **Step 3.2: 加打地鼠樣式區塊**

在 `</style>` 前插入(注意這是 CSS sub-section,加註解錨點):

```css
/* <!-- #SECTION:WHACK-STYLES --> */

/* tab bar overflow(6 個 tab 可能擠手機) */
.tab-bar {
  overflow-x: auto;
  scrollbar-width: none;
}
.tab-bar::-webkit-scrollbar { display: none; }

/* page-whack-mole 整頁 */
#page-whack-mole {
  position: relative;
  background: #FFF8F0;
  min-height: 100vh;
  overflow: hidden;
}
#page-whack-mole #whack-video {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  width: 100%; height: 100%;
  object-fit: cover;
  opacity: 0.35;
  transform: scaleX(-1);  /* 鏡像翻轉,動左手螢幕左邊動 */
  z-index: 0;
}

/* ❌ 結束按鈕 */
.whack-exit-btn {
  position: absolute;
  top: 12px; left: 12px;
  font-size: 28px;
  background: rgba(255,255,255,0.9);
  border-radius: 50%;
  width: 48px; height: 48px;
  z-index: 10;
}

/* 🔴 LIVE 指示 */
.whack-live {
  position: absolute;
  top: 16px; right: 16px;
  background: rgba(0,0,0,0.7);
  color: #fff;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: bold;
  z-index: 10;
  display: flex;
  align-items: center;
  gap: 6px;
}
.whack-live .live-dot {
  width: 10px; height: 10px;
  border-radius: 50%;
  background: #ff3b30;
  animation: whackLivePulse 1.5s ease-in-out infinite;
}
@keyframes whackLivePulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}

/* Mode 選擇 modal */
.whack-modal {
  position: absolute;
  inset: 0;
  background: rgba(255,248,240,0.95);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 20;
}
.whack-modal-card {
  background: #fff;
  border-radius: 20px;
  padding: 32px 24px;
  max-width: 360px;
  width: 90%;
  text-align: center;
  box-shadow: 0 10px 30px rgba(0,0,0,0.15);
}
.whack-modal-card h2 {
  font-size: 24px;
  margin: 0 0 24px;
  color: #222;
}
.whack-mode-btn {
  display: block;
  width: 100%;
  padding: 16px;
  margin: 12px 0;
  font-size: 20px;
  border: 3px solid #E8724A;
  border-radius: 16px;
  background: #fff;
  color: #E8724A;
  cursor: pointer;
  min-height: 64px;
}
.whack-mode-btn:hover, .whack-mode-btn.recommended {
  background: #E8724A;
  color: #fff;
}
.whack-privacy {
  font-size: 13px;
  color: #888;
  margin-top: 16px;
  line-height: 1.5;
}

/* HUD */
.whack-hud {
  position: absolute;
  top: 16px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(255,255,255,0.9);
  padding: 8px 20px;
  border-radius: 20px;
  font-size: 22px;
  font-weight: bold;
  color: #E8724A;
  z-index: 5;
}

/* 距離提示 */
.whack-distance-hint {
  text-align: center;
  color: #888;
  font-size: 16px;
  margin-top: 16px;
  position: relative;
  z-index: 5;
}

/* 遊戲區 */
.whack-game-area {
  position: relative;
  width: 100%;
  height: 100vh;
  padding: 80px 20px 60px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  justify-content: center;
  z-index: 1;
}
.whack-grid {
  display: grid;
  gap: 20px;
  width: 100%;
  max-width: 720px;
  margin: 0 auto;
  place-content: center;
}
.whack-grid.cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.whack-grid.cols-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }

/* 洞口 */
.whack-hole {
  position: relative;
  aspect-ratio: 1 / 1;
  background: radial-gradient(ellipse at 50% 70%, #4a3520 30%, #2a1d10 60%, transparent 80%);
  border-radius: 50%;
  overflow: hidden;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.whack-hole .mole {
  font-size: clamp(48px, 12vw, 96px);
  transform: scale(0);
  transition: transform 0.2s cubic-bezier(.34,1.56,.64,1);
  user-select: none;
  pointer-events: none;
}
.whack-hole.active .mole {
  transform: scale(1);
  animation: whackMoleIdle 0.6s ease-in-out infinite alternate;
}
.whack-hole.hit .mole {
  animation: whackMoleHit 0.3s ease-out forwards;
}
.whack-hole.timeout .mole {
  animation: whackMoleTimeout 0.4s ease-out forwards;
}
@keyframes whackMoleIdle {
  from { transform: scale(1) translateY(0); }
  to { transform: scale(1) translateY(-6px); }
}
@keyframes whackMoleHit {
  0% { transform: scale(1); }
  40% { transform: scale(1.3); }
  100% { transform: scale(0); opacity: 0; }
}
@keyframes whackMoleTimeout {
  0%, 100% { transform: scale(1) translateX(0); }
  25% { transform: scale(1) translateX(-6px); }
  75% { transform: scale(1) translateX(6px); }
  to { transform: scale(0); }
}

/* 塵土效果 */
.whack-dust {
  position: absolute;
  top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  font-size: 40px;
  animation: whackDust 0.4s ease-out forwards;
  pointer-events: none;
}
@keyframes whackDust {
  0% { opacity: 1; transform: translate(-50%, -50%) scale(0.5); }
  100% { opacity: 0; transform: translate(-50%, -150%) scale(1.5); }
}

/* <!-- #END:WHACK-STYLES --> */
```

- [ ] **Step 3.3: 瀏覽器驗證樣式**

開 index.html → navigateTo('page-whack-mole'),DevTools 檢查:
- Modal 居中 + 兩個橘框按鈕
- 視覺風格符合 kids-companion(米白底、暖橘 #E8724A、圓角 16-20px)
- 手機尺寸切換(375px)看一下 modal 沒爆版

DevTools 加 class 測試動畫:

```js
// 手動驗證 mole pop animation:
document.getElementById('whack-grid').innerHTML = '<div class="whack-hole"><span class="mole">🐹</span></div>'
document.querySelector('.whack-hole').classList.add('active')  // 應該看到 🐹 彈出 + idle 浮動
```

- [ ] **Step 3.4: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 打地鼠 CSS — modal/holes/mole 動畫/video overlay/LIVE

#SECTION:WHACK-STYLES 子區放在 #SECTION:CSS 末尾。
- tab-bar overflow-x:auto 解 6 個 tab 手機擠的問題
- video 水平鏡像 + opacity 0.35 鋪滿背景
- mole pop / idle / hit / timeout 四段動畫
- LIVE 紅點呼吸動畫

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: WHACK_CONFIG + mode 選擇 modal + tap 模式 spawn

**Files:**
- Modify: `kids-companion/index.html`

### Anchors to touch
- 新建 `#SECTION:WHACK-LOGIC`(放在 `#SECTION:PAGE-MONEY-JS` 之後)
- `#SECTION:NAV` (line 4214) — 加 navigate hook

### Steps

- [ ] **Step 4.1: 找到 PAGE-MONEY-JS 結束位置**

```bash
grep -n "#SECTION:PAGE-MONEY-JS\|#SECTION:IMAGES-CURRENCY" index.html | head -5
```

`#SECTION:PAGE-MONEY-JS` 大約在 line 15422,後面是 `#SECTION:IMAGES-CURRENCY`。要插在這兩個之間。

- [ ] **Step 4.2: 加 WHACK_CONFIG + WHACK_TUNING 常數 + game state**

在 `#SECTION:IMAGES-CURRENCY` 之**前**插入:

```js
// <!-- #SECTION:WHACK-LOGIC -->

// 各年齡組設定(grid / 達標 / 地鼠停留 / 同時上限)
var WHACK_CONFIG = {
  toddler: { cols: 2, rows: 1, holes: 2, target: 5, moleStayMs: 4000, maxSimultaneous: 1, distHint: null },
  small:   { cols: 3, rows: 1, holes: 3, target: 8, moleStayMs: 3000, maxSimultaneous: 1, distHint: '60cm' },
  middle:  { cols: 3, rows: 2, holes: 6, target: 12, moleStayMs: 2500, maxSimultaneous: 2, distHint: '100cm' },
  large:   { cols: 3, rows: 3, holes: 9, target: 20, moleStayMs: 2000, maxSimultaneous: 3, distHint: '1.8m' }
};

// pixel-diff 調參(體感模式)
var WHACK_TUNING = {
  THRESHOLD_PIXEL: 25,    // 灰階差 > 25 算 changed (out of 255)
  THRESHOLD_CELL: 0.08,   // cell 內 > 8% pixels changed 算動了
  COOLDOWN_MS: 600,       // 打中後 cell 冷卻
  CANVAS_W: 160,
  CANVAS_H: 120,
  DEBUG_OVERLAY: false    // 開啟顯示每格 diff% 即時數值(調參用)
};

// 出現間隔
var WHACK_SPAWN_MIN_MS = 1000;
var WHACK_SPAWN_MAX_MS = 1800;

// Multi-mole 機率(by age)
var WHACK_MULTI_PROB = {
  toddler: { two: 0, three: 0 },
  small:   { two: 0, three: 0 },
  middle:  { two: 0.20, three: 0 },
  large:   { two: 0.30, three: 0.10 }
};

// Game state(non-persisted,只跟單局)
var whackState = {
  active: false,
  mode: null,          // 'tap' | 'motion'
  cfg: null,           // 當前 ageGroup 對應 config
  hits: 0,
  holes: [],           // [{el, active, moleEl, spawnedAt, cooldownUntil}]
  spawnTimer: null,
  videoStream: null,
  videoEl: null,
  canvasEl: null,
  canvasCtx: null,
  prevFrame: null,
  diffRafId: null,
  lastSpawnedIdx: -1
};

// 進入頁面入口(由 navigateTo 觸發)
function startWhackGame() {
  whackState.cfg = WHACK_CONFIG[APP.ageGroup] || WHACK_CONFIG.small;
  whackState.hits = 0;
  whackState.active = false;

  // 顯示 modal,隱藏遊戲區/HUD/LIVE/慶祝畫面
  document.getElementById('whack-modal').style.display = 'flex';
  document.getElementById('whack-hud').style.display = 'none';
  document.getElementById('whack-game-area').style.display = 'none';
  document.getElementById('whack-live').style.display = 'none';
  document.getElementById('whack-complete').classList.remove('show');

  // i18n: modal 文字(沿用 APP.language 模式)
  var isEn = (APP.language === 'en');
  document.getElementById('whack-modal-title').textContent =
    isEn ? 'Ready to play whack-a-mole?' : '準備好玩打地鼠了嗎?';
  document.getElementById('whack-mode-motion-label').textContent =
    isEn ? 'Play with camera' : '用相機體感玩';
  document.getElementById('whack-mode-tap-label').textContent =
    isEn ? 'Tap to play' : '用手指點';
  document.getElementById('whack-privacy-text').textContent =
    isEn ? 'Camera stays on your device, never uploaded' : '相機畫面只在你裝置上,完全不會傳出去';

  // 預設高亮(依年齡)
  var defaultIsMotion = (APP.ageGroup === 'middle' || APP.ageGroup === 'large');
  document.getElementById('whack-mode-motion').classList.toggle('recommended', defaultIsMotion);
  document.getElementById('whack-mode-tap').classList.toggle('recommended', !defaultIsMotion);

  // 若已記住模式,直接套用(跳過 modal)
  if (APP.whackMode) {
    selectWhackMode(APP.whackMode);
  }
}

// 使用者選了模式
function selectWhackMode(mode) {
  APP.whackMode = mode;
  saveState();
  whackState.mode = mode;
  document.getElementById('whack-modal').style.display = 'none';

  if (mode === 'motion') {
    startWhackMotion();  // task 6 實作
  } else {
    startWhackPlay();
  }
}

// 啟動遊戲畫面(共用,motion/tap 都會經過)
function startWhackPlay() {
  whackState.active = true;
  document.getElementById('whack-hud').style.display = 'block';
  document.getElementById('whack-game-area').style.display = 'flex';
  renderWhackGrid();
  updateWhackHud();

  // 距離提示(只體感模式)
  var hint = document.getElementById('whack-distance-hint');
  if (whackState.mode === 'motion' && whackState.cfg.distHint) {
    var isEn = (APP.language === 'en');
    hint.textContent = (isEn ? '📏 About ' : '📏 大約 ') + whackState.cfg.distHint;
    hint.style.display = 'block';
  } else {
    hint.style.display = 'none';
  }

  // 開始 spawn loop
  scheduleNextSpawn();
}

// 渲染 grid + holes(initial state: 全空)
function renderWhackGrid() {
  var grid = document.getElementById('whack-grid');
  var cfg = whackState.cfg;
  grid.className = 'whack-grid cols-' + cfg.cols;
  grid.innerHTML = '';
  whackState.holes = [];

  for (var i = 0; i < cfg.holes; i++) {
    var hole = document.createElement('div');
    hole.className = 'whack-hole';
    hole.setAttribute('data-idx', i);
    hole.innerHTML = '<span class="mole">🐹</span>';

    // tap mode: pointerdown 直接觸發 onHit
    (function(idx) {
      hole.addEventListener('pointerdown', function() {
        if (whackState.mode === 'tap') {
          onWhackHit(idx);
        }
      });
    })(i);

    grid.appendChild(hole);
    whackState.holes.push({
      el: hole,
      active: false,
      moleEl: hole.querySelector('.mole'),
      spawnedAt: 0,
      timeoutTimer: null,
      cooldownUntil: 0
    });
  }
}

// HUD 顯示
function updateWhackHud() {
  var isEn = (APP.language === 'en');
  var label = isEn ? 'Hit: ' : '已打: ';
  document.getElementById('whack-progress').textContent =
    '🐹 ' + label + whackState.hits + ' / ' + whackState.cfg.target;
}

// 排下一隻地鼠
function scheduleNextSpawn() {
  if (!whackState.active) return;
  var delay = WHACK_SPAWN_MIN_MS + Math.random() * (WHACK_SPAWN_MAX_MS - WHACK_SPAWN_MIN_MS);
  whackState.spawnTimer = setTimeout(spawnMole, delay);
}

function spawnMole() {
  if (!whackState.active) return;

  // 算當前活著的數量,以及該 age 同時上限
  var activeCount = whackState.holes.filter(function(h) { return h.active; }).length;
  var probs = WHACK_MULTI_PROB[APP.ageGroup] || WHACK_MULTI_PROB.small;
  var spawnCount = 1;
  var r = Math.random();
  if (r < probs.three) spawnCount = 3;
  else if (r < probs.three + probs.two) spawnCount = 2;

  // 上限約束
  spawnCount = Math.min(spawnCount, whackState.cfg.maxSimultaneous - activeCount);
  if (spawnCount <= 0) {
    scheduleNextSpawn();
    return;
  }

  // 找空著的洞,排除上次同一洞
  var candidates = [];
  for (var i = 0; i < whackState.holes.length; i++) {
    if (!whackState.holes[i].active && i !== whackState.lastSpawnedIdx) {
      candidates.push(i);
    }
  }
  // 沒有候選(全活著)就讓 lastSpawnedIdx 也可用
  if (candidates.length === 0) {
    for (var j = 0; j < whackState.holes.length; j++) {
      if (!whackState.holes[j].active) candidates.push(j);
    }
  }

  for (var s = 0; s < spawnCount && candidates.length > 0; s++) {
    var pick = Math.floor(Math.random() * candidates.length);
    var idx = candidates.splice(pick, 1)[0];
    showMole(idx);
    whackState.lastSpawnedIdx = idx;
  }

  scheduleNextSpawn();
}

function showMole(idx) {
  var hole = whackState.holes[idx];
  hole.active = true;
  hole.spawnedAt = Date.now();
  hole.el.classList.remove('hit', 'timeout');
  hole.el.classList.add('active');

  // 超時自動縮回(沒被打中)
  hole.timeoutTimer = setTimeout(function() {
    if (!hole.active) return;
    hole.active = false;
    hole.el.classList.remove('active');
    hole.el.classList.add('timeout');
    setTimeout(function() { hole.el.classList.remove('timeout'); }, 400);
  }, whackState.cfg.moleStayMs);
}

// onHit 在 task 5 實作(這 task 先佔位)
function onWhackHit(idx) {
  // task 5 補完
}

// exit 在 task 7 實作(這 task 先佔位)
function exitWhack() {
  navigateTo('page-home');
}

// motion mode 在 task 6 實作(這 task 先佔位)
function startWhackMotion() {
  // task 6 補完 — 暫時直接走 tap 模式 fallback
  startWhackPlay();
}

// <!-- #END:WHACK-LOGIC -->
```

- [ ] **Step 4.3: 在 navigateTo() 加 hook**

`grep -n 'if (pageId === ' index.html | tail -5` 找到既有最後一個 hook(line ~4271 `if (pageId === 'page-money') startMoneyGame();`)。

在那行之後加:

```js
  if (pageId === 'page-whack-mole') startWhackGame();
```

- [ ] **Step 4.4: 瀏覽器驗證**

開 index.html → 設定改 small → 進 💪 動一動 tab → 點打地鼠卡片。

預期:
- Modal 出現,「用手指點」按鈕被高亮(recommended class)
- 點「👆 用手指點」→ modal 消失,出現 3 個洞口(small = 3 holes 一橫排)
- 等 1-2 秒 → 看到 🐹 從某個洞冒出來
- 點其他洞 → 沒反應(尚未實作 hit handler — 預期內)
- 等 3 秒 → 🐹 抖兩下後縮回(timeout 動畫)
- DevTools console **無 error**

切換 ageGroup(打開設定改 large)後再進活動:
- Modal 預設高亮「📷 用相機體感玩」
- 點「👆 用手指點」→ 看到 9 個洞口(3×3)

- [ ] **Step 4.5: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): #SECTION:WHACK-LOGIC — mode 選擇 + tap spawn loop

WHACK_CONFIG / WHACK_TUNING / WHACK_SPAWN_* 常數放檔頭。
startWhackGame() / selectWhackMode() / spawnMole() / showMole() ready。
onWhackHit() / exitWhack() / startWhackMotion() 為下游 task 佔位。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: onHit + 動畫 + 計分 + 達標 → completeActivity

**Files:**
- Modify: `kids-companion/index.html`

### Steps

- [ ] **Step 5.1: 實作 onWhackHit()**

找到 task 4 加的佔位 `function onWhackHit(idx) {` (在 `#SECTION:WHACK-LOGIC` 內),替換整個 function:

```js
function onWhackHit(idx) {
  var hole = whackState.holes[idx];
  if (!hole.active) return;  // 沒有地鼠不算
  if (Date.now() < hole.cooldownUntil) return;  // cooldown 內

  hole.active = false;
  clearTimeout(hole.timeoutTimer);
  hole.cooldownUntil = Date.now() + WHACK_TUNING.COOLDOWN_MS;
  hole.el.classList.remove('active');
  hole.el.classList.add('hit');

  // 塵土特效
  var dust = document.createElement('span');
  dust.className = 'whack-dust';
  dust.textContent = '💨';
  hole.el.appendChild(dust);
  setTimeout(function() {
    if (dust.parentNode) dust.parentNode.removeChild(dust);
    hole.el.classList.remove('hit');
  }, 400);

  whackState.hits++;
  updateWhackHud();

  if (whackState.hits >= whackState.cfg.target) {
    finishWhack();
  }
}

function finishWhack() {
  whackState.active = false;
  clearTimeout(whackState.spawnTimer);

  // 全部地鼠收起來
  whackState.holes.forEach(function(h) {
    clearTimeout(h.timeoutTimer);
    h.active = false;
    h.el.classList.remove('active');
  });

  // 顯示慶祝畫面
  var isEn = (APP.language === 'en');
  var target = whackState.cfg.target;
  document.getElementById('whack-complete-title').textContent =
    isEn ? 'Awesome!' : '太厲害!';
  document.getElementById('whack-complete-sub').textContent =
    isEn ? ('You got ' + target + ' moles!') : ('打到了 ' + target + ' 隻!');
  document.getElementById('whack-back-btn').textContent = isEn ? 'Back home' : '回首頁';
  document.getElementById('whack-again-btn').textContent = isEn ? 'Play again' : '再玩一次';

  // 隱藏遊戲區
  document.getElementById('whack-game-area').style.display = 'none';
  document.getElementById('whack-hud').style.display = 'none';

  // 顯示慶祝
  var complete = document.getElementById('whack-complete');
  complete.classList.add('show');

  // 接 app 既有獎勵系統
  completeActivity('page-whack-mole');

  // Web Speech 朗讀(沿用既有 speak)
  if (typeof speak === 'function') {
    speak(isEn ? ('Awesome! You got ' + target + '!') : ('太厲害!打到了 ' + target + '隻!'));
  }
}
```

- [ ] **Step 5.2: 瀏覽器驗證 tap mode 完整流程**

開 index.html → 設定 small ageGroup → 進打地鼠 → 選「手指點」。

預期:
- 🐹 冒出 → 用滑鼠/觸控點 → 看到塵土 💨 + 縮小消失動畫
- HUD 顯示「已打: 1 / 8」
- 連續打 8 隻 → 慶祝畫面出現
- 朗讀「太厲害!打到了 8 隻!」(若聲音開啟)
- 星星 +1(右上 star bar 多一顆 ⭐)
- 點貼紙書 → 💪 格子變 unlocked
- console **無 error**
- 切英文模式重玩一次 → 文字變英文

- [ ] **Step 5.3: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 打地鼠 onHit + 計分 + 達標慶祝接 completeActivity

tap 模式完整可玩。打中: 塵土💨特效 + cooldown 600ms 防多擊。
達標: 慶祝畫面 + Web Speech + completeActivity('page-whack-mole') 給星+貼紙。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: 體感模式 — getUserMedia + video + pixel-diff loop

**Files:**
- Modify: `kids-companion/index.html`

### Steps

- [ ] **Step 6.1: 替換 startWhackMotion() 佔位實作**

定位:`grep -n "function startWhackMotion" index.html`

把整個 function 替換成:

```js
function startWhackMotion() {
  var isEn = (APP.language === 'en');

  // 1. 請求相機
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    alert(isEn ? 'Camera not supported, switching to tap mode.' : '裝置不支援相機,切換成手指模式。');
    APP.whackMode = 'tap';
    whackState.mode = 'tap';
    saveState();
    startWhackPlay();
    return;
  }

  navigator.mediaDevices.getUserMedia({ video: { width: 320, height: 240 } })
    .then(function(stream) {
      whackState.videoStream = stream;
      var video = document.getElementById('whack-video');
      video.srcObject = stream;
      video.style.display = 'block';
      whackState.videoEl = video;

      // 準備 canvas
      var canvas = document.getElementById('whack-canvas');
      whackState.canvasEl = canvas;
      whackState.canvasCtx = canvas.getContext('2d', { willReadFrequently: true });
      whackState.prevFrame = null;

      // 顯示 LIVE
      document.getElementById('whack-live').style.display = 'flex';

      // 等 video 開始播放才開遊戲
      video.onloadedmetadata = function() {
        video.play().then(function() {
          startWhackPlay();
          startWhackDiffLoop();
        });
      };
    })
    .catch(function(err) {
      console.warn('Camera denied or unavailable:', err);
      alert(isEn ? 'Camera off — tap to play instead?' : '相機沒打開,先用手指點玩好嗎?');
      APP.whackMode = 'tap';
      whackState.mode = 'tap';
      saveState();
      startWhackPlay();
    });
}

// pixel-diff loop
function startWhackDiffLoop() {
  function loop() {
    if (!whackState.active || whackState.mode !== 'motion') return;

    var ctx = whackState.canvasCtx;
    var video = whackState.videoEl;
    var W = WHACK_TUNING.CANVAS_W;
    var H = WHACK_TUNING.CANVAS_H;

    // 鏡像翻轉繪到 canvas,跟使用者看到的 video 一致
    ctx.save();
    ctx.translate(W, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(video, 0, 0, W, H);
    ctx.restore();

    var frame = ctx.getImageData(0, 0, W, H);

    if (whackState.prevFrame) {
      // 只檢查「目前有地鼠的 cell」
      var cfg = whackState.cfg;
      var cellW = W / cfg.cols;
      var cellH = H / cfg.rows;

      for (var i = 0; i < whackState.holes.length; i++) {
        var hole = whackState.holes[i];
        if (!hole.active) continue;
        if (Date.now() < hole.cooldownUntil) continue;

        var col = i % cfg.cols;
        var row = Math.floor(i / cfg.cols);
        var x0 = Math.floor(col * cellW);
        var y0 = Math.floor(row * cellH);
        var x1 = Math.floor((col + 1) * cellW);
        var y1 = Math.floor((row + 1) * cellH);

        var changed = 0;
        var total = 0;
        for (var y = y0; y < y1; y++) {
          for (var x = x0; x < x1; x++) {
            var p = (y * W + x) * 4;
            var gNow = (frame.data[p] + frame.data[p+1] + frame.data[p+2]) / 3;
            var gPrev = (whackState.prevFrame.data[p] + whackState.prevFrame.data[p+1] + whackState.prevFrame.data[p+2]) / 3;
            if (Math.abs(gNow - gPrev) > WHACK_TUNING.THRESHOLD_PIXEL) changed++;
            total++;
          }
        }

        var ratio = total > 0 ? (changed / total) : 0;
        if (WHACK_TUNING.DEBUG_OVERLAY) {
          console.log('cell', i, 'diff', (ratio * 100).toFixed(1), '%');
        }
        if (ratio > WHACK_TUNING.THRESHOLD_CELL) {
          onWhackHit(i);
        }
      }
    }

    whackState.prevFrame = frame;
    whackState.diffRafId = requestAnimationFrame(loop);
  }
  whackState.diffRafId = requestAnimationFrame(loop);
}
```

- [ ] **Step 6.2: 真實鏡頭測試**

開 index.html(若是 file://,某些瀏覽器 getUserMedia 會被擋,用本地 server):

```bash
python3 -m http.server 8000
# 開 http://localhost:8000/kids-companion/index.html
```

設定 middle → 進打地鼠 → 選「📷 用相機體感玩」。

預期:
- 瀏覽器跳相機權限 → 允許
- 看到自己半透明 video 鋪滿背景(鏡像翻轉)
- 右上「🔴 LIVE」紅點呼吸
- 🐹 冒出 → 揮手過去 → 被打中
- DevTools console 無 error
- 達標 → 慶祝畫面

被拒測試:重新整理 → 進打地鼠 → 選體感 → 拒絕權限。預期:alert 提示 + 自動切 tap 模式 + 遊戲繼續可玩。

- [ ] **Step 6.3: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 體感模式 — getUserMedia + 純 JS pixel-diff loop

160x120 低解析度 canvas + requestAnimationFrame ~30fps。
只檢查有地鼠的 cell(砍 90% 誤判)。
拒絕/不支援 → 自動 fallback tap 模式不中斷遊戲。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: LIVE 指示 + ❌ 結束 + navigateTo cleanup hook

**Files:**
- Modify: `kids-companion/index.html`

### Steps

- [ ] **Step 7.1: 替換 exitWhack() 佔位實作**

定位 `function exitWhack()`,替換成:

```js
function exitWhack() {
  navigateTo('page-home');
}

// 釋放鏡頭 + 停止所有 timer(被 navigateTo 呼叫)
function stopWhackGame() {
  whackState.active = false;
  if (whackState.spawnTimer) {
    clearTimeout(whackState.spawnTimer);
    whackState.spawnTimer = null;
  }
  whackState.holes.forEach(function(h) {
    if (h.timeoutTimer) clearTimeout(h.timeoutTimer);
  });
  if (whackState.diffRafId) {
    cancelAnimationFrame(whackState.diffRafId);
    whackState.diffRafId = null;
  }
  if (whackState.videoStream) {
    whackState.videoStream.getTracks().forEach(function(t) { t.stop(); });
    whackState.videoStream = null;
  }
  if (whackState.videoEl) {
    whackState.videoEl.srcObject = null;
    whackState.videoEl.style.display = 'none';
  }
  document.getElementById('whack-live').style.display = 'none';
  whackState.prevFrame = null;
}
```

- [ ] **Step 7.2: 在 navigateTo 開頭加 cleanup**

`grep -n "function navigateTo" index.html` 定位(~line 4216)。

把:

```js
function navigateTo(pageId) {
  // Stop any ongoing speech when navigating away
  if ('speechSynthesis' in window) speechSynthesis.cancel();
```

改成:

```js
function navigateTo(pageId) {
  // Stop whack game (release camera + timers) if leaving page-whack-mole
  if (typeof stopWhackGame === 'function') stopWhackGame();
  // Stop any ongoing speech when navigating away
  if ('speechSynthesis' in window) speechSynthesis.cancel();
```

注意:`stopWhackGame()` 對非打地鼠頁面也會跑,但因為 `whackState.active === false`+ `videoStream === null` 都是早期 return,沒副作用。

- [ ] **Step 7.3: 驗證 cleanup**

開 localhost server → 進體感模式 → 看到 🔴 LIVE → 點 ❌(左上)。

預期:
- 立刻回到首頁
- DevTools → Application/Storage → MediaDevices(若有)看不到 active stream
- 系統列相機指示燈熄滅
- 再進打地鼠 → 相機重新請求

也測:玩到一半從 modal 還沒選模式時點 ❌ → 直接回首頁,無 error。

- [ ] **Step 7.4: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): 打地鼠退出釋放鏡頭 + navigateTo 加 stopWhackGame hook

navigateTo 開頭呼叫 stopWhackGame(對其他頁面 no-op)。
stopWhackGame: stop tracks / cancel raf / clear timers / hide LIVE。
退出體感模式系統列相機燈確實熄滅。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: ACTIVITY_LABELS + 設定面板 toggle

**Files:**
- Modify: `kids-companion/index.html`

### Steps

- [ ] **Step 8.1: 加 ACTIVITY_LABELS 條目**

`grep -n "'page-zhuyin': '注音符號" index.html` 定位(~line 4993)。

把:

```js
  'page-zhuyin': '注音符號 ㄅ'
};
```

改成:

```js
  'page-zhuyin': '注音符號 ㄅ',
  'page-whack-mole': '打地鼠 🐹'
};
```

注意尾逗號(踩坑 #1 防護)— 原本最後一筆沒尾逗號,改成中間筆要補上。

- [ ] **Step 8.2: 在設定面板加 toggle**

`grep -n "陪伴模式" index.html | head -3` 找到陪伴模式 settings-group(~line 3803)。

在「陪伴模式」**之前**插入:

```html
  <!-- 打地鼠玩法 -->
  <div class="settings-group">
    <h3>🐹 打地鼠玩法</h3>
    <button class="setting-option" id="whack-mode-setting-motion" onclick="setWhackMode('motion')">📷 體感</button>
    <button class="setting-option" id="whack-mode-setting-tap" onclick="setWhackMode('tap')">👆 手指</button>
    <div style="font-size:12px;color:#888;margin-top:6px;line-height:1.5">
      下次玩打地鼠用哪種輸入。可隨時切換。
    </div>
  </div>
```

- [ ] **Step 8.3: 加 setWhackMode() 函式**

`grep -n "#SECTION:SETTINGS-JS" index.html`(~line 4700)定位。在該區塊內(找個合理位置,例如 toggleCompanionMode 之後),加:

```js
function setWhackMode(mode) {
  APP.whackMode = mode;
  saveState();
  updateWhackModeSettingUI();
}

function updateWhackModeSettingUI() {
  var m = document.getElementById('whack-mode-setting-motion');
  var t = document.getElementById('whack-mode-setting-tap');
  if (!m || !t) return;
  m.classList.toggle('selected', APP.whackMode === 'motion');
  t.classList.toggle('selected', APP.whackMode === 'tap');
}
```

- [ ] **Step 8.4: 在 openSettings() 加 UI 同步**

`grep -n "function openSettings" index.html` 定位。在 openSettings function 末尾(`}` 前)加:

```js
  updateWhackModeSettingUI();
```

(若已有類似 selected 同步 pattern,跟著放在同樣位置)

- [ ] **Step 8.5: 驗證**

- 開 index.html → 進設定 → 看到「🐹 打地鼠玩法」+ 兩個按鈕
- 點「📷 體感」→ 按鈕高亮 selected
- 關掉設定 → 再開 → 還記得選了體感
- 進打地鼠 → 直接跳 modal 並 auto-select(因為 APP.whackMode 已設)
- 在設定改成手指 → 進打地鼠 → 直接 tap 模式不跳 modal

完成今日學習紀錄檢查:
- 玩通關打地鼠 → 回首頁滑到底「今日學習紀錄」應該顯示「打地鼠 🐹」(不是 raw `page-whack-mole`)

- [ ] **Step 8.6: Commit**

```bash
git add kids-companion/index.html
git commit -m "$(cat <<'EOF'
feat(kids-companion): ACTIVITY_LABELS 加打地鼠 + 設定面板新增玩法 toggle

ACTIVITY_LABELS:防今日學習紀錄顯示 raw page-whack-mole(踩坑 #3)。
設定面板:📷 體感 / 👆 手指 二選一,setWhackMode 存 APP + localStorage。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: 全面驗收 — 4 ageGroups × 2 modes + Brain 坑檢查

**Files:**
- (僅讀取 + 手動測試,不修改)

### Steps

- [ ] **Step 9.1: Brain 坑 audit**

```bash
cd /home/tom/Desktop/dementia-care/kids-companion

# 踩坑 #1: ACTIVITY_LABELS 尾逗號
grep -B1 "'page-whack-mole': '打地鼠" index.html
# 預期:前一行(page-zhuyin)結尾有 ','

# 踩坑 #2: .activity-card .icon 合約
grep "activity-card.*onclick.*page-whack-mole" index.html -A 1
# 預期:用 <span class="icon">🐹</span>,不是 whack-icon

# 踩坑 #3: ACTIVITY_LABELS 條目存在
grep "'page-whack-mole'" index.html
# 預期:至少 1 行 in ACTIVITY_LABELS

# 踩坑 #4: 寬螢幕 layout
grep "tab-content.*tab-move\|place-content:center" index.html
# 預期:tab-move 內的 activity-grid 有 place-content:center

# 踩坑 #5: id 重複
grep -c 'id="page-whack-mole"' index.html
# 預期:1(不是 2)
grep -c 'data-sticker="page-whack-mole"' index.html
# 預期:1
```

任何不符合預期 → 回頭修。

- [ ] **Step 9.2: 0 CDN 檢查(mono-repo 強制)**

```bash
grep -n -E 'https?://[^"]*\.(com|net|org|io|co)/' index.html | grep -v 'github.io\|tomting.com\|data:'
```

預期:無新增違規(打地鼠程式碼不應引入任何外部資源)。

- [ ] **Step 9.3: console clean 檢查**

開 index.html localhost server → 跑下列路徑,DevTools console 全程**無 error 無 warning**:

1. 首頁載入
2. 切到 💪 動一動 tab
3. 點打地鼠卡片
4. Modal 顯示
5. 點手指模式
6. 玩一輪到達標
7. 慶祝畫面顯示
8. 回首頁
9. 重新進打地鼠
10. 點體感模式(允許相機)
11. 玩一輪到達標
12. 中途退出(❌)→ 看相機燈熄滅

- [ ] **Step 9.4: 4 ageGroups × 2 modes 手動驗收**

| | toddler 手指 | toddler 體感 | small 手指 | small 體感 | middle 手指 | middle 體感 | large 手指 | large 體感 |
|---|---|---|---|---|---|---|---|---|
| Grid | 2×1 | 2×1 | 3×1 | 3×1 | 3×2 | 3×2 | 3×3 | 3×3 |
| 達標 | 5 | 5 | 8 | 8 | 12 | 12 | 20 | 20 |
| 同時 | 1 | 1 | 1 | 1 | 1-2 | 1-2 | 1-3 | 1-3 |
| 距離提示 | ✗ | ✗ | ✗ | ✓ 60cm | ✗ | ✓ 100cm | ✗ | ✓ 1.8m |

8 個格子,每個都要至少玩到「冒出第一隻地鼠」+ 切換到下一個。完整玩到達標的至少測 2-3 個。

- [ ] **Step 9.5: 回歸測試 — 既有 14 個活動隨機抽 3 個玩**

選 3 個:認中文字 / 拼圖 / 動物園。各玩到完成。

預期:全部正常,沒有任何 regression。星星累積、貼紙解鎖、今日學習紀錄都正常。

- [ ] **Step 9.6: 平板實機測**

把 kids-companion 推到 GitHub Pages(若 main 分支),用真實平板開:
```
https://tm731531.github.io/dementia-care/kids-companion/
```

或本機:
```bash
python3 -m http.server 8000
# 平板開 http://<電腦 IP>:8000/kids-companion/
```

驗收:
- 6 個 tab 在平板橫向不擠
- 體感模式相機解析度 OK
- 觸控反應 OK
- 達標慶祝紙屑流暢(無卡頓)

- [ ] **Step 9.7: 更新 CLAUDE.md 踩坑記錄(若有發現新坑)**

若驗收過程踩到新坑,寫進 `kids-companion/CLAUDE.md` 「踩過的坑」段落 + 視情況更新 `~/.claude/projects/-home-tom/memory/brain/design-principles.md`。

- [ ] **Step 9.8: 最終 commit(若有微調)**

```bash
# 若 step 9.1-9.6 有任何微調
git add kids-companion/index.html kids-companion/CLAUDE.md  # 視範圍
git commit -m "$(cat <<'EOF'
chore(kids-companion): 打地鼠驗收 + 微調

- Brain audit 通過(5 個踩坑點皆已防護)
- 4 ageGroups × 2 modes 全跑通
- 既有 14 活動回歸測無壞
- 平板實機體感模式正常

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

若無微調可跳過此 step。

---

## Self-Review Notes(計畫寫完自審)

**Spec 覆蓋檢查:**
- ✅ 新建 tab「💪 動一動」(Task 1)
- ✅ page-whack-mole + modal 雙模式選擇(Task 2, 4)
- ✅ pixel-diff 純 JS 偵測(Task 6)
- ✅ tap 模式 fallback(Task 4, 6)
- ✅ 4 ageGroups grid/target/timing 差異(Task 4)
- ✅ onHit 共用(Task 5)
- ✅ 達標慶祝接 completeActivity(Task 5)
- ✅ 🔴 LIVE 指示 + ❌ 結束(Task 2 HTML / Task 7 行為)
- ✅ 退出釋放鏡頭(Task 7)
- ✅ ACTIVITY_LABELS / 貼紙(Task 8 / Task 1)
- ✅ 設定面板 toggle(Task 8)
- ✅ tab bar overflow CSS(Task 3)
- ✅ Brain 5 個踩坑點 audit(Task 9)
- ✅ 零 CDN 檢查(Task 9)

**未在 plan 內(YAGNI,spec 也排除):**
- 校準/baseline、連擊、最高分、音效、雙人、限時、闖關、移動目標 — 都明確不做

**型別一致性:**
- `whackState.holes[i]` 結構在 Task 4 定義(`{el, active, moleEl, spawnedAt, timeoutTimer, cooldownUntil}`),Task 5/6/7 使用一致
- `WHACK_CONFIG[ageGroup]` 屬性名:`cols/rows/holes/target/moleStayMs/maxSimultaneous/distHint` — 在 Task 4 定義,後續 task 引用一致
- `onWhackHit(idx)` 簽名:Task 4 佔位 / Task 5 實作 / Task 6 呼叫 — 一致

**Placeholder 掃描:** 無 TBD / TODO,所有 code block 都有完整實作。

---

**Plan 完成,儲存在 `kids-companion/docs/superpowers/plans/2026-05-23-whack-a-mole.md`**
