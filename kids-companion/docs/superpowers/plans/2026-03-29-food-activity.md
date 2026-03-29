# 食物原型活動 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增「食物原型」活動（`page-food`），讓 2–6 歲兒童瀏覽 6 類共 120 種天然食材，了解名稱與對身體的益處，中大班加入分類測驗。

**Architecture:** 與動物園活動（`page-zoo`）完全相同的三層架構：分類貨架 → 瀏覽卡片 → 測驗（中大班）。所有程式碼加入 `index.html` 單一檔案，圖片 base64 append 到 `#SECTION:IMAGES-FOOD`（檔案末尾）。

**Tech Stack:** 純 HTML/CSS/JS，Web Speech API，Wikipedia thumbnail API（圖片抓取）。

---

## 錨點速查（每個 Task 開始前先 grep 定位，禁止整包讀取）

```bash
grep -n "#SECTION:CSS\|#END:CSS" index.html          # CSS 插入點
grep -n "#SECTION:PAGE-ZOO\b\|#END:PAGE-ZOO\b" index.html   # HTML 參考位置
grep -n "#SECTION:PAGE-ZOO-DATA\|#END:PAGE-ZOO-DATA" index.html
grep -n "#SECTION:PAGE-ZOO-JS\|#END:PAGE-ZOO-JS" index.html
grep -n "page-zoo.*showZooShelf\|page-money" index.html      # navigateTo 插入點
grep -n "data-sticker=\"page-zoo\"" index.html               # sticker 插入點
grep -n "#SECTION:IMAGES-ZOO\|#END:IMAGES-ZOO" index.html   # 圖片插入點
```

---

## Task 1: Food CSS

**Files:**
- Modify: `kids-companion/index.html` — 在 `<!-- #END:CSS -->` 前插入

- [ ] **Step 1: 定位 CSS 插入點**

```bash
grep -n "#END:CSS" kids-companion/index.html
# → 例：1083:/* <!-- #END:CSS --> */
```

- [ ] **Step 2: 在 `/* <!-- #END:CSS --> */` 這行之前插入以下 CSS**

```css
/* Food Activity */
.food-category-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  padding: 16px;
}
.food-category-card {
  background: var(--color-card);
  border-radius: 20px;
  padding: 24px 16px;
  text-align: center;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  transition: transform 0.15s;
  border: 3px solid transparent;
}
.food-category-card:active { transform: scale(0.95); border-color: var(--color-primary); }
.food-category-icon { font-size: 48px; display: block; margin-bottom: 8px; }
.food-category-name { font-size: 20px; font-weight: 700; }
.food-category-count { font-size: 14px; color: var(--color-muted, #aaa); margin-top: 4px; }

.food-browse-card {
  background: var(--color-card);
  border-radius: 24px;
  padding: 20px;
  margin: 0 16px 16px;
  text-align: center;
  box-shadow: 0 4px 16px rgba(0,0,0,0.08);
}
.food-item-photo {
  width: 200px;
  height: 200px;
  object-fit: cover;
  border-radius: 16px;
  display: block;
  margin: 0 auto 16px;
  background: #eee;
}
.food-item-photo-large {
  width: min(280px, 80vw);
  height: min(280px, 80vw);
  object-fit: cover;
  border-radius: 20px;
  display: block;
  margin: 0 auto 16px;
  background: #eee;
}
.food-item-name {
  font-size: 32px;
  font-weight: 800;
  color: var(--color-text);
}
.food-item-name-en {
  font-size: 16px;
  color: var(--color-muted, #aaa);
  margin-top: 2px;
}
.food-item-desc {
  font-size: 18px;
  color: var(--color-text);
  margin-top: 12px;
  line-height: 1.5;
}
.food-item-benefit {
  font-size: 16px;
  color: #5a7a3a;
  margin-top: 8px;
  font-weight: 600;
  background: #f0f7e8;
  border-radius: 12px;
  padding: 8px 14px;
}
.food-item-detail {
  font-size: 16px;
  color: #666;
  margin-top: 8px;
  line-height: 1.6;
  background: #f9f5f0;
  border-radius: 12px;
  padding: 10px 14px;
  text-align: left;
}
.food-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 16px 16px;
}
.food-progress {
  font-size: 16px;
  color: var(--color-muted, #aaa);
  font-weight: 600;
}
.food-quiz-area {
  padding: 16px;
}
.food-quiz-question {
  text-align: center;
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 16px;
}
.food-quiz-choices {
  display: grid;
  gap: 10px;
}
.food-quiz-choices.choices-2 { grid-template-columns: 1fr 1fr; }
.food-quiz-choices.choices-3 { grid-template-columns: 1fr 1fr 1fr; }
.food-quiz-choices.choices-4 { grid-template-columns: 1fr 1fr; }
.food-quiz-btn {
  background: var(--color-card);
  border: 3px solid #eee;
  border-radius: 16px;
  padding: 14px 10px;
  font-size: 18px;
  font-weight: 700;
  font-family: inherit;
  cursor: pointer;
  transition: transform 0.1s, border-color 0.2s, background 0.2s;
}
.food-quiz-btn:active { transform: scale(0.96); }
.food-quiz-btn.correct { border-color: #4CAF50; background: #E8F5E9; }
.food-quiz-btn.wrong { border-color: #F44336; background: #FFEBEE; }
```

- [ ] **Step 3: 驗證插入位置正確**

```bash
grep -n "food-category-grid\|#END:CSS" kids-companion/index.html
# food-category-grid 應出現在 #END:CSS 前面
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: food activity CSS"
```

---

## Task 2: Food HTML Page

**Files:**
- Modify: `kids-companion/index.html` — 在 `<!-- #SECTION:PAGE-ZOO -->` 前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-ZOO\b" kids-companion/index.html
# → 例：1759:<!-- #SECTION:PAGE-ZOO -->
# 新的 food page 插入在此行之前
```

- [ ] **Step 2: 插入 HTML（在 `<!-- #SECTION:PAGE-ZOO -->` 這行之前）**

```html
<!-- #SECTION:PAGE-FOOD -->
<div class="page" id="page-food">
  <div class="game-header">
    <button class="back-btn" id="food-back-btn" onclick="foodBack()">← 返回</button>
    <span class="game-title" id="food-title">🍎 食物原型</span>
    <span class="round-counter" id="food-progress-label"></span>
  </div>
  <button class="praise-btn" onclick="showPraiseOverlay()">👏</button>

  <!-- Category shelf -->
  <div id="food-shelf">
    <div class="food-category-grid" id="food-category-grid"></div>
  </div>

  <!-- Browse mode -->
  <div id="food-browse" style="display:none">
    <div class="food-browse-card" id="food-browse-card"></div>
    <div class="food-nav">
      <button class="btn btn-secondary" id="food-prev-btn" onclick="foodPrev()" style="padding:10px 20px">← 上一個</button>
      <span class="food-progress" id="food-browse-progress"></span>
      <button class="btn btn-primary" id="food-next-btn" onclick="foodNext()" style="padding:10px 20px">下一個 →</button>
    </div>
  </div>

  <!-- Quiz mode -->
  <div id="food-quiz" style="display:none">
    <div class="food-quiz-area" id="food-quiz-area"></div>
  </div>

  <!-- Complete screen -->
  <div class="complete-screen" id="food-complete">
    <div class="complete-content">
      <div style="font-size:80px">🍎</div>
      <h2>飲食小達人！</h2>
      <button class="btn btn-primary" onclick="foodRestart()">再看一次 🔄</button>
      <button class="btn btn-secondary" onclick="foodBackToShelf()">換分類</button>
    </div>
  </div>
</div>
<!-- #END:PAGE-FOOD -->

```

- [ ] **Step 3: 驗證**

```bash
grep -n "#SECTION:PAGE-FOOD\|#END:PAGE-FOOD" kids-companion/index.html
# 應各出現一次
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: food activity HTML page"
```

---

## Task 3: Food Data

**Files:**
- Modify: `kids-companion/index.html` — 在 `// <!-- #SECTION:PAGE-ZOO-DATA -->` 前插入

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-ZOO-DATA" kids-companion/index.html
# → 例：9371:// <!-- #SECTION:PAGE-ZOO-DATA -->
# 在此行之前插入 food data
```

- [ ] **Step 2: 插入以下完整資料（在 `// <!-- #SECTION:PAGE-ZOO-DATA -->` 前）**

```javascript
// <!-- #SECTION:PAGE-FOOD-DATA -->
var FOOD_CATEGORIES = [
  { id: 'veggie',   emoji: '🥦', name: { zh: '蔬菜',   en: 'Vegetables'  } },
  { id: 'fruit',    emoji: '🍎', name: { zh: '水果',   en: 'Fruits'      } },
  { id: 'grain',    emoji: '🍚', name: { zh: '五穀根莖', en: 'Grains'    } },
  { id: 'protein',  emoji: '🥚', name: { zh: '魚肉蛋豆', en: 'Proteins'  } },
  { id: 'dairy',    emoji: '🥛', name: { zh: '奶類',   en: 'Dairy'       } },
  { id: 'nut',      emoji: '🥜', name: { zh: '堅果種子', en: 'Nuts'      } }
];

var FOODS = {
  veggie: [
    { id:'broccoli',         emoji:'🥦', zh:'花椰菜',   en:'Broccoli',           desc:{zh:'花椰菜長得像一棵小樹！',en:'Broccoli looks like a tiny tree!'},                    benefit:{zh:'讓身體更強壯 💪',en:'Makes you strong 💪'} },
    { id:'carrot',           emoji:'🥕', zh:'胡蘿蔔',   en:'Carrot',             desc:{zh:'胡蘿蔔是橘色的，兔子最愛吃！',en:'Orange and crunchy — rabbits love them!'},         benefit:{zh:'讓眼睛更亮 👀',en:'Helps you see better 👀'} },
    { id:'spinach',          emoji:'🌿', zh:'菠菜',     en:'Spinach',            desc:{zh:'菠菜是深綠色的葉菜，很有營養！',en:'Dark green leaves full of nutrition!'},           benefit:{zh:'讓血液更健康 ❤️',en:'Keeps blood healthy ❤️'} },
    { id:'tomato',           emoji:'🍅', zh:'番茄',     en:'Tomato',             desc:{zh:'番茄是紅色的，可以生吃也可以煮！',en:'Red and juicy — eat raw or cooked!'},           benefit:{zh:'保護心臟 ❤️',en:'Protects the heart ❤️'} },
    { id:'eggplant',         emoji:'🍆', zh:'茄子',     en:'Eggplant',           desc:{zh:'茄子是深紫色的，長長的！',en:'Long and deep purple!'},                              benefit:{zh:'保護血管 💜',en:'Protects blood vessels 💜'} },
    { id:'bell_pepper',      emoji:'🫑', zh:'青椒',     en:'Bell Pepper',        desc:{zh:'青椒有各種顏色，紅黃綠都有！',en:'Comes in red, yellow, and green!'},                benefit:{zh:'讓皮膚更漂亮 ✨',en:'Makes skin glow ✨'} },
    { id:'cabbage',          emoji:'🥬', zh:'高麗菜',   en:'Cabbage',            desc:{zh:'高麗菜一層一層包起來，像球一樣！',en:'Layers wrapped like a ball!'},                 benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'cucumber',         emoji:'🥒', zh:'小黃瓜',   en:'Cucumber',           desc:{zh:'小黃瓜清脆多汁，很消暑！',en:'Cool, crisp, and refreshing!'},                       benefit:{zh:'補充水分 💧',en:'Keeps you hydrated 💧'} },
    { id:'onion',            emoji:'🧅', zh:'洋蔥',     en:'Onion',              desc:{zh:'洋蔥切開會讓人流眼淚！',en:'Cutting onions makes you cry!'},                         benefit:{zh:'保護心臟 ❤️',en:'Protects the heart ❤️'} },
    { id:'pumpkin',          emoji:'🎃', zh:'南瓜',     en:'Pumpkin',            desc:{zh:'南瓜是橘黃色的，可以做很多美食！',en:'Orange and sweet — great for cooking!'},        benefit:{zh:'讓眼睛更好 👀',en:'Good for your eyes 👀'} },
    { id:'celery',           emoji:'🌱', zh:'芹菜',     en:'Celery',             desc:{zh:'芹菜有特別的香味，脆脆的！',en:'Crunchy with a unique fragrance!'},                  benefit:{zh:'穩定血壓 💚',en:'Supports healthy blood pressure 💚'} },
    { id:'mushroom',         emoji:'🍄', zh:'蘑菇',     en:'Mushroom',           desc:{zh:'蘑菇不是植物，是菌類！',en:'Mushrooms are fungi, not plants!'},                      benefit:{zh:'增強免疫力 🛡️',en:'Boosts immunity 🛡️'} },
    { id:'bean_sprouts',     emoji:'🌱', zh:'豆芽菜',   en:'Bean Sprouts',       desc:{zh:'豆芽是種子發芽長出來的，脆脆的！',en:'Sprouted seeds — crispy and fresh!'},           benefit:{zh:'補充維他命 🌿',en:'Full of vitamins 🌿'} },
    { id:'garlic',           emoji:'🧄', zh:'大蒜',     en:'Garlic',             desc:{zh:'大蒜味道很強，可以殺菌！',en:'Strong-smelling and germ-fighting!'},                  benefit:{zh:'增強免疫力 🛡️',en:'Fights germs 🛡️'} },
    { id:'ginger',           emoji:'🫚', zh:'薑',       en:'Ginger',             desc:{zh:'薑辣辣的，天冷喝薑湯很暖和！',en:'Spicy and warming — great in soups!'},             benefit:{zh:'讓身體暖和 🔥',en:'Warms the body 🔥'} },
    { id:'leek',             emoji:'🌿', zh:'韭菜',     en:'Chinese Leek',       desc:{zh:'韭菜有特殊香味，常用來包水餃！',en:'Fragrant and great for dumplings!'},              benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'radish',           emoji:'🌰', zh:'白蘿蔔',   en:'White Radish',       desc:{zh:'白蘿蔔白白的，可以煮湯很甜！',en:'White and sweet — wonderful in soups!'},            benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'okra',             emoji:'🫛', zh:'秋葵',     en:'Okra',               desc:{zh:'秋葵黏黏的，切開有星星形狀！',en:'Sticky and star-shaped when sliced!'},              benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'sweet_potato_leaf',emoji:'🌿', zh:'地瓜葉',   en:'Sweet Potato Leaves',desc:{zh:'地瓜葉是台灣常見的健康蔬菜！',en:'A common healthy veggie in Taiwan!'},              benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'corn',             emoji:'🌽', zh:'玉米',     en:'Corn',               desc:{zh:'玉米有很多黃色的小顆粒，甜甜的！',en:'Sweet golden kernels in rows!'},               benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} }
  ],
  fruit: [
    { id:'apple',            emoji:'🍎', zh:'蘋果',     en:'Apple',              desc:{zh:'蘋果紅紅的，甜甜脆脆！',en:'Red, sweet, and crunchy!'},                            benefit:{zh:'讓腸子健康 🌿',en:'Keeps tummy healthy 🌿'} },
    { id:'banana',           emoji:'🍌', zh:'香蕉',     en:'Banana',             desc:{zh:'香蕉彎彎的，剝開就能吃！',en:'Peel and eat — no washing needed!'},                  benefit:{zh:'補充能量 ⚡',en:'Quick energy boost ⚡'} },
    { id:'mango',            emoji:'🥭', zh:'芒果',     en:'Mango',              desc:{zh:'芒果是台灣夏天的水果之王！',en:'The king of summer fruits in Taiwan!'},             benefit:{zh:'讓皮膚更漂亮 ✨',en:'Makes skin glow ✨'} },
    { id:'papaya',           emoji:'🍈', zh:'木瓜',     en:'Papaya',             desc:{zh:'木瓜橘黃色，甜甜軟軟的！',en:'Soft, sweet, and orange inside!'},                    benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'pineapple',        emoji:'🍍', zh:'鳳梨',     en:'Pineapple',          desc:{zh:'鳳梨酸甜多汁，頭上有頂王冠！',en:'Sweet and tangy with a leafy crown!'},             benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'grapes',           emoji:'🍇', zh:'葡萄',     en:'Grapes',             desc:{zh:'葡萄一串一串，有紫色也有綠色！',en:'Bunches of purple or green jewels!'},             benefit:{zh:'保護心臟 ❤️',en:'Protects the heart ❤️'} },
    { id:'watermelon',       emoji:'🍉', zh:'西瓜',     en:'Watermelon',         desc:{zh:'西瓜大大的，紅色果肉很消暑！',en:'Big and red inside — super refreshing!'},         benefit:{zh:'補充水分 💧',en:'Keeps you hydrated 💧'} },
    { id:'orange',           emoji:'🍊', zh:'橘子',     en:'Orange',             desc:{zh:'橘子一瓣一瓣的，酸甜多汁！',en:'Juicy segments — sweet and tangy!'},                benefit:{zh:'增強免疫力 🛡️',en:'Boosts immunity 🛡️'} },
    { id:'strawberry',       emoji:'🍓', zh:'草莓',     en:'Strawberry',         desc:{zh:'草莓紅紅的，上面有小小的種子！',en:'Red with tiny seeds on the outside!'},           benefit:{zh:'讓皮膚更漂亮 ✨',en:'Makes skin glow ✨'} },
    { id:'kiwi',             emoji:'🥝', zh:'奇異果',   en:'Kiwi',               desc:{zh:'奇異果綠色果肉，裡面有小黑點！',en:'Green inside with tiny black seeds!'},           benefit:{zh:'增強免疫力 🛡️',en:'Boosts immunity 🛡️'} },
    { id:'wax_apple',        emoji:'🍒', zh:'蓮霧',     en:'Wax Apple',          desc:{zh:'蓮霧是台灣特有水果，脆脆甜甜！',en:'A Taiwan treasure — crisp and sweet!'},          benefit:{zh:'補充水分 💧',en:'Keeps you hydrated 💧'} },
    { id:'guava',            emoji:'🍐', zh:'芭樂',     en:'Guava',              desc:{zh:'芭樂是台灣最常見的水果！',en:'The most popular fruit in Taiwan!'},                  benefit:{zh:'增強免疫力 🛡️',en:'Boosts immunity 🛡️'} },
    { id:'pear',             emoji:'🍐', zh:'梨子',     en:'Pear',               desc:{zh:'梨子水分很多，甜甜脆脆！',en:'Juicy, sweet, and crispy!'},                          benefit:{zh:'補充水分 💧',en:'Keeps you hydrated 💧'} },
    { id:'peach',            emoji:'🍑', zh:'水蜜桃',   en:'Peach',              desc:{zh:'水蜜桃軟軟甜甜，果汁很多！',en:'Soft, sweet, and full of juice!'},                   benefit:{zh:'讓皮膚更漂亮 ✨',en:'Makes skin glow ✨'} },
    { id:'cantaloupe',       emoji:'🍈', zh:'哈密瓜',   en:'Cantaloupe',         desc:{zh:'哈密瓜甜甜的，有特別的香味！',en:'Sweet with a wonderful fragrance!'},               benefit:{zh:'讓眼睛更好 👀',en:'Good for your eyes 👀'} },
    { id:'dragon_fruit',     emoji:'🐉', zh:'火龍果',   en:'Dragon Fruit',       desc:{zh:'火龍果外表鮮豔，果肉有芝麻點點！',en:'Bright outside, dotted inside!'},              benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'tangerine',        emoji:'🍊', zh:'柳橙',     en:'Tangerine',          desc:{zh:'柳橙比橘子大，果汁很豐富！',en:'Bigger than an orange — super juicy!'},             benefit:{zh:'增強免疫力 🛡️',en:'Boosts immunity 🛡️'} },
    { id:'blueberry',        emoji:'🫐', zh:'藍莓',     en:'Blueberry',          desc:{zh:'藍莓小小的，甜甜酸酸！',en:'Tiny, sweet, and slightly tart!'},                      benefit:{zh:'讓眼睛更好 👀',en:'Good for your eyes 👀'} },
    { id:'persimmon',        emoji:'🍊', zh:'柿子',     en:'Persimmon',          desc:{zh:'柿子橘紅色，熟了甜得像蜜！',en:'Sweet as honey when ripe!'},                        benefit:{zh:'保護心臟 ❤️',en:'Protects the heart ❤️'} },
    { id:'lychee',           emoji:'🍒', zh:'荔枝',     en:'Lychee',             desc:{zh:'荔枝是台灣夏天名產，甜如蜜！',en:'Sweet as honey — a Taiwan summer gem!'},           benefit:{zh:'補充能量 ⚡',en:'Quick energy boost ⚡'} }
  ],
  grain: [
    { id:'white_rice',       emoji:'🍚', zh:'白米飯',   en:'White Rice',         desc:{zh:'白米飯是台灣人天天吃的主食！',en:'The everyday staple of Taiwan!'},                 benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'brown_rice',       emoji:'🌾', zh:'糙米',     en:'Brown Rice',         desc:{zh:'糙米比白米顏色深，更有營養！',en:'Darker than white rice and more nutritious!'},    benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'sweet_potato',     emoji:'🍠', zh:'地瓜',     en:'Sweet Potato',       desc:{zh:'地瓜甜甜的，烤地瓜香噴噴！',en:'Sweet and fragrant when roasted!'},                 benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'potato',           emoji:'🥔', zh:'馬鈴薯',   en:'Potato',             desc:{zh:'馬鈴薯可以做薯條、炒菜、煮湯！',en:'So versatile — fries, stir-fry, or soup!'},     benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'taro',             emoji:'🌰', zh:'芋頭',     en:'Taro',               desc:{zh:'芋頭紫色的，可以做芋圓、芋泥！',en:'Purple and perfect for taro balls!'},            benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'oats',             emoji:'🌾', zh:'燕麥',     en:'Oats',               desc:{zh:'燕麥做成的粥又香又健康！',en:'Warm, filling, and healthy in porridge!'},            benefit:{zh:'幫助消化 🌿',en:'Helps digestion 🌿'} },
    { id:'toast',            emoji:'🍞', zh:'吐司',     en:'Toast',              desc:{zh:'吐司是用小麥做的，烤一烤很脆！',en:'Made from wheat — crispy when toasted!'},        benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'steamed_bun',      emoji:'🥟', zh:'饅頭',     en:'Steamed Bun',        desc:{zh:'饅頭軟軟的，用小麥麵粉蒸出來！',en:'Soft and fluffy — steamed from wheat flour!'},  benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'rice_noodles',     emoji:'🍜', zh:'米粉',     en:'Rice Noodles',       desc:{zh:'米粉是用米做的細細的麵條！',en:'Thin noodles made from rice!'},                    benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'noodles',          emoji:'🍝', zh:'麵條',     en:'Noodles',            desc:{zh:'麵條長長的，煮湯炒菜都好吃！',en:'Long and delicious in soup or stir-fried!'},       benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'red_bean',         emoji:'🫘', zh:'紅豆',     en:'Red Bean',           desc:{zh:'紅豆甜甜的，可以做紅豆湯、紅豆麵包！',en:'Sweet — great in soup or bread!'},       benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'mung_bean',        emoji:'🫘', zh:'綠豆',     en:'Mung Bean',          desc:{zh:'綠豆可以做綠豆湯，夏天喝很消暑！',en:'Cool green bean soup for hot days!'},          benefit:{zh:'清涼消暑 🌊',en:'Cools you down 🌊'} },
    { id:'black_bean',       emoji:'🫘', zh:'黑豆',     en:'Black Bean',         desc:{zh:'黑豆是黑色的豆子，很有營養！',en:'Black and full of nutrition!'},                   benefit:{zh:'讓頭髮更黑亮 🖤',en:'Good for hair 🖤'} },
    { id:'barley',           emoji:'🌾', zh:'薏仁',     en:'Barley',             desc:{zh:'薏仁可以煮成甜湯，軟軟的！',en:'Soft and chewy in sweet soup!'},                    benefit:{zh:'讓皮膚更漂亮 ✨',en:'Makes skin glow ✨'} },
    { id:'lotus_seed',       emoji:'🌸', zh:'蓮子',     en:'Lotus Seed',         desc:{zh:'蓮子白白的，可以煮甜湯！',en:'White and tender — perfect in sweet soup!'},          benefit:{zh:'讓心情平靜 😌',en:'Calms the mind 😌'} },
    { id:'chestnut',         emoji:'🌰', zh:'栗子',     en:'Chestnut',           desc:{zh:'栗子烤熟了香噴噴，甜甜的！',en:'Sweet and fragrant when roasted!'},                 benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'yam',              emoji:'🍠', zh:'山藥',     en:'Yam',                desc:{zh:'山藥白白的，黏黏的，很滋補！',en:'White, slightly sticky, and nourishing!'},         benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'millet',           emoji:'🌾', zh:'小米',     en:'Millet',             desc:{zh:'小米小小的，可以煮成小米粥！',en:'Tiny grains perfect for porridge!'},               benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'sorghum',          emoji:'🌾', zh:'高粱',     en:'Sorghum',            desc:{zh:'高粱是台灣金門的特產，可以釀酒！',en:'Famous in Kinmen — used to make wine!'},       benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'quinoa',           emoji:'🌾', zh:'藜麥',     en:'Quinoa',             desc:{zh:'藜麥有很多蛋白質，是超級食物！',en:'A superfood packed with protein!'},             benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} }
  ],
  protein: [
    { id:'egg',              emoji:'🥚', zh:'雞蛋',     en:'Egg',                desc:{zh:'雞蛋可以做很多料理，水煮蛋、荷包蛋！',en:'Boil it, fry it — so many ways to cook!'},  benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'salmon',           emoji:'🐟', zh:'鮭魚',     en:'Salmon',             desc:{zh:'鮭魚是橘紅色的，很多小朋友都喜歡！',en:'Orange and delicious — kids love it!'},       benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'chicken',          emoji:'🍗', zh:'雞肉',     en:'Chicken',            desc:{zh:'雞肉嫩嫩的，可以烤可以煮！',en:'Tender and versatile — roast or boil!'},             benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'pork',             emoji:'🥩', zh:'豬肉',     en:'Pork',               desc:{zh:'豬肉是台灣最常吃的肉類！',en:'The most popular meat in Taiwan!'},                   benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'beef',             emoji:'🥩', zh:'牛肉',     en:'Beef',               desc:{zh:'牛肉有很多鐵質，可以補血！',en:'Full of iron — great for energy!'},                  benefit:{zh:'讓血液更健康 ❤️',en:'Keeps blood healthy ❤️'} },
    { id:'tofu',             emoji:'🫙', zh:'豆腐',     en:'Tofu',               desc:{zh:'豆腐白白軟軟的，是用黃豆做的！',en:'Soft and white — made from soybeans!'},          benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'edamame',          emoji:'🫛', zh:'毛豆',     en:'Edamame',            desc:{zh:'毛豆是綠色的豆子，又甜又脆！',en:'Green, sweet, and crunchy!'},                      benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'mackerel',         emoji:'🐟', zh:'鯖魚',     en:'Mackerel',           desc:{zh:'鯖魚很新鮮，是台灣常吃的魚！',en:'Fresh and popular in Taiwan!'},                   benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'shrimp',           emoji:'🍤', zh:'蝦',       en:'Shrimp',             desc:{zh:'蝦子彎彎的，煮熟了變橘紅色！',en:'Curls up and turns orange when cooked!'},          benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'squid',            emoji:'🦑', zh:'花枝',     en:'Squid',              desc:{zh:'花枝有長長的觸手，可以做鹽酥花枝！',en:'Has long tentacles — great fried!'},         benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'clam',             emoji:'🦪', zh:'蛤蜊',     en:'Clam',               desc:{zh:'蛤蜊有殼，煮湯鮮甜無比！',en:'Has a shell and makes the sweetest soup!'},           benefit:{zh:'讓血液更健康 ❤️',en:'Keeps blood healthy ❤️'} },
    { id:'tilapia',          emoji:'🐟', zh:'鯛魚',     en:'Tilapia',            desc:{zh:'鯛魚肉嫩刺少，很適合小朋友！',en:'Tender with few bones — great for kids!'},        benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'tuna',             emoji:'🐟', zh:'鮪魚',     en:'Tuna',               desc:{zh:'鮪魚可以做成罐頭，很方便！',en:'Great in cans — easy and delicious!'},              benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'duck_egg',         emoji:'🥚', zh:'鴨蛋',     en:'Duck Egg',           desc:{zh:'鴨蛋比雞蛋大一點，可以做皮蛋！',en:'Bigger than chicken eggs — great pickled!'},     benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'sea_bass',         emoji:'🐟', zh:'鱸魚',     en:'Sea Bass',           desc:{zh:'鱸魚肉很嫩，媽媽最愛煮清蒸鱸魚！',en:'Delicate — perfect for steaming!'},           benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'saury',            emoji:'🐟', zh:'秋刀魚',   en:'Pacific Saury',      desc:{zh:'秋刀魚長長的，烤著吃很香！',en:'Long and slim — delicious when grilled!'},          benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'octopus',          emoji:'🐙', zh:'章魚',     en:'Octopus',            desc:{zh:'章魚有八條腿，很厲害！',en:'Eight arms — amazing and delicious!'},                  benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'soy_milk',         emoji:'🥛', zh:'豆漿',     en:'Soy Milk',           desc:{zh:'豆漿是黃豆磨成的，台灣早餐必備！',en:'Made from soybeans — Taiwan breakfast staple!'},benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'natto',            emoji:'🫙', zh:'納豆',     en:'Natto',              desc:{zh:'納豆黏黏的，味道特別但很健康！',en:'Sticky and strong-smelling but very healthy!'},  benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'pork_tenderloin',  emoji:'🥩', zh:'豬里肌',   en:'Pork Tenderloin',    desc:{zh:'豬里肌是最嫩的豬肉，很多人最愛！',en:'The most tender cut of pork!'},               benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} }
  ],
  dairy: [
    { id:'milk',             emoji:'🥛', zh:'牛奶',     en:'Milk',               desc:{zh:'牛奶白白的，每天喝一杯長得高！',en:'White and creamy — drink daily to grow!'},       benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'cheese',           emoji:'🧀', zh:'起司',     en:'Cheese',             desc:{zh:'起司是牛奶做的，有很多種口味！',en:'Made from milk — so many flavors!'},             benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'yogurt',           emoji:'🥛', zh:'優格',     en:'Yogurt',             desc:{zh:'優格酸酸甜甜的，加水果更好吃！',en:'Creamy and tangy — great with fruit!'},          benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'goat_milk',        emoji:'🐐', zh:'羊奶',     en:'Goat Milk',          desc:{zh:'羊奶是山羊產的奶，比牛奶更好消化！',en:'From goats — easier to digest than cow milk!'},benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'butter',           emoji:'🧈', zh:'奶油',     en:'Butter',             desc:{zh:'奶油是用牛奶做的，麵包塗上去很香！',en:'Spread on bread for a delicious treat!'},     benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'whipping_cream',   emoji:'🥛', zh:'鮮奶油',   en:'Whipping Cream',     desc:{zh:'鮮奶油打發後可以擠在蛋糕上！',en:'Whipped into fluffy cream for cakes!'},           benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'cottage_cheese',   emoji:'🧀', zh:'茅屋起司', en:'Cottage Cheese',     desc:{zh:'茅屋起司白白的，顆粒狀，很清爽！',en:'White and lumpy — light and fresh!'},          benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'cheddar',          emoji:'🧀', zh:'切達起司', en:'Cheddar Cheese',     desc:{zh:'切達起司橘黃色，香味濃郁！',en:'Orange and full-flavored!'},                        benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'uht_milk',         emoji:'🥛', zh:'保久乳',   en:'UHT Milk',           desc:{zh:'保久乳不需要冰，可以放很久！',en:'No fridge needed — lasts a long time!'},           benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'condensed_milk',   emoji:'🥛', zh:'煉乳',     en:'Condensed Milk',     desc:{zh:'煉乳甜甜濃濃的，淋在草莓上很好吃！',en:'Sweet and thick — drizzle on strawberries!'},  benefit:{zh:'提供能量 ⚡',en:'Gives you energy ⚡'} }
  ],
  nut: [
    { id:'peanut',           emoji:'🥜', zh:'花生',     en:'Peanut',             desc:{zh:'花生是台灣最常見的堅果，可以做花生醬！',en:'The most popular nut in Taiwan — makes great butter!'},benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'cashew',           emoji:'🥜', zh:'腰果',     en:'Cashew',             desc:{zh:'腰果彎彎的，香香脆脆！',en:'Curved and crunchy with a buttery flavor!'},            benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'walnut',           emoji:'🌰', zh:'核桃',     en:'Walnut',             desc:{zh:'核桃長得像小腦袋，對大腦很好！',en:'Looks like a tiny brain — great for yours!'},      benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'almond',           emoji:'🥜', zh:'杏仁',     en:'Almond',             desc:{zh:'杏仁細長，可以做杏仁豆腐、杏仁茶！',en:'Long and thin — great in almond tofu!'},       benefit:{zh:'讓皮膚更漂亮 ✨',en:'Makes skin glow ✨'} },
    { id:'white_sesame',     emoji:'🌾', zh:'白芝麻',   en:'White Sesame',       desc:{zh:'白芝麻小小的，撒在飯糰上！',en:'Tiny and white — sprinkled on rice balls!'},          benefit:{zh:'讓骨頭更強壯 🦴',en:'Strengthens bones 🦴'} },
    { id:'black_sesame',     emoji:'🖤', zh:'黑芝麻',   en:'Black Sesame',       desc:{zh:'黑芝麻可以做黑芝麻湯圓，香噴噴！',en:'Black and fragrant — great in mochi!'},          benefit:{zh:'讓頭髮更黑亮 🖤',en:'Good for hair 🖤'} },
    { id:'pumpkin_seed',     emoji:'🌰', zh:'南瓜子',   en:'Pumpkin Seed',       desc:{zh:'南瓜子是南瓜的種子，扁扁的！',en:'Flat seeds from inside a pumpkin!'},               benefit:{zh:'增強免疫力 🛡️',en:'Boosts immunity 🛡️'} },
    { id:'sunflower_seed',   emoji:'🌻', zh:'葵瓜子',   en:'Sunflower Seed',     desc:{zh:'葵瓜子是向日葵的種子，嗑起來很過癮！',en:'Seeds from sunflowers — fun to crack open!'},  benefit:{zh:'讓心情更好 😊',en:'Lifts your mood 😊'} },
    { id:'pistachio',        emoji:'🥜', zh:'開心果',   en:'Pistachio',          desc:{zh:'開心果殼裂開一點，像在笑！',en:'Shell cracks open like a smile!'},                   benefit:{zh:'讓心情更好 😊',en:'Lifts your mood 😊'} },
    { id:'pine_nut',         emoji:'🌰', zh:'松子',     en:'Pine Nut',           desc:{zh:'松子小小的，是松樹的種子！',en:'Tiny seeds from pine trees!'},                       benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'macadamia',        emoji:'🥜', zh:'夏威夷果', en:'Macadamia',          desc:{zh:'夏威夷果圓圓的，是最貴的堅果！',en:'Round and buttery — the most expensive nut!'},    benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'hazelnut',         emoji:'🌰', zh:'榛果',     en:'Hazelnut',           desc:{zh:'榛果是咖啡和巧克力的好朋友！',en:'Best friends with coffee and chocolate!'},          benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'flaxseed',         emoji:'🌾', zh:'亞麻籽',   en:'Flaxseed',           desc:{zh:'亞麻籽小小的，可以加在優格裡！',en:'Tiny seeds — great mixed into yogurt!'},          benefit:{zh:'護腸胃 💚',en:'Protects the stomach 💚'} },
    { id:'chia_seed',        emoji:'🌾', zh:'奇亞籽',   en:'Chia Seed',          desc:{zh:'奇亞籽泡水會變成果凍狀，很神奇！',en:'Turn gel-like in water — like magic!'},          benefit:{zh:'補充能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'red_date',         emoji:'🍒', zh:'紅棗',     en:'Red Date',           desc:{zh:'紅棗紅紅甜甜，可以煮湯也可以直接吃！',en:'Red, sweet — eat fresh or in soup!'},        benefit:{zh:'補充能量 ⚡',en:'Gives you energy ⚡'} },
    { id:'goji_berry',       emoji:'🍒', zh:'枸杞',     en:'Goji Berry',         desc:{zh:'枸杞紅紅的小顆粒，泡茶很補！',en:'Tiny red berries — great in herbal tea!'},          benefit:{zh:'讓眼睛更亮 👀',en:'Helps you see better 👀'} },
    { id:'lotus_nut',        emoji:'🌸', zh:'花生仁',   en:'Peanut Kernel',      desc:{zh:'花生仁去殼後白白的，香香的！',en:'The creamy kernel inside a peanut!'},               benefit:{zh:'讓身體更強壯 💪',en:'Builds strength 💪'} },
    { id:'pecan',            emoji:'🌰', zh:'碧根果',   en:'Pecan',              desc:{zh:'碧根果長長的，比核桃更甜！',en:'Long and sweeter than walnuts!'},                    benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} },
    { id:'brazil_nut',       emoji:'🌰', zh:'巴西堅果', en:'Brazil Nut',         desc:{zh:'巴西堅果是最大的堅果，一天吃一顆就夠！',en:'The biggest nut — one a day is enough!'},  benefit:{zh:'增強免疫力 🛡️',en:'Boosts immunity 🛡️'} },
    { id:'hemp_seed',        emoji:'🌾', zh:'大麻籽',   en:'Hemp Seed',          desc:{zh:'大麻籽小小的，營養非常豐富！',en:'Tiny seeds packed with nutrition!'},               benefit:{zh:'讓大腦更聰明 🧠',en:'Makes the brain smarter 🧠'} }
  ]
};
// <!-- #END:PAGE-FOOD-DATA -->

```

- [ ] **Step 3: 驗證**

```bash
grep -n "#SECTION:PAGE-FOOD-DATA\|#END:PAGE-FOOD-DATA" kids-companion/index.html
grep -n "FOOD_CATEGORIES\|var FOODS" kids-companion/index.html
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: food data (6 categories, 110 items)"
```

---

## Task 4: Food JS Logic

**Files:**
- Modify: `kids-companion/index.html` — 在 `// <!-- #SECTION:PAGE-ZOO-JS -->` 前插入

**關鍵差異（與 zoo JS 不同之處）：**
- `foodState` 多一個 `quizType` 欄位
- toddler/small 測驗：「這是什麼食物？」→ 同分類其他食物作干擾選項
- middle/large 測驗：「這是哪一類食物？」→ 6 個分類名稱作選項
- 卡片顯示多一個 `.food-item-benefit`（所有年齡都顯示）

- [ ] **Step 1: 定位插入點**

```bash
grep -n "#SECTION:PAGE-ZOO-JS\b" kids-companion/index.html
# 在此行之前插入
```

- [ ] **Step 2: 插入以下 JS（在 `// <!-- #SECTION:PAGE-ZOO-JS -->` 前）**

```javascript
// <!-- #SECTION:PAGE-FOOD-JS -->
var foodState = {
  currentCategory: null,
  currentIdx: 0,
  quizPending: false,
  quizActive: false
};

function showFoodShelf() {
  foodState.currentCategory = null;
  foodState.currentIdx = 0;
  var shelf = document.getElementById('food-shelf');
  var browse = document.getElementById('food-browse');
  var quiz = document.getElementById('food-quiz');
  var complete = document.getElementById('food-complete');
  if (shelf) shelf.style.display = '';
  if (browse) browse.style.display = 'none';
  if (quiz) quiz.style.display = 'none';
  if (complete) complete.classList.remove('show');
  document.getElementById('food-title').textContent = '🍎 食物原型';
  document.getElementById('food-progress-label').textContent = '';
  document.getElementById('food-back-btn').onclick = function() { navigateTo('page-home'); };
  renderFoodShelf();
}

function renderFoodShelf() {
  var grid = document.getElementById('food-category-grid');
  if (!grid) return;
  var lang = APP.language || 'zh';
  var html = '';
  FOOD_CATEGORIES.forEach(function(cat) {
    var count = (FOODS[cat.id] || []).length;
    html += '<div class="food-category-card" onclick="openFoodCategory(\'' + cat.id + '\')">';
    html += '<span class="food-category-icon">' + cat.emoji + '</span>';
    html += '<div class="food-category-name">' + cat.name[lang] + '</div>';
    html += '<div class="food-category-count">' + count + ' 種食物</div>';
    html += '</div>';
  });
  grid.innerHTML = html;
}

function foodBack() {
  if (foodState.currentCategory) {
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    showFoodShelf();
  } else {
    navigateTo('page-home');
  }
}

function foodBackToShelf() {
  if ('speechSynthesis' in window) speechSynthesis.cancel();
  var complete = document.getElementById('food-complete');
  if (complete) complete.classList.remove('show');
  showFoodShelf();
}

function foodRestart() {
  var complete = document.getElementById('food-complete');
  if (complete) complete.classList.remove('show');
  foodState.currentIdx = 0;
  foodState.quizPending = false;
  foodState.quizActive = false;
  showFoodBrowse();
}

function openFoodCategory(catId) {
  var cat = null;
  for (var i = 0; i < FOOD_CATEGORIES.length; i++) {
    if (FOOD_CATEGORIES[i].id === catId) { cat = FOOD_CATEGORIES[i]; break; }
  }
  if (!cat) return;
  foodState.currentCategory = catId;
  foodState.currentIdx = 0;
  foodState.quizPending = false;
  foodState.quizActive = false;

  var lang = APP.language || 'zh';
  document.getElementById('food-title').textContent = cat.emoji + ' ' + cat.name[lang];
  document.getElementById('food-back-btn').onclick = function() { showFoodShelf(); };

  var shelf = document.getElementById('food-shelf');
  if (shelf) shelf.style.display = 'none';
  showFoodBrowse();
}

function showFoodBrowse() {
  var browse = document.getElementById('food-browse');
  var quiz = document.getElementById('food-quiz');
  if (browse) browse.style.display = '';
  if (quiz) quiz.style.display = 'none';
  foodState.quizActive = false;
  renderFoodCard();
}

function renderFoodCard() {
  var foods = FOODS[foodState.currentCategory] || [];
  var idx = foodState.currentIdx;
  var food = foods[idx];
  if (!food) return;

  var lang = APP.language || 'zh';
  var ag = APP.ageGroup;
  var isSmall = (ag === 'toddler' || ag === 'small');
  var isLarge = (ag === 'large');

  var total = foods.length;
  document.getElementById('food-progress-label').textContent = (idx + 1) + '/' + total;
  document.getElementById('food-browse-progress').textContent = (idx + 1) + ' / ' + total;

  var prevBtn = document.getElementById('food-prev-btn');
  var nextBtn = document.getElementById('food-next-btn');
  if (prevBtn) prevBtn.style.display = idx === 0 ? 'none' : '';
  if (nextBtn) nextBtn.textContent = idx === total - 1 ? '完成 ✓' : '下一個 →';

  var imgSrc = (typeof IMG !== 'undefined' && IMG['food-' + food.id]) ? IMG['food-' + food.id] : '';
  var photoClass = isSmall ? 'food-item-photo-large' : 'food-item-photo';
  var html = '';

  if (imgSrc) {
    html += '<img src="' + imgSrc + '" class="' + photoClass + '" alt="' + food[lang] + '" onclick="foodSpeak()" style="cursor:pointer">';
  } else {
    html += '<div class="' + photoClass + '" onclick="foodSpeak()" style="display:flex;align-items:center;justify-content:center;background:#f0ebe3;cursor:pointer;font-size:80px">' + food.emoji + '</div>';
  }

  html += '<div class="food-item-name" onclick="foodSpeak()" style="cursor:pointer">' + food[lang] + '</div>';

  if (!isSmall) {
    html += '<div class="food-item-name-en">' + food.en + '</div>';
  }

  if (!isSmall && food.desc) {
    html += '<div class="food-item-desc">' + food.desc[lang] + '</div>';
  }

  if (food.benefit) {
    html += '<div class="food-item-benefit">' + food.benefit[lang] + '</div>';
  }

  if (isLarge && food.desc) {
    html += '<div class="food-item-detail">' + food.desc[lang] + '</div>';
  }

  document.getElementById('food-browse-card').innerHTML = html;

  if (isSmall) {
    setTimeout(function() { foodSpeak(); }, 400);
  }
}

function foodSpeak() {
  var foods = FOODS[foodState.currentCategory] || [];
  var food = foods[foodState.currentIdx];
  if (!food) return;
  var lang = APP.language || 'zh';
  var ag = APP.ageGroup;
  var isSmall = (ag === 'toddler' || ag === 'small');
  var text = food[lang];
  if (!isSmall && food.desc) text += '。' + food.desc[lang];
  if ('speechSynthesis' in window) {
    speechSynthesis.cancel();
    var u = new SpeechSynthesisUtterance(text);
    u.lang = lang === 'zh' ? 'zh-TW' : 'en-US';
    u.rate = 0.85; u.pitch = 1.2;
    speechSynthesis.speak(u);
  }
}

function foodPrev() {
  if (foodState.currentIdx > 0) {
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    foodState.currentIdx--;
    renderFoodCard();
  }
}

function foodNext() {
  var foods = FOODS[foodState.currentCategory] || [];
  var ag = APP.ageGroup;
  var isSmall = (ag === 'toddler' || ag === 'small');
  if ('speechSynthesis' in window) speechSynthesis.cancel();

  var nextIdx = foodState.currentIdx + 1;
  var shouldQuiz = !isSmall && nextIdx % 5 === 0 && nextIdx < foods.length;

  if (nextIdx >= foods.length) {
    if (!isSmall && !foodState.quizPending) {
      foodState.quizPending = true;
      startFoodQuiz();
    } else {
      showFoodComplete();
    }
  } else if (shouldQuiz) {
    foodState.currentIdx = nextIdx;
    foodState.quizPending = true;
    startFoodQuiz();
  } else {
    foodState.currentIdx = nextIdx;
    renderFoodCard();
  }
}

function startFoodQuiz() {
  var browse = document.getElementById('food-browse');
  var quiz = document.getElementById('food-quiz');
  if (browse) browse.style.display = 'none';
  if (quiz) quiz.style.display = '';
  foodState.quizActive = true;

  var foods = FOODS[foodState.currentCategory] || [];
  var ag = APP.ageGroup;
  var isSmall = (ag === 'toddler' || ag === 'small');
  var isMiddle = (ag === 'middle');
  var isLarge = (ag === 'large');
  var lang = APP.language || 'zh';

  var qIdx = foodState.currentIdx - 1;
  if (qIdx < 0) qIdx = 0;
  var qFood = foods[qIdx];

  var imgSrc = (typeof IMG !== 'undefined' && IMG['food-' + qFood.id]) ? IMG['food-' + qFood.id] : '';
  var html = '';

  if (isSmall) {
    // toddler/small: "這是什麼食物？" — choices are food names from same category
    var numChoices = (ag === 'toddler') ? 2 : 3;
    html += '<div class="food-quiz-question">' + (lang === 'zh' ? '這是什麼食物？' : 'What food is this?') + '</div>';
    if (imgSrc) {
      html += '<div style="text-align:center;margin-bottom:16px"><img src="' + imgSrc + '" style="width:min(200px,60vw);height:min(200px,60vw);object-fit:cover;border-radius:16px" alt="?"></div>';
    } else {
      html += '<div style="text-align:center;font-size:80px;margin-bottom:16px">' + qFood.emoji + '</div>';
    }
    var pool = foods.filter(function(f) { return f.id !== qFood.id; });
    var shuffled = pool.slice().sort(function() { return Math.random() - 0.5; });
    var choices = [qFood].concat(shuffled.slice(0, numChoices - 1)).sort(function() { return Math.random() - 0.5; });
    html += '<div class="food-quiz-choices choices-' + numChoices + '">';
    choices.forEach(function(c) {
      html += '<button class="food-quiz-btn" onclick="foodQuizAnswer(this,' + (c.id === qFood.id) + ',\'' + qFood.id + '\',\'name\')">' + c[lang] + '</button>';
    });
    html += '</div>';

    if ('speechSynthesis' in window) {
      speechSynthesis.cancel();
      var u = new SpeechSynthesisUtterance(lang === 'zh' ? '這是什麼食物？' : 'What food is this?');
      u.lang = lang === 'zh' ? 'zh-TW' : 'en-US'; u.rate = 0.85; u.pitch = 1.2;
      speechSynthesis.speak(u);
    }
  } else {
    // middle/large: "這是哪一類食物？" — choices are category names
    var numCatChoices = isMiddle ? 3 : 4;
    html += '<div class="food-quiz-question">' + (lang === 'zh' ? '這是哪一類食物？' : 'Which food group is this?') + '</div>';
    if (imgSrc) {
      html += '<div style="text-align:center;margin-bottom:16px"><img src="' + imgSrc + '" style="width:min(200px,60vw);height:min(200px,60vw);object-fit:cover;border-radius:16px" alt="?"></div>';
    } else {
      html += '<div style="text-align:center;font-size:80px;margin-bottom:16px">' + qFood.emoji + '</div>';
    }
    var correctCat = null;
    for (var i = 0; i < FOOD_CATEGORIES.length; i++) {
      if (FOOD_CATEGORIES[i].id === foodState.currentCategory) { correctCat = FOOD_CATEGORIES[i]; break; }
    }
    var wrongCats = FOOD_CATEGORIES.filter(function(c) { return c.id !== foodState.currentCategory; });
    var shuffledWrong = wrongCats.slice().sort(function() { return Math.random() - 0.5; });
    var catChoices = [correctCat].concat(shuffledWrong.slice(0, numCatChoices - 1)).sort(function() { return Math.random() - 0.5; });
    html += '<div class="food-quiz-choices choices-' + numCatChoices + '">';
    catChoices.forEach(function(c) {
      html += '<button class="food-quiz-btn" onclick="foodQuizAnswer(this,' + (c.id === foodState.currentCategory) + ',\'' + foodState.currentCategory + '\',\'category\')">' + c.emoji + ' ' + c.name[lang] + '</button>';
    });
    html += '</div>';

    if (!isLarge && 'speechSynthesis' in window) {
      speechSynthesis.cancel();
      var u2 = new SpeechSynthesisUtterance(lang === 'zh' ? '這是哪一類食物？' : 'Which food group is this?');
      u2.lang = lang === 'zh' ? 'zh-TW' : 'en-US'; u2.rate = 0.85; u2.pitch = 1.2;
      speechSynthesis.speak(u2);
    }
  }

  document.getElementById('food-quiz-area').innerHTML = html;
}

function foodQuizAnswer(btn, isCorrect, correctId, quizType) {
  var area = document.getElementById('food-quiz-area');
  var btns = area.querySelectorAll('.food-quiz-btn');
  btns.forEach(function(b) { b.disabled = true; });

  var lang = APP.language || 'zh';

  if (isCorrect) {
    btn.classList.add('correct');
    playCorrectSound();
    var msg = '';
    if (quizType === 'category') {
      var correctCat = null;
      for (var i = 0; i < FOOD_CATEGORIES.length; i++) {
        if (FOOD_CATEGORIES[i].id === correctId) { correctCat = FOOD_CATEGORIES[i]; break; }
      }
      msg = lang === 'zh' ? '答對了！是' + (correctCat ? correctCat.name.zh : '') + '！' : 'Correct! It\'s ' + (correctCat ? correctCat.name.en : '') + '!';
    } else {
      var foods = FOODS[foodState.currentCategory] || [];
      var correctFood = null;
      for (var j = 0; j < foods.length; j++) {
        if (foods[j].id === correctId) { correctFood = foods[j]; break; }
      }
      msg = lang === 'zh' ? '答對了！是' + (correctFood ? correctFood.zh : '') + '！' : 'Correct! It\'s ' + (correctFood ? correctFood.en : '') + '!';
    }
    if ('speechSynthesis' in window) {
      speechSynthesis.cancel();
      var u = new SpeechSynthesisUtterance(msg);
      u.lang = lang === 'zh' ? 'zh-TW' : 'en-US'; u.rate = 0.85; u.pitch = 1.2;
      speechSynthesis.speak(u);
    }
    setTimeout(function() { foodAfterQuiz(); }, 1500);
  } else {
    btn.classList.add('wrong');
    playWrongSound();
    btns.forEach(function(b) {
      if (b !== btn) {
        var bText = b.textContent.trim();
        if (quizType === 'category') {
          var cc = null;
          for (var i = 0; i < FOOD_CATEGORIES.length; i++) {
            if (FOOD_CATEGORIES[i].id === correctId) { cc = FOOD_CATEGORIES[i]; break; }
          }
          if (cc && bText.indexOf(cc.name[lang]) !== -1) b.classList.add('correct');
        } else {
          var foods2 = FOODS[foodState.currentCategory] || [];
          var cf = null;
          for (var j = 0; j < foods2.length; j++) {
            if (foods2[j].id === correctId) { cf = foods2[j]; break; }
          }
          if (cf && bText === cf[lang]) b.classList.add('correct');
        }
      }
    });
    var msg2 = lang === 'zh' ? '哎呀，再試一次！' : 'Oops, try again!';
    if ('speechSynthesis' in window) {
      speechSynthesis.cancel();
      var u2 = new SpeechSynthesisUtterance(msg2);
      u2.lang = lang === 'zh' ? 'zh-TW' : 'en-US'; u2.rate = 0.85; u2.pitch = 1.2;
      speechSynthesis.speak(u2);
    }
    setTimeout(function() { foodAfterQuiz(); }, 2000);
  }
}

function foodAfterQuiz() {
  foodState.quizPending = false;
  var foods = FOODS[foodState.currentCategory] || [];
  if (foodState.currentIdx >= foods.length) {
    showFoodComplete();
  } else {
    showFoodBrowse();
  }
}

function showFoodComplete() {
  if ('speechSynthesis' in window) speechSynthesis.cancel();
  showCompleteScreen('food-complete');
  completeActivity('page-food');
}
// <!-- #END:PAGE-FOOD-JS -->

```

- [ ] **Step 3: 驗證**

```bash
grep -n "#SECTION:PAGE-FOOD-JS\|#END:PAGE-FOOD-JS\|function showFoodShelf\|function startFoodQuiz" kids-companion/index.html
```

- [ ] **Step 4: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: food activity JS — browse, quiz, age-adaptive modes"
```

---

## Task 5: Wire Food to Home Page + Navigation + Stickers

**Files:**
- Modify: `kids-companion/index.html` — 4 個地方

- [ ] **Step 1: 定位 4 個插入點**

```bash
grep -n "navigateTo('page-zoo')" kids-companion/index.html        # activity card
grep -n "data-sticker=\"page-zoo\"" kids-companion/index.html     # sticker slot
grep -n "page-zoo.*showZooShelf\|if.*page-zoo" kids-companion/index.html  # navigateTo()
grep -n "'page-zoo'.*動物園\|page-money.*理財" kids-companion/index.html  # page title map (optional)
```

- [ ] **Step 2: 在探索 tab 加入食物活動卡（緊接 zoo 卡片後面）**

找到：
```html
      <div class="activity-card" onclick="navigateTo('page-zoo')">
        <span class="activity-icon">🦁</span>
        <span class="label">動物園</span>
      </div>
```

在其後插入：
```html
      <div class="activity-card" onclick="navigateTo('page-food')">
        <span class="activity-icon">🍎</span>
        <span class="label">食物原型</span>
      </div>
```

- [ ] **Step 3: 在貼紙板加入食物貼紙（緊接 zoo 貼紙後）**

找到：
```html
    <div class="sticker-slot locked" data-sticker="page-zoo">🦁</div>
```

在其後插入：
```html
    <div class="sticker-slot locked" data-sticker="page-food">🍎</div>
```

- [ ] **Step 4: 在 navigateTo() 函式加入 food 的初始化**

找到：
```javascript
  if (pageId === 'page-zoo') showZooShelf();
```

在其後插入：
```javascript
  if (pageId === 'page-food') showFoodShelf();
```

- [ ] **Step 5: 驗證**

```bash
grep -n "page-food\|showFoodShelf\|data-sticker=\"page-food\"" kids-companion/index.html
# 應各找到一筆
```

- [ ] **Step 6: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: wire food activity to home, navigation, sticker board"
```

---

## Task 6: Source & Embed 110 Food Images

**Files:**
- Modify: `kids-companion/index.html` — append to `#SECTION:IMAGES-ZOO` 之後

**方法：** 與動物園相同，使用 Wikipedia thumbnail API（200px）轉 base64。

- [ ] **Step 1: 定位圖片插入點**

```bash
grep -n "#END:IMAGES-ZOO" kids-companion/index.html
# → 在此行之後插入新的 IMAGES-FOOD 區塊
```

- [ ] **Step 2: 對每種食物抓取圖片**

對每個食物 ID，用以下邏輯：
1. 嘗試 Wikipedia thumbnail API：`https://en.wikipedia.org/w/api.php?action=query&titles=SEARCH_TERM&prop=pageimages&pithumbsize=200&format=json&origin=*`
2. 如果 HTTP 429（rate limit），等待 2 秒後重試
3. 如果找不到圖片，跳過（`renderFoodCard()` 已有 emoji fallback）
4. 將圖片 URL 下載後轉 base64

搜尋詞對應表：
```
broccoli → Broccoli
carrot → Carrot
spinach → Spinach
tomato → Tomato
eggplant → Eggplant
bell_pepper → Bell pepper
cabbage → Cabbage
cucumber → Cucumber
onion → Onion
pumpkin → Pumpkin
celery → Celery
mushroom → Mushroom (food)
bean_sprouts → Bean sprout
garlic → Garlic
ginger → Ginger
leek → Allium tuberosum (Chinese leek)
radish → Daikon
okra → Okra
sweet_potato_leaf → Sweet potato
corn → Corn on the cob
apple → Apple (fruit)
banana → Banana
mango → Mango
papaya → Papaya
pineapple → Pineapple
grapes → Grape
watermelon → Watermelon
orange → Orange (fruit)
strawberry → Strawberry
kiwi → Kiwifruit
wax_apple → Syzygium samarangense (wax apple)
guava → Guava
pear → Pear
peach → Peach
cantaloupe → Cantaloupe
dragon_fruit → Pitaya
tangerine → Tangerine
blueberry → Blueberry
persimmon → Persimmon
lychee → Lychee
white_rice → Cooked white rice
brown_rice → Brown rice
sweet_potato → Sweet potato
potato → Potato
taro → Taro (food)
oats → Oat (food)
toast → Toast (food)
steamed_bun → Mantou
rice_noodles → Rice vermicelli
noodles → Noodle
red_bean → Azuki bean
mung_bean → Mung bean
black_bean → Black turtle bean
barley → Barley
lotus_seed → Lotus seed
chestnut → Chestnut (food)
yam → Yam (vegetable)
millet → Millet
sorghum → Sorghum
quinoa → Quinoa
egg → Chicken egg
salmon → Salmon
chicken → Chicken (food)
pork → Pork
beef → Beef
tofu → Tofu
edamame → Edamame
mackerel → Atlantic mackerel
shrimp → Shrimp (food)
squid → Squid (food)
clam → Clam
tilapia → Tilapia
tuna → Tuna
duck_egg → Duck egg
sea_bass → Sea bass
saury → Pacific saury
octopus → Octopus (food)
soy_milk → Soy milk
natto → Natto
pork_tenderloin → Pork tenderloin
milk → Milk
cheese → Cheese
yogurt → Yogurt
goat_milk → Goat milk
butter → Butter
whipping_cream → Whipped cream
cottage_cheese → Cottage cheese
cheddar → Cheddar cheese
uht_milk → Ultra-high-temperature processing
condensed_milk → Condensed milk
peanut → Peanut
cashew → Cashew
walnut → Walnut
almond → Almond
white_sesame → Sesame
black_sesame → Sesame
pumpkin_seed → Pumpkin seed
sunflower_seed → Sunflower seed
pistachio → Pistachio
pine_nut → Pine nut
macadamia → Macadamia
hazelnut → Hazelnut
flaxseed → Flax
chia_seed → Chia seed
red_date → Jujube
goji_berry → Wolfberry
lotus_nut → Peanut
pecan → Pecan
brazil_nut → Brazil nut
hemp_seed → Hemp
```

- [ ] **Step 3: 在 `#END:IMAGES-ZOO` 後插入 IMAGES-FOOD 區塊**

格式如下（僅示意，實際值由抓取腳本填入）：
```javascript
// <!-- #SECTION:IMAGES-FOOD -->
Object.assign(IMG, {
  'food-broccoli': 'data:image/jpeg;base64,...',
  'food-carrot': 'data:image/jpeg;base64,...',
  // ... 所有成功抓到圖片的 food ID
});
// <!-- #END:IMAGES-FOOD -->
```

- [ ] **Step 4: 驗證圖片數量**

```bash
grep -c "'food-" kids-companion/index.html
# 預期 80 以上（部分食物 Wikipedia 可能無圖）
```

- [ ] **Step 5: Commit**

```bash
git add kids-companion/index.html
git commit -m "feat: add food item images (base64 from Wikipedia Commons)"
```

---

## Task 7: Final Test & Push

**Files:** 無需修改，僅測試與推送

- [ ] **Step 1: 開啟瀏覽器測試**

用瀏覽器開啟 `kids-companion/index.html`，依以下項目驗證：

**分類貨架：**
- [ ] 探索 tab 出現「食物原型 🍎」活動卡片
- [ ] 點進去顯示 6 個分類（蔬菜/水果/五穀根莖/魚肉蛋豆/奶類/堅果種子）
- [ ] 每個分類卡片顯示正確食物數量

**瀏覽模式：**
- [ ] 點分類進入瀏覽，顯示食物卡片（圖片或 emoji fallback）
- [ ] 卡片顯示中文名稱、英文名稱（非幼小班）、益處提示
- [ ] 點擊卡片或名稱會朗讀
- [ ] 幼小班自動朗讀
- [ ] 上一個 / 下一個導航正確

**測驗模式（切換至中班或大班測試）：**
- [ ] 每 5 張觸發測驗
- [ ] 中大班：題目「這是哪一類食物？」，選項是分類名稱
- [ ] 答對綠色，答錯紅色並高亮正確答案
- [ ] 幼小班（切換回去測試）：題目「這是什麼食物？」，選項是食物名稱

**完成畫面：**
- [ ] 看完全部後顯示「飲食小達人！」完成畫面
- [ ] 「再看一次」重播，「換分類」回到貨架
- [ ] 完成後貼紙板出現蘋果 🍎 貼紙解鎖

- [ ] **Step 2: 確認 git 狀態乾淨**

```bash
git status
# 應顯示 nothing to commit, working tree clean
```

- [ ] **Step 3: Push**

```bash
git push
```

---

## CLAUDE.md 更新提醒

Task 1–5 完成後，更新 `kids-companion/CLAUDE.md` 的錨點清單加入：

```
| `#SECTION:PAGE-FOOD` | 食物原型活動 |
```

圖片區塊說明已含「查 grep -n "#SECTION:IMAGES" index.html」，不需加行數。
