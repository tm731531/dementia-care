# 場景佈置 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增「場景佈置」活動（`page-scene`），讓孩子選場景（草地/海邊/森林），點擊放置 + 拖動調整素材位置，依年齡提供自由/任務模式。

**Architecture:** 單一 `page-scene` 頁面，場景選擇貨架 → 佈置畫面。素材資料定義在 `PAGE-SCENE-DATA`，圖片從 Wikipedia 抓取存入 `IMAGES-SCENE`。全部在 `index.html` 單檔完成。

**Tech Stack:** HTML + CSS（漸層背景） + vanilla JS（pointer events 拖動）

---

## 錨點速查

```bash
grep -n "#END:CSS" kids-companion/index.html                     # CSS 插入點
grep -n "#SECTION:PAGE-PLATE\>" kids-companion/index.html        # HTML 插入點（在 plate 前面）
grep -n "#SECTION:PAGE-PLATE-JS" kids-companion/index.html       # JS 插入點（在 plate-JS 前面）
grep -n "#END:IMAGES-FOOD" kids-companion/index.html             # 圖片插入點（在 food 圖片後面）
```

---

## Task 1: Scene CSS

**Files:**
- Modify: `kids-companion/index.html` — 在 `/* <!-- #END:CSS --> */` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#END:CSS" kids-companion/index.html
```

- [ ] **Step 2: 插入 CSS**

```css
/* --- Scene Activity --- */
.scene-shelf-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 16px;
  max-width: 420px;
  margin: 40px auto;
  padding: 20px;
}
.scene-shelf-card {
  background: #fff;
  border-radius: 20px;
  padding: 24px 12px;
  text-align: center;
  cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s;
}
.scene-shelf-card:active {
  transform: scale(0.95);
}
.scene-shelf-icon {
  font-size: 48px;
  display: block;
  margin-bottom: 8px;
}
.scene-shelf-name {
  font-size: 18px;
  font-weight: bold;
  color: #333;
}
.scene-canvas {
  width: min(500px, 90vw);
  height: min(320px, 50vh);
  border-radius: 20px;
  position: relative;
  margin: 10px auto;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  touch-action: none;
}
.scene-bg-meadow {
  background: linear-gradient(180deg, #87CEEB 40%, #90EE90 40%);
}
.scene-bg-beach {
  background: linear-gradient(180deg, #87CEEB 35%, #F5DEB3 35%, #F5DEB3 55%, #4169E1 55%);
}
.scene-bg-forest {
  background: linear-gradient(180deg, #6B8E6B 30%, #2E4E2E 30%);
}
.scene-placed-item {
  position: absolute;
  width: 60px;
  height: 60px;
  cursor: grab;
  touch-action: none;
  transition: transform 0.1s;
  user-select: none;
  -webkit-user-select: none;
}
.scene-placed-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 10px;
  pointer-events: none;
}
.scene-placed-item.dragging {
  transform: scale(1.15);
  z-index: 100;
  cursor: grabbing;
}
.scene-placed-emoji {
  font-size: 44px;
  line-height: 60px;
  text-align: center;
  pointer-events: none;
}
.scene-picker {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
  margin: 10px auto;
  max-width: 500px;
  padding: 8px;
}
.scene-picker-item {
  width: 64px;
  text-align: center;
  cursor: pointer;
  border-radius: 12px;
  padding: 4px;
  background: #fff;
  border: 2px solid #eee;
  transition: all 0.2s;
}
.scene-picker-item:active {
  transform: scale(0.9);
}
.scene-picker-item.used {
  opacity: 0.4;
  pointer-events: none;
}
.scene-picker-item img {
  width: 44px;
  height: 44px;
  border-radius: 8px;
  object-fit: cover;
  display: block;
  margin: 0 auto 2px;
}
.scene-picker-item .scene-picker-emoji {
  font-size: 32px;
  display: block;
  margin-bottom: 2px;
}
.scene-picker-item .scene-picker-label {
  font-size: 11px;
  color: #555;
  line-height: 1.2;
}
.scene-task-text {
  font-size: 20px;
  font-weight: bold;
  color: #333;
  text-align: center;
  margin: 8px 16px;
  line-height: 1.4;
}
.scene-submit-btn {
  display: block;
  margin: 8px auto;
  padding: 12px 36px;
  font-size: 20px;
  font-weight: bold;
  border: none;
  border-radius: 16px;
  background: #E8724A;
  color: #fff;
  cursor: pointer;
  transition: transform 0.2s;
}
.scene-submit-btn:active {
  transform: scale(0.95);
}
.scene-feedback {
  text-align: center;
  padding: 20px;
}
.scene-feedback-icon {
  font-size: 80px;
  margin-bottom: 10px;
}
.scene-feedback-text {
  font-size: 24px;
  font-weight: bold;
  color: #333;
  line-height: 1.6;
  margin-bottom: 10px;
}
.scene-stars {
  font-size: 40px;
  margin: 10px 0;
}
```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add scene activity CSS styles"
```

---

## Task 2: Scene HTML Page

**Files:**
- Modify: `kids-companion/index.html` — 在 `<!-- #SECTION:PAGE-PLATE -->` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-PLATE\>" kids-companion/index.html | head -1
```

- [ ] **Step 2: 插入 HTML**

```html
<!-- #SECTION:PAGE-SCENE -->
<div class="page" id="page-scene">
  <div class="game-header">
    <button class="back-btn" id="scene-back-btn" onclick="sceneBack()">← 返回</button>
    <span class="game-title" id="scene-title">🎨 場景佈置</span>
    <span class="round-counter" id="scene-counter"></span>
  </div>
  <button class="praise-btn" onclick="showPraiseOverlay()">👏</button>

  <!-- Scene shelf -->
  <div id="scene-shelf">
    <div class="scene-shelf-grid">
      <div class="scene-shelf-card" onclick="openScene('meadow')">
        <span class="scene-shelf-icon">🌿</span>
        <div class="scene-shelf-name">草地</div>
      </div>
      <div class="scene-shelf-card" onclick="openScene('beach')">
        <span class="scene-shelf-icon">🏖️</span>
        <div class="scene-shelf-name">海邊</div>
      </div>
      <div class="scene-shelf-card" onclick="openScene('forest')">
        <span class="scene-shelf-icon">🌲</span>
        <div class="scene-shelf-name">森林</div>
      </div>
    </div>
  </div>

  <!-- Build area -->
  <div id="scene-build" style="display:none"></div>

  <!-- Complete screen -->
  <div class="complete-screen" id="scene-complete">
    <div class="complete-content">
      <div style="font-size:80px">🎨</div>
      <h2>小小設計師！</h2>
      <button class="btn btn-primary" onclick="openScene(sceneState.currentScene)">再玩一次 🔄</button>
      <button class="btn btn-secondary" onclick="showSceneShelf()">換場景</button>
    </div>
  </div>
</div>
<!-- #END:PAGE-SCENE -->

```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add scene activity HTML page structure"
```

---

## Task 3: Scene Data

**Files:**
- Modify: `kids-companion/index.html` — 在 `// <!-- #SECTION:PAGE-PLATE-JS -->` 之前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-PLATE-JS" kids-companion/index.html
```

- [ ] **Step 2: 插入素材資料**

```javascript
// <!-- #SECTION:PAGE-SCENE-DATA -->
var SCENE_THEMES = [
  { id: 'meadow', emoji: '🌿', name: { zh: '草地', en: 'Meadow' }, bgClass: 'scene-bg-meadow' },
  { id: 'beach',  emoji: '🏖️', name: { zh: '海邊', en: 'Beach' },  bgClass: 'scene-bg-beach' },
  { id: 'forest', emoji: '🌲', name: { zh: '森林', en: 'Forest' }, bgClass: 'scene-bg-forest' }
];

var SCENE_ITEMS = {
  meadow: [
    { id: 'sunflower', emoji: '🌻', zh: '向日葵', en: 'Sunflower', type: 'plant' },
    { id: 'rose', emoji: '🌹', zh: '玫瑰', en: 'Rose', type: 'plant' },
    { id: 'tulip', emoji: '🌷', zh: '鬱金香', en: 'Tulip', type: 'plant' },
    { id: 'daisy', emoji: '🌼', zh: '雛菊', en: 'Daisy', type: 'plant' },
    { id: 'oak_tree', emoji: '🌳', zh: '橡樹', en: 'Oak tree', type: 'plant' },
    { id: 'cherry_blossom', emoji: '🌸', zh: '櫻花樹', en: 'Cherry blossom', type: 'plant' },
    { id: 'rabbit', emoji: '🐰', zh: '兔子', en: 'Rabbit', type: 'animal' },
    { id: 'butterfly', emoji: '🦋', zh: '蝴蝶', en: 'Butterfly', type: 'animal' },
    { id: 'ladybug', emoji: '🐞', zh: '瓢蟲', en: 'Ladybug', type: 'animal' },
    { id: 'sparrow', emoji: '🐦', zh: '小鳥', en: 'Sparrow', type: 'animal' },
    { id: 'fence', emoji: '🏗️', zh: '柵欄', en: 'Fence', type: 'object' },
    { id: 'cottage', emoji: '🏠', zh: '小屋', en: 'Cottage', type: 'object' }
  ],
  beach: [
    { id: 'seashell', emoji: '🐚', zh: '貝殼', en: 'Seashell', type: 'object' },
    { id: 'crab', emoji: '🦀', zh: '螃蟹', en: 'Crab', type: 'animal' },
    { id: 'starfish', emoji: '⭐', zh: '海星', en: 'Starfish', type: 'animal' },
    { id: 'tropical_fish', emoji: '🐠', zh: '熱帶魚', en: 'Tropical fish', type: 'animal' },
    { id: 'dolphin', emoji: '🐬', zh: '海豚', en: 'Dolphin', type: 'animal' },
    { id: 'coconut_tree', emoji: '🌴', zh: '椰子樹', en: 'Coconut tree', type: 'plant' },
    { id: 'sailboat', emoji: '⛵', zh: '帆船', en: 'Sailboat', type: 'object' },
    { id: 'lighthouse', emoji: '🗼', zh: '燈塔', en: 'Lighthouse', type: 'object' },
    { id: 'seagull', emoji: '🕊️', zh: '海鷗', en: 'Seagull', type: 'animal' },
    { id: 'coral', emoji: '🪸', zh: '珊瑚', en: 'Coral', type: 'plant' },
    { id: 'jellyfish', emoji: '🪼', zh: '水母', en: 'Jellyfish', type: 'animal' },
    { id: 'octopus_s', emoji: '🐙', zh: '章魚', en: 'Octopus', type: 'animal' }
  ],
  forest: [
    { id: 'pine_tree', emoji: '🌲', zh: '松樹', en: 'Pine tree', type: 'plant' },
    { id: 'mushroom_s', emoji: '🍄', zh: '蘑菇', en: 'Mushroom', type: 'plant' },
    { id: 'squirrel', emoji: '🐿️', zh: '松鼠', en: 'Squirrel', type: 'animal' },
    { id: 'deer', emoji: '🦌', zh: '鹿', en: 'Deer', type: 'animal' },
    { id: 'owl', emoji: '🦉', zh: '貓頭鷹', en: 'Owl', type: 'animal' },
    { id: 'log_cabin', emoji: '🏚️', zh: '木屋', en: 'Log cabin', type: 'object' },
    { id: 'stream', emoji: '💧', zh: '溪流', en: 'Stream', type: 'object' },
    { id: 'fern', emoji: '🌿', zh: '蕨類', en: 'Fern', type: 'plant' },
    { id: 'woodpecker', emoji: '🐦', zh: '啄木鳥', en: 'Woodpecker', type: 'animal' },
    { id: 'hedgehog', emoji: '🦔', zh: '刺蝟', en: 'Hedgehog', type: 'animal' },
    { id: 'acorn', emoji: '🌰', zh: '橡實', en: 'Acorn', type: 'object' },
    { id: 'waterfall', emoji: '🏞️', zh: '瀑布', en: 'Waterfall', type: 'object' }
  ]
};

var SCENE_TASKS = {
  meadow: [
    { zh: '在草地上種 3 朵花 🌸', en: 'Plant 3 flowers on the meadow 🌸', check: function(items) { return items.filter(function(i){return i.type==='plant'}).length >= 3; } },
    { zh: '放 2 隻小動物到草地上', en: 'Put 2 animals on the meadow', check: function(items) { return items.filter(function(i){return i.type==='animal'}).length >= 2; } },
    { zh: '佈置一個有花、有動物、有房子的草地', en: 'Make a meadow with flowers, animals, and a house', check: function(items) { var t={}; items.forEach(function(i){t[i.type]=true}); return t.plant && t.animal && t.object; } },
    { zh: '放 5 樣東西讓草地變熱鬧', en: 'Place 5 items to liven up the meadow', check: function(items) { return items.length >= 5; } }
  ],
  beach: [
    { zh: '放 3 隻海洋動物到海邊', en: 'Put 3 sea animals on the beach', check: function(items) { return items.filter(function(i){return i.type==='animal'}).length >= 3; } },
    { zh: '放椰子樹和帆船到海邊', en: 'Put a coconut tree and sailboat on the beach', check: function(items) { var ids=items.map(function(i){return i.id}); return ids.indexOf('coconut_tree')!==-1 && ids.indexOf('sailboat')!==-1; } },
    { zh: '放 2 棵植物和 2 隻動物', en: 'Place 2 plants and 2 animals', check: function(items) { return items.filter(function(i){return i.type==='plant'}).length>=2 && items.filter(function(i){return i.type==='animal'}).length>=2; } },
    { zh: '放 5 樣東西讓海邊變熱鬧', en: 'Place 5 items to liven up the beach', check: function(items) { return items.length >= 5; } }
  ],
  forest: [
    { zh: '種 3 棵樹在森林裡 🌲', en: 'Plant 3 trees in the forest 🌲', check: function(items) { return items.filter(function(i){return i.type==='plant'}).length >= 3; } },
    { zh: '放 2 隻森林動物', en: 'Put 2 forest animals', check: function(items) { return items.filter(function(i){return i.type==='animal'}).length >= 2; } },
    { zh: '蓋一間木屋，旁邊放樹和動物', en: 'Build a cabin with trees and animals nearby', check: function(items) { var ids=items.map(function(i){return i.id}); var t={}; items.forEach(function(i){t[i.type]=true}); return ids.indexOf('log_cabin')!==-1 && t.plant && t.animal; } },
    { zh: '放 5 樣東西讓森林變熱鬧', en: 'Place 5 items to liven up the forest', check: function(items) { return items.length >= 5; } }
  ]
};
// <!-- #END:PAGE-SCENE-DATA -->
```

- [ ] **Step 3: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add scene activity data (themes, items, tasks)"
```

---

## Task 4: Scene JS — 全部邏輯（shelf + build + drag + submit）

**Files:**
- Modify: `kids-companion/index.html` — 在 `// <!-- #END:PAGE-SCENE-DATA -->` 之後、`// <!-- #SECTION:PAGE-PLATE-JS -->` 之前插入

全域可用：`SCENE_THEMES`, `SCENE_ITEMS`, `SCENE_TASKS`, `IMG`, `APP`, `speak()`, `playCorrectSound()`, `playWrongSound()`, `completeActivity()`, `launchConfettiSmall()`, `navigateTo()`

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#END:PAGE-SCENE-DATA\|#SECTION:PAGE-PLATE-JS" kids-companion/index.html
```

- [ ] **Step 2: 插入全部 JS**

```javascript
// <!-- #SECTION:PAGE-SCENE-JS -->
var sceneState = {
  currentScene: null,
  placedItems: [],   // [{id, emoji, zh, en, type, x, y}, ...]
  maxItems: 6,
  availableItems: [],
  task: null,
  dragItem: null,
  dragOffset: { x: 0, y: 0 }
};

function sceneShuffle(arr) {
  var a = arr.slice();
  for (var i = a.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var tmp = a[i]; a[i] = a[j]; a[j] = tmp;
  }
  return a;
}

function showSceneShelf() {
  sceneState.currentScene = null;
  sceneState.placedItems = [];
  sceneState.task = null;
  var shelf = document.getElementById('scene-shelf');
  var build = document.getElementById('scene-build');
  var complete = document.getElementById('scene-complete');
  if (shelf) shelf.style.display = '';
  if (build) build.style.display = 'none';
  if (complete) complete.classList.remove('show');
  document.getElementById('scene-title').textContent = '🎨 場景佈置';
  document.getElementById('scene-counter').textContent = '';
  document.getElementById('scene-back-btn').onclick = function() { navigateTo('page-home'); };
}

function sceneBack() {
  if ('speechSynthesis' in window) speechSynthesis.cancel();
  if (sceneState.currentScene) {
    showSceneShelf();
  } else {
    navigateTo('page-home');
  }
}

function getSceneAgeConfig() {
  var configs = {
    toddler: { itemCount: 8, maxPlace: 6, mode: 'free' },
    small:   { itemCount: 10, maxPlace: 8, mode: 'free' },
    middle:  { itemCount: 12, maxPlace: 10, mode: 'task' },
    large:   { itemCount: 12, maxPlace: 12, mode: 'task' }
  };
  return configs[APP.ageGroup] || configs.small;
}

function openScene(sceneId) {
  var theme = null;
  for (var i = 0; i < SCENE_THEMES.length; i++) {
    if (SCENE_THEMES[i].id === sceneId) { theme = SCENE_THEMES[i]; break; }
  }
  if (!theme) return;

  sceneState.currentScene = sceneId;
  sceneState.placedItems = [];
  sceneState.task = null;

  var lang = APP.language || 'zh';
  var cfg = getSceneAgeConfig();
  sceneState.maxItems = cfg.maxPlace;

  var allItems = SCENE_ITEMS[sceneId] || [];
  sceneState.availableItems = sceneShuffle(allItems).slice(0, cfg.itemCount);

  document.getElementById('scene-title').textContent = theme.emoji + ' ' + theme.name[lang];
  document.getElementById('scene-back-btn').onclick = function() {
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    showSceneShelf();
  };
  document.getElementById('scene-shelf').style.display = 'none';
  document.getElementById('scene-build').style.display = '';
  document.getElementById('scene-complete').classList.remove('show');

  if (cfg.mode === 'task') {
    var tasks = SCENE_TASKS[sceneId] || [];
    var ag = APP.ageGroup || 'small';
    if (ag === 'large') {
      sceneState.task = tasks[2] || tasks[tasks.length - 1];
    } else {
      sceneState.task = tasks[Math.floor(Math.random() * tasks.length)];
    }
  }

  renderSceneBuild();

  if (cfg.mode === 'task' && sceneState.task) {
    setTimeout(function() { speak(sceneState.task[lang]); }, 400);
  } else {
    setTimeout(function() {
      speak(lang === 'zh' ? '點選下面的東西，放到場景裡吧！' : 'Tap items below to place them in the scene!');
    }, 400);
  }
}

function renderSceneBuild() {
  var lang = APP.language || 'zh';
  var ag = APP.ageGroup || 'small';
  var build = document.getElementById('scene-build');
  var counter = document.getElementById('scene-counter');
  if (counter) counter.textContent = sceneState.placedItems.length + '/' + sceneState.maxItems;

  var theme = null;
  for (var i = 0; i < SCENE_THEMES.length; i++) {
    if (SCENE_THEMES[i].id === sceneState.currentScene) { theme = SCENE_THEMES[i]; break; }
  }

  var html = '';

  if (sceneState.task) {
    html += '<div class="scene-task-text">' + sceneState.task[lang] + '</div>';
  }

  html += '<div class="scene-canvas ' + theme.bgClass + '" id="scene-canvas">';
  sceneState.placedItems.forEach(function(item, idx) {
    var imgSrc = (typeof IMG !== 'undefined' && IMG['scene-' + item.id]) ? IMG['scene-' + item.id] : '';
    html += '<div class="scene-placed-item" data-idx="' + idx + '" style="left:' + item.x + 'px;top:' + item.y + 'px"';
    html += ' onpointerdown="sceneStartDrag(event,' + idx + ')">';
    if (imgSrc) {
      html += '<img src="' + imgSrc + '" alt="' + item[lang] + '">';
    } else {
      html += '<div class="scene-placed-emoji">' + item.emoji + '</div>';
    }
    html += '</div>';
  });
  html += '</div>';

  html += '<div class="scene-picker">';
  sceneState.availableItems.forEach(function(item) {
    var isUsed = false;
    for (var j = 0; j < sceneState.placedItems.length; j++) {
      if (sceneState.placedItems[j].id === item.id) { isUsed = true; break; }
    }
    var imgSrc = (typeof IMG !== 'undefined' && IMG['scene-' + item.id]) ? IMG['scene-' + item.id] : '';
    html += '<div class="scene-picker-item' + (isUsed ? ' used' : '') + '" onclick="scenePlaceItem(\'' + item.id + '\')">';
    if (imgSrc) {
      html += '<img src="' + imgSrc + '" alt="' + item[lang] + '">';
    } else {
      html += '<span class="scene-picker-emoji">' + item.emoji + '</span>';
    }
    html += '<div class="scene-picker-label">' + item[lang] + '</div>';
    html += '</div>';
  });
  html += '</div>';

  if (sceneState.placedItems.length > 0) {
    html += '<button class="scene-submit-btn" onclick="sceneSubmit()">完成！✨</button>';
  }

  build.innerHTML = html;
}

function scenePlaceItem(itemId) {
  if (sceneState.placedItems.length >= sceneState.maxItems) return;

  var item = null;
  for (var i = 0; i < sceneState.availableItems.length; i++) {
    if (sceneState.availableItems[i].id === itemId) { item = sceneState.availableItems[i]; break; }
  }
  if (!item) return;

  for (var j = 0; j < sceneState.placedItems.length; j++) {
    if (sceneState.placedItems[j].id === itemId) return;
  }

  var canvas = document.getElementById('scene-canvas');
  var cw = canvas ? canvas.offsetWidth : 400;
  var ch = canvas ? canvas.offsetHeight : 280;
  var x = Math.floor(cw / 2 - 30 + (Math.random() - 0.5) * 80);
  var y = Math.floor(ch / 2 - 30 + (Math.random() - 0.5) * 60);
  x = Math.max(0, Math.min(x, cw - 60));
  y = Math.max(0, Math.min(y, ch - 60));

  sceneState.placedItems.push({
    id: item.id, emoji: item.emoji, zh: item.zh, en: item.en, type: item.type, x: x, y: y
  });

  playCorrectSound();

  var ag = APP.ageGroup || 'small';
  var lang = APP.language || 'zh';
  if (ag === 'toddler' || ag === 'small') {
    speak(item[lang]);
  }

  renderSceneBuild();
}

function sceneStartDrag(e, idx) {
  e.preventDefault();
  var el = e.target.closest('.scene-placed-item');
  if (!el) return;
  var canvas = document.getElementById('scene-canvas');
  if (!canvas) return;

  el.classList.add('dragging');
  el.setPointerCapture(e.pointerId);

  var rect = canvas.getBoundingClientRect();
  sceneState.dragItem = idx;
  sceneState.dragOffset.x = e.clientX - (rect.left + sceneState.placedItems[idx].x);
  sceneState.dragOffset.y = e.clientY - (rect.top + sceneState.placedItems[idx].y);

  el.onpointermove = function(ev) {
    ev.preventDefault();
    var r = canvas.getBoundingClientRect();
    var nx = ev.clientX - r.left - sceneState.dragOffset.x;
    var ny = ev.clientY - r.top - sceneState.dragOffset.y;
    nx = Math.max(0, Math.min(nx, r.width - 60));
    ny = Math.max(0, Math.min(ny, r.height - 60));
    sceneState.placedItems[idx].x = nx;
    sceneState.placedItems[idx].y = ny;
    el.style.left = nx + 'px';
    el.style.top = ny + 'px';
  };

  el.onpointerup = function(ev) {
    el.classList.remove('dragging');
    el.onpointermove = null;
    el.onpointerup = null;
    sceneState.dragItem = null;
  };
}

function sceneSubmit() {
  var ag = APP.ageGroup || 'small';
  var lang = APP.language || 'zh';
  var build = document.getElementById('scene-build');

  if (ag === 'toddler') {
    var msg = lang === 'zh' ? '好漂亮的場景！🦊 好喜歡！' : 'Beautiful scene! 🦊 loves it!';
    var html = '<div class="scene-feedback">';
    html += '<div class="scene-feedback-icon">🦊</div>';
    html += '<div class="scene-feedback-text">' + msg + '</div>';
    html += '<button class="btn btn-primary" onclick="openScene(\'' + sceneState.currentScene + '\')" style="margin:8px">再玩一次 🔄</button>';
    html += '<button class="btn btn-secondary" onclick="showSceneShelf()" style="margin:8px">換場景</button>';
    html += '</div>';
    build.innerHTML = html;
    completeActivity('page-scene');
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    speak(msg);
    launchConfettiSmall();
  } else if (ag === 'small') {
    var n = sceneState.placedItems.length;
    var msg = lang === 'zh' ? '你放了 ' + n + ' 樣東西，好豐富！🦊 好開心！' : 'You placed ' + n + ' items! 🦊 is happy!';
    var html = '<div class="scene-feedback">';
    html += '<div class="scene-feedback-icon">🦊</div>';
    html += '<div class="scene-feedback-text">' + msg + '</div>';
    html += '<button class="btn btn-primary" onclick="openScene(\'' + sceneState.currentScene + '\')" style="margin:8px">再玩一次 🔄</button>';
    html += '<button class="btn btn-secondary" onclick="showSceneShelf()" style="margin:8px">換場景</button>';
    html += '</div>';
    build.innerHTML = html;
    completeActivity('page-scene');
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    speak(msg);
    launchConfettiSmall();
  } else if (ag === 'middle') {
    var task = sceneState.task;
    var success = task && task.check(sceneState.placedItems);
    if (success) {
      var msg = lang === 'zh' ? '太棒了！任務完成！' : 'Great! Mission accomplished!';
      var html = '<div class="scene-feedback">';
      html += '<div class="scene-feedback-icon">🦊</div>';
      html += '<div class="scene-feedback-text">' + msg + '</div>';
      html += '<button class="btn btn-primary" onclick="openScene(\'' + sceneState.currentScene + '\')" style="margin:8px">再玩一次 🔄</button>';
      html += '<button class="btn btn-secondary" onclick="showSceneShelf()" style="margin:8px">換場景</button>';
      html += '</div>';
      build.innerHTML = html;
      completeActivity('page-scene');
      playCorrectSound();
      if ('speechSynthesis' in window) speechSynthesis.cancel();
      speak(msg);
      launchConfettiSmall();
    } else {
      playWrongSound();
      var hint = lang === 'zh' ? '差一點點！再看看任務要求喔！' : 'Almost! Check the task again!';
      if ('speechSynthesis' in window) speechSynthesis.cancel();
      speak(hint);
    }
  } else {
    var task = sceneState.task;
    var success = task && task.check(sceneState.placedItems);
    var n = sceneState.placedItems.length;
    var types = {};
    sceneState.placedItems.forEach(function(i) { types[i.type] = true; });
    var typeCount = Object.keys(types).length;

    var stars = 1;
    var msg = '';
    if (success && n >= 6 && typeCount >= 3) {
      stars = 3;
      msg = lang === 'zh' ? '完美佈置！太厲害了！' : 'Perfect scene! Amazing!';
    } else if (success) {
      stars = 2;
      msg = lang === 'zh' ? '任務完成！做得很好！' : 'Mission accomplished! Great job!';
    } else {
      stars = 1;
      msg = lang === 'zh' ? '不錯的開始！再試試看任務要求！' : 'Good start! Try the task again!';
    }

    if (stars >= 2) {
      var starsHtml = '';
      for (var i = 0; i < stars; i++) starsHtml += '⭐';
      var html = '<div class="scene-feedback">';
      html += '<div class="scene-feedback-icon">🎨</div>';
      html += '<div class="scene-stars">' + starsHtml + '</div>';
      html += '<div class="scene-feedback-text">' + msg + '</div>';
      html += '<button class="btn btn-primary" onclick="openScene(\'' + sceneState.currentScene + '\')" style="margin:8px">再玩一次 🔄</button>';
      html += '<button class="btn btn-secondary" onclick="showSceneShelf()" style="margin:8px">換場景</button>';
      html += '</div>';
      build.innerHTML = html;
      completeActivity('page-scene');
      playCorrectSound();
      if ('speechSynthesis' in window) speechSynthesis.cancel();
      speak(msg);
      if (stars >= 3) launchConfettiSmall();
    } else {
      playWrongSound();
      if ('speechSynthesis' in window) speechSynthesis.cancel();
      speak(msg);
    }
  }
}
// <!-- #END:PAGE-SCENE-JS -->
```

- [ ] **Step 3: 驗證錨點**

```bash
grep -n "#SECTION:PAGE-SCENE-JS\|#END:PAGE-SCENE-JS\|#SECTION:PAGE-SCENE-DATA\|#END:PAGE-SCENE-DATA" kids-companion/index.html
# 預期: 4 行
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add scene activity JS — shelf, build, drag, tasks, feedback"
```

---

## Task 5: Wire Scene to Home Page + Navigation + Stickers

**Files:**
- Modify: `kids-companion/index.html` — 3 個地方

- [ ] **Step 1: 在探索 tab 加入場景活動卡（緊接 plate 卡片後面）**

找到：
```html
      <div class="activity-card" onclick="navigateTo('page-plate')">
        <span class="activity-icon">🍽️</span>
        <span class="label">餐盤設計</span>
      </div>
```

在其後插入：
```html
      <div class="activity-card" onclick="navigateTo('page-scene')">
        <span class="activity-icon">🎨</span>
        <span class="label">場景佈置</span>
      </div>
```

- [ ] **Step 2: 在貼紙板加入場景貼紙（緊接 plate 貼紙後）**

找到：
```html
    <div class="sticker-slot locked" data-sticker="page-plate">🍽️</div>
```

在其後插入：
```html
    <div class="sticker-slot locked" data-sticker="page-scene">🎨</div>
```

- [ ] **Step 3: 在 navigateTo() 函式加入 scene 的初始化**

找到：
```javascript
  if (pageId === 'page-plate') startPlateGame();
```

在其後插入：
```javascript
  if (pageId === 'page-scene') showSceneShelf();
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: wire scene activity to home, navigation, sticker board"
```

---

## Task 6: Source & Embed Scene Images

**Files:**
- Modify: `kids-companion/index.html` — 在 `#END:IMAGES-FOOD` 之後追加

**方法：** 與動物園/食物相同，Wikipedia thumbnail API（200px）轉 base64。

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#END:IMAGES-FOOD" kids-companion/index.html
```

- [ ] **Step 2: 對 36 個素材抓取圖片**

搜尋詞對應表：
```
scene-sunflower → Helianthus
scene-rose → Rose (flower)
scene-tulip → Tulip
scene-daisy → Bellis perennis
scene-oak_tree → Oak
scene-cherry_blossom → Cherry blossom
scene-rabbit → Rabbit
scene-butterfly → Butterfly
scene-ladybug → Coccinellidae
scene-sparrow → House sparrow
scene-fence → Fence
scene-cottage → Cottage
scene-seashell → Seashell
scene-crab → Crab
scene-starfish → Starfish
scene-tropical_fish → Tropical fish
scene-dolphin → Dolphin
scene-coconut_tree → Coconut
scene-sailboat → Sailboat
scene-lighthouse → Lighthouse
scene-seagull → Gull
scene-coral → Coral reef
scene-jellyfish → Jellyfish
scene-octopus_s → Octopus
scene-pine_tree → Pine
scene-mushroom_s → Mushroom
scene-squirrel → Squirrel
scene-deer → Deer
scene-owl → Owl
scene-log_cabin → Log cabin
scene-stream → Stream
scene-fern → Fern
scene-woodpecker → Woodpecker
scene-hedgehog → Hedgehog
scene-acorn → Acorn
scene-waterfall → Waterfall
```

- [ ] **Step 3: 在 `#END:IMAGES-FOOD` 後插入 IMAGES-SCENE 區塊**

格式：
```javascript
// <!-- #SECTION:IMAGES-SCENE -->
Object.assign(IMG, {
  'scene-sunflower': 'data:image/jpeg;base64,...',
  'scene-rose': 'data:image/jpeg;base64,...',
  // ...
});
// <!-- #END:IMAGES-SCENE -->
```

- [ ] **Step 4: 驗證**

```bash
grep -c "'scene-" kids-companion/index.html
# 預期 30 以上
```

- [ ] **Step 5: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add scene item images (base64 from Wikipedia Commons)"
```

---

## Task 7: Update CLAUDE.md + Push

**Files:**
- Modify: `kids-companion/CLAUDE.md`

- [ ] **Step 1: 在錨點清單加入 scene 活動**

找到 `#SECTION:PAGE-PLATE-JS` 那行之後，插入：

```markdown
| `#SECTION:PAGE-SCENE` | 場景佈置活動 |
| `#SECTION:PAGE-SCENE-DATA` | 場景素材資料 |
| `#SECTION:PAGE-SCENE-JS` | 場景佈置 JS 邏輯 |
| `#SECTION:IMAGES-SCENE` | 場景素材照片（36 張，檔案末尾） |
```

- [ ] **Step 2: Commit + Push**

```bash
git add kids-companion/CLAUDE.md
git commit -m "docs: add scene activity anchors to CLAUDE.md"
git push
```
