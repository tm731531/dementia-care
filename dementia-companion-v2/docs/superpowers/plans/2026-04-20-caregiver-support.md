# 照護者支援功能 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 v2 加入「陪伴指南」與「今日摘要」兩個照護者支援功能，不引入資料庫與測試框架，全部做在既有的單一 HTML 檔案中。

**Architecture:** 所有程式碼繼續收在 `dementia-companion-v2/index.html` 一個檔。資料（45 條提示、描述句規則）以純 JS 常數存放；UI 以原有 `.screen`/`.modal-backdrop` 系統擴充；狀態分成「session 記憶體」（`APP.session`）與「一個 localStorage 字串」（`elderName`）兩層，刻意不做資料庫。

**Tech Stack:** HTML + CSS + 純 JS（無框架、無建置工具、無測試框架）。驗證靠 `node -e` 做語法與純函數 asserts、`grep` 做結構檢查、人工瀏覽器測試做 UI 行為。

**Spec:** `docs/superpowers/specs/2026-04-20-caregiver-support-design.md`

---

## File Structure

全部動作都在 `dementia-companion-v2/index.html` 這一個檔案：

- **新增 CSS**：`.tip-banner`、`.tip-icon`、`.summary-btn`、`#summary-modal`、`#elder-name-modal`
- **新增 DOM**：15 個遊戲 screen 內各加一組 `.tip-banner` + `.tip-icon`；首頁加 `.summary-btn`；兩個新 modal
- **新增 JS**：`TIPS` 常數、`TipBanner` 控制器、`APP.session`、`recordCompletion`、`formatSummary`（純函數，可測試）、`showSummaryModal`、`showElderNameModal`、`copySummary`
- **修改 JS**：15 個遊戲的 start / correct / complete 時機呼叫 `TipBanner.show()`；完成流程呼叫 `recordCompletion()`

**為何不分檔**：CLAUDE.md 明確規定「所有功能維持在單一 index.html」，v2 沿用此約束。

---

## Verification Strategy

沒有測試框架，採三種驗證：

1. **JS 語法檢查** — `node -e "new Function(fs.readFileSync('index.html','utf8').match(/<script>([\s\S]*?)<\/script>/)[1])"`
2. **純函數單元測試** — 將可測試的邏輯（例 `formatSummary`）寫成無 DOM 依賴的函數，在 plan 中用 `node -e` 直接載入執行斷言
3. **人工 UI 測試** — 打開 `file:///.../dementia-companion-v2/index.html`，照每個 Task 尾端的「Manual check」步驟點擊驗證

**不要 commit 如果：**
- JS 語法檢查失敗
- 純函數 asserts 失敗
- 頁面打開主控台（Console）有紅色錯誤

---

## Task 1: TIPS 資料常數

**目的：** 把 spec 裡 15 遊戲 × 3 時機 = 45 條提示寫成一個 JS 常數，放進既有的資料區塊（`GAMES` 陣列之後）。

**Files:**
- Modify: `dementia-companion-v2/index.html`（在 `const GAMES = [...]` 區塊之後、`function getTimeOfDay()` 之前插入 `TIPS` 常數）

**Steps:**

- [ ] **Step 1: 定位插入點**

  Run: `grep -n "^function getTimeOfDay" dementia-companion-v2/index.html`
  Expected: 一行如 `1163:function getTimeOfDay() {`

- [ ] **Step 2: 在該行之前插入 TIPS 常數**

  把下列整段插入到 `function getTimeOfDay()` 前一行：

  ```js
  // 45 條陪伴提示：15 遊戲 × 3 時機（start / correct / complete）
  // breath 特例：correct 改用 mid（中段顯示）
  const TIPS = {
    color:       { start: '哇，好多顏色，你以前最愛穿什麼顏色？', correct: '對！你好厲害',            complete: '今天陪你看顏色，我也覺得很漂亮' },
    pairs:       { start: '這個要記一下，慢慢翻沒關係',           correct: '哎喲！你記得耶',            complete: '你記憶力真好' },
    word:        { start: '這個字你以前就認得吧',                 correct: '對啦，這個字你小時候就會了', complete: '今天還認這麼多字,真棒' },
    differences: { start: '看看這兩排哪一個不一樣?',              correct: '你眼睛真利!',               complete: '你觀察力比我還好' },
    clock:       { start: '以前上學都要看這個呢',                 correct: '你看時間很準',              complete: '看時鐘不難吧？' },
    matching:    { start: '看看哪個配哪個,慢慢來',                correct: '對！就是這一對',            complete: '都配對完了,好厲害' },
    shape:       { start: '看看是什麼形狀',                       correct: '對啦,一樣的形狀',           complete: '這些形狀你都認得' },
    picture:     { start: '這個你認得吧,以前家裡可能有',          correct: '沒錯!',                     complete: '這些東西你都認得好熟' },
    number:      { start: '以前買菜都要算錢的',                   correct: '對,就是這個數字',           complete: '數字你還是那麼清楚' },
    sorting:     { start: '從小到大排排看',                       correct: '對!你排得真好',             complete: '你很會排喔' },
    classify:    { start: '想想這個是哪一類',                     correct: '沒錯,就是那邊',             complete: '分類對你來說不難吧' },
    counting:    { start: '一起數數看有幾個',                     correct: '對,就是這麼多個',           complete: '數得很準' },
    emotion:     { start: '看看他的表情是怎麼樣',                 correct: '對,他看起來就是這樣',       complete: '你很會看人的心情' },
    breath:      { start: '我們一起慢慢呼吸',                     mid:     '吸氣...吐氣...不急',        complete: '輕輕摸摸他的手,這樣就好' },
    body:        { start: '聽聽看要指哪裡',                       correct: '對,就是那邊',               complete: '你身體的名稱都記得很清楚' },
  };

  ```

- [ ] **Step 3: 驗證 JS 語法 OK 且 TIPS 有 15 個 key**

  Run:
  ```bash
  node -e "
  const fs=require('fs');
  const html=fs.readFileSync('dementia-companion-v2/index.html','utf8');
  const js=html.match(/<script>([\s\S]*?)<\/script>/)[1];
  new Function(js + '; return TIPS;'); // syntax check
  const fn = new Function(js + '; return TIPS;');
  const TIPS = fn();
  const expectedKeys = ['color','pairs','word','differences','clock','matching','shape','picture','number','sorting','classify','counting','emotion','breath','body'];
  const missing = expectedKeys.filter(k => !TIPS[k]);
  if (missing.length) throw new Error('Missing TIPS keys: ' + missing.join(','));
  for (const k of expectedKeys) {
    const need = k === 'breath' ? ['start','mid','complete'] : ['start','correct','complete'];
    for (const m of need) {
      if (!TIPS[k][m] || TIPS[k][m].length < 2) throw new Error(k + '.' + m + ' missing');
    }
  }
  console.log('TIPS OK: 15 games, 45 tips total');
  "
  ```
  Expected: `TIPS OK: 15 games, 45 tips total`

- [ ] **Step 4: Commit**

  ```bash
  cd /home/tom/Desktop/dementia-care
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 加入 TIPS 常數（15 遊戲 × 3 時機共 45 條陪伴提示）"
  ```

---

## Task 2: Tip banner / icon 的 CSS 與共用 HTML

**目的：** 在 `<style>` 區塊加入 `.tip-banner` 與 `.tip-icon` 的樣式；因為銀光綠色的 feedback 已經修過，這次繼續用 `#333333` 深灰確保跟純黑 bg 有邊界。

**Files:**
- Modify: `dementia-companion-v2/index.html`（在 `/* ===== Feedback banner ===== */` 區塊下方新增 `/* ===== Tip banner ===== */`）

**Steps:**

- [ ] **Step 1: 定位插入點**

  Run: `grep -n "Feedback banner" dementia-companion-v2/index.html`
  找到 CSS 註解 `/* ===== Feedback banner ===== */`，然後找該區塊結束後的下一個區塊起點（例如 `/* ===== Complete screen ===== */`）——插入點是 Complete screen 前一行。

- [ ] **Step 2: 在 Complete screen 區塊前插入 tip banner CSS**

  ```css
      /* ===== Tip banner（照護者陪伴指南） ===== */
      .tip-banner {
        background: #333333;
        color: #FFFFFF;
        padding: 16px 24px;
        border-radius: 12px;
        font-size: 18px;
        line-height: 1.5;
        margin-bottom: 16px;
        opacity: 0;
        transform: translateY(-10px);
        transition: opacity 0.3s, transform 0.3s;
        pointer-events: none;
        display: none;
      }
      .tip-banner.show {
        opacity: 1;
        transform: translateY(0);
        pointer-events: auto;
        display: block;
      }
      .tip-banner::before {
        content: '💬 ';
      }
      .tip-icon {
        position: absolute;
        top: 16px;
        right: 16px;
        width: 44px;
        height: 44px;
        border-radius: 50%;
        background: #333333;
        border: 2px solid #FFFFFF;
        color: #FFFFFF;
        font-size: 22px;
        line-height: 40px;
        text-align: center;
        cursor: pointer;
        font-family: inherit;
        padding: 0;
        z-index: 50;
        display: none;
      }
      .tip-icon.show { display: block; }
      .tip-icon:hover { background: #555555; }
      .screen { position: relative; } /* 讓 tip-icon 的 absolute 定位錨定在 screen */
  ```

- [ ] **Step 3: 驗證 CSS 與 JS 仍正常**

  Run:
  ```bash
  grep -c "\.tip-banner" dementia-companion-v2/index.html
  grep -c "\.tip-icon" dementia-companion-v2/index.html
  node -e "const fs=require('fs');const html=fs.readFileSync('dementia-companion-v2/index.html','utf8');const m=html.match(/<script>([\s\S]*?)<\/script>/);new Function(m[1]);console.log('JS OK')"
  ```
  Expected:
  - `.tip-banner` 出現 ≥ 4 次（定義 + `.show` + `::before` + `.screen` 不算）
  - `.tip-icon` 出現 ≥ 3 次
  - `JS OK`

- [ ] **Step 4: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 加入 tip banner / icon 的 CSS（深灰底白字符合 AAA 對比）"
  ```

---

## Task 3: TipBanner 控制器（JS 邏輯）

**目的：** 提供 `TipBanner.show(gameId, moment)`、`TipBanner.collapse()`、`TipBanner.expand()` 三個方法，管理目前顯示哪個遊戲哪個時機的提示，5 秒後自動摺疊。

**Files:**
- Modify: `dementia-companion-v2/index.html`（在 `TIPS` 常數之後、`function getTimeOfDay()` 之前插入）

**Steps:**

- [ ] **Step 1: 定位插入點**

  Run: `grep -n "^function getTimeOfDay" dementia-companion-v2/index.html`

- [ ] **Step 2: 插入 TipBanner 物件**

  在 `function getTimeOfDay()` 前一行加入：

  ```js
  // TipBanner 控制器：管理遊戲畫面上的陪伴指南
  const TipBanner = {
    currentGame: null,
    currentMoment: null,
    collapseTimer: null,

    // 在指定遊戲的 banner 元素顯示對應時機的提示，並在 5 秒後收起成 icon
    show(gameId, moment) {
      this.currentGame = gameId;
      this.currentMoment = moment;

      const tip = TIPS[gameId] && TIPS[gameId][moment];
      if (!tip) return;

      const banner = document.getElementById('tip-banner-' + gameId);
      const icon = document.getElementById('tip-icon-' + gameId);
      if (!banner || !icon) return;

      banner.textContent = tip;
      banner.classList.add('show');
      icon.classList.remove('show');

      clearTimeout(this.collapseTimer);
      // complete 時機不自動收起,讓它一直顯示在完成畫面
      if (moment !== 'complete') {
        this.collapseTimer = setTimeout(() => this.collapse(), 5000);
      }
    },

    collapse() {
      if (!this.currentGame) return;
      const banner = document.getElementById('tip-banner-' + this.currentGame);
      const icon = document.getElementById('tip-icon-' + this.currentGame);
      if (banner) banner.classList.remove('show');
      if (icon) icon.classList.add('show');
    },

    expand() {
      if (!this.currentGame || !this.currentMoment) return;
      this.show(this.currentGame, this.currentMoment);
    },

    reset() {
      this.currentGame = null;
      this.currentMoment = null;
      clearTimeout(this.collapseTimer);
    },
  };

  ```

- [ ] **Step 3: 驗證 JS 語法 OK**

  Run:
  ```bash
  node -e "const fs=require('fs');const html=fs.readFileSync('dementia-companion-v2/index.html','utf8');const m=html.match(/<script>([\s\S]*?)<\/script>/);new Function(m[1]);console.log('JS OK')"
  ```
  Expected: `JS OK`

- [ ] **Step 4: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 加入 TipBanner 控制器（show/collapse/expand/reset）"
  ```

---

## Task 4: 插入 tip-banner + tip-icon DOM 到 15 個遊戲 screen

**目的：** 每個 `id="game-xxx"` 的 screen 在 `.game-header` 下方、`.round-indicator` 上方插入兩個元素：banner 與 icon。

**Files:**
- Modify: `dementia-companion-v2/index.html`（15 個遊戲 screen）

**Steps:**

- [ ] **Step 1: 找到所有遊戲 screen**

  Run: `grep -n 'id="game-' dementia-companion-v2/index.html`
  列出 15 個 id：color, word, shape, number, classify, picture, clock, matching, sorting, breath, emotion, counting, differences, pairs, body

- [ ] **Step 2: 對每個遊戲，在 `<div class="game-header">` 區塊結束後插入 banner + icon**

  **範本（以 color 為例）：**

  找到：
  ```html
    <div id="game-color" class="screen">
      <div class="game-header">
        <button class="back-btn" onclick="goHome()">← 回首頁</button>
        <h2>🎨 顏色辨識</h2>
        <div style="width: 100px;"></div>
      </div>
  ```

  在 `</div>` 之後（`.game-header` 結束後），插入：
  ```html
      <button class="tip-icon" id="tip-icon-color" onclick="TipBanner.expand()">💬</button>
      <div class="tip-banner" id="tip-banner-color" onclick="TipBanner.collapse()"></div>
  ```

  **對以下 15 個 id 全部重複此插入：**
  `color, word, shape, number, classify, picture, clock, matching, sorting, breath, emotion, counting, differences, pairs, body`

  注意：id 命名為 `tip-icon-{gameId}` 與 `tip-banner-{gameId}`，跟 TIPS 常數的 key 一致。

- [ ] **Step 3: 驗證 15 組 banner + icon 都插入了**

  Run:
  ```bash
  for id in color word shape number classify picture clock matching sorting breath emotion counting differences pairs body; do
    count_banner=$(grep -c "id=\"tip-banner-$id\"" dementia-companion-v2/index.html)
    count_icon=$(grep -c "id=\"tip-icon-$id\"" dementia-companion-v2/index.html)
    if [ "$count_banner" != "1" ] || [ "$count_icon" != "1" ]; then
      echo "MISSING: $id (banner=$count_banner, icon=$count_icon)"
    fi
  done
  echo "check done"
  ```
  Expected: 只印出 `check done`，沒有 `MISSING:` 行

- [ ] **Step 4: Manual check — banner 元素存在但預設隱藏**

  - 用瀏覽器打開 `dementia-companion-v2/index.html`
  - 首頁應該跟之前一樣，沒有多出任何 UI
  - F12 → Elements，搜尋 `tip-banner-color` 應該找得到但 style 是 `display: none`
  - 點進顏色辨識 → 目前還不會顯示（下一個 task 才接上）

- [ ] **Step 5: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 15 個遊戲 screen 插入 tip-banner + tip-icon DOM"
  ```

---

## Task 5: 串接 start 時機（進入每個遊戲時顯示提示）

**目的：** 所有遊戲的起始函式（`startColorGame()`、`WordGame.init()` 等）一開始呼叫 `TipBanner.show(gameId, 'start')`。

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 列出 15 個遊戲的起始函式位置**

  Run: `grep -nE "function start\w+Game|const (\w+)Game = \{" dementia-companion-v2/index.html`

  預期對應表（id → 起始函式）：
  - `color` → `function startColorGame() { ... }` — 第一行加 `TipBanner.show('color', 'start');`
  - `word` → `WordGame.init()` 內 — 加 `TipBanner.show('word', 'start');`
  - `shape` → `ShapeGame.init()` 內
  - `number` → `NumberGame.init()` 內
  - `classify` → `ClassifyGame.init()` 內
  - `picture` → `PictureGame.init()` 內
  - `clock` → `ClockGame.init()` 內
  - `matching` → `MatchingGame.init()` 內
  - `sorting` → `SortingGame.init()` 內
  - `breath` → `startBreathGame()` 內
  - `emotion` → `EmotionGame.init()` 內
  - `counting` → `CountingGame.init()` 內
  - `differences` → `DifferencesGame.init()` 內
  - `pairs` → `PairsGame.init()` 內
  - `body` → `BodyGame.init()` 內

- [ ] **Step 2: 對每個遊戲，在 init/start 函式的 `showScreen('game-xxx');` 之後加一行 `TipBanner.show('xxx', 'start');`**

  **範本（以 color 為例，`function startColorGame()` 內）：**

  找到：
  ```js
  function startColorGame() {
    APP.game = { ... };
    document.getElementById('color-complete').classList.remove('show');
    showScreen('game-color');
    nextColorRound();
  }
  ```

  改為：
  ```js
  function startColorGame() {
    APP.game = { ... };
    document.getElementById('color-complete').classList.remove('show');
    showScreen('game-color');
    TipBanner.show('color', 'start');
    nextColorRound();
  }
  ```

  **範本（以 word 為例，`WordGame.init()` 內）：**

  找到 `init()` 方法裡 `showScreen('game-word');` 那一行，在下一行加 `TipBanner.show('word', 'start');`。

  **對所有 15 個遊戲重複。**

- [ ] **Step 3: 驗證 15 處呼叫都加上**

  Run:
  ```bash
  grep -cE "TipBanner\.show\('(color|word|shape|number|classify|picture|clock|matching|sorting|breath|emotion|counting|differences|pairs|body)', 'start'\)" dementia-companion-v2/index.html
  ```
  Expected: `15`

- [ ] **Step 4: Manual check — 進入每個遊戲看到 start 提示**

  開瀏覽器 → 首頁 → 點「我想自己選」 → 依序點開幾個遊戲（例如顏色、認字、翻牌、呼吸）：
  - 進入每個遊戲時，上方應立刻看到深灰色 banner 顯示該遊戲的 start 提示
  - 5 秒後 banner 收起，右上角出現 💬 icon
  - 點 💬 icon banner 再出現

- [ ] **Step 5: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 串接 start 時機 — 15 遊戲進入時顯示照護者提示"
  ```

---

## Task 6: 串接 correct 時機（答對時切換提示）

**目的：** 14 個有答對/答錯邏輯的遊戲（排除 breath，因為沒有答對概念），答對時呼叫 `TipBanner.show(gameId, 'correct')`。

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 對每個遊戲的答對分支插入呼叫**

  **範本（以 color 為例，`handleColorPick` 函式內）：**

  找到：
  ```js
  function handleColorPick(el, opt) {
    const g = APP.game;
    if (opt.name === g.currentAnswer.name) {
      el.classList.add('correct');
      const praise = randomPraise();
      showFeedback(praise);
      speak(praise);
      g.round++;
      setTimeout(nextColorRound, 1400);
    } else {
      ...
    }
  }
  ```

  在答對分支的最開頭（`el.classList.add('correct');` 前或緊接之後）加：
  ```js
      TipBanner.show('color', 'correct');
  ```

  **對以下 14 個遊戲重複**（在各自的「答對」分支——通常是 `if (isCorrect)` 或 `if (opt.name === target)` 這類條件的開頭）：
  - color: `handleColorPick` 內
  - word: `WordGame.checkAnswer` 內 `if (opt.isCorrect)`
  - shape: `ShapeGame.checkAnswer` 類似位置
  - number, classify, picture, clock, matching, sorting, emotion, counting, differences, pairs, body：各自的 checkAnswer / handlePick / matchAttempt 內

  **特例 breath：不插入 correct，改在 Task 7 處理 mid**

- [ ] **Step 2: 驗證 14 處呼叫都加上**

  Run:
  ```bash
  grep -cE "TipBanner\.show\('(color|word|shape|number|classify|picture|clock|matching|sorting|emotion|counting|differences|pairs|body)', 'correct'\)" dementia-companion-v2/index.html
  ```
  Expected: `14`

- [ ] **Step 3: Manual check — 玩一個遊戲答對時切換提示**

  開顏色辨識 → 等 start 提示收起（5 秒）→ 點正確答案：
  - Banner 應該再次出現，顯示 correct 提示（例：「對！你好厲害」）
  - 5 秒後收起成 💬 icon
  - 下一題答對時再切回 correct 提示

- [ ] **Step 4: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 串接 correct 時機 — 14 遊戲答對時切換提示"
  ```

---

## Task 7: 串接 complete 時機 + breath mid

**目的：**
1. 15 個遊戲完成時，在 complete screen 顯示對應的 complete 提示
2. breath 遊戲在呼吸循環進行到一半時，顯示 mid 提示

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 在每個遊戲的「完成」路徑呼叫 `TipBanner.show(id, 'complete')`**

  **範本（color 的 finishColorGame）：**
  ```js
  function finishColorGame() {
    document.getElementById('color-complete').classList.add('show');
    TipBanner.show('color', 'complete');
    speak('全部完成了，你好厲害！');
  }
  ```

  其他遊戲通常在 `nextRound()` 的 `if (round > total)` 分支裡 `document.getElementById('xxx-complete').classList.add('show')` 的那一行下面插一行 `TipBanner.show('xxx', 'complete');`。

  **對全部 15 個遊戲重複**（包含 breath，breath 的 complete 在完成動畫結束時觸發）。

- [ ] **Step 2: breath 特例 — 加入 mid 時機**

  定位 `function startBreathGame()` 和 breath 遊戲的呼吸循環（通常有個 `breathCycle` 或 `doBreath` 函式）。

  Run: `grep -nE "breathing-text|breathCycle|inhale|exhale" dementia-companion-v2/index.html`

  在呼吸循環每輪執行到「吐氣」階段開始時插入一次 `TipBanner.show('breath', 'mid');`，讓中段提示「吸氣...吐氣...不急」出現。

  > 注意：由於 mid 提示每輪都會跳，這裡**不要**每輪都呼叫，只在第 2 輪（總共 4 輪的一半）呼叫一次。加一個 counter：
  > ```js
  > if (this.cycleCount === 2) TipBanner.show('breath', 'mid');
  > ```
  > （實際實作依 breath 遊戲的現有結構決定變數名）

- [ ] **Step 3: 驗證 15 處 complete + 1 處 mid**

  Run:
  ```bash
  grep -cE "TipBanner\.show\('[a-z]+', 'complete'\)" dementia-companion-v2/index.html
  grep -cE "TipBanner\.show\('breath', 'mid'\)" dementia-companion-v2/index.html
  ```
  Expected:
  - complete: `15`
  - mid: `1`

- [ ] **Step 4: Manual check — 完整玩完 2 個遊戲**

  - 玩完一輪顏色辨識到 complete screen → 看到 complete 提示（例：「今天陪你看顏色，我也覺得很漂亮」）並且**不會**自動消失
  - 玩呼吸練習到第 2 輪中段 → mid 提示出現

- [ ] **Step 5: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 串接 complete 時機 + breath mid — 15 遊戲完成時顯示照護者提示"
  ```

---

## Task 8: APP.session 狀態與 recordCompletion()

**目的：** 新增 session 記憶體層，記錄本次打開到現在完成了哪些活動；每個遊戲完成時呼叫 `recordCompletion(id)`。

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 擴充 APP 物件**

  Run: `grep -n "^const APP" dementia-companion-v2/index.html`

  找到既有的 `const APP = { ... };` 區塊，加入 `session` 欄位：

  找到：
  ```js
  const APP = {
    level: 4,
    history: {},
    currentRec: null,
    game: null,
  };
  ```

  改為：
  ```js
  const APP = {
    level: 4,
    history: {},
    currentRec: null,
    game: null,
    session: {
      startTime: Date.now(),
      completed: [],
    },
  };
  ```

- [ ] **Step 2: 新增 `recordCompletion()` 函式**

  在 `function startGame(id)` 之後插入：

  ```js
  // 記錄一個活動完成(純 session,不存 localStorage)
  function recordCompletion(id) {
    const game = GAMES.find(g => g.id === id);
    if (!game) return;
    APP.session.completed.push({
      id: id,
      name: game.name,
      icon: game.icon,
      finishedAt: Date.now(),
    });
    renderSummaryButton(); // Task 9 會實作
  }

  ```

- [ ] **Step 3: 插入暫時的 `renderSummaryButton` 空函式避免錯誤**

  在 `recordCompletion` 之後加一個 placeholder（Task 9 會補實作）：

  ```js
  function renderSummaryButton() {
    // placeholder: Task 9 實作
  }

  ```

- [ ] **Step 4: 在 15 個遊戲的 complete 路徑中呼叫 recordCompletion**

  在 Task 7 已經加入 `TipBanner.show(id, 'complete')` 的那幾個地方，緊接著加一行 `recordCompletion('xxx');`。

  **範本（color）：**
  ```js
  function finishColorGame() {
    document.getElementById('color-complete').classList.add('show');
    TipBanner.show('color', 'complete');
    recordCompletion('color');
    speak('全部完成了，你好厲害！');
  }
  ```

- [ ] **Step 5: 驗證 15 處 recordCompletion 呼叫**

  Run:
  ```bash
  grep -cE "recordCompletion\('(color|word|shape|number|classify|picture|clock|matching|sorting|breath|emotion|counting|differences|pairs|body)'\)" dementia-companion-v2/index.html
  ```
  Expected: `15`

- [ ] **Step 6: Manual check — session 記錄正常**

  開瀏覽器 → F12 Console → 玩完一個遊戲到 complete 畫面 → 在 Console 輸入：
  ```js
  APP.session.completed
  ```
  Expected: 陣列有一個物件，含 `id`, `name`, `icon`, `finishedAt`

- [ ] **Step 7: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 新增 APP.session 狀態層與 recordCompletion() 記錄活動"
  ```

---

## Task 9: 首頁「把今天傳給家人」按鈕（條件顯示）

**目的：** 首頁 `.difficulty-pill` 下方新增一個按鈕，只在 `APP.session.completed.length >= 1` 時出現。

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 加 CSS**

  找到 `/* ===== Tip banner */` 區塊之後，加：

  ```css
      /* ===== Summary button（今日摘要觸發） ===== */
      .summary-btn {
        display: none;
        margin: 24px auto 0;
        background: transparent;
        color: #FFFFFF;
        border: 2px solid #FFFFFF;
        padding: 14px 28px;
        font-size: 18px;
        border-radius: 12px;
        cursor: pointer;
        font-family: inherit;
        font-weight: 600;
      }
      .summary-btn.show { display: block; }
      .summary-btn:hover { background: #FFFFFF; color: #000000; }
  ```

- [ ] **Step 2: 加首頁 HTML 按鈕**

  找到首頁的 `.difficulty-pill` 區塊，在其關閉 `</div>` 之後加：

  ```html
      <button class="summary-btn" id="summary-btn" onclick="showSummaryModal()">📝 把今天傳給家人</button>
  ```

- [ ] **Step 3: 實作 renderSummaryButton（取代 Task 8 的 placeholder）**

  找到 Task 8 插入的 placeholder，替換為：

  ```js
  function renderSummaryButton() {
    const btn = document.getElementById('summary-btn');
    if (!btn) return;
    if (APP.session.completed.length >= 1) {
      btn.classList.add('show');
    } else {
      btn.classList.remove('show');
    }
  }
  ```

- [ ] **Step 4: 首頁進入時也要呼叫一次 renderSummaryButton**

  找到 `function goHome()`:

  ```js
  function goHome() {
    renderRecommendation();
    showScreen('home');
  }
  ```

  改為：
  ```js
  function goHome() {
    renderRecommendation();
    renderSummaryButton();
    showScreen('home');
  }
  ```

- [ ] **Step 5: 先加 `showSummaryModal` 的 stub 避免 onclick 錯誤**

  在 renderSummaryButton 之後加：

  ```js
  function showSummaryModal() {
    // stub: Task 11 實作
    console.log('summary modal stub — session:', APP.session.completed);
  }

  ```

- [ ] **Step 6: 驗證**

  Run: JS 語法檢查
  ```bash
  node -e "const fs=require('fs');const html=fs.readFileSync('dementia-companion-v2/index.html','utf8');const m=html.match(/<script>([\s\S]*?)<\/script>/);new Function(m[1]);console.log('JS OK')"
  ```
  Expected: `JS OK`

- [ ] **Step 7: Manual check**

  - 打開頁面 → 首頁沒有「把今天傳給家人」按鈕
  - 玩完一個遊戲到 complete → 按「回首頁」→ 按鈕出現
  - Reload 頁面 → 按鈕消失
  - 玩兩個活動再回首頁 → 按鈕還在
  - 按一下按鈕 → F12 Console 看到 `summary modal stub — session: [...]`

- [ ] **Step 8: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 首頁新增條件顯示的「把今天傳給家人」按鈕"
  ```

---

## Task 10: 稱呼設定 modal（elder name prompt）

**目的：** 第一次點 summary 按鈕時，問照護者怎麼稱呼長輩，存到 `localStorage.elderName`。

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 加 modal HTML**

  找到既有 `.modal-backdrop` 的其他 modal（例如難度 modal），在附近加入：

  ```html
    <!-- ===== Elder name modal ===== -->
    <div class="modal-backdrop" id="elder-name-modal">
      <div class="modal">
        <h2>請問您要怎麼稱呼長輩？</h2>
        <p style="color:#333; font-size:16px; margin-bottom:20px;">之後的紀錄都會這樣寫</p>
        <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:12px;">
          <button class="btn-name-choice" onclick="saveElderName('爸')">爸</button>
          <button class="btn-name-choice" onclick="saveElderName('媽')">媽</button>
          <button class="btn-name-choice" onclick="saveElderName('奶奶')">奶奶</button>
          <button class="btn-name-choice" onclick="saveElderName('外公')">外公</button>
          <button class="btn-name-choice" onclick="saveElderName('外婆')">外婆</button>
          <button class="btn-name-choice" onclick="saveElderName('阿公')">阿公</button>
          <button class="btn-name-choice" onclick="saveElderName('阿嬤')">阿嬤</button>
          <button class="btn-name-choice" onclick="saveElderName('爺爺')">爺爺</button>
          <button class="btn-name-choice" onclick="promptCustomName()">其他...</button>
        </div>
        <div class="modal-actions">
          <button class="btn-cancel" onclick="closeElderNameModal()">取消</button>
        </div>
      </div>
    </div>
  ```

- [ ] **Step 2: 加對應 CSS**

  在 `.btn-cancel` 規則之後加：

  ```css
      .btn-name-choice {
        background: #000000;
        color: #FFFFFF;
        border: 2px solid #000000;
        padding: 16px;
        border-radius: 12px;
        font-size: 22px;
        cursor: pointer;
        font-family: inherit;
        font-weight: 700;
        min-height: 56px;
      }
      .btn-name-choice:hover {
        background: #FFFFFF;
        color: #000000;
      }
  ```

- [ ] **Step 3: 實作三個函式**

  在 `function showSummaryModal() { ... stub ... }` 附近加：

  ```js
  function showElderNameModal(onDone) {
    APP.pendingAfterName = onDone || null;
    document.getElementById('elder-name-modal').classList.add('show');
  }

  function closeElderNameModal() {
    document.getElementById('elder-name-modal').classList.remove('show');
    APP.pendingAfterName = null;
  }

  function saveElderName(name) {
    try { localStorage.setItem('elderName', name); } catch(e) {}
    const cb = APP.pendingAfterName;
    closeElderNameModal();
    if (cb) cb();
  }

  function promptCustomName() {
    const name = window.prompt('請輸入稱呼（例如：阿公、阿嬤）');
    if (name && name.trim()) saveElderName(name.trim());
  }

  function getElderName() {
    try { return localStorage.getItem('elderName') || ''; } catch(e) { return ''; }
  }

  ```

- [ ] **Step 4: 修改 showSummaryModal stub，先問名字**

  ```js
  function showSummaryModal() {
    const name = getElderName();
    if (!name) {
      showElderNameModal(() => showSummaryModal()); // 問完再呼叫自己
      return;
    }
    // 有名字了 — Task 11 實作真正的 modal
    console.log('summary would show for', name, 'session:', APP.session.completed);
  }
  ```

- [ ] **Step 5: 驗證**

  JS 語法檢查通過。

- [ ] **Step 6: Manual check**

  - 開無痕視窗（確保沒 elderName）→ 玩完 1 個活動 → 回首頁點 summary 按鈕
  - 看到「請問您要怎麼稱呼長輩？」 modal，9 個選項
  - 點「爸」→ modal 關閉 → Console 顯示 `summary would show for 爸 session: [...]`
  - 再點一次 summary 按鈕 → 不再問（因為已有 elderName）
  - 點「其他...」→ 跳 window.prompt → 輸入「阿姨」→ 下次不再問
  - `localStorage.getItem('elderName')` 在 Console 確認有值

- [ ] **Step 7: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 新增稱呼設定 modal（第一次分享前問，存 localStorage.elderName）"
  ```

---

## Task 11: formatSummary 純函數（可用 node 直接測試）

**目的：** 寫一個純函數 `formatSummary(session, elderName, now)` 回傳最終要複製的文字。純函數、無 DOM 依賴，所以可用 `node -e` 直接 assert。

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 在 `getElderName()` 之後加 formatSummary 函式**

  ```js
  // formatSummary: 依 session 資料產生摘要文字(純函數,可用 node 測試)
  function formatSummary(session, elderName, now) {
    now = now || new Date();
    const name = elderName || '家人';

    const h = now.getHours();
    let timeLabel;
    if (h < 5)       timeLabel = '凌晨';
    else if (h < 11) timeLabel = '早上';
    else if (h < 13) timeLabel = '中午';
    else if (h < 18) timeLabel = '下午';
    else if (h < 22) timeLabel = '晚上';
    else             timeLabel = '深夜';

    const dateStr = now.getFullYear() + '/' + (now.getMonth()+1) + '/' + now.getDate();
    const mins = Math.max(1, Math.ceil((now.getTime() - session.startTime) / 60000));

    const activityLines = session.completed.map(c => '▸ ' + c.name).join('\n');

    const count = session.completed.length;
    let desc;
    if (count === 1)       desc = '一起做了一件事,陪著他就很好';
    else if (count === 2)  desc = '他配合度不錯,狀態還可以';
    else if (count === 3)  desc = '他配合度很好,狀態平穩 😊';
    else if (count <= 5)   desc = '今天狀態很好,玩了好幾樣 🌟';
    else                   desc = '今天狀態非常好,玩了一圈呢 🎉';

    return `📝 ${dateStr} ${timeLabel}
今天和${name}一起玩了 ${mins} 分鐘

${activityLines}

${desc}`;
  }

  ```

- [ ] **Step 2: 用 node 直接 assert 純函數邏輯**

  Run:
  ```bash
  node -e "
  const fs=require('fs');
  const html=fs.readFileSync('dementia-companion-v2/index.html','utf8');
  const js=html.match(/<script>([\s\S]*?)<\/script>/)[1];
  const fn = new Function(js + '; return formatSummary;');
  const formatSummary = fn();

  // Case 1: 下午, 1 個活動
  const now1 = new Date('2026-04-20T14:30:00');
  const s1 = { startTime: now1.getTime() - 5*60000, completed: [{id:'color',name:'顏色辨識',icon:'🎨'}] };
  const out1 = formatSummary(s1, '爸', now1);
  console.log('CASE 1:\n' + out1);
  if (!out1.includes('下午')) throw new Error('case1: 時段錯');
  if (!out1.includes('爸')) throw new Error('case1: 稱呼錯');
  if (!out1.includes('5 分鐘')) throw new Error('case1: 分鐘錯');
  if (!out1.includes('▸ 顏色辨識')) throw new Error('case1: 活動列表錯');
  if (!out1.includes('一起做了一件事')) throw new Error('case1: 1 活動描述錯');

  // Case 2: 晚上, 3 個活動
  const now2 = new Date('2026-04-20T20:30:00');
  const s2 = { startTime: now2.getTime() - 12*60000, completed: [
    {id:'breath',name:'呼吸練習'},{id:'color',name:'顏色辨識'},{id:'pairs',name:'翻牌配對'}
  ]};
  const out2 = formatSummary(s2, '媽', now2);
  console.log('\nCASE 2:\n' + out2);
  if (!out2.includes('晚上')) throw new Error('case2: 時段錯');
  if (!out2.includes('12 分鐘')) throw new Error('case2: 分鐘錯');
  if (!out2.includes('狀態平穩')) throw new Error('case2: 3 活動描述錯');

  // Case 3: 沒稱呼,1 分鐘,6 活動
  const now3 = new Date('2026-04-20T09:05:30');
  const s3 = { startTime: now3.getTime() - 30000, completed: [
    {name:'A'},{name:'B'},{name:'C'},{name:'D'},{name:'E'},{name:'F'}
  ]};
  const out3 = formatSummary(s3, '', now3);
  console.log('\nCASE 3:\n' + out3);
  if (!out3.includes('家人')) throw new Error('case3: 預設稱呼錯');
  if (!out3.includes('1 分鐘')) throw new Error('case3: 最少 1 分鐘錯');
  if (!out3.includes('玩了一圈')) throw new Error('case3: 6+ 活動描述錯');
  if (!out3.includes('早上')) throw new Error('case3: 時段錯');

  console.log('\nALL PASS');
  "
  ```
  Expected: 印出 3 個 case 的摘要文字，最後 `ALL PASS`

- [ ] **Step 3: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): formatSummary 純函數 — 依 session 產生可複製的摘要文字"
  ```

---

## Task 12: 今日摘要 modal + 複製功能

**目的：** 點「把今天傳給家人」→ 開 modal 預覽 formatSummary 的輸出 → 複製到剪貼簿，失敗則 fallback 到 textarea。

**Files:**
- Modify: `dementia-companion-v2/index.html`

**Steps:**

- [ ] **Step 1: 加 modal HTML**

  在 `#elder-name-modal` 之後加：

  ```html
    <!-- ===== Summary modal ===== -->
    <div class="modal-backdrop" id="summary-modal">
      <div class="modal">
        <h2>今天的紀錄</h2>
        <pre id="summary-text" style="background:#F5F5F5; color:#000; padding:20px; border-radius:12px; font-family:inherit; font-size:16px; white-space:pre-wrap; line-height:1.6; margin:0;"></pre>
        <textarea id="summary-fallback" style="display:none; width:100%; padding:12px; font-family:inherit; font-size:14px; margin-top:12px; border-radius:8px; border:1px solid #CCC;" rows="8" readonly></textarea>
        <div id="summary-hint" style="display:none; color:#CC6600; font-size:14px; margin-top:8px;">複製不了,請長按上方選取後複製</div>
        <div class="modal-actions">
          <button class="btn-cancel" onclick="closeSummaryModal()">我不要傳</button>
          <button class="btn-ok" onclick="copySummary()">📋 複製傳 LINE</button>
        </div>
      </div>
    </div>
  ```

- [ ] **Step 2: 改寫 showSummaryModal（取代 Task 10 的 stub）**

  ```js
  function showSummaryModal() {
    const name = getElderName();
    if (!name) {
      showElderNameModal(() => showSummaryModal());
      return;
    }
    const text = formatSummary(APP.session, name, new Date());
    document.getElementById('summary-text').textContent = text;
    document.getElementById('summary-fallback').value = text;
    document.getElementById('summary-fallback').style.display = 'none';
    document.getElementById('summary-hint').style.display = 'none';
    document.getElementById('summary-modal').classList.add('show');
  }

  function closeSummaryModal() {
    document.getElementById('summary-modal').classList.remove('show');
  }

  function copySummary() {
    const text = document.getElementById('summary-text').textContent;
    const doFallback = () => {
      const ta = document.getElementById('summary-fallback');
      ta.style.display = 'block';
      ta.focus();
      ta.select();
      document.getElementById('summary-hint').style.display = 'block';
    };

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(
        () => {
          showFeedback('已複製,貼到 LINE 群就好');
          setTimeout(closeSummaryModal, 1500);
        },
        doFallback
      );
    } else {
      doFallback();
    }
  }
  ```

- [ ] **Step 3: 驗證 JS 仍 OK**

  Run:
  ```bash
  node -e "const fs=require('fs');const html=fs.readFileSync('dementia-companion-v2/index.html','utf8');const m=html.match(/<script>([\s\S]*?)<\/script>/);new Function(m[1]);console.log('JS OK')"
  ```
  Expected: `JS OK`

- [ ] **Step 4: Manual check — 完整流程**

  1. 開瀏覽器 → 玩完 2 個活動 → 回首頁
  2. 點「把今天傳給家人」→（若第一次）選稱呼 → 看到摘要 modal
  3. 摘要內容應符合格式：
     - 日期 + 時段（例：2026/4/20 下午）
     - 「今天和 XX 一起玩了 N 分鐘」
     - 2 行 `▸ 活動名`
     - 「他配合度不錯,狀態還可以」（因為完成 2 個）
  4. 點「📋 複製傳 LINE」→ 綠色 feedback「已複製,貼到 LINE 群就好」→ modal 關閉
  5. 在別處 Ctrl+V → 應貼出摘要
  6. 點「我不要傳」→ modal 關閉、沒複製

- [ ] **Step 5: Commit**

  ```bash
  git add dementia-companion-v2/index.html
  git commit -m "feat(v2): 今日摘要 modal + 剪貼簿複製（含舊瀏覽器 textarea fallback）"
  ```

---

## Task 13: End-to-end 驗收 + 文件更新

**目的：** 整合驗收 spec 裡列出的驗收條件，確認全部 13 項通過；更新 v2 的使用說明（如有需要）。

**Files:**
- Read: `dementia-companion-v2/docs/superpowers/specs/2026-04-20-caregiver-support-design.md`
- Modify (optional): `dementia-companion-v2/index.html` 的 meta description（如想加新功能描述）

**Steps:**

- [ ] **Step 1: 跑完整驗收清單（照 spec 的驗收條件一個個打勾）**

  在瀏覽器打開 `file:///home/tom/Desktop/dementia-care/dementia-companion-v2/index.html`，然後：

  - [ ] 進入任一遊戲，頂部 5 秒內看到該遊戲的 start 提示
  - [ ] 提示 fade 後右上角有 💬 icon，點了能再展開
  - [ ] 答對時 banner 切換到 correct 提示（找不同/呼吸等無 correct 的除外）
  - [ ] 完成畫面顯示 complete 提示，且不會自動消失
  - [ ] 清除 localStorage 後 reload，首頁**沒有**「把今天傳給家人」按鈕
  - [ ] 完成 1 個活動後回首頁 → 按鈕**出現**
  - [ ] 點按鈕第一次 → 先跳稱呼選單，填完才看到摘要
  - [ ] 摘要 modal 顯示正確日期、時段、稱呼、分鐘數、活動列表、描述句
  - [ ] 不同完成數（1/2/3/5/7）下描述句對應切換
  - [ ] 點「複製傳 LINE」成功複製，toast 出現
  - [ ] 貼到其他地方 Ctrl+V 看到完整摘要文字
  - [ ] Reload 頁面後，按鈕消失，session 歸零
  - [ ] `localStorage.getItem('elderName')` 仍有值
  - [ ] 全部文字對比 AAA 7:1：banner 深灰底白字 ✓，summary modal 淺灰底黑字 ✓

- [ ] **Step 2: 跑 full JS 語法 + TIPS 完整性再測一次**

  Run:
  ```bash
  cd /home/tom/Desktop/dementia-care/dementia-companion-v2
  node -e "
  const fs=require('fs');
  const html=fs.readFileSync('index.html','utf8');
  const js=html.match(/<script>([\s\S]*?)<\/script>/)[1];
  new Function(js);
  console.log('✓ JS syntax OK');
  const fn = new Function(js + '; return {TIPS, GAMES, formatSummary};');
  const {TIPS, GAMES, formatSummary} = fn();
  if (Object.keys(TIPS).length !== 15) throw new Error('TIPS should have 15 entries');
  if (GAMES.length !== 15) throw new Error('GAMES should have 15 entries');
  const now = new Date();
  const s = {startTime: now.getTime() - 60000, completed: [{name:'test'}]};
  if (!formatSummary(s, '爸', now).includes('爸')) throw new Error('formatSummary broken');
  console.log('✓ TIPS=15, GAMES=15, formatSummary OK');
  "
  ```
  Expected: 兩個 ✓

- [ ] **Step 3: 推上 GitHub Pages**

  ```bash
  cd /home/tom/Desktop/dementia-care
  git push origin main
  ```

- [ ] **Step 4: Manual check — GitHub Pages 版本**

  等 1–2 分鐘後用手機開 `https://tm731531.github.io/dementia-care/dementia-companion-v2/` 跑一次完整流程：
  - 玩 2–3 個遊戲
  - 回首頁分享
  - 貼到 LINE 看看輸出

- [ ] **Step 5: 更新 CLAUDE.md（若需要）**

  若 v2 現在跟 v1 的功能差距夠大需要標示，在 parent `CLAUDE.md` 或 v2 自己的 README 中描述差異。這一步如無必要可跳過。

- [ ] **Step 6: 最終 commit（如有 CLAUDE.md / 文件更新）**

  ```bash
  git add -A
  git commit -m "docs(v2): 照護者支援功能驗收完成,更新說明"
  git push origin main
  ```

---

## 如果卡住

- **JS 語法錯誤 / undefined function** → 先確認 TipBanner、recordCompletion、formatSummary 都在 script 裡面、沒被寫到 style 或 HTML 區塊
- **Banner 不顯示** → F12 Elements 查 `tip-banner-<id>` 是否有 class `show`、是否被別的 CSS rule 蓋掉 `display: none`
- **某個遊戲答對沒切換提示** → 檢查該遊戲的 checkAnswer / handlePick 裡是不是真的加了 `TipBanner.show(id, 'correct')`，而且在 `if (正確)` 分支裡
- **breath 的 mid 沒出現** → 確認 cycleCount 條件寫對、變數名跟該遊戲現有的一致
- **複製失敗** → 檢查是否在 http:// 或 https:// 協議下（file:// 可能擋 clipboard API，這時 fallback 會跑）

---

## 預估工時

以資深開發者而言：
- Task 1–3 (資料 + CSS + 控制器): ~30 分
- Task 4–7 (15 遊戲插入 + 3 時機串接): ~60–90 分（最花時間，15 個地方要改）
- Task 8–9 (session + 首頁按鈕): ~30 分
- Task 10 (稱呼 modal): ~20 分
- Task 11 (formatSummary + 測試): ~30 分
- Task 12 (summary modal + 複製): ~30 分
- Task 13 (驗收): ~20 分

**總計約 3.5–4.5 小時**。
