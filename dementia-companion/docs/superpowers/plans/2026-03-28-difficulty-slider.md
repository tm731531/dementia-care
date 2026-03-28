# 難度滑桿與遊戲庫 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 首頁加入難度滑桿（1-10），從 15 個遊戲庫中隨機抽 10 個顯示，難度值同時控制各遊戲內部參數與語音行為。

**Architecture:** 所有程式碼在單一 `index.html`。新增全域 `window.APP` 物件管理難度狀態與遊戲庫，首頁卡片改為動態渲染。語音系統擴充 hover-to-speak 與 auto-read-options。

**Tech Stack:** 純 HTML + CSS + JS，Web Speech API，localStorage

---

## 檔案變更

- Modify: `index.html` — 所有變更均在此檔

---

## Task 1: 全域難度狀態 + localStorage

**Files:**
- Modify: `index.html` — 在 `<script>` 開頭加入全域 APP 物件

- [ ] **Step 1: 在 `randomFrom` 函式之前加入 APP 全域物件**

找到 `index.html` 第 897 行 `function randomFrom(arr)` 前方，插入：

```javascript
// ============================
// 全域狀態
// ============================
const APP = {
  level: 5,  // 1-10，預設中度

  load() {
    const saved = localStorage.getItem('dementiaApp');
    if (saved) {
      const data = JSON.parse(saved);
      this.level = data.level ?? 5;
      this.selectedGameIds = data.selectedGames ?? null;
    }
  },

  save() {
    localStorage.setItem('dementiaApp', JSON.stringify({
      level: this.level,
      selectedGames: this.selectedGameIds
    }));
  },

  selectedGameIds: null
};

APP.load();
```

- [ ] **Step 2: 在 `navigateTo('page-home')` 後呼叫時，確認 APP 已載入**

找到 `updateHomeGreeting()` 函式（約第 943 行），確認不需要修改（APP.load 在頁面載入時已執行）。

- [ ] **Step 3: 手動驗證**

在瀏覽器 console 執行：
```javascript
APP.level = 7;
APP.save();
location.reload();
console.log(APP.level); // 應印出 7
```

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: add APP global state with localStorage persistence"
```

---

## Task 2: 遊戲庫定義

**Files:**
- Modify: `index.html` — 在 APP 物件後加入遊戲庫

- [ ] **Step 1: 在 APP 物件後加入 GAME_LIBRARY 陣列**

```javascript
// ============================
// 遊戲庫
// ============================
const GAME_LIBRARY = [
  { id: 'page-body',       icon: '🖐️', title: '身體部位',   desc: '指出身體的部位',   min: 1, max: 4  },
  { id: 'page-breathing',  icon: '💨', title: '呼吸練習',   desc: '跟著慢慢呼吸',     min: 1, max: 5  },
  { id: 'page-emotion',    icon: '😊', title: '情緒辨識',   desc: '這是什麼表情？',   min: 1, max: 7  },
  { id: 'page-counting',   icon: '🔢', title: '數數練習',   desc: '數數看有幾個',     min: 2, max: 7  },
  { id: 'page-colors',     icon: '🎨', title: '顏色辨識',   desc: '找出正確的顏色',   min: 2, max: 8  },
  { id: 'page-shapes',     icon: '🔷', title: '形狀配對',   desc: '找出一樣的形狀',   min: 2, max: 8  },
  { id: 'page-picture',    icon: '🖼️', title: '看圖認物',   desc: '看圖片說名字',     min: 2, max: 8  },
  { id: 'page-sorting',    icon: '📏', title: '大小排序',   desc: '從小排到大',       min: 3, max: 8  },
  { id: 'page-classify',   icon: '📦', title: '物品分類',   desc: '把東西放對地方',   min: 3, max: 8  },
  { id: 'page-numbers',    icon: '🔢', title: '認數字',     desc: '找出一樣的數字',   min: 3, max: 8  },
  { id: 'page-matching',   icon: '🔗', title: '連連看',     desc: '圖片配文字',       min: 4, max: 9  },
  { id: 'page-clock',      icon: '🕐', title: '時鐘認讀',   desc: '看時鐘說時間',     min: 4, max: 9  },
  { id: 'page-differences',icon: '🔍', title: '找不同',     desc: '找出不一樣的地方', min: 4, max: 10 },
  { id: 'page-memory',     icon: '📖', title: '認字遊戲',   desc: '找出一樣的字',     min: 5, max: 10 },
  { id: 'page-pairs',      icon: '🃏', title: '翻牌配對',   desc: '翻開找相同圖案',   min: 6, max: 10 },
];

function selectGames(level) {
  // 從符合難度範圍的遊戲中抽 10 個
  let pool = GAME_LIBRARY.filter(g => g.min <= level && level <= g.max);
  let expand = 1;
  while (pool.length < 10 && expand <= 5) {
    pool = GAME_LIBRARY.filter(g => g.min <= level + expand && level - expand <= g.max);
    expand++;
  }
  // Fisher-Yates shuffle，取前 10
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool.slice(0, 10).map(g => g.id);
}
```

- [ ] **Step 2: 驗證 selectGames 邏輯**

在 console 測試：
```javascript
console.log(selectGames(1).length);  // 應為 10（重度，放寬後）
console.log(selectGames(5).length);  // 應為 10
console.log(selectGames(10).length); // 應為 10
// level=1 不應出現 page-pairs（min=6）
console.log(selectGames(1).includes('page-pairs')); // false（除非放寬擴展）
```

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add game library and selectGames logic"
```

---

## Task 3: 難度滑桿 UI + 動態首頁卡片

**Files:**
- Modify: `index.html` — CSS + HTML + JS

- [ ] **Step 1: 加入滑桿 CSS**

在 `</style>` 前（約第 595 行）插入：

```css
/* === 難度滑桿 === */
.difficulty-bar {
  padding: 12px 16px 8px;
  background: #111;
  border-radius: var(--radius);
  margin-bottom: 16px;
}
.difficulty-bar .bar-labels {
  display: flex; justify-content: space-between;
  font-size: 13px; color: #888; margin-bottom: 6px;
}
.difficulty-bar input[type=range] {
  width: 100%; accent-color: #CC0000;
  height: 6px; cursor: pointer;
}
.difficulty-bar .bar-value {
  text-align: center; font-size: 13px; color: #ccc; margin-top: 4px;
}
.difficulty-notice {
  text-align: center; font-size: 14px; color: #FF6600;
  min-height: 20px; margin-bottom: 8px;
}
```

- [ ] **Step 2: 替換首頁 HTML**

找到首頁 `<div id="page-home" class="page">` 區塊（約 601-659 行），將整個區塊替換為：

```html
  <!-- ===== 首頁 ===== -->
  <div id="page-home" class="page">
    <div class="home-header">
      <h1 id="home-greeting">您好！</h1>
      <div class="date" id="home-date"></div>
    </div>
    <div class="difficulty-bar">
      <div class="bar-labels">
        <span>需要協助</span><span>可自主操作</span>
      </div>
      <input type="range" id="difficulty-slider" min="1" max="10" value="5">
      <div class="bar-value" id="difficulty-value">程度：5 / 10</div>
    </div>
    <div class="difficulty-notice" id="difficulty-notice"></div>
    <div class="home-grid" id="home-grid"></div>
  </div>
```

- [ ] **Step 3: 加入動態首頁渲染 JS**

找到 `function updateHomeGreeting()` 前，加入：

```javascript
function renderHomeGrid() {
  const grid = document.getElementById('home-grid');
  const ids = APP.selectedGameIds || [];
  grid.innerHTML = ids.map(id => {
    const g = GAME_LIBRARY.find(x => x.id === id);
    if (!g) return '';
    return `<button class="home-card" onclick="navigateTo('${g.id}')">
      <span class="icon">${g.icon}</span>
      <span class="title">${g.title}</span>
      <span class="desc">${g.desc}</span>
    </button>`;
  }).join('');
}

function initDifficultySlider() {
  const slider = document.getElementById('difficulty-slider');
  const valueEl = document.getElementById('difficulty-value');
  const notice = document.getElementById('difficulty-notice');

  slider.value = APP.level;
  valueEl.textContent = '程度：' + APP.level + ' / 10';

  // 確保有已選遊戲
  if (!APP.selectedGameIds) {
    APP.selectedGameIds = selectGames(APP.level);
    APP.save();
  }

  slider.addEventListener('input', () => {
    valueEl.textContent = '程度：' + slider.value + ' / 10';
  });

  slider.addEventListener('change', () => {
    const newLevel = parseInt(slider.value);
    APP.level = newLevel;
    APP.selectedGameIds = selectGames(newLevel);
    APP.save();
    renderHomeGrid();
    notice.textContent = '已根據新程度重新選擇遊戲';
    setTimeout(() => notice.textContent = '', 2500);
  });
}
```

- [ ] **Step 4: 修改 `updateHomeGreeting` 加入 renderHomeGrid 呼叫**

找到 `function updateHomeGreeting()` 並修改：

```javascript
function updateHomeGreeting() {
  const h = new Date().getHours();
  let greet = '您好！';
  if (h >= 5 && h < 12) greet = '早安！今天過得好嗎？';
  else if (h >= 12 && h < 18) greet = '午安！今天過得好嗎？';
  else greet = '晚安！今天辛苦了！';
  document.getElementById('home-greeting').textContent = greet;
  document.getElementById('home-date').textContent = formatDate(new Date());
  initDifficultySlider();
  renderHomeGrid();
}
```

- [ ] **Step 5: 瀏覽器驗證**

1. 開啟 `http://localhost:8002`，首頁應顯示難度滑桿和 10 個遊戲卡片
2. 拖動滑桿放開，卡片應重新隨機排列，出現橘色提示
3. 重新整理，卡片應維持相同（localStorage 保持）

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "feat: difficulty slider UI and dynamic home grid"
```

---

## Task 4: 語音系統升級

**Files:**
- Modify: `index.html` — speak 函式 + 新增 speakOptions / speakWithDelay

- [ ] **Step 1: 修改 speak 函式，rate 改為 0.7**

找到第 901 行的 `speak` 函式，修改 rate：

```javascript
function speak(text) {
  if (!('speechSynthesis' in window)) return;
  speechSynthesis.cancel();
  const clean = text.replace(/[\u{1F000}-\u{1FFFF}]|[\u{2600}-\u{27BF}]|[\u{FE00}-\u{FEFF}]|[\u{1F900}-\u{1F9FF}]|[\u{200D}\u{20E3}\u{FE0F}]/gu, '').trim();
  if (!clean) return;
  const u = new SpeechSynthesisUtterance(clean);
  u.lang = 'zh-TW';
  u.rate = 0.7;
  u.pitch = 1.1;
  speechSynthesis.speak(u);
}
```

- [ ] **Step 2: 加入 speakSequence 函式（依序朗讀一組文字，間隔 800ms）**

在 `speak` 函式後加入：

```javascript
function speakSequence(texts, delayMs = 800) {
  if (!texts.length) return;
  speak(texts[0]);
  texts.slice(1).forEach((t, i) => {
    setTimeout(() => speak(t), delayMs * (i + 1));
  });
}

// 對選項按鈕綁定 hover-to-speak（中度：4-6）
function bindOptionHover(containerSelector) {
  const level = APP.level;
  if (level < 4 || level > 6) return;
  document.querySelectorAll(containerSelector).forEach(btn => {
    btn.addEventListener('mouseenter', () => speak(btn.textContent));
    btn.addEventListener('touchmove', (e) => {
      const touch = e.touches[0];
      const el = document.elementFromPoint(touch.clientX, touch.clientY);
      if (el && el.closest(containerSelector.replace(' ', ''))) {
        const target = el.closest(containerSelector.replace(' ', ''));
        if (target && target !== btn._lastSpoken) {
          btn._lastSpoken = target;
          speak(target.textContent);
        }
      }
    }, { passive: true });
  });
}

// 重度（1-3）：自動朗讀題目 + 所有選項，間隔 800ms
function autoReadQuestion(questionText, optionTexts) {
  const level = APP.level;
  if (level > 3) {
    speak(questionText);
    return;
  }
  const all = [questionText, ...optionTexts];
  speakSequence(all, 1000);
  // 重度重複一次
  setTimeout(() => speakSequence(all, 1000), all.length * 1000 + 1500);
}
```

- [ ] **Step 3: 驗證 speak rate**

開啟瀏覽器，進入任一遊戲，確認語音速度明顯比之前慢。

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: voice system - rate 0.7, hover-to-speak, auto-read for heavy difficulty"
```

---

## Task 5: 既有遊戲接入難度參數

**Files:**
- Modify: `index.html` — 各遊戲的 init / nextRound 函式

- [ ] **Step 1: 認數字（NumberGame）接入難度**

找到 `NumberGame` 物件的 `init` 與 `nextRound`，根據 `APP.level` 調整：

```javascript
// 在 nextRound() 開頭加入
const level = APP.level;
const maxNum = level <= 3 ? 5 : level <= 6 ? 10 : 20;
const optionCount = level <= 3 ? 3 : level <= 6 ? 4 : 6;

// 修改產生題目的數字範圍
let target;
do { target = Math.floor(Math.random() * maxNum) + 1; }
while (this.usedNumbers.includes(target));

// 修改產生選項的數量（把 while (nums.length < 6) 改為：）
while (nums.length < optionCount) { ... }
```

同時在 `nextRound` 中呼叫 `autoReadQuestion`：
```javascript
// 在產生選項後加入
const optTexts = nums.map(String);
autoReadQuestion('請找出數字：' + target, optTexts);
bindOptionHover('.number-btn');
```

- [ ] **Step 2: 顏色辨識（ColorGame）接入難度**

在 `nextRound()` 中：

```javascript
const level = APP.level;
const optionCount = level <= 3 ? 4 : 6;

// 修改選項數量（while (options.length < 6) 改為：）
while (options.length < optionCount) { ... }

// 朗讀題目
autoReadQuestion('請找出' + target.name, options.map(o => o.color.name));
bindOptionHover('.color-option');
```

- [ ] **Step 3: 形狀配對（ShapeGame）接入難度**

在 `nextRound()` 找到形狀定義，根據難度限制形狀種類：

```javascript
const level = APP.level;
const shapeCount = level <= 3 ? 3 : level <= 6 ? 5 : 6;
// 只取 shapes 陣列前 shapeCount 個
const availableShapes = this.shapes.slice(0, shapeCount);
```

朗讀題目：
```javascript
autoReadQuestion('請找出：' + target.name, options.map(o => o.name));
bindOptionHover('.shape-option');
```

- [ ] **Step 4: 大小排序（SortingGame）接入難度**

```javascript
const level = APP.level;
const itemCount = level <= 6 ? 3 : 4;
// 取 itemCount 個物品排序
```

- [ ] **Step 5: 連連看（MatchingGame）接入難度**

```javascript
const level = APP.level;
const pairCount = level <= 3 ? 3 : level <= 6 ? 4 : 5;
// 限制配對組數為 pairCount
```

- [ ] **Step 6: 時鐘認讀（ClockGame）接入難度**

```javascript
const level = APP.level;
// level <= 3: 整點（分鐘固定 0）
// level 4-6: 半點（分鐘 0 或 30）
// level 7+: 任意 5 分鐘
const minute = level <= 3 ? 0 :
               level <= 6 ? (Math.random() < 0.5 ? 0 : 30) :
               Math.floor(Math.random() * 12) * 5;
```

- [ ] **Step 7: 物品分類（ClassifyGame）接入難度**

```javascript
const level = APP.level;
const categoryCount = level <= 3 ? 2 : level <= 6 ? 3 : 4;
// 限制顯示類別數量
```

- [ ] **Step 8: 認字（MemoryGame）接入難度**

找到字組定義，根據難度選用不同字組：

```javascript
const level = APP.level;
// level <= 3: 象形常用字組（簡單字，少干擾）
// level 4-6: 國小低年級字
// level 7+: 形近干擾字組（現有邏輯）
const useSimpleGroups = level <= 3;
const groups = useSimpleGroups ? this.simpleGroups : this.wordGroups;
```

需在 MemoryGame 加入 `simpleGroups` 陣列：
```javascript
simpleGroups: [
  ['山','水','火','木','土'],
  ['日','月','星','雲','雨'],
  ['人','手','口','目','耳'],
  ['大','小','上','下','中'],
  ['一','二','三','四','五'],
]
```

- [ ] **Step 9: 瀏覽器驗證**

將滑桿調到 2，進入認數字，確認選項只有 3 個且數字範圍 1-5。
將滑桿調到 9，進入認數字，確認選項有 6 個且數字範圍 1-20。

- [ ] **Step 10: Commit**

```bash
git add index.html
git commit -m "feat: existing games adapt to difficulty level"
```

---

## Task 6: 新遊戲 — 情緒辨識（page-emotion）

**Files:**
- Modify: `index.html` — HTML + CSS + JS

- [ ] **Step 1: 加入 CSS**

在 `</style>` 前插入：

```css
/* === 情緒辨識 === */
.emotion-game-layout {
  display: flex; flex-direction: column; align-items: center;
  gap: 24px; flex: 1; justify-content: center;
  max-width: 600px; margin: 0 auto; width: 100%;
}
.emotion-display { font-size: 160px; line-height: 1; text-align: center; }
.emotion-options {
  display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; width: 100%;
}
.emotion-btn {
  background: var(--bg-card); border: 3px solid #CCCCCC;
  border-radius: var(--radius); padding: 20px;
  cursor: pointer; font-size: 32px; font-weight: bold;
  color: #000; font-family: inherit; transition: transform 0.2s;
}
.emotion-btn:active { transform: scale(0.95); }
.emotion-btn.correct { border-color: var(--accent-green); animation: glow 0.5s ease; }
.emotion-btn.wrong { animation: shake 0.5s ease; }
.emotion-round { font-size: 20px; text-align: center; color: #CCCCCC; margin-bottom: 8px; }
@media (max-width: 600px) {
  .emotion-display { font-size: 120px; }
  .emotion-btn { font-size: 26px; padding: 14px; }
}
```

- [ ] **Step 2: 加入 HTML**

在最後一個遊戲 HTML 區塊後、`</body>` 前加入：

```html
  <!-- ===== 情緒辨識 ===== -->
  <div id="page-emotion" class="page">
    <div class="page-top">
      <button class="back-btn" onclick="navigateTo('page-home')">← 回首頁</button>
      <h2 class="page-title">😊 情緒辨識</h2>
    </div>
    <div class="emotion-round" id="emotion-round"></div>
    <div class="emotion-game-layout" id="emotion-game-layout">
      <div class="emotion-display" id="emotion-display"></div>
      <div class="emotion-options" id="emotion-options"></div>
    </div>
    <div id="emotion-complete" class="complete-screen" >
      <div class="msg">全部答對了！<br>你好厲害！</div>
      <button class="btn-primary" onclick="EmotionGame.reset()">再玩一次</button>
    </div>
  </div>
```

- [ ] **Step 3: 加入 JS**

在 `navigateTo` 函式的 if 區塊加入：
```javascript
if (pageId === 'page-emotion') EmotionGame.init();
```

在其他遊戲 JS 後加入：

```javascript
// ============================
// 情緒辨識
// ============================
const EmotionGame = {
  allEmotions: [
    { emoji: '😊', name: '開心' },
    { emoji: '😢', name: '難過' },
    { emoji: '😠', name: '生氣' },
    { emoji: '😮', name: '驚訝' },
    { emoji: '😐', name: '平靜' },
    { emoji: '😍', name: '喜愛' },
  ],
  currentRound: 0,
  totalRounds: 8,
  usedEmotions: [],

  init() {
    this.currentRound = 0;
    this.usedEmotions = [];
    document.getElementById('emotion-complete').classList.remove('show');
    document.getElementById('emotion-game-layout').style.display = '';
    this.nextRound();
  },

  nextRound() {
    this.currentRound++;
    if (this.currentRound > this.totalRounds) {
      document.getElementById('emotion-game-layout').style.display = 'none';
      document.getElementById('emotion-complete').classList.add('show');
      return;
    }

    document.getElementById('emotion-round').textContent =
      '第 ' + this.currentRound + ' / ' + this.totalRounds + ' 題';

    const level = APP.level;
    const optCount = level <= 3 ? 2 : level <= 6 ? 4 : 6;
    const pool = this.allEmotions.slice(0, optCount);

    const available = pool.filter(e => !this.usedEmotions.includes(e.emoji));
    const target = available.length ? randomFrom(available) : randomFrom(pool);
    this.usedEmotions.push(target.emoji);

    document.getElementById('emotion-display').textContent = target.emoji;

    let options = [target];
    while (options.length < Math.min(optCount, pool.length)) {
      const e = randomFrom(pool);
      if (!options.find(o => o.emoji === e.emoji)) options.push(e);
    }
    for (let i = options.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [options[i], options[j]] = [options[j], options[i]];
    }

    const container = document.getElementById('emotion-options');
    container.innerHTML = '';
    options.forEach(opt => {
      const btn = document.createElement('button');
      btn.className = 'emotion-btn';
      btn.textContent = opt.name;
      btn.onclick = () => this.checkAnswer(opt, target, btn);
      container.appendChild(btn);
    });

    autoReadQuestion('這是什麼表情？', options.map(o => o.name));
    bindOptionHover('.emotion-btn');
  },

  checkAnswer(opt, target, btn) {
    if (opt.emoji === target.emoji) {
      btn.classList.add('correct');
      showFeedback(randomFrom(praiseMessages), 'correct');
      setTimeout(() => this.nextRound(), 1200);
    } else {
      btn.classList.add('wrong');
      showFeedback(randomFrom(retryMessages), 'retry');
      setTimeout(() => btn.classList.remove('wrong'), 500);
    }
  },

  reset() { this.init(); }
};
```

- [ ] **Step 4: 驗證**

進入情緒辨識遊戲，確認大 emoji 顯示正確，選項文字正確，答對有語音鼓勵。

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add 情緒辨識 game"
```

---

## Task 7: 新遊戲 — 數數練習（page-counting）

**Files:**
- Modify: `index.html`

- [ ] **Step 1: 加入 CSS**

```css
/* === 數數練習 === */
.counting-game-layout {
  display: flex; flex-direction: column; align-items: center;
  gap: 24px; flex: 1; justify-content: center;
  max-width: 700px; margin: 0 auto; width: 100%;
}
.counting-display {
  background: var(--bg-card); border-radius: var(--radius);
  padding: 24px; text-align: center; width: 100%;
  font-size: 64px; line-height: 1.4; min-height: 160px;
  display: flex; flex-wrap: wrap; gap: 8px;
  align-items: center; justify-content: center;
}
.counting-question { font-size: 28px; color: #CCCCCC; text-align: center; }
.counting-options {
  display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; width: 100%;
}
.counting-btn {
  background: var(--bg-card); border: 3px solid #CCCCCC;
  border-radius: var(--radius); padding: 20px;
  cursor: pointer; font-size: 48px; font-weight: bold;
  color: #000; font-family: inherit; transition: transform 0.2s;
}
.counting-btn:active { transform: scale(0.95); }
.counting-btn.correct { border-color: var(--accent-green); animation: glow 0.5s ease; }
.counting-btn.wrong { animation: shake 0.5s ease; }
.counting-round { font-size: 20px; text-align: center; color: #CCCCCC; margin-bottom: 8px; }
```

- [ ] **Step 2: 加入 HTML**

```html
  <!-- ===== 數數練習 ===== -->
  <div id="page-counting" class="page">
    <div class="page-top">
      <button class="back-btn" onclick="navigateTo('page-home')">← 回首頁</button>
      <h2 class="page-title">🔢 數數練習</h2>
    </div>
    <div class="counting-round" id="counting-round"></div>
    <div class="counting-game-layout" id="counting-game-layout">
      <div class="counting-question">有幾個？</div>
      <div class="counting-display" id="counting-display"></div>
      <div class="counting-options" id="counting-options"></div>
    </div>
    <div id="counting-complete" class="complete-screen" >
      <div class="msg">數完了！<br>數得很準確！</div>
      <button class="btn-primary" onclick="CountingGame.reset()">再玩一次</button>
    </div>
  </div>
```

- [ ] **Step 3: 加入 JS**

在 `navigateTo` 加入 `if (pageId === 'page-counting') CountingGame.init();`

```javascript
// ============================
// 數數練習
// ============================
const CountingGame = {
  emojis: ['🍎','🌟','🐶','🌸','🍪','🎈','🐠','🌈','🏀','🦋'],
  currentRound: 0,
  totalRounds: 8,

  init() {
    this.currentRound = 0;
    document.getElementById('counting-complete').classList.remove('show');
    document.getElementById('counting-game-layout').style.display = '';
    this.nextRound();
  },

  nextRound() {
    this.currentRound++;
    if (this.currentRound > this.totalRounds) {
      document.getElementById('counting-game-layout').style.display = 'none';
      document.getElementById('counting-complete').classList.add('show');
      return;
    }

    document.getElementById('counting-round').textContent =
      '第 ' + this.currentRound + ' / ' + this.totalRounds + ' 題';

    const level = APP.level;
    const maxCount = level <= 3 ? 5 : level <= 6 ? 10 : 15;
    const optCount = level <= 3 ? 3 : 4;

    const target = Math.floor(Math.random() * maxCount) + 1;
    const emoji = randomFrom(this.emojis);

    document.getElementById('counting-display').textContent = emoji.repeat(target);

    let nums = [target];
    while (nums.length < optCount) {
      const n = Math.floor(Math.random() * maxCount) + 1;
      if (!nums.includes(n)) nums.push(n);
    }
    for (let i = nums.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [nums[i], nums[j]] = [nums[j], nums[i]];
    }

    const container = document.getElementById('counting-options');
    container.innerHTML = '';
    nums.forEach(n => {
      const btn = document.createElement('button');
      btn.className = 'counting-btn';
      btn.textContent = n;
      btn.onclick = () => this.checkAnswer(n, target, btn);
      container.appendChild(btn);
    });

    autoReadQuestion('有幾個？', nums.map(String));
    bindOptionHover('.counting-btn');
  },

  checkAnswer(n, target, btn) {
    if (n === target) {
      btn.classList.add('correct');
      showFeedback(randomFrom(praiseMessages), 'correct');
      setTimeout(() => this.nextRound(), 1200);
    } else {
      btn.classList.add('wrong');
      showFeedback(randomFrom(retryMessages), 'retry');
      setTimeout(() => btn.classList.remove('wrong'), 500);
    }
  },

  reset() { this.init(); }
};
```

- [ ] **Step 4: 驗證**

進入數數練習，確認 emoji 顯示正確數量，答對有回饋。

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add 數數練習 game"
```

---

## Task 8: 新遊戲 — 找不同（page-differences）

**Files:**
- Modify: `index.html`

- [ ] **Step 1: 加入 CSS**

```css
/* === 找不同 === */
.differences-game-layout {
  display: flex; flex-direction: column; align-items: center;
  gap: 24px; flex: 1; justify-content: center;
  max-width: 700px; margin: 0 auto; width: 100%;
}
.differences-row {
  display: flex; gap: 12px; justify-content: center; flex-wrap: wrap;
}
.diff-item {
  background: var(--bg-card); border: 3px solid #CCCCCC;
  border-radius: var(--radius); padding: 12px 16px;
  cursor: pointer; font-size: 64px; line-height: 1;
  transition: transform 0.2s;
}
.diff-item:active { transform: scale(0.95); }
.diff-item.correct { border-color: var(--accent-green); animation: glow 0.5s ease; }
.diff-item.wrong { animation: shake 0.5s ease; }
.differences-hint { font-size: 24px; color: #CCCCCC; text-align: center; }
.differences-round { font-size: 20px; text-align: center; color: #CCCCCC; margin-bottom: 8px; }
@media (max-width: 600px) {
  .diff-item { font-size: 48px; padding: 10px 12px; }
}
```

- [ ] **Step 2: 加入 HTML**

```html
  <!-- ===== 找不同 ===== -->
  <div id="page-differences" class="page">
    <div class="page-top">
      <button class="back-btn" onclick="navigateTo('page-home')">← 回首頁</button>
      <h2 class="page-title">🔍 找不同</h2>
    </div>
    <div class="differences-round" id="differences-round"></div>
    <div class="differences-game-layout" id="differences-game-layout">
      <div class="differences-hint">哪一個不一樣？</div>
      <div class="differences-row" id="differences-row"></div>
    </div>
    <div id="differences-complete" class="complete-screen" >
      <div class="msg">全找到了！<br>眼力真好！</div>
      <button class="btn-primary" onclick="DifferencesGame.reset()">再玩一次</button>
    </div>
  </div>
```

- [ ] **Step 3: 加入 JS**

在 `navigateTo` 加入 `if (pageId === 'page-differences') DifferencesGame.init();`

```javascript
// ============================
// 找不同
// ============================
const DifferencesGame = {
  // 重度：顏色不同組（同形狀，不同 emoji）
  easyGroups: [
    { same: '🍎', diff: '🍊' }, { same: '🐶', diff: '🐱' },
    { same: '🌟', diff: '🌙' }, { same: '🌸', diff: '🌼' },
    { same: '🍪', diff: '🎂' }, { same: '🚗', diff: '🚌' },
  ],
  // 中度：形狀不同
  mediumGroups: [
    { same: '🔵', diff: '🔴' }, { same: '🟦', diff: '🟥' },
    { same: '⬆️', diff: '⬇️' }, { same: '🔺', diff: '🔻' },
  ],
  // 輕度：細微差異
  hardGroups: [
    { same: '😊', diff: '😄' }, { same: '🐶', diff: '🦊' },
    { same: '🌲', diff: '🌳' }, { same: '🍇', diff: '🫐' },
  ],
  currentRound: 0,
  totalRounds: 8,

  init() {
    this.currentRound = 0;
    document.getElementById('differences-complete').classList.remove('show');
    document.getElementById('differences-game-layout').style.display = '';
    this.nextRound();
  },

  nextRound() {
    this.currentRound++;
    if (this.currentRound > this.totalRounds) {
      document.getElementById('differences-game-layout').style.display = 'none';
      document.getElementById('differences-complete').classList.add('show');
      return;
    }

    document.getElementById('differences-round').textContent =
      '第 ' + this.currentRound + ' / ' + this.totalRounds + ' 題';

    const level = APP.level;
    const groups = level <= 3 ? this.easyGroups :
                   level <= 6 ? this.mediumGroups : this.hardGroups;

    const pair = randomFrom(groups);
    const total = 5;
    const diffPos = Math.floor(Math.random() * total);

    const items = Array(total).fill(pair.same);
    items[diffPos] = pair.diff;

    const row = document.getElementById('differences-row');
    row.innerHTML = '';
    items.forEach((emoji, i) => {
      const btn = document.createElement('button');
      btn.className = 'diff-item';
      btn.textContent = emoji;
      btn.onclick = () => this.checkAnswer(i === diffPos, btn);
      row.appendChild(btn);
    });

    autoReadQuestion('哪一個不一樣？', []);
  },

  checkAnswer(isCorrect, btn) {
    if (isCorrect) {
      btn.classList.add('correct');
      showFeedback(randomFrom(praiseMessages), 'correct');
      setTimeout(() => this.nextRound(), 1200);
    } else {
      btn.classList.add('wrong');
      showFeedback(randomFrom(retryMessages), 'retry');
      setTimeout(() => btn.classList.remove('wrong'), 500);
    }
  },

  reset() { this.init(); }
};
```

- [ ] **Step 4: 驗證**

進入找不同，確認 5 個 emoji 中有 1 個不同，點選正確得到鼓勵，點錯搖動。

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add 找不同 game"
```

---

## Task 9: 新遊戲 — 翻牌記憶配對（page-pairs）

**Files:**
- Modify: `index.html`

- [ ] **Step 1: 加入 CSS**

```css
/* === 翻牌記憶配對 === */
.pairs-game-layout {
  display: flex; flex-direction: column; align-items: center;
  gap: 16px; flex: 1; padding-top: 8px;
  max-width: 600px; margin: 0 auto; width: 100%;
}
.pairs-grid {
  display: grid; gap: 12px; width: 100%;
}
.pairs-grid.grid-2x3 { grid-template-columns: repeat(3, 1fr); }
.pairs-grid.grid-3x4 { grid-template-columns: repeat(4, 1fr); }
.pair-card {
  aspect-ratio: 1; border-radius: var(--radius);
  border: 3px solid #555; background: #222;
  cursor: pointer; font-size: 52px;
  display: flex; align-items: center; justify-content: center;
  transition: transform 0.3s; position: relative; overflow: hidden;
}
.pair-card .card-front {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  background: var(--bg-card); font-size: 52px;
  transform: rotateY(180deg); backface-visibility: hidden;
  transition: transform 0.3s;
}
.pair-card .card-back {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  background: #333; font-size: 36px; color: #555;
  backface-visibility: hidden; transition: transform 0.3s;
}
.pair-card.flipped .card-front { transform: rotateY(0); }
.pair-card.flipped .card-back  { transform: rotateY(-180deg); }
.pair-card.matched { border-color: var(--accent-green); opacity: 0.6; pointer-events: none; }
.pairs-round { font-size: 20px; text-align: center; color: #CCCCCC; margin-bottom: 4px; }
@media (max-width: 600px) {
  .pair-card { font-size: 36px; }
  .pair-card .card-front { font-size: 36px; }
}
```

- [ ] **Step 2: 加入 HTML**

```html
  <!-- ===== 翻牌記憶配對 ===== -->
  <div id="page-pairs" class="page">
    <div class="page-top">
      <button class="back-btn" onclick="navigateTo('page-home')">← 回首頁</button>
      <h2 class="page-title">🃏 翻牌配對</h2>
    </div>
    <div class="pairs-round" id="pairs-round"></div>
    <div class="pairs-game-layout">
      <div class="pairs-grid" id="pairs-grid"></div>
    </div>
    <div id="pairs-complete" class="complete-screen" >
      <div class="msg">全部配對完成！<br>記憶力真好！</div>
      <button class="btn-primary" onclick="PairsGame.reset()">再玩一次</button>
    </div>
  </div>
```

- [ ] **Step 3: 加入 JS**

在 `navigateTo` 加入 `if (pageId === 'page-pairs') PairsGame.init();`

```javascript
// ============================
// 翻牌記憶配對
// ============================
const PairsGame = {
  emojis: ['🍎','🐶','🌟','🎈','🌸','🍪','🐠','🦋','🌈','🎵','🌻','🦁'],
  firstCard: null,
  lock: false,
  matched: 0,
  total: 0,

  init() {
    this.firstCard = null;
    this.lock = false;
    this.matched = 0;
    document.getElementById('pairs-complete').classList.remove('show');

    const level = APP.level;
    const pairCount = level <= 7 ? 3 : 6;
    this.total = pairCount;

    const grid = document.getElementById('pairs-grid');
    grid.className = 'pairs-grid ' + (pairCount <= 3 ? 'grid-2x3' : 'grid-3x4');

    const selected = this.emojis.slice(0, pairCount);
    let cards = [...selected, ...selected];
    for (let i = cards.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [cards[i], cards[j]] = [cards[j], cards[i]];
    }

    document.getElementById('pairs-round').textContent =
      '找出 ' + pairCount + ' 對相同的圖案';

    grid.innerHTML = '';
    cards.forEach(emoji => {
      const card = document.createElement('div');
      card.className = 'pair-card';
      card.innerHTML = `<div class="card-back">？</div><div class="card-front">${emoji}</div>`;
      card.dataset.emoji = emoji;
      card.onclick = () => this.flipCard(card);
      grid.appendChild(card);
    });

    speak('翻開牌，找出相同的圖案');
  },

  flipCard(card) {
    if (this.lock || card.classList.contains('flipped') || card.classList.contains('matched')) return;
    card.classList.add('flipped');
    speak(card.dataset.emoji);

    if (!this.firstCard) {
      this.firstCard = card;
      return;
    }

    const second = card;
    this.lock = true;

    if (this.firstCard.dataset.emoji === second.dataset.emoji) {
      this.firstCard.classList.add('matched');
      second.classList.add('matched');
      this.matched++;
      this.firstCard = null;
      this.lock = false;
      if (this.matched === this.total) {
        setTimeout(() => {
          showFeedback('全部配對完成！', 'correct');
          setTimeout(() => {
            document.getElementById('pairs-complete').classList.add('show');
          }, 1500);
        }, 500);
      }
    } else {
      setTimeout(() => {
        this.firstCard.classList.remove('flipped');
        second.classList.remove('flipped');
        this.firstCard = null;
        this.lock = false;
      }, 1000);
    }
  },

  reset() { this.init(); }
};
```

- [ ] **Step 4: 驗證**

難度 7-10：6x2 格牌（12張）；難度 6-7：3x2 格牌（6張）。
翻兩張相同配對成功，翻兩張不同自動蓋回。

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add 翻牌記憶配對 game"
```

---

## Task 10: 新遊戲 — 身體部位指認（page-body）

**Files:**
- Modify: `index.html`

- [ ] **Step 1: 加入 CSS**

```css
/* === 身體部位指認 === */
.body-game-layout {
  display: flex; gap: 32px; flex: 1; align-items: center;
  max-width: 800px; margin: 0 auto; width: 100%;
}
.body-figure {
  flex-shrink: 0; text-align: center;
  background: var(--bg-card); border-radius: var(--radius);
  padding: 16px; min-width: 200px;
}
.body-figure-img { font-size: 120px; line-height: 1; }
.body-right { flex: 1; }
.body-question { font-size: 32px; font-weight: bold; color: #fff; margin-bottom: 16px; text-align: center; }
.body-options {
  display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px;
}
.body-btn {
  background: var(--bg-card); border: 3px solid #CCCCCC;
  border-radius: var(--radius); padding: 20px;
  cursor: pointer; font-size: 32px; font-weight: bold;
  color: #000; font-family: inherit; transition: transform 0.2s;
}
.body-btn:active { transform: scale(0.95); }
.body-btn.correct { border-color: var(--accent-green); animation: glow 0.5s ease; }
.body-btn.wrong { animation: shake 0.5s ease; }
.body-round { font-size: 20px; text-align: center; color: #CCCCCC; margin-bottom: 12px; }
@media (max-width: 600px) {
  .body-game-layout { flex-direction: column; gap: 16px; }
  .body-figure-img { font-size: 80px; }
  .body-btn { font-size: 26px; padding: 14px; }
}
```

- [ ] **Step 2: 加入 HTML**

```html
  <!-- ===== 身體部位指認 ===== -->
  <div id="page-body" class="page">
    <div class="page-top">
      <button class="back-btn" onclick="navigateTo('page-home')">← 回首頁</button>
      <h2 class="page-title">🖐️ 身體部位</h2>
    </div>
    <div class="body-round" id="body-round"></div>
    <div class="body-game-layout" id="body-game-layout">
      <div class="body-figure">
        <div class="body-figure-img">🧍</div>
      </div>
      <div class="body-right">
        <div class="body-question" id="body-question"></div>
        <div class="body-options" id="body-options"></div>
      </div>
    </div>
    <div id="body-complete" class="complete-screen" >
      <div class="msg">答完了！<br>身體部位都認識！</div>
      <button class="btn-primary" onclick="BodyGame.reset()">再玩一次</button>
    </div>
  </div>
```

- [ ] **Step 3: 加入 JS**

在 `navigateTo` 加入 `if (pageId === 'page-body') BodyGame.init();`

```javascript
// ============================
// 身體部位指認
// ============================
const BodyGame = {
  basicParts: ['眼睛','嘴巴','鼻子','耳朵'],
  advancedParts: ['眼睛','嘴巴','鼻子','耳朵','肩膀','手','腳','頭髮'],
  currentRound: 0,
  totalRounds: 8,
  usedParts: [],

  init() {
    this.currentRound = 0;
    this.usedParts = [];
    document.getElementById('body-complete').classList.remove('show');
    document.getElementById('body-game-layout').style.display = '';
    this.nextRound();
  },

  nextRound() {
    this.currentRound++;
    if (this.currentRound > this.totalRounds) {
      document.getElementById('body-game-layout').style.display = 'none';
      document.getElementById('body-complete').classList.add('show');
      return;
    }

    document.getElementById('body-round').textContent =
      '第 ' + this.currentRound + ' / ' + this.totalRounds + ' 題';

    const level = APP.level;
    const pool = level <= 2 ? this.basicParts : this.advancedParts;
    const optCount = level <= 3 ? 2 : 4;

    const available = pool.filter(p => !this.usedParts.includes(p));
    const target = available.length ? randomFrom(available) : randomFrom(pool);
    this.usedParts.push(target);

    document.getElementById('body-question').textContent = '指出：' + target;

    let options = [target];
    while (options.length < Math.min(optCount, pool.length)) {
      const p = randomFrom(pool);
      if (!options.includes(p)) options.push(p);
    }
    for (let i = options.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [options[i], options[j]] = [options[j], options[i]];
    }

    const container = document.getElementById('body-options');
    container.innerHTML = '';
    options.forEach(part => {
      const btn = document.createElement('button');
      btn.className = 'body-btn';
      btn.textContent = part;
      btn.onclick = () => this.checkAnswer(part, target, btn);
      container.appendChild(btn);
    });

    autoReadQuestion('請指出：' + target, options);
    bindOptionHover('.body-btn');
  },

  checkAnswer(part, target, btn) {
    if (part === target) {
      btn.classList.add('correct');
      showFeedback(randomFrom(praiseMessages), 'correct');
      setTimeout(() => this.nextRound(), 1200);
    } else {
      btn.classList.add('wrong');
      showFeedback(randomFrom(retryMessages), 'retry');
      setTimeout(() => btn.classList.remove('wrong'), 500);
    }
  },

  reset() { this.init(); }
};
```

- [ ] **Step 4: 驗證**

進入身體部位，確認重度（1-3）只顯示 2 個選項（眼睛/嘴巴等基本部位），語音自動念出題目與選項。

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add 身體部位指認 game"
```

---

## Task 11: 整合驗收

- [ ] **Step 1: 端到端測試**

1. 開啟 `http://localhost:8002`
2. 難度設為 1，確認首頁只出現重度遊戲（身體部位、呼吸練習等），不出現翻牌配對
3. 難度設為 10，確認出現認字、翻牌配對，不出現身體部位
4. 難度設為 5，進入任一遊戲確認語音速度變慢（0.7）
5. 難度設為 3，進入認數字：選項應為 3 個，數字範圍 1-5，語音自動念題目與選項並重複
6. 難度設為 5，進入顏色辨識：手指劃過選項應逐一朗讀顏色名稱
7. 重新整理頁面，確認難度與遊戲卡片維持不變（localStorage）

- [ ] **Step 2: Final commit**

```bash
git add index.html
git commit -m "feat: complete difficulty slider and game library system"
```
