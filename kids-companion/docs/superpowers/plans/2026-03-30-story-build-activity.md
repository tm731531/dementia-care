# 故事拼組 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增「故事拼組」活動（`page-story-build`），讓孩子選圖卡排列成故事，系統用語音念出來。toddler/small 自由排列，middle/large 欄位式。

**Architecture:** 單一 `page-story-build` 頁面，根據 `APP.ageGroup` 切換自由/欄位模式。複用 `ANIMALS`、`SCENE_THEMES`、`FOODS`、`IMG` 現有資料。全部在 `index.html` 單檔。

**Tech Stack:** HTML + CSS + vanilla JS + Web Speech API

---

## 錨點速查

```bash
grep -n "#END:CSS" kids-companion/index.html                      # CSS 插入點
grep -n "#SECTION:PAGE-SCENE\>" kids-companion/index.html         # HTML 插入點（在 scene 前面）
grep -n "#SECTION:PAGE-SCENE-DATA" kids-companion/index.html      # JS 插入點（在 scene-data 前面）
grep -n "navigateTo('page-scene')" kids-companion/index.html      # 首頁卡片參考
grep -n "data-sticker=\"page-scene\"" kids-companion/index.html   # 貼紙參考
grep -n "page-scene.*showSceneShelf" kids-companion/index.html    # navigateTo hook 參考
```

---

## Task 1: Story Build CSS

**Files:**
- Modify: `kids-companion/index.html` — 在 `/* <!-- #END:CSS --> */` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#END:CSS" kids-companion/index.html
```

- [ ] **Step 2: 插入 CSS**

```css
/* --- Story Build Activity --- */
.story-track {
  display: flex;
  gap: 10px;
  justify-content: center;
  margin: 16px auto;
  max-width: 500px;
  min-height: 90px;
  align-items: center;
}
.story-slot {
  width: 72px;
  height: 80px;
  border: 3px dashed #ccc;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
  color: #ccc;
  background: #fafafa;
  cursor: pointer;
  transition: all 0.2s;
}
.story-slot.filled {
  border-style: solid;
  border-color: #98D8C8;
  background: #e8f8f2;
}
.story-slot.filled img {
  width: 56px;
  height: 56px;
  border-radius: 10px;
  object-fit: cover;
}
.story-slot .story-slot-emoji {
  font-size: 40px;
}
.story-slot .story-slot-label {
  font-size: 10px;
  color: #555;
  text-align: center;
  margin-top: 2px;
}
.story-card-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
  margin: 12px auto;
  max-width: 500px;
  padding: 8px;
}
.story-card-item {
  width: 68px;
  text-align: center;
  cursor: pointer;
  border-radius: 12px;
  padding: 6px;
  background: #fff;
  border: 2px solid #eee;
  transition: all 0.2s;
}
.story-card-item:active {
  transform: scale(0.9);
}
.story-card-item.used {
  opacity: 0.4;
  pointer-events: none;
}
.story-card-item img {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  object-fit: cover;
  display: block;
  margin: 0 auto 2px;
}
.story-card-item .story-card-emoji {
  font-size: 36px;
  display: block;
  margin-bottom: 2px;
}
.story-card-item .story-card-label {
  font-size: 11px;
  color: #555;
  line-height: 1.2;
}

/* Structured mode (middle/large) */
.story-columns {
  display: flex;
  gap: 8px;
  justify-content: center;
  margin: 12px auto;
  max-width: 520px;
  overflow-x: auto;
  padding: 8px;
}
.story-column {
  min-width: 90px;
  text-align: center;
}
.story-column-title {
  font-size: 14px;
  font-weight: bold;
  color: #E8724A;
  margin-bottom: 6px;
}
.story-column-options {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.story-col-option {
  padding: 8px 6px;
  border: 2px solid #eee;
  border-radius: 12px;
  background: #fff;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 13px;
}
.story-col-option:active {
  transform: scale(0.95);
}
.story-col-option.selected {
  border-color: #98D8C8;
  background: #e8f8f2;
}
.story-col-option img {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  object-fit: cover;
  display: block;
  margin: 0 auto 4px;
}

.story-submit-btn {
  display: block;
  margin: 10px auto;
  padding: 14px 36px;
  font-size: 22px;
  font-weight: bold;
  border: none;
  border-radius: 16px;
  background: #E8724A;
  color: #fff;
  cursor: pointer;
  transition: transform 0.2s;
}
.story-submit-btn:active {
  transform: scale(0.95);
}
.story-result {
  text-align: center;
  padding: 20px;
}
.story-result-text {
  font-size: 22px;
  font-weight: bold;
  color: #333;
  line-height: 1.8;
  margin: 16px 20px;
  padding: 16px;
  background: #FFF8F0;
  border-radius: 16px;
  border: 2px solid #FFB347;
}
.story-result-feedback {
  font-size: 20px;
  color: #555;
  margin: 12px 0;
}
.story-result-icon {
  font-size: 80px;
  margin-bottom: 8px;
}
.story-result-stars {
  font-size: 40px;
  margin: 8px 0;
}
```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add story build activity CSS styles"
```

---

## Task 2: Story Build HTML Page

**Files:**
- Modify: `kids-companion/index.html` — 在 `<!-- #SECTION:PAGE-SCENE -->` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-SCENE\>" kids-companion/index.html | head -1
```

- [ ] **Step 2: 插入 HTML**

```html
<!-- #SECTION:PAGE-STORY-BUILD -->
<div class="page" id="page-story-build">
  <div class="game-header">
    <button class="back-btn" onclick="navigateTo('page-home')">← 返回</button>
    <span class="game-title">📖 故事拼組</span>
    <span class="round-counter" id="story-build-counter"></span>
  </div>
  <button class="praise-btn" onclick="showPraiseOverlay()">👏</button>

  <!-- Build area -->
  <div id="story-build-area"></div>

  <!-- Complete screen -->
  <div class="complete-screen" id="story-build-complete">
    <div class="complete-content">
      <div style="font-size:80px">📖</div>
      <h2>小小說書人！</h2>
      <button class="btn btn-primary" onclick="startStoryBuild()">再說一個 🔄</button>
      <button class="btn btn-secondary" onclick="navigateTo('page-home')">回首頁</button>
    </div>
  </div>
</div>
<!-- #END:PAGE-STORY-BUILD -->

```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add story build activity HTML page structure"
```

---

## Task 3: Story Build Data + JS — 全部邏輯

**Files:**
- Modify: `kids-companion/index.html` — 在 `// <!-- #SECTION:PAGE-SCENE-DATA -->` 之前插入

全域可用（已存在）：`ANIMAL_CATEGORIES`, `ANIMALS`（動物園資料）, `SCENE_THEMES`, `FOODS`, `FOOD_CATEGORIES`, `IMG`, `APP`, `speak()`, `speakSequence()`, `playCorrectSound()`, `completeActivity()`, `launchConfettiSmall()`, `navigateTo()`

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-SCENE-DATA" kids-companion/index.html
```

- [ ] **Step 2: 插入 DATA + JS**

```javascript
// <!-- #SECTION:PAGE-STORY-BUILD-DATA -->
var STORY_ACTIONS = [
  { emoji: '🚶', zh: '散步', en: 'took a walk' },
  { emoji: '🎵', zh: '唱歌', en: 'sang a song' },
  { emoji: '💃', zh: '跳舞', en: 'danced' },
  { emoji: '😴', zh: '睡覺', en: 'took a nap' },
  { emoji: '🏃', zh: '跑步', en: 'went running' },
  { emoji: '🔍', zh: '探險', en: 'went exploring' },
  { emoji: '🎮', zh: '玩遊戲', en: 'played games' },
  { emoji: '📖', zh: '看書', en: 'read a book' }
];

var STORY_ENDINGS = [
  { emoji: '🍎', zh: '一起吃蘋果', en: 'ate apples together' },
  { emoji: '🐚', zh: '找到貝殼', en: 'found a seashell' },
  { emoji: '🌈', zh: '看到彩虹', en: 'saw a rainbow' },
  { emoji: '⭐', zh: '許了一個願望', en: 'made a wish' },
  { emoji: '🏠', zh: '一起回家', en: 'went home together' },
  { emoji: '🎉', zh: '開了一場派對', en: 'threw a party' }
];
// <!-- #END:PAGE-STORY-BUILD-DATA -->

// <!-- #SECTION:PAGE-STORY-BUILD-JS -->
var storyBuildState = {
  mode: null,        // 'free' | 'structured'
  slots: [],         // free mode: [{id, emoji, zh, en, imgKey, type}, ...]
  maxSlots: 3,
  availableCards: [],
  columns: {},       // structured mode: {who: item, where: item, action: item, meet: item, then: item}
  columnOptions: {}  // structured mode: {who: [...], where: [...], ...}
};

function storyBuildShuffle(arr) {
  var a = arr.slice();
  for (var i = a.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var tmp = a[i]; a[i] = a[j]; a[j] = tmp;
  }
  return a;
}

function storyBuildGetRandomAnimals(count) {
  var all = [];
  ANIMAL_CATEGORIES.forEach(function(cat) {
    var animals = ANIMALS[cat.id] || [];
    animals.forEach(function(a) {
      all.push({ id: a.id, emoji: a.emoji, zh: a.zh, en: a.en, imgKey: 'zoo-' + a.id, type: 'animal' });
    });
  });
  return storyBuildShuffle(all).slice(0, count);
}

function storyBuildGetRandomFoods(count) {
  var all = [];
  FOOD_CATEGORIES.forEach(function(cat) {
    var foods = FOODS[cat.id] || [];
    foods.forEach(function(f) {
      all.push({ id: f.id, emoji: f.emoji, zh: f.zh, en: f.en, imgKey: 'food-' + f.id, type: 'food' });
    });
  });
  return storyBuildShuffle(all).slice(0, count);
}

function storyBuildGetScenes() {
  return SCENE_THEMES.map(function(t) {
    return { id: t.id, emoji: t.emoji, zh: t.name.zh, en: t.name.en, imgKey: null, type: 'scene' };
  });
}

function startStoryBuild() {
  storyBuildState.slots = [];
  storyBuildState.columns = {};
  storyBuildState.columnOptions = {};
  var complete = document.getElementById('story-build-complete');
  if (complete) complete.classList.remove('show');

  var ag = APP.ageGroup || 'small';

  if (ag === 'toddler' || ag === 'small') {
    storyBuildState.mode = 'free';
    storyBuildState.maxSlots = ag === 'toddler' ? 3 : 4;
    var cardCount = ag === 'toddler' ? 8 : 10;
    var animals = storyBuildGetRandomAnimals(Math.ceil(cardCount * 0.4));
    var scenes = storyBuildGetScenes();
    var foods = storyBuildGetRandomFoods(Math.ceil(cardCount * 0.3));
    var all = animals.concat(scenes).concat(foods);
    storyBuildState.availableCards = storyBuildShuffle(all).slice(0, cardCount);
    renderStoryBuildFree();
  } else {
    storyBuildState.mode = 'structured';
    var optCount = ag === 'large' ? 4 : 3;
    var whoAnimals = storyBuildGetRandomAnimals(optCount);
    var meetAnimals = storyBuildGetRandomAnimals(optCount + 2);
    // Filter out duplicates from who
    var whoIds = {};
    whoAnimals.forEach(function(a) { whoIds[a.id] = true; });
    meetAnimals = meetAnimals.filter(function(a) { return !whoIds[a.id]; }).slice(0, optCount);
    // If not enough, just get more
    if (meetAnimals.length < optCount) {
      var more = storyBuildGetRandomAnimals(optCount * 2);
      more = more.filter(function(a) { return !whoIds[a.id]; });
      meetAnimals = meetAnimals.concat(more).slice(0, optCount);
    }

    var scenes = storyBuildShuffle(storyBuildGetScenes()).slice(0, optCount);
    var actions = storyBuildShuffle(STORY_ACTIONS).slice(0, optCount);

    storyBuildState.columnOptions = {
      who: whoAnimals,
      where: scenes,
      action: actions.map(function(a) { return { id: a.emoji, emoji: a.emoji, zh: a.zh, en: a.en, imgKey: null, type: 'action' }; }),
      meet: meetAnimals
    };

    if (ag === 'large') {
      var endings = storyBuildShuffle(STORY_ENDINGS).slice(0, 4);
      storyBuildState.columnOptions.then_col = endings.map(function(e) {
        return { id: e.emoji, emoji: e.emoji, zh: e.zh, en: e.en, imgKey: null, type: 'ending' };
      });
    }

    renderStoryBuildStructured();
  }

  var lang = APP.language || 'zh';
  setTimeout(function() {
    speak(lang === 'zh' ? '來拼一個你自己的故事吧！' : 'Let\'s build your own story!');
  }, 400);
}

function renderStoryBuildFree() {
  var lang = APP.language || 'zh';
  var area = document.getElementById('story-build-area');
  var counter = document.getElementById('story-build-counter');
  if (counter) counter.textContent = storyBuildState.slots.length + '/' + storyBuildState.maxSlots;

  var html = '<div class="story-track">';
  for (var s = 0; s < storyBuildState.maxSlots; s++) {
    var slot = storyBuildState.slots[s];
    if (slot) {
      var imgSrc = slot.imgKey && IMG[slot.imgKey] ? IMG[slot.imgKey] : '';
      html += '<div class="story-slot filled" onclick="storyBuildRemoveSlot(' + s + ')">';
      if (imgSrc) {
        html += '<img src="' + imgSrc + '" alt="' + slot[lang] + '">';
      } else {
        html += '<div class="story-slot-emoji">' + slot.emoji + '</div>';
      }
      html += '<div class="story-slot-label">' + slot[lang] + '</div>';
      html += '</div>';
    } else {
      html += '<div class="story-slot">?</div>';
    }
  }
  html += '</div>';

  html += '<div class="story-card-picker">';
  storyBuildState.availableCards.forEach(function(card) {
    var isUsed = false;
    for (var i = 0; i < storyBuildState.slots.length; i++) {
      if (storyBuildState.slots[i] && storyBuildState.slots[i].id === card.id) { isUsed = true; break; }
    }
    var imgSrc = card.imgKey && IMG[card.imgKey] ? IMG[card.imgKey] : '';
    html += '<div class="story-card-item' + (isUsed ? ' used' : '') + '" onclick="storyBuildPickCard(\'' + card.id + '\')">';
    if (imgSrc) {
      html += '<img src="' + imgSrc + '" alt="' + card[lang] + '">';
    } else {
      html += '<span class="story-card-emoji">' + card.emoji + '</span>';
    }
    html += '<div class="story-card-label">' + card[lang] + '</div>';
    html += '</div>';
  });
  html += '</div>';

  if (storyBuildState.slots.length >= storyBuildState.maxSlots) {
    html += '<button class="story-submit-btn" onclick="storyBuildSubmit()">說故事！📖</button>';
  }

  area.innerHTML = html;
}

function storyBuildPickCard(cardId) {
  if (storyBuildState.slots.length >= storyBuildState.maxSlots) return;
  for (var i = 0; i < storyBuildState.slots.length; i++) {
    if (storyBuildState.slots[i] && storyBuildState.slots[i].id === cardId) return;
  }
  var card = null;
  for (var j = 0; j < storyBuildState.availableCards.length; j++) {
    if (storyBuildState.availableCards[j].id === cardId) { card = storyBuildState.availableCards[j]; break; }
  }
  if (!card) return;

  storyBuildState.slots.push(card);
  playCorrectSound();

  var ag = APP.ageGroup || 'small';
  var lang = APP.language || 'zh';
  if (ag === 'toddler' || ag === 'small') {
    speak(card[lang]);
  }

  renderStoryBuildFree();
}

function storyBuildRemoveSlot(idx) {
  storyBuildState.slots.splice(idx, 1);
  renderStoryBuildFree();
}

function renderStoryBuildStructured() {
  var lang = APP.language || 'zh';
  var ag = APP.ageGroup || 'small';
  var area = document.getElementById('story-build-area');
  var cols = storyBuildState.columnOptions;
  var sel = storyBuildState.columns;

  var colDefs = [
    { key: 'who', title: { zh: '誰？', en: 'Who?' } },
    { key: 'where', title: { zh: '去了哪裡？', en: 'Where?' } },
    { key: 'action', title: { zh: '做什麼？', en: 'Did what?' } },
    { key: 'meet', title: { zh: '遇到誰？', en: 'Met who?' } }
  ];
  if (ag === 'large') {
    colDefs.push({ key: 'then_col', title: { zh: '然後…', en: 'Then...' } });
  }

  var filledCount = 0;
  colDefs.forEach(function(cd) { if (sel[cd.key]) filledCount++; });
  var counter = document.getElementById('story-build-counter');
  if (counter) counter.textContent = filledCount + '/' + colDefs.length;

  var html = '<div class="story-columns">';
  colDefs.forEach(function(cd) {
    var options = cols[cd.key] || [];
    html += '<div class="story-column">';
    html += '<div class="story-column-title">' + cd.title[lang] + '</div>';
    html += '<div class="story-column-options">';
    options.forEach(function(opt) {
      var isSelected = sel[cd.key] && sel[cd.key].id === opt.id;
      var imgSrc = opt.imgKey && IMG[opt.imgKey] ? IMG[opt.imgKey] : '';
      html += '<div class="story-col-option' + (isSelected ? ' selected' : '') + '" onclick="storyBuildColPick(\'' + cd.key + '\',\'' + opt.id + '\')">';
      if (imgSrc) {
        html += '<img src="' + imgSrc + '" alt="' + opt[lang] + '">';
      }
      html += opt.emoji + ' ' + opt[lang];
      html += '</div>';
    });
    html += '</div></div>';
  });
  html += '</div>';

  if (filledCount >= colDefs.length) {
    html += '<button class="story-submit-btn" onclick="storyBuildSubmit()">說故事！📖</button>';
  }

  area.innerHTML = html;
}

function storyBuildColPick(colKey, optId) {
  var options = storyBuildState.columnOptions[colKey] || [];
  var opt = null;
  for (var i = 0; i < options.length; i++) {
    if (options[i].id === optId) { opt = options[i]; break; }
  }
  if (!opt) return;

  if (storyBuildState.columns[colKey] && storyBuildState.columns[colKey].id === optId) {
    delete storyBuildState.columns[colKey];
  } else {
    storyBuildState.columns[colKey] = opt;
  }
  playCorrectSound();
  renderStoryBuildStructured();
}

function storyBuildSubmit() {
  var ag = APP.ageGroup || 'small';
  var lang = APP.language || 'zh';
  var area = document.getElementById('story-build-area');

  if (storyBuildState.mode === 'free') {
    // Build story text from slots
    var names = storyBuildState.slots.map(function(s) { return s[lang]; });
    var storyText = names.join(lang === 'zh' ? '… ' : '... ');

    // Count types
    var types = {};
    storyBuildState.slots.forEach(function(s) { types[s.type] = true; });
    var typeCount = Object.keys(types).length;

    var feedbackMsg = '';
    if (ag === 'toddler') {
      feedbackMsg = lang === 'zh' ? '🦊 好有趣的故事！' : '🦊 What a fun story!';
    } else {
      feedbackMsg = lang === 'zh' ? '🦊 你用了 ' + typeCount + ' 種不同的東西！好豐富！' : '🦊 You used ' + typeCount + ' different types! So creative!';
    }

    var html = '<div class="story-result">';
    html += '<div class="story-result-icon">📖</div>';
    html += '<div class="story-result-text">' + storyText + '</div>';
    html += '<div class="story-result-feedback">' + feedbackMsg + '</div>';
    html += '<button class="btn btn-primary" onclick="startStoryBuild()" style="margin:8px">再說一個 🔄</button>';
    html += '<button class="btn btn-secondary" onclick="navigateTo(\'page-home\')" style="margin:8px">回首頁</button>';
    html += '</div>';
    area.innerHTML = html;

    completeActivity('page-story-build');
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    speakSequence(names.concat([feedbackMsg]));
    launchConfettiSmall();

  } else {
    // Structured mode
    var sel = storyBuildState.columns;
    var parts = [];
    if (sel.who) parts.push(sel.who[lang]);
    if (sel.where) parts.push(lang === 'zh' ? '去了' + sel.where[lang] : 'went to ' + sel.where[lang]);
    if (sel.action) parts.push(sel.action[lang]);
    if (sel.meet) parts.push(lang === 'zh' ? '遇到' + sel.meet[lang] : 'and met ' + sel.meet[lang]);
    if (sel.then_col) parts.push(lang === 'zh' ? '然後' + sel.then_col[lang] : 'then ' + sel.then_col[lang]);

    var storyText = lang === 'zh' ? parts.join('，') : parts.join(', ');

    var filledCount = Object.keys(sel).length;
    var totalCols = ag === 'large' ? 5 : 4;

    var feedbackMsg = '';
    var starsHtml = '';
    if (ag === 'large') {
      var stars = 1;
      if (filledCount >= 5) { stars = 3; feedbackMsg = lang === 'zh' ? '完美的故事！太有創意了！' : 'Perfect story! So creative!'; }
      else if (filledCount >= 4) { stars = 2; feedbackMsg = lang === 'zh' ? '很棒的故事！' : 'Great story!'; }
      else { stars = 1; feedbackMsg = lang === 'zh' ? '不錯的開始！' : 'Good start!'; }
      for (var i = 0; i < stars; i++) starsHtml += '⭐';
    } else {
      feedbackMsg = lang === 'zh' ? '好棒的故事！你用了角色、場景和動作，好完整！' : 'Great story! You used characters, scenes, and actions!';
    }

    var html = '<div class="story-result">';
    html += '<div class="story-result-icon">📖</div>';
    html += '<div class="story-result-text">' + storyText + '</div>';
    if (starsHtml) html += '<div class="story-result-stars">' + starsHtml + '</div>';
    html += '<div class="story-result-feedback">' + feedbackMsg + '</div>';
    html += '<button class="btn btn-primary" onclick="startStoryBuild()" style="margin:8px">再說一個 🔄</button>';
    html += '<button class="btn btn-secondary" onclick="navigateTo(\'page-home\')" style="margin:8px">回首頁</button>';
    html += '</div>';
    area.innerHTML = html;

    completeActivity('page-story-build');
    playCorrectSound();
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    speak(storyText);
    setTimeout(function() { speak(feedbackMsg); }, storyText.length * 150 + 1000);
    launchConfettiSmall();
  }
}
// <!-- #END:PAGE-STORY-BUILD-JS -->
```

- [ ] **Step 3: 驗證錨點**

```bash
grep -n "#SECTION:PAGE-STORY-BUILD-DATA\|#END:PAGE-STORY-BUILD-DATA\|#SECTION:PAGE-STORY-BUILD-JS\|#END:PAGE-STORY-BUILD-JS" kids-companion/index.html
# 預期: 4 行
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add story build activity data + JS (free mode, structured mode, speech)"
```

---

## Task 4: Wire Story Build to Home Page + Navigation + Stickers

**Files:**
- Modify: `kids-companion/index.html` — 3 個地方

- [ ] **Step 1: 在探索 tab 加入故事拼組活動卡（緊接 scene 卡片後面）**

找到：
```html
      <div class="activity-card" onclick="navigateTo('page-scene')">
        <span class="activity-icon">🎨</span>
        <span class="label">場景佈置</span>
      </div>
```

在其後插入：
```html
      <div class="activity-card" onclick="navigateTo('page-story-build')">
        <span class="activity-icon">📖</span>
        <span class="label">故事拼組</span>
      </div>
```

- [ ] **Step 2: 在貼紙板加入故事拼組貼紙（緊接 scene 貼紙後）**

找到：
```html
    <div class="sticker-slot locked" data-sticker="page-scene">🎨</div>
```

在其後插入：
```html
    <div class="sticker-slot locked" data-sticker="page-story-build">📖</div>
```

- [ ] **Step 3: 在 navigateTo() 函式加入初始化**

找到：
```javascript
  if (pageId === 'page-scene') showSceneShelf();
```

在其後插入：
```javascript
  if (pageId === 'page-story-build') startStoryBuild();
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: wire story build activity to home, navigation, sticker board"
```

---

## Task 5: Update CLAUDE.md + Push

**Files:**
- Modify: `kids-companion/CLAUDE.md`

- [ ] **Step 1: 在錨點清單加入 story-build 活動**

找到 `#SECTION:IMAGES-SCENE` 那行之後，插入：

```markdown
| `#SECTION:PAGE-STORY-BUILD` | 故事拼組活動 |
| `#SECTION:PAGE-STORY-BUILD-DATA` | 故事拼組資料（動作詞、結局詞） |
| `#SECTION:PAGE-STORY-BUILD-JS` | 故事拼組 JS 邏輯 |
```

- [ ] **Step 2: Commit + Push**

```bash
git add kids-companion/CLAUDE.md
git commit -m "docs: add story build activity anchors to CLAUDE.md"
git push
```
