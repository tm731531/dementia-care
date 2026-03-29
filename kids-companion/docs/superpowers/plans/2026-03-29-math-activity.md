# 數學樂園 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增「數學樂園」活動（`page-math`），含算術和時鐘兩個子模式，依年齡分級。

**Architecture:** 單一 `page-math` 頁面，進入顯示模式選擇（算術/時鐘），各子模式獨立出題流程與完成畫面。全部在 `index.html` 單檔完成，遵循現有錨點規範。

**Tech Stack:** HTML + CSS + inline SVG（時鐘盤面） + vanilla JS

---

## 錨點速查（每個 Task 開始前先 grep 定位，禁止整包讀取）

```bash
grep -n "#END:CSS" kids-companion/index.html                    # CSS 插入點
grep -n "#SECTION:PAGE-FOOD" kids-companion/index.html          # HTML 插入點（在 food 前面）
grep -n "#SECTION:PAGE-FOOD-JS" kids-companion/index.html       # JS 插入點（在 food-JS 前面）
grep -n "navigateTo('page-food')" kids-companion/index.html     # 首頁活動卡片參考
grep -n "data-sticker=\"page-food\"" kids-companion/index.html  # 貼紙參考
grep -n "page-food.*showFoodShelf" kids-companion/index.html    # navigateTo hook 參考
```

---

## Task 1: Math CSS

**Files:**
- Modify: `kids-companion/index.html` — 在 `/* <!-- #END:CSS --> */` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#END:CSS" kids-companion/index.html
```

- [ ] **Step 2: 在 `#END:CSS` 之前插入以下 CSS**

```css
/* --- Math Activity --- */
.math-mode-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  max-width: 400px;
  margin: 40px auto;
  padding: 20px;
}
.math-mode-card {
  background: #fff;
  border-radius: 20px;
  padding: 30px 20px;
  text-align: center;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s;
}
.math-mode-card:active {
  transform: scale(0.95);
}
.math-mode-icon {
  font-size: 64px;
  display: block;
  margin-bottom: 10px;
}
.math-mode-name {
  font-size: 22px;
  font-weight: bold;
  color: #333;
}

.math-question {
  text-align: center;
  margin: 30px auto;
  max-width: 500px;
}
.math-question-text {
  font-size: 36px;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}
.math-emoji-area {
  font-size: 48px;
  line-height: 1.4;
  margin: 20px 0;
  min-height: 80px;
}
.math-formula {
  font-size: 48px;
  font-weight: bold;
  color: #E8724A;
  margin: 20px 0;
  font-family: 'Nunito', sans-serif;
}
.math-choices {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  justify-content: center;
  margin-top: 20px;
}
.math-choice-btn {
  min-width: 80px;
  padding: 15px 25px;
  font-size: 28px;
  font-weight: bold;
  border: 3px solid #ddd;
  border-radius: 16px;
  background: #fff;
  cursor: pointer;
  transition: all 0.2s;
  color: #333;
}
.math-choice-btn:active {
  transform: scale(0.95);
}
.math-choice-btn.correct {
  border-color: #98D8C8;
  background: #e8f8f2;
  color: #2a7a5a;
}
.math-choice-btn.wrong {
  border-color: #e88;
  background: #fee;
  color: #c44;
}

/* Clock SVG */
.clock-container {
  display: flex;
  justify-content: center;
  margin: 20px auto;
}
.clock-container svg {
  width: 220px;
  height: 220px;
}
.clock-face {
  fill: #fff;
  stroke: #999;
  stroke-width: 3;
}
.clock-tick {
  stroke: #666;
  stroke-width: 2;
}
.clock-number {
  font-size: 16px;
  font-weight: bold;
  fill: #333;
  text-anchor: middle;
  dominant-baseline: central;
  font-family: 'Nunito', sans-serif;
}
.clock-hand-hour {
  stroke: #333;
  stroke-width: 5;
  stroke-linecap: round;
}
.clock-hand-minute {
  stroke: #E8724A;
  stroke-width: 3;
  stroke-linecap: round;
}
.clock-center-dot {
  fill: #333;
}
```

- [ ] **Step 3: 驗證**

```bash
grep -c "math-mode-grid\|clock-container\|math-formula" kids-companion/index.html
# 預期: 3（各出現一次在 CSS）
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add math activity CSS styles"
```

---

## Task 2: Math HTML Page

**Files:**
- Modify: `kids-companion/index.html` — 在 `<!-- #SECTION:PAGE-FOOD -->` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-FOOD" kids-companion/index.html | head -1
# 在此行之前插入
```

- [ ] **Step 2: 插入 HTML**

```html
<!-- #SECTION:PAGE-MATH -->
<div class="page" id="page-math">
  <div class="game-header">
    <button class="back-btn" id="math-back-btn" onclick="mathBack()">← 返回</button>
    <span class="game-title" id="math-title">🔢 數學樂園</span>
    <span class="round-counter" id="math-round"></span>
  </div>
  <button class="praise-btn" onclick="showPraiseOverlay()">👏</button>

  <!-- Mode shelf -->
  <div id="math-shelf">
    <div class="math-mode-grid">
      <div class="math-mode-card" onclick="startMathArithmetic()">
        <span class="math-mode-icon">🔢</span>
        <div class="math-mode-name">算術</div>
      </div>
      <div class="math-mode-card" onclick="startMathClock()">
        <span class="math-mode-icon">🕐</span>
        <div class="math-mode-name">時鐘</div>
      </div>
    </div>
  </div>

  <!-- Game area (arithmetic or clock) -->
  <div id="math-game" style="display:none">
    <div class="math-question" id="math-question-area"></div>
  </div>

  <!-- Complete screen -->
  <div class="complete-screen" id="math-complete">
    <div class="complete-content">
      <div style="font-size:80px">🔢</div>
      <h2>數學小天才！</h2>
      <button class="btn btn-primary" onclick="mathReplay()">再玩一次 🔄</button>
      <button class="btn btn-secondary" onclick="showMathShelf()">換模式</button>
    </div>
  </div>
</div>
<!-- #END:PAGE-MATH -->

```

- [ ] **Step 3: 驗證**

```bash
grep -n "SECTION:PAGE-MATH\|END:PAGE-MATH" kids-companion/index.html
# 預期: 兩行（SECTION 和 END）
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add math activity HTML page structure"
```

---

## Task 3: Math JS — 算術模式

**Files:**
- Modify: `kids-companion/index.html` — 在 `// <!-- #SECTION:PAGE-FOOD-DATA -->` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-FOOD-DATA" kids-companion/index.html
# 在此行之前插入
```

- [ ] **Step 2: 插入算術 JS（第一部分：state + 共用函式 + showMathShelf）**

```javascript
// <!-- #SECTION:PAGE-MATH-JS -->
var mathState = {
  mode: null,       // 'arithmetic' | 'clock'
  round: 0,
  total: 0,
  wrongCount: 0,
  locked: false,
  correctAnswer: null
};

var MATH_ANIMALS = ['🐱','🐶','🐸','🐧','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐙','🦋','🐢','🐬','🦜','🦒','🦓'];

function getMathAgeConfig() {
  var configs = {
    toddler: { options: 2, rounds: 4 },
    small:   { options: 3, rounds: 5 },
    middle:  { options: 4, rounds: 6 },
    large:   { options: 4, rounds: 8 }
  };
  return configs[APP.ageGroup] || configs.small;
}

function mathShuffle(arr) {
  var a = arr.slice();
  for (var i = a.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var tmp = a[i]; a[i] = a[j]; a[j] = tmp;
  }
  return a;
}

function showMathShelf() {
  mathState.mode = null;
  mathState.round = 0;
  var shelf = document.getElementById('math-shelf');
  var game = document.getElementById('math-game');
  var complete = document.getElementById('math-complete');
  if (shelf) shelf.style.display = '';
  if (game) game.style.display = 'none';
  if (complete) complete.classList.remove('show');
  document.getElementById('math-title').textContent = '🔢 數學樂園';
  document.getElementById('math-round').textContent = '';
  document.getElementById('math-back-btn').onclick = function() { navigateTo('page-home'); };
}

function mathBack() {
  if ('speechSynthesis' in window) speechSynthesis.cancel();
  if (mathState.mode) {
    showMathShelf();
  } else {
    navigateTo('page-home');
  }
}

function mathReplay() {
  var complete = document.getElementById('math-complete');
  if (complete) complete.classList.remove('show');
  if (mathState.mode === 'arithmetic') {
    startMathArithmetic();
  } else if (mathState.mode === 'clock') {
    startMathClock();
  } else {
    showMathShelf();
  }
}

function showMathComplete() {
  var complete = document.getElementById('math-complete');
  if (complete) complete.classList.add('show');
  completeActivity('page-math');
  if ('speechSynthesis' in window) {
    speechSynthesis.cancel();
    var lang = APP.language || 'zh';
    var msg = lang === 'zh' ? '太棒了！數學小天才！' : 'Amazing! Math genius!';
    speak(msg);
  }
}

function mathGenerateDistractors(correct, count, min, max) {
  var distractors = [];
  var candidates = [];
  for (var d = 1; d <= 5; d++) {
    if (correct + d <= max) candidates.push(correct + d);
    if (correct - d >= min) candidates.push(correct - d);
  }
  candidates = mathShuffle(candidates);
  for (var i = 0; i < candidates.length && distractors.length < count; i++) {
    if (candidates[i] !== correct && distractors.indexOf(candidates[i]) === -1) {
      distractors.push(candidates[i]);
    }
  }
  while (distractors.length < count) {
    var fallback = Math.floor(Math.random() * (max - min + 1)) + min;
    if (fallback !== correct && distractors.indexOf(fallback) === -1) {
      distractors.push(fallback);
    }
  }
  return distractors;
}
```

- [ ] **Step 3: 插入算術 JS（第二部分：算術模式）**

接在上面的程式碼之後，同一個 section 內：

```javascript
function startMathArithmetic() {
  mathState.mode = 'arithmetic';
  mathState.round = 0;
  mathState.total = getMathAgeConfig().rounds;
  document.getElementById('math-shelf').style.display = 'none';
  document.getElementById('math-game').style.display = '';
  document.getElementById('math-complete').classList.remove('show');
  var lang = APP.language || 'zh';
  document.getElementById('math-title').textContent = '🔢 ' + (lang === 'zh' ? '算術' : 'Arithmetic');
  document.getElementById('math-back-btn').onclick = function() {
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    showMathShelf();
  };
  nextMathArithmetic();
}

function nextMathArithmetic() {
  mathState.round++;
  mathState.wrongCount = 0;
  mathState.locked = false;
  var cfg = getMathAgeConfig();
  document.getElementById('math-round').textContent = mathState.round + '/' + mathState.total;

  var age = APP.ageGroup || 'small';
  var question, answer, emojiHtml, formulaHtml;
  var lang = APP.language || 'zh';

  if (age === 'toddler') {
    var n = Math.floor(Math.random() * 5) + 1;
    answer = n;
    var animal = MATH_ANIMALS[Math.floor(Math.random() * MATH_ANIMALS.length)];
    var emojis = '';
    for (var i = 0; i < n; i++) emojis += animal;
    emojiHtml = '<div class="math-emoji-area">' + emojis + '</div>';
    formulaHtml = '';
    question = lang === 'zh' ? '一共幾隻？' : 'How many?';
  } else if (age === 'small') {
    var a = Math.floor(Math.random() * 5) + 1;
    var b = Math.floor(Math.random() * (10 - a)) + 1;
    answer = a + b;
    var animal = MATH_ANIMALS[Math.floor(Math.random() * MATH_ANIMALS.length)];
    var leftEmojis = '';
    for (var i = 0; i < a; i++) leftEmojis += animal;
    var rightEmojis = '';
    for (var i = 0; i < b; i++) rightEmojis += animal;
    emojiHtml = '<div class="math-emoji-area">' + leftEmojis + ' + ' + rightEmojis + '</div>';
    formulaHtml = '';
    question = lang === 'zh' ? '一共幾隻？' : 'How many in total?';
  } else if (age === 'middle') {
    var isAdd = Math.random() < 0.5;
    if (isAdd) {
      var a = Math.floor(Math.random() * 10) + 1;
      var b = Math.floor(Math.random() * 10) + 1;
      if (a + b > 20) b = 20 - a;
      answer = a + b;
      formulaHtml = '<div class="math-formula">' + a + ' + ' + b + ' = ?</div>';
    } else {
      var a = Math.floor(Math.random() * 18) + 3;
      var b = Math.floor(Math.random() * (a - 1)) + 1;
      answer = a - b;
      formulaHtml = '<div class="math-formula">' + a + ' − ' + b + ' = ?</div>';
    }
    emojiHtml = '';
    question = lang === 'zh' ? '答案是多少？' : 'What is the answer?';
  } else {
    var a = Math.floor(Math.random() * 15) + 1;
    var op1 = Math.random() < 0.5 ? '+' : '-';
    var b = Math.floor(Math.random() * 10) + 1;
    var mid = op1 === '+' ? a + b : a - b;
    if (mid < 0) { op1 = '+'; mid = a + b; }
    var op2 = Math.random() < 0.5 ? '+' : '-';
    var c = Math.floor(Math.random() * 10) + 1;
    var result = op2 === '+' ? mid + c : mid - c;
    if (result < 0) { op2 = '+'; result = mid + c; }
    if (result > 30) { c = Math.max(1, c - (result - 30)); result = op2 === '+' ? mid + c : mid - c; }
    answer = result;
    var displayOp1 = op1 === '+' ? ' + ' : ' − ';
    var displayOp2 = op2 === '+' ? ' + ' : ' − ';
    formulaHtml = '<div class="math-formula">' + a + displayOp1 + b + displayOp2 + c + ' = ?</div>';
    emojiHtml = '';
    question = lang === 'zh' ? '答案是多少？' : 'What is the answer?';
  }

  mathState.correctAnswer = answer;

  var distractors = mathGenerateDistractors(answer, cfg.options - 1, 0, age === 'large' ? 30 : 20);
  var choices = mathShuffle([answer].concat(distractors));

  var html = '<div class="math-question-text">' + question + '</div>';
  html += emojiHtml;
  html += formulaHtml;
  html += '<div class="math-choices">';
  choices.forEach(function(c) {
    html += '<button class="math-choice-btn" onclick="mathArithmeticAnswer(this,' + (c === answer) + ',' + answer + ')">' + c + '</button>';
  });
  html += '</div>';

  document.getElementById('math-question-area').innerHTML = html;

  var isSmall = (age === 'toddler' || age === 'small');
  if (isSmall) {
    var speakTexts = [question];
    choices.forEach(function(c) { speakTexts.push(String(c)); });
    setTimeout(function() { speakSequence(speakTexts); }, 400);
  } else {
    setTimeout(function() { speak(question); }, 400);
  }
}

function mathArithmeticAnswer(btn, isCorrect, correctVal) {
  if (mathState.locked) return;
  var age = APP.ageGroup || 'small';

  if (isCorrect) {
    mathState.locked = true;
    btn.classList.add('correct');
    playCorrectSound();
    var lang = APP.language || 'zh';
    speak(lang === 'zh' ? '太棒了！' : 'Great job!');
    setTimeout(function() {
      if (mathState.round >= mathState.total) {
        showMathComplete();
      } else {
        nextMathArithmetic();
      }
    }, 1200);
  } else {
    mathState.wrongCount++;
    btn.classList.add('wrong');
    playWrongSound();
    var showAnswer = false;
    if (age === 'toddler' || age === 'small') showAnswer = true;
    if (age === 'middle' && mathState.wrongCount >= 2) showAnswer = true;

    if (showAnswer) {
      mathState.locked = true;
      var btns = document.querySelectorAll('#math-question-area .math-choice-btn');
      btns.forEach(function(b) {
        if (b.textContent.trim() === String(correctVal)) b.classList.add('correct');
      });
      setTimeout(function() {
        if (mathState.round >= mathState.total) {
          showMathComplete();
        } else {
          nextMathArithmetic();
        }
      }, 1500);
    } else {
      var lang = APP.language || 'zh';
      speak(lang === 'zh' ? '再試一次！' : 'Try again!');
      setTimeout(function() { btn.classList.remove('wrong'); }, 800);
    }
  }
}
```

- [ ] **Step 4: 驗證算術函式**

```bash
grep -c "startMathArithmetic\|nextMathArithmetic\|mathArithmeticAnswer\|showMathShelf\|showMathComplete" kids-companion/index.html
# 預期: 至少 5 個定義 + 呼叫
```

- [ ] **Step 5: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add math activity JS — arithmetic mode"
```

---

## Task 4: Math JS — 時鐘模式

**Files:**
- Modify: `kids-companion/index.html` — 接在 Task 3 插入的算術 JS 之後、`// <!-- #END:PAGE-MATH-JS -->` 之前

注意：Task 3 結束時尚未寫 `#END` 標記。本 Task 在算術 JS 末尾之後繼續寫時鐘模式，最後寫 `// <!-- #END:PAGE-MATH-JS -->`。

- [ ] **Step 1: 定位插入點**

```bash
grep -n "mathArithmeticAnswer" kids-companion/index.html | tail -1
# 找到算術最後一個函式，在其結束 } 之後插入
```

- [ ] **Step 2: 插入時鐘 JS**

在算術模式 JS 末尾之後追加：

```javascript
function renderClockSVG(hour, minute) {
  var cx = 110, cy = 110, r = 95;
  var svg = '<svg viewBox="0 0 220 220">';
  svg += '<circle class="clock-face" cx="' + cx + '" cy="' + cy + '" r="' + r + '"/>';
  for (var i = 1; i <= 12; i++) {
    var angle = (i * 30 - 90) * Math.PI / 180;
    var nx = cx + Math.cos(angle) * (r - 20);
    var ny = cy + Math.sin(angle) * (r - 20);
    svg += '<text class="clock-number" x="' + nx + '" y="' + ny + '">' + i + '</text>';
    var tx1 = cx + Math.cos(angle) * (r - 8);
    var ty1 = cy + Math.sin(angle) * (r - 8);
    var tx2 = cx + Math.cos(angle) * r;
    var ty2 = cy + Math.sin(angle) * r;
    svg += '<line class="clock-tick" x1="' + tx1 + '" y1="' + ty1 + '" x2="' + tx2 + '" y2="' + ty2 + '"/>';
  }
  var hAngle = ((hour % 12) * 30 + minute * 0.5 - 90) * Math.PI / 180;
  var hx = cx + Math.cos(hAngle) * 50;
  var hy = cy + Math.sin(hAngle) * 50;
  svg += '<line class="clock-hand-hour" x1="' + cx + '" y1="' + cy + '" x2="' + hx + '" y2="' + hy + '"/>';
  var mAngle = (minute * 6 - 90) * Math.PI / 180;
  var mx = cx + Math.cos(mAngle) * 70;
  var my = cy + Math.sin(mAngle) * 70;
  svg += '<line class="clock-hand-minute" x1="' + cx + '" y1="' + cy + '" x2="' + mx + '" y2="' + my + '"/>';
  svg += '<circle class="clock-center-dot" cx="' + cx + '" cy="' + cy + '" r="5"/>';
  svg += '</svg>';
  return svg;
}

function formatClockLabel(hour, minute, lang) {
  if (lang === 'en') {
    if (minute === 0) return hour + " o'clock";
    return hour + ':' + (minute < 10 ? '0' : '') + minute;
  }
  if (minute === 0) return hour + ' 點';
  if (minute === 30) return hour + ' 點半';
  return hour + ' 點 ' + minute + ' 分';
}

function generateClockTime() {
  var age = APP.ageGroup || 'small';
  var hour = Math.floor(Math.random() * 12) + 1;
  var minute = 0;
  if (age === 'middle') {
    minute = Math.random() < 0.5 ? 0 : 30;
  } else if (age === 'large') {
    var mins = [0, 15, 30, 45];
    minute = mins[Math.floor(Math.random() * mins.length)];
  }
  return { hour: hour, minute: minute };
}

function generateClockDistractors(correctHour, correctMinute, count) {
  var age = APP.ageGroup || 'small';
  var distractors = [];
  var attempts = 0;
  while (distractors.length < count && attempts < 50) {
    attempts++;
    var h = Math.floor(Math.random() * 12) + 1;
    var m = 0;
    if (age === 'middle') {
      m = Math.random() < 0.5 ? 0 : 30;
    } else if (age === 'large') {
      var mins = [0, 15, 30, 45];
      m = mins[Math.floor(Math.random() * mins.length)];
    }
    if (h === correctHour && m === correctMinute) continue;
    var dup = false;
    for (var i = 0; i < distractors.length; i++) {
      if (distractors[i].hour === h && distractors[i].minute === m) { dup = true; break; }
    }
    if (!dup) distractors.push({ hour: h, minute: m });
  }
  return distractors;
}

function startMathClock() {
  mathState.mode = 'clock';
  mathState.round = 0;
  mathState.total = getMathAgeConfig().rounds;
  document.getElementById('math-shelf').style.display = 'none';
  document.getElementById('math-game').style.display = '';
  document.getElementById('math-complete').classList.remove('show');
  var lang = APP.language || 'zh';
  document.getElementById('math-title').textContent = '🕐 ' + (lang === 'zh' ? '時鐘' : 'Clock');
  document.getElementById('math-back-btn').onclick = function() {
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    showMathShelf();
  };
  nextMathClock();
}

function nextMathClock() {
  mathState.round++;
  mathState.wrongCount = 0;
  mathState.locked = false;
  var cfg = getMathAgeConfig();
  var lang = APP.language || 'zh';
  document.getElementById('math-round').textContent = mathState.round + '/' + mathState.total;

  var time = generateClockTime();
  var correctLabel = formatClockLabel(time.hour, time.minute, lang);
  mathState.correctAnswer = correctLabel;

  var distractors = generateClockDistractors(time.hour, time.minute, cfg.options - 1);
  var allChoices = [{ hour: time.hour, minute: time.minute }].concat(distractors);
  allChoices = mathShuffle(allChoices);

  var question = lang === 'zh' ? '現在幾點？' : 'What time is it?';
  var html = '<div class="math-question-text">' + question + '</div>';
  html += '<div class="clock-container">' + renderClockSVG(time.hour, time.minute) + '</div>';
  html += '<div class="math-choices">';
  allChoices.forEach(function(c) {
    var label = formatClockLabel(c.hour, c.minute, lang);
    var isCorrect = (c.hour === time.hour && c.minute === time.minute);
    html += '<button class="math-choice-btn" onclick="mathClockAnswer(this,' + isCorrect + ')">' + label + '</button>';
  });
  html += '</div>';

  document.getElementById('math-question-area').innerHTML = html;

  var age = APP.ageGroup || 'small';
  var isSmall = (age === 'toddler' || age === 'small');
  if (isSmall) {
    var speakTexts = [question];
    allChoices.forEach(function(c) { speakTexts.push(formatClockLabel(c.hour, c.minute, lang)); });
    setTimeout(function() { speakSequence(speakTexts); }, 400);
  } else {
    setTimeout(function() { speak(question); }, 400);
  }
}

function mathClockAnswer(btn, isCorrect) {
  if (mathState.locked) return;
  var age = APP.ageGroup || 'small';

  if (isCorrect) {
    mathState.locked = true;
    btn.classList.add('correct');
    playCorrectSound();
    var lang = APP.language || 'zh';
    speak(lang === 'zh' ? '太棒了！' : 'Great job!');
    setTimeout(function() {
      if (mathState.round >= mathState.total) {
        showMathComplete();
      } else {
        nextMathClock();
      }
    }, 1200);
  } else {
    mathState.wrongCount++;
    btn.classList.add('wrong');
    playWrongSound();
    var showAnswer = false;
    if (age === 'toddler' || age === 'small') showAnswer = true;
    if (age === 'middle' && mathState.wrongCount >= 2) showAnswer = true;

    if (showAnswer) {
      mathState.locked = true;
      var btns = document.querySelectorAll('#math-question-area .math-choice-btn');
      btns.forEach(function(b) {
        if (b.textContent.trim() === mathState.correctAnswer) b.classList.add('correct');
      });
      setTimeout(function() {
        if (mathState.round >= mathState.total) {
          showMathComplete();
        } else {
          nextMathClock();
        }
      }, 1500);
    } else {
      var lang = APP.language || 'zh';
      speak(lang === 'zh' ? '再試一次！' : 'Try again!');
      setTimeout(function() { btn.classList.remove('wrong'); }, 800);
    }
  }
}
// <!-- #END:PAGE-MATH-JS -->
```

- [ ] **Step 3: 驗證時鐘函式**

```bash
grep -c "startMathClock\|nextMathClock\|mathClockAnswer\|renderClockSVG\|formatClockLabel" kids-companion/index.html
# 預期: 至少 5 個定義 + 呼叫
```

- [ ] **Step 4: 驗證 SECTION 錨點完整**

```bash
grep -n "#SECTION:PAGE-MATH-JS\|#END:PAGE-MATH-JS" kids-companion/index.html
# 預期: 兩行（開頭和結尾）
```

- [ ] **Step 5: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add math activity JS — clock mode + section anchors"
```

---

## Task 5: Wire Math to Home Page + Navigation + Stickers

**Files:**
- Modify: `kids-companion/index.html` — 4 個地方

- [ ] **Step 1: 定位插入點**

```bash
grep -n "navigateTo('page-food')" kids-companion/index.html          # 首頁活動卡
grep -n "data-sticker=\"page-food\"" kids-companion/index.html       # 貼紙
grep -n "page-food.*showFoodShelf" kids-companion/index.html         # navigateTo hook
```

- [ ] **Step 2: 在探索 tab 加入數學活動卡（緊接 food 卡片後面）**

找到：
```html
      <div class="activity-card" onclick="navigateTo('page-food')">
        <span class="activity-icon">🍎</span>
        <span class="label">食物原型</span>
      </div>
```

在其後插入：
```html
      <div class="activity-card" onclick="navigateTo('page-math')">
        <span class="activity-icon">🔢</span>
        <span class="label">數學樂園</span>
      </div>
```

- [ ] **Step 3: 在貼紙板加入數學貼紙（緊接 food 貼紙後）**

找到：
```html
    <div class="sticker-slot locked" data-sticker="page-food">🍎</div>
```

在其後插入：
```html
    <div class="sticker-slot locked" data-sticker="page-math">🔢</div>
```

- [ ] **Step 4: 在 navigateTo() 函式加入 math 的初始化**

找到：
```javascript
  if (pageId === 'page-food') showFoodShelf();
```

在其後插入：
```javascript
  if (pageId === 'page-math') showMathShelf();
```

- [ ] **Step 5: 驗證**

```bash
grep -n "page-math\|showMathShelf\|data-sticker=\"page-math\"" kids-companion/index.html
# 應找到多筆
```

- [ ] **Step 6: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: wire math activity to home, navigation, sticker board"
```

---

## Task 6: Update CLAUDE.md + Final Test + Push

**Files:**
- Modify: `kids-companion/CLAUDE.md` — 錨點清單

- [ ] **Step 1: 在 CLAUDE.md 的錨點清單加入 math 活動**

找到 `#SECTION:PAGE-FOOD-JS` 那一行之後，插入：

```markdown
| `#SECTION:PAGE-MATH` | 數學樂園活動 |
| `#SECTION:PAGE-MATH-JS` | 數學樂園 JS 邏輯（算術 + 時鐘） |
```

- [ ] **Step 2: 驗證所有錨點存在**

```bash
grep -n "#SECTION:PAGE-MATH\b\|#END:PAGE-MATH\b\|#SECTION:PAGE-MATH-JS\|#END:PAGE-MATH-JS" kids-companion/index.html
# 預期: 4 行
```

- [ ] **Step 3: 瀏覽器測試清單**

在瀏覽器開啟 `kids-companion/index.html`：

1. 首頁探索 tab 出現「🔢 數學樂園」卡片
2. 點入看到兩個模式卡片（算術 / 時鐘）
3. 算術模式：
   - 切換 toddler → 看到 emoji 動物計數題，2 選項
   - 切換 small → 看到 emoji 加法視覺題，3 選項
   - 切換 middle → 看到數字加減算式，4 選項
   - 切換 large → 看到連續加減算式，4 選項
   - 答對有綠色 + 音效，答錯有提示
   - 完成所有輪次後出現完成畫面
4. 時鐘模式：
   - 看到 SVG 時鐘盤面（12 個數字、時針、分針）
   - toddler/small → 整點題目，2 選項
   - middle → 整點+半點，3 選項
   - large → 整點+半點+刻鐘，4 選項
   - 答對/答錯回饋正常
5. 返回按鈕：遊戲中 → 回模式選擇 → 回首頁
6. 貼紙板出現 🔢 貼紙
7. 語音朗讀正常

- [ ] **Step 4: Commit + Push**

```bash
git add kids-companion/CLAUDE.md
git commit -m "docs: add math activity anchors to CLAUDE.md"
git push
```

---

Task 1–5 完成後，更新 `kids-companion/CLAUDE.md` 的錨點清單加入：

| 錨點 | 說明 |
|------|------|
| `#SECTION:PAGE-MATH` | 數學樂園 HTML |
| `#SECTION:PAGE-MATH-JS` | 數學樂園 JS（算術 + 時鐘） |
