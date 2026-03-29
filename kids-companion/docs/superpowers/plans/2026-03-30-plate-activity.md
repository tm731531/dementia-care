# 餐盤設計 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增「餐盤設計」活動（`page-plate`），讓孩子運用食物知識組合餐盤，依年齡提供自由裝盤/任務/分格三種模式。

**Architecture:** 單一 `page-plate` 頁面，根據 `APP.ageGroup` 切換三種模式。複用現有 `FOOD_CATEGORIES` + `FOODS` + `IMG['food-*']` 資料。全部在 `index.html` 單檔完成。

**Tech Stack:** HTML + CSS + vanilla JS

---

## 錨點速查

```bash
grep -n "#END:CSS" kids-companion/index.html                    # CSS 插入點
grep -n "#SECTION:PAGE-MATH" kids-companion/index.html          # HTML 插入點（在 math 前面）
grep -n "#SECTION:PAGE-MATH-JS" kids-companion/index.html       # JS 插入點（在 math-JS 前面）
grep -n "navigateTo('page-math')" kids-companion/index.html     # 首頁活動卡片參考
grep -n "data-sticker=\"page-math\"" kids-companion/index.html  # 貼紙參考
grep -n "page-math.*showMathShelf" kids-companion/index.html    # navigateTo hook 參考
```

---

## Task 1: Plate CSS

**Files:**
- Modify: `kids-companion/index.html` — 在 `/* <!-- #END:CSS --> */` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#END:CSS" kids-companion/index.html
```

- [ ] **Step 2: 在 `#END:CSS` 之前插入以下 CSS**

```css
/* --- Plate Activity --- */
.plate-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 10px 20px;
}
.plate-circle {
  width: min(280px, 70vw);
  height: min(280px, 70vw);
  border-radius: 50%;
  background: #fff;
  border: 4px solid #ddd;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  position: relative;
  margin: 10px auto;
  overflow: hidden;
}
.plate-food-on-plate {
  position: absolute;
  width: 56px;
  height: 56px;
  border-radius: 12px;
  object-fit: cover;
  animation: plate-pop 0.3s ease;
}
.plate-food-on-plate-emoji {
  position: absolute;
  font-size: 40px;
  animation: plate-pop 0.3s ease;
}
@keyframes plate-pop {
  0% { transform: scale(0); }
  70% { transform: scale(1.2); }
  100% { transform: scale(1); }
}
.plate-task-text {
  font-size: 22px;
  font-weight: bold;
  color: #333;
  text-align: center;
  margin: 10px 20px;
  line-height: 1.5;
}
.plate-food-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  justify-content: center;
  margin: 15px auto;
  max-width: 500px;
  max-height: 200px;
  overflow-y: auto;
  padding: 10px;
}
.plate-food-item {
  width: 72px;
  text-align: center;
  cursor: pointer;
  border-radius: 12px;
  padding: 6px;
  transition: all 0.2s;
  background: #fff;
  border: 2px solid #eee;
}
.plate-food-item:active {
  transform: scale(0.9);
}
.plate-food-item.selected {
  border-color: #98D8C8;
  background: #e8f8f2;
}
.plate-food-item img {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  object-fit: cover;
  display: block;
  margin: 0 auto 4px;
}
.plate-food-item .plate-food-emoji {
  font-size: 36px;
  display: block;
  margin-bottom: 4px;
}
.plate-food-item .plate-food-label {
  font-size: 12px;
  color: #555;
  line-height: 1.2;
}
.plate-submit-btn {
  display: block;
  margin: 10px auto;
  padding: 14px 40px;
  font-size: 22px;
  font-weight: bold;
  border: none;
  border-radius: 16px;
  background: #E8724A;
  color: #fff;
  cursor: pointer;
  transition: transform 0.2s;
}
.plate-submit-btn:active {
  transform: scale(0.95);
}
.plate-feedback {
  text-align: center;
  padding: 20px;
}
.plate-feedback-icon {
  font-size: 80px;
  margin-bottom: 10px;
}
.plate-feedback-text {
  font-size: 24px;
  font-weight: bold;
  color: #333;
  line-height: 1.6;
  margin-bottom: 10px;
}
.plate-feedback-sub {
  font-size: 18px;
  color: #666;
  margin-bottom: 16px;
}
.plate-stars {
  font-size: 40px;
  margin: 10px 0;
}

/* Large: grid plate */
.plate-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 8px;
  max-width: 420px;
  margin: 10px auto;
}
.plate-grid-cell {
  background: #fff;
  border: 2px solid #eee;
  border-radius: 16px;
  padding: 10px 6px;
  text-align: center;
  min-height: 120px;
}
.plate-grid-cell-header {
  font-size: 14px;
  font-weight: bold;
  color: #666;
  margin-bottom: 6px;
}
.plate-grid-cell-icon {
  font-size: 28px;
}
.plate-grid-options {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 6px;
}
.plate-grid-option {
  font-size: 13px;
  padding: 6px;
  border: 2px solid #eee;
  border-radius: 10px;
  background: #fafafa;
  cursor: pointer;
  transition: all 0.2s;
}
.plate-grid-option:active {
  transform: scale(0.95);
}
.plate-grid-option.selected {
  border-color: #98D8C8;
  background: #e8f8f2;
}
.plate-grid-cell.filled {
  border-color: #98D8C8;
}
```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add plate activity CSS styles"
```

---

## Task 2: Plate HTML Page

**Files:**
- Modify: `kids-companion/index.html` — 在 `<!-- #SECTION:PAGE-MATH -->` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-MATH" kids-companion/index.html | head -1
```

- [ ] **Step 2: 插入 HTML**

```html
<!-- #SECTION:PAGE-PLATE -->
<div class="page" id="page-plate">
  <div class="game-header">
    <button class="back-btn" onclick="navigateTo('page-home')">← 返回</button>
    <span class="game-title">🍽️ 餐盤設計</span>
    <span class="round-counter" id="plate-counter"></span>
  </div>
  <button class="praise-btn" onclick="showPraiseOverlay()">👏</button>

  <!-- Game area -->
  <div id="plate-game" class="plate-area"></div>

  <!-- Complete screen -->
  <div class="complete-screen" id="plate-complete">
    <div class="complete-content">
      <div style="font-size:80px">🍽️</div>
      <h2>小小營養師！</h2>
      <button class="btn btn-primary" onclick="startPlateGame()">再玩一次 🔄</button>
      <button class="btn btn-secondary" onclick="navigateTo('page-home')">回首頁</button>
    </div>
  </div>
</div>
<!-- #END:PAGE-PLATE -->

```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add plate activity HTML page structure"
```

---

## Task 3: Plate JS — 共用函式 + 自由裝盤模式（toddler/small）

**Files:**
- Modify: `kids-companion/index.html` — 在 `// <!-- #SECTION:PAGE-MATH-JS -->` 之前插入

全域可用變數（已存在，不需定義）：`FOOD_CATEGORIES`, `FOODS`, `IMG`, `APP`, `speak()`, `speakSequence()`, `playCorrectSound()`, `completeActivity()`, `launchConfettiSmall()`, `navigateTo()`

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-MATH-JS" kids-companion/index.html
```

- [ ] **Step 2: 插入共用函式 + 自由裝盤 JS**

```javascript
// <!-- #SECTION:PAGE-PLATE-JS -->
var plateState = {
  selectedFoods: [],  // [{id, emoji, zh, en, category}, ...]
  maxFoods: 5,
  availableFoods: [],
  mode: null,         // 'free' | 'task' | 'grid'
  task: null,         // middle mode task object
  gridSelections: {}  // large mode: {veggie: food, fruit: food, ...}
};

function plateShuffle(arr) {
  var a = arr.slice();
  for (var i = a.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var tmp = a[i]; a[i] = a[j]; a[j] = tmp;
  }
  return a;
}

function plateGetRandomFoods(count) {
  var all = [];
  FOOD_CATEGORIES.forEach(function(cat) {
    var foods = FOODS[cat.id] || [];
    foods.forEach(function(f) {
      all.push({ id: f.id, emoji: f.emoji, zh: f.zh, en: f.en, category: cat.id });
    });
  });
  // Ensure at least 1 per category
  var picked = [];
  var usedIds = {};
  FOOD_CATEGORIES.forEach(function(cat) {
    var foods = FOODS[cat.id] || [];
    if (foods.length > 0) {
      var f = foods[Math.floor(Math.random() * foods.length)];
      picked.push({ id: f.id, emoji: f.emoji, zh: f.zh, en: f.en, category: cat.id });
      usedIds[f.id] = true;
    }
  });
  var remaining = all.filter(function(f) { return !usedIds[f.id]; });
  remaining = plateShuffle(remaining);
  for (var i = 0; i < remaining.length && picked.length < count; i++) {
    picked.push(remaining[i]);
  }
  return plateShuffle(picked);
}

function plateGetCategories(foods) {
  var cats = {};
  foods.forEach(function(f) { cats[f.category] = true; });
  return Object.keys(cats);
}

function startPlateGame() {
  plateState.selectedFoods = [];
  plateState.gridSelections = {};
  plateState.task = null;
  var complete = document.getElementById('plate-complete');
  if (complete) complete.classList.remove('show');

  var ag = APP.ageGroup || 'small';
  if (ag === 'toddler' || ag === 'small') {
    plateState.mode = 'free';
    plateState.maxFoods = ag === 'toddler' ? 5 : 6;
    var foodCount = ag === 'toddler' ? 12 : 16;
    plateState.availableFoods = plateGetRandomFoods(foodCount);
    renderPlateFree();
  } else if (ag === 'middle') {
    plateState.mode = 'task';
    plateState.maxFoods = 5;
    plateState.availableFoods = plateGetRandomFoods(16);
    startPlateTask();
  } else {
    plateState.mode = 'grid';
    renderPlateGrid();
  }
}

function renderPlateFree() {
  var lang = APP.language || 'zh';
  var ag = APP.ageGroup || 'small';
  var game = document.getElementById('plate-game');
  var counter = document.getElementById('plate-counter');
  if (counter) counter.textContent = plateState.selectedFoods.length + '/' + plateState.maxFoods;

  var html = '';
  // Plate circle
  html += '<div class="plate-circle" id="plate-circle">';
  plateState.selectedFoods.forEach(function(f, idx) {
    var angle = (idx / plateState.maxFoods) * 2 * Math.PI - Math.PI / 2;
    var radius = 60 + Math.random() * 30;
    var cx = 50 + Math.cos(angle) * (radius / 140 * 50);
    var cy = 50 + Math.sin(angle) * (radius / 140 * 50);
    var imgSrc = (typeof IMG !== 'undefined' && IMG['food-' + f.id]) ? IMG['food-' + f.id] : '';
    if (imgSrc) {
      html += '<img src="' + imgSrc + '" class="plate-food-on-plate" style="left:calc(' + cx + '% - 28px);top:calc(' + cy + '% - 28px)">';
    } else {
      html += '<div class="plate-food-on-plate-emoji" style="left:calc(' + cx + '% - 20px);top:calc(' + cy + '% - 20px)">' + f.emoji + '</div>';
    }
  });
  html += '</div>';

  // Food picker
  html += '<div class="plate-food-picker">';
  plateState.availableFoods.forEach(function(f) {
    var isSelected = false;
    for (var i = 0; i < plateState.selectedFoods.length; i++) {
      if (plateState.selectedFoods[i].id === f.id) { isSelected = true; break; }
    }
    var imgSrc = (typeof IMG !== 'undefined' && IMG['food-' + f.id]) ? IMG['food-' + f.id] : '';
    html += '<div class="plate-food-item' + (isSelected ? ' selected' : '') + '" onclick="platePick(\'' + f.id + '\')">';
    if (imgSrc) {
      html += '<img src="' + imgSrc + '" alt="' + f[lang] + '">';
    } else {
      html += '<span class="plate-food-emoji">' + f.emoji + '</span>';
    }
    html += '<div class="plate-food-label">' + f[lang] + '</div>';
    html += '</div>';
  });
  html += '</div>';

  // Submit button
  if (plateState.selectedFoods.length > 0) {
    html += '<button class="plate-submit-btn" onclick="plateSubmit()">開動！🍴</button>';
  }

  game.innerHTML = html;

  // Auto-speak for toddler/small
  if (plateState.selectedFoods.length === 0 && (ag === 'toddler' || ag === 'small')) {
    setTimeout(function() {
      speak(lang === 'zh' ? '選你喜歡的食物放到盤子上吧！' : 'Pick foods you like and put them on the plate!');
    }, 400);
  }
}

function platePick(foodId) {
  var ag = APP.ageGroup || 'small';
  var lang = APP.language || 'zh';

  // Check if already selected → deselect
  for (var i = 0; i < plateState.selectedFoods.length; i++) {
    if (plateState.selectedFoods[i].id === foodId) {
      plateState.selectedFoods.splice(i, 1);
      if (plateState.mode === 'free') renderPlateFree();
      else if (plateState.mode === 'task') renderPlateTask();
      return;
    }
  }

  // Check max
  if (plateState.selectedFoods.length >= plateState.maxFoods) return;

  // Find food
  var food = null;
  for (var j = 0; j < plateState.availableFoods.length; j++) {
    if (plateState.availableFoods[j].id === foodId) { food = plateState.availableFoods[j]; break; }
  }
  if (!food) return;

  plateState.selectedFoods.push(food);
  playCorrectSound();

  // Speak food name for toddler/small
  if (ag === 'toddler' || ag === 'small') {
    speak(food[lang]);
  }

  if (plateState.mode === 'free') renderPlateFree();
  else if (plateState.mode === 'task') renderPlateTask();
}
```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add plate activity JS — shared utils + free mode (toddler/small)"
```

---

## Task 4: Plate JS — 任務模式（middle）+ 分格模式（large）+ 回饋 + submit

**Files:**
- Modify: `kids-companion/index.html` — 接在 Task 3 的 JS 後面，在 `// <!-- #SECTION:PAGE-MATH-JS -->` 之前

- [ ] **Step 1: 定位插入點**

Task 3 末尾之後追加以下程式碼，最後加 `// <!-- #END:PAGE-PLATE-JS -->` 標記。

- [ ] **Step 2: 插入任務模式 + 分格模式 + 回饋 JS**

```javascript
// --- Middle: Task mode ---
var PLATE_TASKS = [
  { zh: '幫 🦊 準備有蔬菜和蛋白質的午餐', en: 'Help 🦊 prepare lunch with vegetables and protein', required: ['veggie', 'protein'] },
  { zh: '🦊 想吃有水果和奶類的點心', en: '🦊 wants a snack with fruits and dairy', required: ['fruit', 'dairy'] },
  { zh: '選三種不同類別的食物給 🦊', en: 'Pick 3 different food groups for 🦊', required: null, minCategories: 3 },
  { zh: '幫 🦊 準備有五穀和蔬菜的晚餐', en: 'Help 🦊 prepare dinner with grains and vegetables', required: ['grain', 'veggie'] },
  { zh: '🦊 需要堅果和水果補充能量', en: '🦊 needs nuts and fruits for energy', required: ['nut', 'fruit'] },
  { zh: '準備一份有蛋白質和五穀的便當', en: 'Prepare a lunchbox with protein and grains', required: ['protein', 'grain'] },
  { zh: '幫 🦊 選有蔬菜和水果的沙拉', en: 'Help 🦊 make a salad with vegetables and fruits', required: ['veggie', 'fruit'] },
  { zh: '🦊 想要均衡的一餐，至少選四種不同類', en: '🦊 wants a balanced meal with at least 4 groups', required: null, minCategories: 4 }
];

function startPlateTask() {
  var task = PLATE_TASKS[Math.floor(Math.random() * PLATE_TASKS.length)];
  plateState.task = task;
  plateState.selectedFoods = [];
  renderPlateTask();
}

function renderPlateTask() {
  var lang = APP.language || 'zh';
  var game = document.getElementById('plate-game');
  var counter = document.getElementById('plate-counter');
  if (counter) counter.textContent = plateState.selectedFoods.length + '/' + plateState.maxFoods;

  var task = plateState.task;
  var html = '';
  html += '<div class="plate-task-text">' + task[lang] + '</div>';

  // Plate circle
  html += '<div class="plate-circle" id="plate-circle">';
  plateState.selectedFoods.forEach(function(f, idx) {
    var angle = (idx / plateState.maxFoods) * 2 * Math.PI - Math.PI / 2;
    var radius = 60 + Math.random() * 30;
    var cx = 50 + Math.cos(angle) * (radius / 140 * 50);
    var cy = 50 + Math.sin(angle) * (radius / 140 * 50);
    var imgSrc = (typeof IMG !== 'undefined' && IMG['food-' + f.id]) ? IMG['food-' + f.id] : '';
    if (imgSrc) {
      html += '<img src="' + imgSrc + '" class="plate-food-on-plate" style="left:calc(' + cx + '% - 28px);top:calc(' + cy + '% - 28px)">';
    } else {
      html += '<div class="plate-food-on-plate-emoji" style="left:calc(' + cx + '% - 20px);top:calc(' + cy + '% - 20px)">' + f.emoji + '</div>';
    }
  });
  html += '</div>';

  // Food picker
  html += '<div class="plate-food-picker">';
  plateState.availableFoods.forEach(function(f) {
    var isSelected = false;
    for (var i = 0; i < plateState.selectedFoods.length; i++) {
      if (plateState.selectedFoods[i].id === f.id) { isSelected = true; break; }
    }
    var imgSrc = (typeof IMG !== 'undefined' && IMG['food-' + f.id]) ? IMG['food-' + f.id] : '';
    html += '<div class="plate-food-item' + (isSelected ? ' selected' : '') + '" onclick="platePick(\'' + f.id + '\')">';
    if (imgSrc) {
      html += '<img src="' + imgSrc + '" alt="' + f[lang] + '">';
    } else {
      html += '<span class="plate-food-emoji">' + f.emoji + '</span>';
    }
    html += '<div class="plate-food-label">' + f[lang] + '</div>';
    html += '</div>';
  });
  html += '</div>';

  if (plateState.selectedFoods.length > 0) {
    html += '<button class="plate-submit-btn" onclick="plateSubmit()">開動！🍴</button>';
  }

  game.innerHTML = html;

  // Speak task on first render
  if (plateState.selectedFoods.length === 0) {
    setTimeout(function() { speak(task[lang]); }, 400);
  }
}

// --- Large: Grid mode ---
function renderPlateGrid() {
  var lang = APP.language || 'zh';
  var game = document.getElementById('plate-game');
  var filledCount = Object.keys(plateState.gridSelections).length;
  var counter = document.getElementById('plate-counter');
  if (counter) counter.textContent = filledCount + '/6';

  var html = '<div class="plate-grid">';
  FOOD_CATEGORIES.forEach(function(cat) {
    var foods = FOODS[cat.id] || [];
    var options = plateShuffle(foods).slice(0, 3);
    var selected = plateState.gridSelections[cat.id] || null;
    var isFilled = selected !== null;

    html += '<div class="plate-grid-cell' + (isFilled ? ' filled' : '') + '">';
    html += '<div class="plate-grid-cell-icon">' + cat.emoji + '</div>';
    html += '<div class="plate-grid-cell-header">' + cat.name[lang] + '</div>';
    html += '<div class="plate-grid-options">';
    options.forEach(function(f) {
      var isSelected = selected && selected.id === f.id;
      html += '<div class="plate-grid-option' + (isSelected ? ' selected' : '') + '" onclick="plateGridPick(\'' + cat.id + '\',\'' + f.id + '\')">';
      html += f.emoji + ' ' + f[lang];
      html += '</div>';
    });
    html += '</div></div>';
  });
  html += '</div>';

  html += '<button class="plate-submit-btn" onclick="plateSubmit()">開動！🍴</button>';
  game.innerHTML = html;
}

function plateGridPick(catId, foodId) {
  var foods = FOODS[catId] || [];
  var food = null;
  for (var i = 0; i < foods.length; i++) {
    if (foods[i].id === foodId) { food = foods[i]; break; }
  }
  if (!food) return;

  if (plateState.gridSelections[catId] && plateState.gridSelections[catId].id === foodId) {
    delete plateState.gridSelections[catId];
  } else {
    plateState.gridSelections[catId] = { id: food.id, emoji: food.emoji, zh: food.zh, en: food.en, category: catId };
  }
  playCorrectSound();
  renderPlateGrid();
}

// --- Submit & Feedback ---
function plateSubmit() {
  var ag = APP.ageGroup || 'small';
  if (ag === 'large') {
    plateSubmitGrid();
  } else if (ag === 'middle') {
    plateSubmitTask();
  } else {
    plateSubmitFree();
  }
}

function plateSubmitFree() {
  var lang = APP.language || 'zh';
  var ag = APP.ageGroup || 'small';
  var cats = plateGetCategories(plateState.selectedFoods);
  var catCount = cats.length;
  var game = document.getElementById('plate-game');

  var html = '<div class="plate-feedback">';
  html += '<div class="plate-feedback-icon">🦊</div>';

  var msg = '';
  if (ag === 'toddler') {
    msg = lang === 'zh' ? '好好吃！🦊 吃得好開心！' : 'Yummy! 🦊 is so happy!';
  } else {
    if (catCount >= 5) {
      msg = lang === 'zh' ? '太厲害了！營養超級均衡！🦊 開心地轉圈圈！' : 'Amazing! Super balanced! 🦊 is spinning with joy!';
    } else if (catCount >= 3) {
      msg = lang === 'zh' ? '哇！好均衡！🦊 變得好有力氣！' : 'Wow! So balanced! 🦊 is getting strong!';
    } else {
      msg = lang === 'zh' ? '好好吃！下次可以試試不同的食物喔！' : 'Tasty! Try different foods next time!';
    }
  }

  html += '<div class="plate-feedback-text">' + msg + '</div>';
  html += '<button class="btn btn-primary" onclick="startPlateGame()" style="margin:8px">再玩一次 🔄</button>';
  html += '<button class="btn btn-secondary" onclick="navigateTo(\'page-home\')" style="margin:8px">回首頁</button>';
  html += '</div>';

  game.innerHTML = html;
  completeActivity('page-plate');
  if ('speechSynthesis' in window) { speechSynthesis.cancel(); }
  speak(msg);
  launchConfettiSmall();
}

function plateSubmitTask() {
  var lang = APP.language || 'zh';
  var task = plateState.task;
  var cats = plateGetCategories(plateState.selectedFoods);
  var game = document.getElementById('plate-game');

  var success = false;
  if (task.required) {
    success = task.required.every(function(r) { return cats.indexOf(r) !== -1; });
  } else if (task.minCategories) {
    success = cats.length >= task.minCategories;
  }

  if (success) {
    var msg = lang === 'zh' ? '太棒了！你選了 ' + cats.length + ' 類食物，好均衡！' : 'Great! You picked ' + cats.length + ' food groups!';
    var html = '<div class="plate-feedback">';
    html += '<div class="plate-feedback-icon">🦊</div>';
    html += '<div class="plate-feedback-text">' + msg + '</div>';
    html += '<button class="btn btn-primary" onclick="startPlateGame()" style="margin:8px">再玩一次 🔄</button>';
    html += '<button class="btn btn-secondary" onclick="navigateTo(\'page-home\')" style="margin:8px">回首頁</button>';
    html += '</div>';
    game.innerHTML = html;
    completeActivity('page-plate');
    playCorrectSound();
    if ('speechSynthesis' in window) { speechSynthesis.cancel(); }
    speak(msg);
    launchConfettiSmall();
  } else {
    playWrongSound();
    var missingMsg = '';
    if (task.required) {
      var missing = task.required.filter(function(r) { return cats.indexOf(r) === -1; });
      var missingNames = missing.map(function(m) {
        for (var i = 0; i < FOOD_CATEGORIES.length; i++) {
          if (FOOD_CATEGORIES[i].id === m) return FOOD_CATEGORIES[i].name[lang];
        }
        return m;
      });
      missingMsg = lang === 'zh'
        ? '差一點點！再加一樣' + missingNames[0] + '就完美了！'
        : 'Almost! Add some ' + missingNames[0] + '!';
    } else {
      missingMsg = lang === 'zh'
        ? '差一點點！再多選一種不同類別的食物！'
        : 'Almost! Pick one more food group!';
    }
    if ('speechSynthesis' in window) { speechSynthesis.cancel(); }
    speak(missingMsg);
    // Reset selection, keep task
    plateState.selectedFoods = [];
    setTimeout(function() { renderPlateTask(); }, 1500);
  }
}

function plateSubmitGrid() {
  var lang = APP.language || 'zh';
  var filledCount = Object.keys(plateState.gridSelections).length;
  var game = document.getElementById('plate-game');

  var stars = 1;
  var msg = '';
  if (filledCount >= 5) {
    stars = 3;
    msg = lang === 'zh' ? '完美營養餐！' : 'Perfect balanced meal!';
  } else if (filledCount >= 3) {
    stars = 2;
    msg = lang === 'zh' ? '吃得真均衡！' : 'So balanced!';
  } else {
    stars = 1;
    msg = lang === 'zh' ? '不錯的開始！' : 'Good start!';
  }

  var starsHtml = '';
  for (var i = 0; i < stars; i++) starsHtml += '⭐';

  var html = '<div class="plate-feedback">';
  html += '<div class="plate-feedback-icon">🍽️</div>';
  html += '<div class="plate-stars">' + starsHtml + '</div>';
  html += '<div class="plate-feedback-text">' + msg + '</div>';
  html += '<div class="plate-feedback-sub">' + (lang === 'zh' ? '你填了 ' + filledCount + ' 類食物' : 'You filled ' + filledCount + ' food groups') + '</div>';
  html += '<button class="btn btn-primary" onclick="startPlateGame()" style="margin:8px">再玩一次 🔄</button>';
  html += '<button class="btn btn-secondary" onclick="navigateTo(\'page-home\')" style="margin:8px">回首頁</button>';
  html += '</div>';

  game.innerHTML = html;
  completeActivity('page-plate');
  playCorrectSound();
  if ('speechSynthesis' in window) { speechSynthesis.cancel(); }
  speak(msg);
  if (stars >= 3) launchConfettiSmall();
}
// <!-- #END:PAGE-PLATE-JS -->
```

- [ ] **Step 3: 驗證錨點**

```bash
grep -n "#SECTION:PAGE-PLATE-JS\|#END:PAGE-PLATE-JS" kids-companion/index.html
# 預期: 2 行
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add plate activity JS — task mode, grid mode, feedback"
```

---

## Task 5: Wire Plate to Home Page + Navigation + Stickers

**Files:**
- Modify: `kids-companion/index.html` — 3 個地方

- [ ] **Step 1: 在探索 tab 加入餐盤活動卡（緊接 math 卡片後面）**

找到：
```html
      <div class="activity-card" onclick="navigateTo('page-math')">
        <span class="activity-icon">🔢</span>
        <span class="label">數學樂園</span>
      </div>
```

在其後插入：
```html
      <div class="activity-card" onclick="navigateTo('page-plate')">
        <span class="activity-icon">🍽️</span>
        <span class="label">餐盤設計</span>
      </div>
```

- [ ] **Step 2: 在貼紙板加入餐盤貼紙（緊接 math 貼紙後）**

找到：
```html
    <div class="sticker-slot locked" data-sticker="page-math">🔢</div>
```

在其後插入：
```html
    <div class="sticker-slot locked" data-sticker="page-plate">🍽️</div>
```

- [ ] **Step 3: 在 navigateTo() 函式加入 plate 的初始化**

找到：
```javascript
  if (pageId === 'page-math') showMathShelf();
```

在其後插入：
```javascript
  if (pageId === 'page-plate') startPlateGame();
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: wire plate activity to home, navigation, sticker board"
```

---

## Task 6: Update CLAUDE.md + Push

**Files:**
- Modify: `kids-companion/CLAUDE.md`

- [ ] **Step 1: 在錨點清單加入 plate 活動**

找到 `#SECTION:PAGE-MATH-JS` 那行之後，插入：

```markdown
| `#SECTION:PAGE-PLATE` | 餐盤設計活動 |
| `#SECTION:PAGE-PLATE-JS` | 餐盤設計 JS 邏輯 |
```

- [ ] **Step 2: 驗證錨點**

```bash
grep -n "#SECTION:PAGE-PLATE\b\|#END:PAGE-PLATE\b\|#SECTION:PAGE-PLATE-JS\|#END:PAGE-PLATE-JS" kids-companion/index.html
# 預期: 4 行
```

- [ ] **Step 3: Commit + Push**

```bash
git add kids-companion/CLAUDE.md
git commit -m "docs: add plate activity anchors to CLAUDE.md"
git push
```
