# Zoo Activity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 動物園 (Zoo) activity to kids-companion with 6 categories × 20+ animals, real photos from Wikimedia Commons (base64), and age-adaptive gameplay.

**Architecture:** Single HTML file pattern — new `<!-- #SECTION:PAGE-ZOO -->` HTML block, new `// <!-- #SECTION:PAGE-ZOO-JS -->` JS block, images stored in existing `IMG` object. Age logic mirrors existing ageGroup system (toddler/small/middle/large).

**Tech Stack:** Vanilla JS, Web Speech API, base64 JPEG images from Wikimedia Commons, existing CSS variables.

---

## Age-Group Gameplay

| ageGroup | Mode |
|----------|------|
| toddler / small | Browse only: big photo + name. Tap card → hear name. No quiz. |
| middle | Browse + 1-line desc. After every 5 animals: 2-choice quiz (photo shown, choose name). |
| large | Browse + full description. After every 5 animals: 4-choice quiz (photo shown, choose name). |

---

## Animal List

### 🌍 非洲 Africa (20)
lion, elephant, giraffe, zebra, hippo, rhino, leopard, cheetah, gorilla, baboon, hyena, warthog, meerkat, wildebeest, crocodile, ostrich, flamingo, african_wild_dog, aardvark, impala

### 🌿 草原 Grassland (20)
kangaroo, koala, bison, emu, wombat, dingo, tasmanian_devil, echidna, prairie_dog, puma, mustang, skunk, mule_deer, pronghorn, possum, rainbow_lorikeet, numbat, quokka, cassowary, wallaby

### 🏡 家庭 Farm & Pets (20)
dog, cat, rabbit, cow, pig, horse, sheep, goat, chicken, duck, goose, hamster, guinea_pig, goldfish, budgie, donkey, turkey, pigeon, bee, rooster

### 🇹🇼 台灣 Taiwan (20)
formosan_black_bear, formosan_macaque, sika_deer, muntjac, pangolin, taiwan_blue_magpie, mikado_pheasant, leopard_cat, giant_flying_squirrel, taiwan_serow, taiwan_hare, crab_eating_mongoose, taiwan_sambar, taiwan_salmon, lanyu_scops_owl, taiwan_salamander, taiwan_barbet, black_faced_spoonbill, fairy_pitta, collared_scops_owl

### 🦅 鳥類 Birds (20)
eagle, owl, peacock, penguin, parrot, swan, egret, hummingbird, kingfisher, toucan, woodpecker, crane, albatross, hornbill, pelican, macaw, puffin, flamingo_bird, barn_owl, secretary_bird

### 🌊 海中 Ocean (20)
dolphin, whale, shark, octopus, sea_turtle, jellyfish, starfish, crab, lobster, seahorse, manta_ray, clownfish, sea_lion, orca, seal, pufferfish, lionfish, eel, blue_tang, sea_horse

---

## Animal Data Structure (JS)

Each animal entry:
```javascript
{
  id: 'lion',
  img: 'zoo-lion',           // key into IMG object
  emoji: '🦁',
  zh: '獅子',
  en: 'Lion',
  desc: {
    zh: '獅子住在非洲草原，是森林之王！',
    en: 'Lions live on African savanna — king of the wild!'
  },
  detail: {
    zh: '獅子是貓科動物中唯一群居的，一群獅子叫做「獅群」。雄獅有威風的鬃毛，雌獅負責狩獵。',
    en: 'Lions are the only social big cats. A group is called a pride. Female lions do most of the hunting.'
  }
}
```

---

## Task 1: Source & Embed Animal Images

**Files:**
- Modify: `kids-companion/index.html` (add to IMG object near line ~1853 where coin images are)

Image sourcing strategy: Use Wikipedia's thumbnail API to get public domain images, then fetch the binary and convert to base64.

For each animal, use this Wikipedia API call to get the main article image URL:
```
https://en.wikipedia.org/w/api.php?action=query&titles=ANIMAL_NAME&prop=pageimages&pithumbsize=200&format=json&origin=*
```

Then fetch the returned thumbnail URL and convert to base64.

- [ ] **Step 1: Source 非洲 Africa images (20 animals)**

For each animal, fetch via Wikipedia API:
| id | Wikipedia title |
|----|----------------|
| lion | African lion |
| elephant | African elephant |
| giraffe | Giraffe |
| zebra | Zebra |
| hippo | Hippopotamus |
| rhino | White rhinoceros |
| leopard | Leopard |
| cheetah | Cheetah |
| gorilla | Gorilla |
| baboon | Baboon |
| hyena | Spotted hyena |
| warthog | Common warthog |
| meerkat | Meerkat |
| wildebeest | Wildebeest |
| crocodile | Nile crocodile |
| ostrich | Common ostrich |
| flamingo | Flamingo |
| african_wild_dog | African wild dog |
| aardvark | Aardvark |
| impala | Impala (animal) |

Fetch example (do for each):
```
GET https://en.wikipedia.org/w/api.php?action=query&titles=African+lion&prop=pageimages&pithumbsize=200&format=json&origin=*
→ parse json.query.pages[id].thumbnail.source
→ fetch that URL
→ convert to base64: btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))
→ get mime type from URL extension (usually image/jpeg)
```

Add each to IMG object:
```javascript
'zoo-lion': 'data:image/jpeg;base64,/9j/...',
'zoo-elephant': 'data:image/jpeg;base64,...',
// ... etc
```

- [ ] **Step 2: Source 草原 Grassland images (20 animals)**

| id | Wikipedia title |
|----|----------------|
| kangaroo | Red kangaroo |
| koala | Koala |
| bison | American bison |
| emu | Emu |
| wombat | Common wombat |
| dingo | Dingo |
| tasmanian_devil | Tasmanian devil |
| echidna | Short-beaked echidna |
| prairie_dog | Black-tailed prairie dog |
| puma | Cougar |
| mustang | Mustang (horse) |
| skunk | Striped skunk |
| mule_deer | Mule deer |
| pronghorn | Pronghorn |
| possum | Common brushtail possum |
| rainbow_lorikeet | Rainbow lorikeet |
| numbat | Numbat |
| quokka | Quokka |
| cassowary | Southern cassowary |
| wallaby | Red-necked wallaby |

- [ ] **Step 3: Source 家庭 Farm & Pets images (20 animals)**

| id | Wikipedia title |
|----|----------------|
| dog | Domestic dog |
| cat | Cat |
| rabbit | European rabbit |
| cow | Domestic cow |
| pig | Domestic pig |
| horse | Horse |
| sheep | Domestic sheep |
| goat | Domestic goat |
| chicken | Chicken |
| duck | Domestic duck |
| goose | Domestic goose |
| hamster | Golden hamster |
| guinea_pig | Guinea pig |
| goldfish | Goldfish |
| budgie | Budgerigar |
| donkey | Donkey |
| turkey | Wild turkey |
| pigeon | Rock dove |
| bee | Western honey bee |
| rooster | Rooster |

- [ ] **Step 4: Source 台灣 Taiwan images (20 animals)**

| id | Wikipedia title |
|----|----------------|
| formosan_black_bear | Formosan black bear |
| formosan_macaque | Formosan rock macaque |
| sika_deer | Formosan sika deer |
| muntjac | Reeves's muntjac |
| pangolin | Chinese pangolin |
| taiwan_blue_magpie | Taiwan blue magpie |
| mikado_pheasant | Mikado pheasant |
| leopard_cat | Leopard cat |
| giant_flying_squirrel | Red giant flying squirrel |
| taiwan_serow | Taiwan serow |
| taiwan_hare | Taiwanese hare |
| crab_eating_mongoose | Crab-eating mongoose |
| taiwan_sambar | Sambar deer |
| taiwan_salmon | Formosan landlocked salmon |
| lanyu_scops_owl | Lanyu scops owl |
| taiwan_salamander | Hynobius arisanensis |
| taiwan_barbet | Taiwan barbet |
| black_faced_spoonbill | Black-faced spoonbill |
| fairy_pitta | Fairy pitta |
| collared_scops_owl | Collared scops owl |

- [ ] **Step 5: Source 鳥類 Birds images (20 animals)**

| id | Wikipedia title |
|----|----------------|
| eagle | Bald eagle |
| owl | Great horned owl |
| peacock | Indian peafowl |
| penguin | Emperor penguin |
| parrot | African grey parrot |
| swan | Mute swan |
| egret | Great egret |
| hummingbird | Ruby-throated hummingbird |
| kingfisher | Common kingfisher |
| toucan | Toco toucan |
| woodpecker | Pileated woodpecker |
| crane | Red-crowned crane |
| albatross | Wandering albatross |
| hornbill | Great hornbill |
| pelican | American white pelican |
| macaw | Scarlet macaw |
| puffin | Atlantic puffin |
| flamingo_bird | Greater flamingo |
| barn_owl | Barn owl |
| secretary_bird | Secretarybird |

- [ ] **Step 6: Source 海中 Ocean images (20 animals)**

| id | Wikipedia title |
|----|----------------|
| dolphin | Common bottlenose dolphin |
| whale | Blue whale |
| shark | Great white shark |
| octopus | Common octopus |
| sea_turtle | Green sea turtle |
| jellyfish | Moon jellyfish |
| starfish | Common starfish |
| crab | Blue crab |
| lobster | American lobster |
| seahorse | Lined seahorse |
| manta_ray | Oceanic manta ray |
| clownfish | Ocellaris clownfish |
| sea_lion | California sea lion |
| orca | Orca |
| seal | Harbor seal |
| pufferfish | Porcupinefish |
| lionfish | Red lionfish |
| eel | Green moray |
| blue_tang | Blue tang |
| sea_horse | Dwarf seahorse |

- [ ] **Step 7: Commit image data**

```bash
git add kids-companion/index.html
git commit -m "feat: add zoo animal images (120 base64 photos from Wikipedia Commons)"
```

---

## Task 2: Add CSS

**Files:**
- Modify: `kids-companion/index.html` (inside `#SECTION:CSS`, after existing CSS)

- [ ] **Step 1: Add zoo CSS block**

Find the line `<!-- #END:CSS -->` and insert before it:

```css
/* Zoo Activity */
.zoo-category-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
  padding: 16px;
}
.zoo-category-card {
  background: var(--color-card);
  border-radius: 20px;
  padding: 24px 16px;
  text-align: center;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  transition: transform 0.15s;
  border: 3px solid transparent;
}
.zoo-category-card:active { transform: scale(0.95); border-color: var(--color-primary); }
.zoo-category-icon { font-size: 48px; display: block; margin-bottom: 8px; }
.zoo-category-name { font-size: 20px; font-weight: 700; }
.zoo-category-count { font-size: 14px; color: var(--color-muted, #aaa); margin-top: 4px; }

.zoo-browse-card {
  background: var(--color-card);
  border-radius: 24px;
  padding: 20px;
  margin: 0 16px 16px;
  text-align: center;
  box-shadow: 0 4px 16px rgba(0,0,0,0.08);
}
.zoo-animal-photo {
  width: 200px;
  height: 200px;
  object-fit: cover;
  border-radius: 16px;
  display: block;
  margin: 0 auto 16px;
  background: #eee;
}
.zoo-animal-photo-large {
  width: min(280px, 80vw);
  height: min(280px, 80vw);
  object-fit: cover;
  border-radius: 20px;
  display: block;
  margin: 0 auto 16px;
  background: #eee;
}
.zoo-animal-name {
  font-size: 32px;
  font-weight: 800;
  color: var(--color-text);
}
.zoo-animal-name-en {
  font-size: 16px;
  color: var(--color-muted, #aaa);
  margin-top: 2px;
}
.zoo-animal-desc {
  font-size: 18px;
  color: var(--color-text);
  margin-top: 12px;
  line-height: 1.5;
}
.zoo-animal-detail {
  font-size: 16px;
  color: #666;
  margin-top: 8px;
  line-height: 1.6;
  background: #f9f5f0;
  border-radius: 12px;
  padding: 10px 14px;
  text-align: left;
}
.zoo-nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 16px 16px;
}
.zoo-progress {
  font-size: 16px;
  color: var(--color-muted, #aaa);
  font-weight: 600;
}
.zoo-quiz-area {
  padding: 16px;
}
.zoo-quiz-question {
  text-align: center;
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 16px;
}
.zoo-quiz-choices {
  display: grid;
  gap: 10px;
}
.zoo-quiz-choices.choices-2 { grid-template-columns: 1fr 1fr; }
.zoo-quiz-choices.choices-4 { grid-template-columns: 1fr 1fr; }
.zoo-quiz-btn {
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
.zoo-quiz-btn:active { transform: scale(0.96); }
.zoo-quiz-btn.correct { border-color: #4CAF50; background: #E8F5E9; }
.zoo-quiz-btn.wrong { border-color: #F44336; background: #FFEBEE; }
```

- [ ] **Step 2: Commit CSS**

```bash
git add kids-companion/index.html
git commit -m "feat: zoo activity CSS"
```

---

## Task 3: Add HTML Page

**Files:**
- Modify: `kids-companion/index.html`

Find `<!-- #SECTION:PAGE-MONEY -->` (around line 1639). Insert the zoo page HTML **before** it.

- [ ] **Step 1: Insert HTML block**

```html
<!-- #SECTION:PAGE-ZOO -->
<div class="page" id="page-zoo">
  <div class="game-header">
    <button class="back-btn" id="zoo-back-btn" onclick="zooBack()">← 返回</button>
    <span class="game-title" id="zoo-title">🦁 動物園</span>
    <span class="round-counter" id="zoo-progress-label"></span>
  </div>
  <button class="praise-btn" onclick="showPraiseOverlay()">👏</button>

  <!-- Category shelf -->
  <div id="zoo-shelf">
    <div class="zoo-category-grid" id="zoo-category-grid"></div>
  </div>

  <!-- Browse mode -->
  <div id="zoo-browse" style="display:none">
    <div class="zoo-browse-card" id="zoo-browse-card"></div>
    <div class="zoo-nav">
      <button class="btn btn-secondary" id="zoo-prev-btn" onclick="zooPrev()" style="padding:10px 20px">← 上一隻</button>
      <span class="zoo-progress" id="zoo-browse-progress"></span>
      <button class="btn btn-primary" id="zoo-next-btn" onclick="zooNext()" style="padding:10px 20px">下一隻 →</button>
    </div>
  </div>

  <!-- Quiz mode -->
  <div id="zoo-quiz" style="display:none">
    <div class="zoo-quiz-area" id="zoo-quiz-area"></div>
  </div>

  <!-- Complete screen -->
  <div class="complete-screen" id="zoo-complete">
    <div class="complete-content">
      <div style="font-size:80px">🦁</div>
      <h2>動物小達人！</h2>
      <button class="btn btn-primary" onclick="zooRestart()">再看一次 🔄</button>
      <button class="btn btn-secondary" onclick="zooBackToShelf()">換分類</button>
    </div>
  </div>
</div>
<!-- #END:PAGE-ZOO -->
```

- [ ] **Step 2: Commit HTML**

```bash
git add kids-companion/index.html
git commit -m "feat: zoo activity HTML page"
```

---

## Task 4: Add Animal Data JS

**Files:**
- Modify: `kids-companion/index.html` — add before `// <!-- #SECTION:PAGE-MONEY-JS -->`

- [ ] **Step 1: Insert ANIMAL_CATEGORIES and ANIMALS data block**

```javascript
// <!-- #SECTION:PAGE-ZOO-DATA -->
var ANIMAL_CATEGORIES = [
  { id: 'africa',    emoji: '🌍', name: { zh: '非洲',  en: 'Africa'       } },
  { id: 'grassland', emoji: '🌿', name: { zh: '草原',  en: 'Grassland'    } },
  { id: 'home',      emoji: '🏡', name: { zh: '家庭',  en: 'Farm & Pets'  } },
  { id: 'taiwan',    emoji: '🇹🇼', name: { zh: '台灣',  en: 'Taiwan'       } },
  { id: 'birds',     emoji: '🦅', name: { zh: '鳥類',  en: 'Birds'        } },
  { id: 'ocean',     emoji: '🌊', name: { zh: '海中',  en: 'Ocean'        } }
];

var ANIMALS = {
  africa: [
    { id:'lion',           emoji:'🦁', zh:'獅子',     en:'Lion',          desc:{zh:'獅子是草原之王，住在非洲大草原！',en:'The lion is king of the savanna!'},         detail:{zh:'雄獅有威風的鬃毛，一群獅子叫做「獅群」，雌獅負責狩獵。',en:'Male lions have manes. A group is called a pride. Female lions do most of the hunting.'} },
    { id:'elephant',       emoji:'🐘', zh:'大象',     en:'Elephant',      desc:{zh:'大象是陸地上最大的動物，有長長的鼻子！',en:'Elephants are the largest land animals with long trunks!'},  detail:{zh:'大象用鼻子喝水、拿東西，還能發出低頻聲音和遠方的同伴溝通。',en:'Elephants use trunks to drink and grab things. They communicate with infrasound over long distances.'} },
    { id:'giraffe',        emoji:'🦒', zh:'長頸鹿',   en:'Giraffe',       desc:{zh:'長頸鹿是世界上最高的動物！',en:'Giraffes are the tallest animals in the world!'},              detail:{zh:'長頸鹿的脖子可以長達 1.8 公尺，舌頭是黑色的，可以長達 45 公分！',en:'Giraffe necks can reach 1.8m. Their tongues are bluish-black and up to 45cm long!'} },
    { id:'zebra',          emoji:'🦓', zh:'斑馬',     en:'Zebra',         desc:{zh:'斑馬有黑白條紋，每隻花紋都不一樣！',en:'Zebras have black and white stripes — each unique!'},       detail:{zh:'斑馬的條紋像指紋一樣，每隻都不同。牠們用條紋辨認彼此。',en:'Stripe patterns are unique like fingerprints. Zebras recognize each other by their stripes.'} },
    { id:'hippo',          emoji:'🦛', zh:'河馬',     en:'Hippopotamus',  desc:{zh:'河馬很愛泡水，是非洲最危險的動物之一！',en:'Hippos love water and are one of Africa\'s most dangerous animals!'},  detail:{zh:'河馬皮膚會分泌紅色液體，像天然防曬乳，保護皮膚不被曬傷。',en:'Hippos secrete a red liquid that acts as natural sunscreen and skin moisturizer.'} },
    { id:'rhino',          emoji:'🦏', zh:'犀牛',     en:'Rhinoceros',    desc:{zh:'犀牛頭上有角，皮膚很厚！',en:'Rhinos have horns and very thick skin!'},                   detail:{zh:'犀牛的角是由角蛋白組成，和我們的指甲一樣的材料。白犀牛其實不是白色的！',en:'Rhino horns are made of keratin — the same as our nails. White rhinos are not actually white!'} },
    { id:'leopard',        emoji:'🐆', zh:'豹',       en:'Leopard',       desc:{zh:'豹身上有漂亮的斑點，爬樹高手！',en:'Leopards have beautiful spots and are expert tree climbers!'},   detail:{zh:'豹會把獵物拖上樹，防止其他動物搶食。牠們是最神秘的大型貓科動物。',en:'Leopards drag prey up trees to keep it safe from scavengers. They are the most secretive big cats.'} },
    { id:'cheetah',        emoji:'🐆', zh:'獵豹',     en:'Cheetah',       desc:{zh:'獵豹是跑得最快的動物，每小時可達 120 公里！',en:'Cheetahs are the fastest animals — up to 120 km/h!'},        detail:{zh:'獵豹加速比跑車還快！但只能維持短距離衝刺，之後需要休息。',en:'Cheetahs accelerate faster than sports cars! But can only sprint short distances before resting.'} },
    { id:'gorilla',        emoji:'🦍', zh:'大猩猩',   en:'Gorilla',       desc:{zh:'大猩猩是人類的近親，非常聰明！',en:'Gorillas are close relatives of humans and very intelligent!'},    detail:{zh:'大猩猩的 DNA 有 98.3% 和人類相同。牠們會使用工具，還能學習手語。',en:'Gorilla DNA is 98.3% identical to humans. They use tools and can learn sign language.'} },
    { id:'baboon',         emoji:'🐒', zh:'狒狒',     en:'Baboon',        desc:{zh:'狒狒有鮮豔的臉色，生活在大群體裡！',en:'Baboons have colorful faces and live in large groups!'},        detail:{zh:'狒狒是非洲除了人類外分布最廣的靈長類。牠們很有社會性，會互相理毛。',en:'Baboons are Africa\'s most widespread primates after humans. They are very social and groom each other.'} },
    { id:'hyena',          emoji:'🐺', zh:'鬣狗',     en:'Hyena',         desc:{zh:'鬣狗會發出奇特的笑聲！',en:'Hyenas make a distinctive laughing sound!'},                     detail:{zh:'鬣狗的笑聲其實是興奮或緊張時發出的聲音。牠們的咬合力是所有哺乳類中最強之一。',en:'Hyena "laughs" are excitement or stress vocalizations. They have one of the strongest bites of any mammal.'} },
    { id:'warthog',        emoji:'🐗', zh:'疣豬',     en:'Warthog',       desc:{zh:'疣豬臉上有凸起的疣，喜歡打滾！',en:'Warthogs have facial warts and love to roll in mud!'},          detail:{zh:'疣豬跑步時尾巴會豎直，像根天線。牠們用膝蓋跪著吃草。',en:'Warthogs run with tails straight up like antennas. They kneel to eat grass.'} },
    { id:'meerkat',        emoji:'🦦', zh:'狐獴',     en:'Meerkat',       desc:{zh:'狐獴喜歡站起來曬太陽，輪流看守！',en:'Meerkats love to stand and sunbathe, taking turns as lookouts!'},  detail:{zh:'狐獴群體裡有「哨兵」輪流站崗，發現危險時會發出叫聲警告大家。',en:'Meerkat groups have rotating sentinels on lookout. They call out specific warnings for different predators.'} },
    { id:'wildebeest',     emoji:'🐃', zh:'牛羚',     en:'Wildebeest',    desc:{zh:'牛羚每年大遷徙，有上百萬隻！',en:'Wildebeest migrate in millions every year!'},                 detail:{zh:'牛羚的大遷徙是地球上最壯觀的動物奇景之一，每年跨越塞倫蓋提草原。',en:'The wildebeest migration is one of earth\'s greatest spectacles, crossing the Serengeti each year.'} },
    { id:'crocodile',      emoji:'🐊', zh:'鱷魚',     en:'Crocodile',     desc:{zh:'鱷魚是古老的爬行動物，嘴巴有很多牙齒！',en:'Crocodiles are ancient reptiles with many sharp teeth!'},    detail:{zh:'鱷魚的咬合力是地球上最強的動物之一。牠們的祖先和恐龍生活在同一時代。',en:'Crocodiles have one of the strongest bites on earth. Their ancestors lived alongside dinosaurs.'} },
    { id:'ostrich',        emoji:'🦅', zh:'鴕鳥',     en:'Ostrich',       desc:{zh:'鴕鳥是世界上最大的鳥，不能飛但跑很快！',en:'Ostriches are the world\'s largest birds — can\'t fly but run fast!'},  detail:{zh:'鴕鳥的眼睛比腦還大！牠們每小時可以跑 70 公里，是鳥類中跑最快的。',en:'Ostriches have eyes bigger than their brains! They run up to 70 km/h — fastest running bird.'} },
    { id:'flamingo',       emoji:'🦩', zh:'火烈鳥',   en:'Flamingo',      desc:{zh:'火烈鳥是粉紅色的，用一隻腳站立！',en:'Flamingos are pink and stand on one leg!'},                  detail:{zh:'火烈鳥是粉色的因為吃了含有色素的藻類和蝦。剛出生的雛鳥是白色的。',en:'Flamingos are pink because of pigments in the algae and shrimp they eat. Chicks are born white.'} },
    { id:'african_wild_dog', emoji:'🐕', zh:'非洲野狗', en:'African Wild Dog', desc:{zh:'非洲野狗有獨特的花紋，是最成功的獵食者！',en:'African wild dogs have unique markings and are Africa\'s most successful hunters!'},  detail:{zh:'非洲野狗的狩獵成功率高達 80%，遠超獅子的 30%。牠們會照顧受傷的同伴。',en:'African wild dogs succeed in 80% of hunts vs lions\' 30%. They care for injured pack members.'} },
    { id:'aardvark',       emoji:'🐽', zh:'土豚',     en:'Aardvark',      desc:{zh:'土豚有長長的鼻子，會挖地道！',en:'Aardvarks have long snouts and dig tunnels!'},                  detail:{zh:'土豚每晚可以吃掉 5 萬隻螞蟻或白蟻。牠們的地道也成為其他動物的家。',en:'Aardvarks eat up to 50,000 ants and termites nightly. Their burrows become homes for other animals.'} },
    { id:'impala',         emoji:'🦌', zh:'黑斑羚',   en:'Impala',        desc:{zh:'黑斑羚跳得很高，可以跳過 3 公尺！',en:'Impalas jump incredibly high — over 3 meters!'},             detail:{zh:'黑斑羚起跳高度可達 3 公尺，跳遠可達 10 公尺。牠們用跳躍來迷惑掠食者。',en:'Impalas can leap 3m high and 10m far. They use erratic jumps to confuse predators.'} }
  ],
  grassland: [
    { id:'kangaroo',      emoji:'🦘', zh:'袋鼠',     en:'Kangaroo',           desc:{zh:'袋鼠有口袋，寶寶在裡面長大！',en:'Kangaroos have pouches where joeys grow up!'},                   detail:{zh:'袋鼠寶寶出生時只有花生大小，要在媽媽的育兒袋裡待 6 個月才能出來。',en:'Joeys are born peanut-sized and stay in the pouch for 6 months.'} },
    { id:'koala',         emoji:'🐨', zh:'無尾熊',   en:'Koala',              desc:{zh:'無尾熊愛吃尤加利葉，一天睡 22 小時！',en:'Koalas eat eucalyptus and sleep 22 hours a day!'},          detail:{zh:'無尾熊幾乎只吃尤加利葉，這種葉子有毒，所以牠們需要很長的睡眠來解毒。',en:'Koalas eat almost only eucalyptus — which is toxic — so they sleep up to 22 hours to digest it.'} },
    { id:'bison',         emoji:'🐃', zh:'野牛',     en:'Bison',              desc:{zh:'北美野牛是北美洲最重的陸地動物！',en:'American bison are the heaviest land animals in North America!'},  detail:{zh:'野牛群曾經有 6000 萬隻橫跨北美大平原，後來幾乎被獵殺滅絕，現在靠保育重新復甦。',en:'Bison once numbered 60 million across North America, nearly hunted to extinction, now recovering.'} },
    { id:'emu',           emoji:'🦅', zh:'鴯鶓',     en:'Emu',                desc:{zh:'鴯鶓是澳洲最大的鳥，不會飛！',en:'Emus are Australia\'s largest birds and can\'t fly!'},            detail:{zh:'鴯鶓爸爸負責孵蛋和照顧小鳥，媽媽產完蛋就走了。牠們每小時可以跑 50 公里。',en:'Emu fathers incubate eggs and raise chicks alone. They run up to 50 km/h.'} },
    { id:'wombat',        emoji:'🐻', zh:'袋熊',     en:'Wombat',             desc:{zh:'袋熊會挖地道，大便是方形的！',en:'Wombats dig tunnels and produce cube-shaped poop!'},           detail:{zh:'袋熊是世界上唯一會排出方形糞便的動物，這樣糞便不會滾走，用來標記地盤。',en:'Wombats are the only animals that produce cube-shaped feces — so it doesn\'t roll away from their territory.'} },
    { id:'dingo',         emoji:'🐕', zh:'澳洲野犬', en:'Dingo',              desc:{zh:'澳洲野犬是澳洲最大的野生肉食動物！',en:'Dingoes are Australia\'s largest wild carnivores!'},        detail:{zh:'澳洲野犬不會吠叫，只會嗥叫。牠們大約 4000 年前由人類帶到澳洲。',en:'Dingoes don\'t bark — they howl. They were brought to Australia by humans about 4,000 years ago.'} },
    { id:'tasmanian_devil', emoji:'😈', zh:'袋獾',   en:'Tasmanian Devil',    desc:{zh:'袋獾叫聲很大，是世界上最大的肉食性有袋動物！',en:'Tasmanian devils are the world\'s largest carnivorous marsupials!'},  detail:{zh:'袋獾咬合力相對體型來說是哺乳類中最強的。牠們是瀕危動物，只生活在塔斯馬尼亞島。',en:'Tasmanian devils have the strongest bite relative to body size of any mammal. Endangered, found only in Tasmania.'} },
    { id:'echidna',       emoji:'🦔', zh:'針鼴',     en:'Echidna',            desc:{zh:'針鼴身上有刺，會產卵！哺乳類中很特別！',en:'Echidnas have spines and lay eggs — very unusual mammals!'},  detail:{zh:'針鼴和鴨嘴獸是世界上僅有的兩種產卵哺乳動物（單孔目）。牠們沒有牙齒，用舌頭抓蟲。',en:'Echidnas and platypuses are the only two egg-laying mammals. They have no teeth, catching insects with their tongues.'} },
    { id:'prairie_dog',   emoji:'🐿️', zh:'草原犬鼠', en:'Prairie Dog',        desc:{zh:'草原犬鼠住在地下城市，有自己的語言！',en:'Prairie dogs live in underground cities and have their own language!'},  detail:{zh:'研究發現草原犬鼠的叫聲可以描述掠食者的顏色、大小和速度，語言相當複雜。',en:'Research shows prairie dog calls can describe predator color, size, and speed — a complex language.'} },
    { id:'puma',          emoji:'🐱', zh:'美洲獅',   en:'Puma',               desc:{zh:'美洲獅也叫山獅或美洲豹，跳躍力超強！',en:'Pumas (mountain lions) have incredible jumping ability!'},    detail:{zh:'美洲獅可以向上跳 5.5 公尺高，水平跳躍可達 12 公尺。牠們是美洲分布最廣的大型貓科動物。',en:'Pumas can jump 5.5m vertically and 12m horizontally. They have the widest range of any large cat in the Americas.'} },
    { id:'mustang',       emoji:'🐎', zh:'野馬',     en:'Mustang',            desc:{zh:'野馬是北美的自由奔馳的馬，非常漂亮！',en:'Mustangs are free-roaming horses of North America!'},       detail:{zh:'野馬的祖先是西班牙殖民者帶來的家馬，後來逃跑變成野生的。現在受到美國法律保護。',en:'Mustangs descended from horses brought by Spanish colonists that escaped. Now protected by US law.'} },
    { id:'skunk',         emoji:'🦨', zh:'臭鼬',     en:'Skunk',              desc:{zh:'臭鼬會噴臭臭的液體保護自己！',en:'Skunks spray smelly liquid to protect themselves!'},          detail:{zh:'臭鼬的噴霧可以噴到 3 公尺遠，味道可以傳到 1.5 公里外。臭味可以在皮膚上持續好幾天。',en:'Skunks spray up to 3m, scent travels 1.5km, and the smell can last days on skin.'} },
    { id:'mule_deer',     emoji:'🦌', zh:'黑尾鹿',   en:'Mule Deer',          desc:{zh:'黑尾鹿有大大的耳朵，跳起來像彈簧！',en:'Mule deer have big ears and bounce like springs!'},        detail:{zh:'黑尾鹿用四腳同時彈跳的方式逃跑，這叫做「stotting」，可以讓牠們在任何方向迅速轉向。',en:'Mule deer escape by bouncing on all four legs simultaneously — called "stotting" — allowing rapid direction changes.'} },
    { id:'pronghorn',     emoji:'🦌', zh:'叉角羚',   en:'Pronghorn',          desc:{zh:'叉角羚是北美跑第二快的動物！',en:'Pronghorns are the second fastest land animals in North America!'},  detail:{zh:'叉角羚時速可達 96 公里，只比獵豹慢，但比獵豹耐力更強，可以維持高速跑更長距離。',en:'Pronghorns reach 96 km/h — just slower than cheetahs but with much greater endurance over distance.'} },
    { id:'possum',        emoji:'🐀', zh:'負鼠',     en:'Possum',             desc:{zh:'負鼠被嚇到會裝死，還會假裝發臭！',en:'Possums play dead when frightened — even fake a bad smell!'},  detail:{zh:'負鼠裝死時會倒地、流口水、發出臭味，狀態可以維持幾分鐘到幾小時。這是自動反應，不是有意識的行為。',en:'Playing dead is an involuntary reaction — they fall, drool, and emit odors. Can last minutes to hours.'} },
    { id:'rainbow_lorikeet', emoji:'🦜', zh:'彩虹吸蜜鸚鵡', en:'Rainbow Lorikeet', desc:{zh:'彩虹吸蜜鸚鵡有彩虹一樣的顏色！',en:'Rainbow lorikeets have rainbow-colored feathers!'},       detail:{zh:'彩虹吸蜜鸚鵡有特別的刷狀舌頭，專門用來舔花蜜。牠們喝花蜜，不吃種子。',en:'Rainbow lorikeets have brush-tipped tongues for lapping nectar. They eat nectar, not seeds.'} },
    { id:'numbat',        emoji:'🦊', zh:'袋食蟻獸', en:'Numbat',             desc:{zh:'袋食蟻獸是澳洲瀕危動物，專吃白蟻！',en:'Numbats are endangered Australian animals that eat only termites!'},  detail:{zh:'一隻袋食蟻獸每天可以吃掉 2 萬隻白蟻。全球只剩大約 1000 隻。',en:'A numbat eats up to 20,000 termites daily. Only about 1,000 remain in the wild.'} },
    { id:'quokka',        emoji:'🐹', zh:'短尾矮袋鼠', en:'Quokka',           desc:{zh:'短尾矮袋鼠是世界上最快樂的動物，一直在笑！',en:'Quokkas are called the world\'s happiest animal — always smiling!'},  detail:{zh:'短尾矮袋鼠只生活在澳洲西南部的幾個小島上。牠們臉部結構讓嘴角上揚，看起來像在笑。',en:'Quokkas live only on a few small islands in SW Australia. Their facial structure creates a natural smile.'} },
    { id:'cassowary',     emoji:'🦅', zh:'食火雞',   en:'Cassowary',          desc:{zh:'食火雞是世界上最危險的鳥！頭上有頭盔！',en:'Cassowaries are the world\'s most dangerous birds with helmet-like casques!'},  detail:{zh:'食火雞的踢力非常強，爪子可以撕裂皮膚。牠們是熱帶雨林的「種子傳播者」。',en:'Cassowaries have powerful kicks with dagger-like claws. They are vital seed dispersers in rainforests.'} },
    { id:'wallaby',       emoji:'🦘', zh:'小袋鼠',   en:'Wallaby',            desc:{zh:'小袋鼠是袋鼠的迷你版，很可愛！',en:'Wallabies are like miniature kangaroos!'},                     detail:{zh:'小袋鼠和袋鼠是不同物種。通常比袋鼠小，生活在有更多遮蔽的環境中。',en:'Wallabies are distinct from kangaroos. Generally smaller, they prefer more sheltered habitats.'} }
  ],
  home: [
    { id:'dog',        emoji:'🐕', zh:'狗',     en:'Dog',          desc:{zh:'狗是人類最忠實的朋友，會搖尾巴！',en:'Dogs are humans\' best friends and wag their tails!'},         detail:{zh:'狗已經被人類馴養了至少 15000 年。牠們的嗅覺比人類強 10000 倍以上。',en:'Dogs have been domesticated for at least 15,000 years. Their sense of smell is 10,000+ times stronger than ours.'} },
    { id:'cat',        emoji:'🐱', zh:'貓',     en:'Cat',          desc:{zh:'貓咪喜歡玩耍，發出呼嚕聲表示開心！',en:'Cats love to play and purr when happy!'},                    detail:{zh:'貓的眼睛在黑暗中可以看得很清楚。牠們每天睡 12-16 小時。貓咪的叫聲是為了和人溝通發展出來的。',en:'Cats see well in darkness. They sleep 12-16 hours a day. Meowing is a behavior developed specifically to communicate with humans.'} },
    { id:'rabbit',     emoji:'🐰', zh:'兔子',   en:'Rabbit',       desc:{zh:'兔子有長耳朵，跑起來很快！',en:'Rabbits have long ears and are very fast runners!'},          detail:{zh:'兔子的牙齒一生持續生長，所以需要不斷咀嚼東西磨牙。兔子的眼睛可以看到幾乎 360 度。',en:'Rabbit teeth grow continuously throughout their lives. Their eyes provide nearly 360° vision.'} },
    { id:'cow',        emoji:'🐄', zh:'牛',     en:'Cow',          desc:{zh:'牛提供牛奶給我們喝，非常有用！',en:'Cows give us milk and are very useful animals!'},             detail:{zh:'一頭牛每天可以產 25-40 公升的牛奶。牛有四個胃，需要反覆咀嚼食物。',en:'A cow produces 25-40 liters of milk daily. Cows have four stomach compartments and chew cud repeatedly.'} },
    { id:'pig',        emoji:'🐷', zh:'豬',     en:'Pig',          desc:{zh:'豬其實很聰明，喜歡打滾在泥巴裡！',en:'Pigs are actually very smart and love to roll in mud!'},      detail:{zh:'豬的智商排在動物界前五名，比狗更聰明。牠們在泥巴裡打滾是為了散熱，因為沒有汗腺。',en:'Pigs rank in the top 5 most intelligent animals — smarter than dogs. They roll in mud to cool down as they can\'t sweat.'} },
    { id:'horse',      emoji:'🐎', zh:'馬',     en:'Horse',        desc:{zh:'馬跑得很快，人類的好幫手！',en:'Horses run fast and are wonderful helpers to humans!'},         detail:{zh:'馬的眼睛是哺乳動物中最大的，幾乎可以看到 360 度。馬站著也可以睡覺！',en:'Horses have the largest eyes of any land mammal with near-360° vision. They can sleep standing up!'} },
    { id:'sheep',      emoji:'🐑', zh:'綿羊',   en:'Sheep',        desc:{zh:'綿羊有蓬鬆的毛，可以做成毛衣！',en:'Sheep have fluffy wool that can be made into sweaters!'},      detail:{zh:'一隻綿羊每年可以剪出約 4 公斤的羊毛。綿羊能記住同伴的臉，記憶力可以長達兩年。',en:'One sheep yields about 4kg of wool per year. Sheep can remember up to 50 faces for over 2 years.'} },
    { id:'goat',       emoji:'🐐', zh:'山羊',   en:'Goat',         desc:{zh:'山羊很會爬山，連石頭牆都能爬！',en:'Goats are amazing climbers — even vertical rock faces!'},      detail:{zh:'山羊的瞳孔是方形的，這讓牠們能有更廣的視野，看到掠食者。',en:'Goats have rectangular pupils giving them a wider field of view to spot predators.'} },
    { id:'chicken',    emoji:'🐔', zh:'雞',     en:'Chicken',      desc:{zh:'雞每天下蛋，給我們好吃的雞蛋！',en:'Chickens lay eggs every day for us to eat!'},               detail:{zh:'雞是全世界數量最多的鳥類，大約有 250 億隻。牠們有超過 30 種不同的叫聲。',en:'Chickens are the world\'s most numerous birds at about 25 billion. They have over 30 distinct vocalizations.'} },
    { id:'duck',       emoji:'🦆', zh:'鴨子',   en:'Duck',         desc:{zh:'鴨子游泳很厲害，羽毛防水！',en:'Ducks are great swimmers with waterproof feathers!'},          detail:{zh:'鴨子的羽毛上有防水油脂，水珠會在羽毛上滾動。鴨寶寶出生後幾小時就會游泳。',en:'Duck feathers are coated with waterproofing oil. Ducklings can swim within hours of hatching.'} },
    { id:'goose',      emoji:'🪿', zh:'鵝',     en:'Goose',        desc:{zh:'鵝的叫聲很大，可以保護家園！',en:'Geese are loud and can protect homes!'},                      detail:{zh:'鵝是非常忠誠的動物，會認主人。古羅馬人用鵝來警衛城堡，效果比狗還好。',en:'Geese are loyal and recognize their owners. Ancient Romans used geese as sentinels — more effective than dogs.'} },
    { id:'hamster',    emoji:'🐹', zh:'倉鼠',   en:'Hamster',      desc:{zh:'倉鼠的頰囊可以裝很多食物！',en:'Hamsters have cheek pouches that can hold lots of food!'},     detail:{zh:'倉鼠的頰囊延伸到肩膀，可以裝超過自身體重一半的食物。牠們是夜行性動物。',en:'Hamster cheek pouches extend to their shoulders, holding food weighing half their body weight. They are nocturnal.'} },
    { id:'guinea_pig', emoji:'🐹', zh:'天竺鼠', en:'Guinea Pig',   desc:{zh:'天竺鼠很愛說話，會發出很多聲音！',en:'Guinea pigs are very vocal and make many sounds!'},         detail:{zh:'天竺鼠有超過 11 種不同的叫聲，用來表達不同的情緒。牠們是社交動物，喜歡有伴。',en:'Guinea pigs have 11+ distinct vocalizations for different emotions. They are social animals and need companionship.'} },
    { id:'goldfish',   emoji:'🐟', zh:'金魚',   en:'Goldfish',     desc:{zh:'金魚有金色的鱗片，游起來很漂亮！',en:'Goldfish have shiny scales and swim beautifully!'},         detail:{zh:'金魚的記憶力遠不只三秒，其實可以記住幾個月的事。野生金魚是橄欖綠色的，不是金色的。',en:'Goldfish memory isn\'t just 3 seconds — they can remember things for months. Wild goldfish are olive-green, not golden.'} },
    { id:'budgie',     emoji:'🦜', zh:'虎皮鸚鵡', en:'Budgerigar', desc:{zh:'虎皮鸚鵡可以學說話，非常聰明！',en:'Budgerigars can learn to talk and are very smart!'},        detail:{zh:'虎皮鸚鵡可以學會超過 100 個詞彙，是學說話最多的鸚鵡之一。牠們是野生群居動物，喜歡有同伴。',en:'Budgies can learn 100+ words and are among the best talking parrots. Wild ones are flock animals needing companionship.'} },
    { id:'donkey',     emoji:'🫏', zh:'驢',     en:'Donkey',       desc:{zh:'驢子很強壯，是古代的好幫手！',en:'Donkeys are strong and have been helpers throughout history!'},  detail:{zh:'驢子有超過 6000 年的馴養歷史，比馬更早。牠們記憶力很好，從來不忘記去過的路。',en:'Donkeys have been domesticated over 6,000 years — longer than horses. They have excellent memories and never forget a path.'} },
    { id:'turkey',     emoji:'🦃', zh:'火雞',   en:'Turkey',       desc:{zh:'火雞頭上有鮮紅色的肉垂，很特別！',en:'Turkeys have bright red wattles and are very distinctive!'},  detail:{zh:'雄火雞發情時臉部和頸部的顏色會從紅色變成藍色。火雞能以時速 25 公里奔跑。',en:'Male turkeys\' head and neck change from red to blue when excited. They can run 25 km/h.'} },
    { id:'pigeon',     emoji:'🕊️', zh:'鴿子',   en:'Pigeon',       desc:{zh:'鴿子能找到回家的路，古代用來送信！',en:'Pigeons can always find their way home — used as messengers!'},  detail:{zh:'鴿子的導航能力令人驚嘆，可以從 1800 公里外找到回家的路。牠們利用地球磁場和地標導航。',en:'Pigeons navigate home from 1,800km away using Earth\'s magnetic field and visual landmarks.'} },
    { id:'bee',        emoji:'🐝', zh:'蜜蜂',   en:'Bee',          desc:{zh:'蜜蜂採花蜜做蜂蜜，幫植物傳花粉！',en:'Bees collect nectar for honey and pollinate plants!'},         detail:{zh:'一隻蜜蜂一生只能生產 1/12 茶匙的蜂蜜。全球三分之一的食物需要靠蜜蜂授粉。',en:'One bee produces just 1/12 teaspoon of honey in its lifetime. One-third of all food relies on bee pollination.'} },
    { id:'rooster',    emoji:'🐓', zh:'公雞',   en:'Rooster',      desc:{zh:'公雞每天早晨啼叫，叫大家起床！',en:'Roosters crow every morning to wake everyone up!'},          detail:{zh:'公雞的啼叫可以達到 140 分貝，和噴射機一樣響。牠們其實全天都會叫，不只是早上。',en:'A rooster\'s crow can reach 140 decibels — as loud as a jet engine. They actually crow all day, not just at dawn.'} }
  ],
  taiwan: [
    { id:'formosan_black_bear',    emoji:'🐻', zh:'台灣黑熊',   en:'Formosan Black Bear',   desc:{zh:'台灣黑熊是台灣最大的野生動物，胸前有V字形白斑！',en:'The Formosan black bear is Taiwan\'s largest wild animal with a V-shaped chest mark!'},     detail:{zh:'台灣黑熊是台灣原住民的精神象徵。牠們是雜食性動物，目前被列為易危物種，全台只剩約 400-600 隻。',en:'The Formosan black bear is a spiritual symbol for Taiwan\'s indigenous peoples. Classified as vulnerable, only 400-600 remain.'} },
    { id:'formosan_macaque',       emoji:'🐒', zh:'台灣獼猴',   en:'Formosan Rock Macaque', desc:{zh:'台灣獼猴是台灣唯一的原生靈長類！',en:'The Formosan macaque is Taiwan\'s only native primate!'},                          detail:{zh:'台灣獼猴是台灣特有種，分布在中低海拔山區。牠們的社會結構複雜，由雌猴為核心組成群體。',en:'Endemic to Taiwan, found in mid to low altitude mountains. Female-centered social structure.'} },
    { id:'sika_deer',              emoji:'🦌', zh:'梅花鹿',     en:'Formosan Sika Deer',    desc:{zh:'梅花鹿身上有白色斑點，像梅花一樣！',en:'Sika deer have white spots like plum blossoms!'},                              detail:{zh:'台灣梅花鹿曾經幾乎絕跡，後來靠保育計畫重新野放。牠們是台灣原住民文化中重要的動物。',en:'Once nearly extinct, reintroduced through conservation programs. Important in Taiwan aboriginal culture.'} },
    { id:'muntjac',                emoji:'🦌', zh:'山羌',       en:'Formosan Reeve\'s Muntjac', desc:{zh:'山羌是台灣山區常見的小鹿，叫聲像狗！',en:'The muntjac is a small deer common in Taiwan mountains with a dog-like bark!'},         detail:{zh:'山羌受驚嚇時會發出一聲響亮的叫聲，像是狗吠，所以俗稱「吠鹿」。牠們是台灣分布最廣的鹿科動物。',en:'When alarmed, muntjacs emit a loud bark — earning the name "barking deer." Most widespread deer in Taiwan.'} },
    { id:'pangolin',               emoji:'🦔', zh:'穿山甲',     en:'Chinese Pangolin',      desc:{zh:'穿山甲全身有鱗片，受到威脅會縮成球！',en:'Pangolins have scales and curl into a ball when threatened!'},                 detail:{zh:'穿山甲是世界上被非法交易最多的哺乳動物。台灣穿山甲靠保育計畫數量逐漸回升中。',en:'Pangolins are the world\'s most illegally trafficked mammals. Taiwan\'s conservation programs are helping numbers recover.'} },
    { id:'taiwan_blue_magpie',     emoji:'🦅', zh:'台灣藍鵲',   en:'Taiwan Blue Magpie',    desc:{zh:'台灣藍鵲是台灣最美麗的鳥之一，藍色羽毛超漂亮！',en:'The Taiwan blue magpie is one of Taiwan\'s most beautiful birds!'},           detail:{zh:'台灣藍鵲是台灣特有種，尾巴很長，飛行時非常壯觀。台灣人票選牠為「台灣國鳥」。',en:'Endemic to Taiwan with a spectacular long tail in flight. Voted Taiwan\'s national bird by public poll.'} },
    { id:'mikado_pheasant',        emoji:'🦅', zh:'帝雉',       en:'Mikado Pheasant',       desc:{zh:'帝雉是台灣高山的珍貴鳥類，新台幣千元鈔票上的鳥！',en:'The Mikado pheasant appears on Taiwan\'s NT$1000 banknote!'},              detail:{zh:'帝雉是台灣特有種，生活在高海拔山區。雄鳥有藍黑色羽毛和白色橫紋尾羽，非常漂亮。',en:'Endemic to high-altitude Taiwan mountains. Males have deep blue-black plumage with white-striped tail feathers.'} },
    { id:'leopard_cat',            emoji:'🐱', zh:'石虎',       en:'Leopard Cat',           desc:{zh:'石虎是台灣最後的野生貓科動物，身上有斑點！',en:'The leopard cat is Taiwan\'s last wild cat species with beautiful spots!'},    detail:{zh:'台灣石虎目前只剩約 400-600 隻，主要分布在苗栗、南投等地。牠們是瀕危物種，受到嚴格保護。',en:'Only 400-600 remain in Taiwan, mainly in Miaoli and Nantou. Critically protected as an endangered species.'} },
    { id:'giant_flying_squirrel',  emoji:'🐿️', zh:'台灣大赤鼯鼠', en:'Red Giant Flying Squirrel', desc:{zh:'大赤鼯鼠可以滑翔超過 100 公尺！',en:'Red giant flying squirrels can glide over 100 meters!'},         detail:{zh:'大赤鼯鼠靠前後腿之間的皮膜滑翔，可以在樹與樹之間滑翔很長的距離。牠們是夜行性動物。',en:'Glide using skin membranes between limbs, covering great distances between trees. Nocturnal animals.'} },
    { id:'taiwan_serow',           emoji:'🐐', zh:'台灣長鬃山羊', en:'Taiwan Serow',         desc:{zh:'台灣長鬃山羊是台灣唯一的野生牛科動物！',en:'The Taiwan serow is Taiwan\'s only native wild bovid!'},                   detail:{zh:'台灣長鬃山羊生活在陡峭的山壁上，是爬山高手。牠是台灣特有種，目前數量稀少。',en:'Lives on steep cliff faces and is an expert climber. Endemic to Taiwan and now relatively rare.'} },
    { id:'taiwan_hare',            emoji:'🐰', zh:'台灣野兔',   en:'Taiwanese Hare',        desc:{zh:'台灣野兔是台灣特有種，跑起來超快！',en:'The Taiwanese hare is endemic to Taiwan and very fast!'},                  detail:{zh:'台灣野兔分布在低海拔草地和農田附近，是台灣特有種。牠們靠高速奔跑和靈活轉向逃避天敵。',en:'Found in lowland grasslands and farmland edges. Endemic to Taiwan. Escapes predators with speed and agility.'} },
    { id:'crab_eating_mongoose',   emoji:'🦦', zh:'食蟹獴',     en:'Crab-eating Mongoose',  desc:{zh:'食蟹獴很勇敢，敢和眼鏡蛇打架！',en:'The crab-eating mongoose is brave enough to fight cobras!'},            detail:{zh:'食蟹獴對蛇毒有一定的抗性，會主動獵捕毒蛇。牠們也吃螃蟹、青蛙等各種食物。',en:'Partially immune to snake venom and actively hunt venomous snakes. Also eat crabs, frogs, and other prey.'} },
    { id:'taiwan_sambar',          emoji:'🦌', zh:'台灣水鹿',   en:'Taiwan Sambar Deer',    desc:{zh:'台灣水鹿是台灣最大的鹿，生活在高山！',en:'Taiwan sambar deer are Taiwan\'s largest deer, living in high mountains!'},  detail:{zh:'台灣水鹿是台灣原生鹿類中體型最大的，主要生活在海拔 2000-3000 公尺的高山。',en:'Taiwan\'s largest native deer, primarily found at elevations of 2,000-3,000 meters.'} },
    { id:'taiwan_salmon',          emoji:'🐟', zh:'台灣鮭魚',   en:'Formosan Landlocked Salmon', desc:{zh:'台灣鮭魚只住在武陵的七家灣溪，是冰河時期的孑遺生物！',en:'Taiwan salmon lives only in one stream — a relic from the Ice Age!'},  detail:{zh:'台灣鮭魚是冰河時期留下的孑遺物種，目前只生活在武陵農場附近的七家灣溪。數量極稀少，是台灣國寶。',en:'A glacial relict species surviving only in Cijiawan Creek near Wuling Farm. Extremely rare national treasure.'} },
    { id:'lanyu_scops_owl',        emoji:'🦉', zh:'蘭嶼角鴞',   en:'Lanyu Scops Owl',       desc:{zh:'蘭嶼角鴞只住在蘭嶼島，叫聲很特別！',en:'The Lanyu scops owl lives only on Orchid Island with a unique call!'},   detail:{zh:'蘭嶼角鴞是台灣特有種，只生活在蘭嶼島上。牠們的叫聲是蘭嶼達悟族文化的一部分。',en:'Endemic to Orchid Island (Lanyu). Its call is part of the culture of the Tao indigenous people.'} },
    { id:'taiwan_salamander',      emoji:'🦎', zh:'台灣山椒魚', en:'Taiwan Salamander',     desc:{zh:'台灣山椒魚是冰河時期留下的活化石！',en:'Taiwan salamanders are living fossils from the Ice Age!'},              detail:{zh:'台灣山椒魚是冰河時期的孑遺生物，分布在高海拔山區。牠們需要冷涼濕潤的環境，是氣候變遷的指標物種。',en:'Glacial relict species in high-altitude Taiwan. Requires cool moist habitat, making them indicators of climate change.'} },
    { id:'taiwan_barbet',          emoji:'🦜', zh:'五色鳥',     en:'Taiwan Barbet',         desc:{zh:'五色鳥有五種顏色，是台灣常見的留鳥！',en:'The Taiwan barbet has five colors and is a common Taiwan resident bird!'},  detail:{zh:'五色鳥是台灣特有種，全身有紅、黃、藍、黑、綠五種顏色。牠在樹幹上鑿洞築巢，叫聲像敲木魚。',en:'Endemic to Taiwan with red, yellow, blue, black, and green. Nests in tree cavities. Call sounds like a wooden block.'} },
    { id:'black_faced_spoonbill',  emoji:'🦢', zh:'黑面琵鷺',   en:'Black-faced Spoonbill', desc:{zh:'黑面琵鷺嘴巴像湯匙，是全球瀕危鳥類！',en:'The black-faced spoonbill has a spoon-shaped bill and is globally endangered!'},  detail:{zh:'全球只剩約 5000 隻黑面琵鷺，台灣是最重要的度冬棲息地。每年冬天在台南七股可以看到大群。',en:'Only ~5,000 remain globally. Taiwan, especially Tainan\'s Qigu, is the most important wintering ground.'} },
    { id:'fairy_pitta',            emoji:'🦜', zh:'八色鳥',     en:'Fairy Pitta',           desc:{zh:'八色鳥有八種顏色，是最美麗的候鳥之一！',en:'The fairy pitta has eight colors and is one of the most beautiful migratory birds!'},  detail:{zh:'八色鳥每年夏天來台灣繁殖，是台灣最受關注的夏候鳥之一。牠的羽色有八種顏色，非常美麗。',en:'Arrives in Taiwan each summer to breed. One of Taiwan\'s most watched summer migratory birds. Has eight distinct colors.'} },
    { id:'collared_scops_owl',     emoji:'🦉', zh:'領角鴞',     en:'Collared Scops Owl',    desc:{zh:'領角鴞是台灣最常見的貓頭鷹！晚上活動！',en:'The collared scops owl is Taiwan\'s most common owl, active at night!'},   detail:{zh:'領角鴞廣泛分布在台灣低海拔山區和城市公園。牠們的叫聲是「嗚嗚嗚」，夜晚常可聽見。',en:'Widely distributed in Taiwan\'s lowland mountains and city parks. Their soft "hoo hoo hoo" is commonly heard at night.'} }
  ],
  birds: [
    { id:'eagle',          emoji:'🦅', zh:'老鷹',   en:'Eagle',             desc:{zh:'老鷹是天空的霸主，視力超強！',en:'Eagles rule the sky with incredible eyesight!'},                  detail:{zh:'老鷹的視力比人類強 4-8 倍，可以從 3 公里外看到獵物。牠們的爪力非常強，可以抓起比自己重的動物。',en:'Eagles have 4-8x human vision, spotting prey from 3km. Their talons can grip prey heavier than themselves.'} },
    { id:'owl',            emoji:'🦉', zh:'貓頭鷹', en:'Owl',               desc:{zh:'貓頭鷹是夜行性動物，頭可以轉 270 度！',en:'Owls are nocturnal and can rotate their heads 270 degrees!'},     detail:{zh:'貓頭鷹的眼睛是固定的，不能轉動，所以要轉動整個頭。牠們飛行時幾乎無聲。',en:'Owl eyes are fixed in their sockets — they rotate their whole head instead. Their flight is nearly silent.'} },
    { id:'peacock',        emoji:'🦚', zh:'孔雀',   en:'Peacock',           desc:{zh:'孔雀的尾巴像彩虹扇子，超級漂亮！',en:'Peacocks have rainbow fan tails — stunningly beautiful!'},        detail:{zh:'孔雀展開尾羽時可以長達 2 公尺。那不是尾巴，而是背部的覆羽。雌孔雀沒有長尾羽。',en:'The peacock\'s train can reach 2m long — it\'s actually back feathers, not a tail. Females lack the colorful train.'} },
    { id:'penguin',        emoji:'🐧', zh:'企鵝',   en:'Penguin',           desc:{zh:'企鵝不會飛，但游泳超厲害！住在南極！',en:'Penguins can\'t fly but are amazing swimmers — they live in Antarctica!'},  detail:{zh:'企鵝的翅膀演化成鰭狀肢，游泳時速可達 25 公里。帝企鵝爸爸在零下 60 度的嚴寒中孵蛋。',en:'Penguin wings evolved into flippers, reaching 25 km/h swimming. Emperor penguin dads incubate eggs in -60°C cold.'} },
    { id:'parrot',         emoji:'🦜', zh:'鸚鵡',   en:'Parrot',            desc:{zh:'鸚鵡可以說話，非常聰明！',en:'Parrots can talk and are incredibly intelligent!'},                detail:{zh:'非洲灰鸚鵡的智力相當於 5 歲小孩，可以理解數字概念和顏色分類。壽命可達 80 年。',en:'African grey parrots have intelligence comparable to a 5-year-old child, understanding numbers and categories. Can live 80 years.'} },
    { id:'swan',           emoji:'🦢', zh:'天鵝',   en:'Swan',              desc:{zh:'天鵝雪白優雅，是愛情的象徵！',en:'Swans are elegant and white — a symbol of love!'},               detail:{zh:'天鵝是終生伴侶，如果一方死亡，另一方可能因傷心而拒絕進食。牠們的翅膀拍擊力可以折斷人的骨頭。',en:'Swans mate for life. If one dies, the other may refuse to eat. Their wing-beats can break human bones.'} },
    { id:'egret',          emoji:'🦢', zh:'白鷺鷥', en:'Great Egret',       desc:{zh:'白鷺鷥是純白色的鳥，常見於台灣水田！',en:'Great egrets are pure white birds, common in Taiwan\'s rice fields!'},  detail:{zh:'白鷺鷥在台灣是常見的留鳥和候鳥，常常站在水牛背上或田間覓食。繁殖期會長出漂亮的飾羽。',en:'Common resident and migratory bird in Taiwan, often seen on water buffalo backs or in rice paddies.'} },
    { id:'hummingbird',    emoji:'🐦', zh:'蜂鳥',   en:'Hummingbird',       desc:{zh:'蜂鳥是最小的鳥，翅膀震動很快！',en:'Hummingbirds are the smallest birds with incredibly fast wings!'},   detail:{zh:'蜂鳥每秒可以拍翅 80 次！牠們是唯一能後退飛行的鳥。心跳每分鐘可達 1260 下。',en:'Hummingbirds flap wings up to 80 times per second and are the only birds that can fly backwards. Heart rate: 1,260 bpm.'} },
    { id:'kingfisher',     emoji:'🐦', zh:'翠鳥',   en:'Common Kingfisher', desc:{zh:'翠鳥有藍綠色的羽毛，俯衝捕魚高手！',en:'Kingfishers have blue-green feathers and dive-bomb for fish!'},     detail:{zh:'翠鳥俯衝入水的速度極快，幾乎不激起水花。牠們的喙型啟發了新幹線車頭的設計。',en:'Kingfishers dive with minimal splash. Their bill shape inspired the design of Japan\'s bullet train nose.'} },
    { id:'toucan',         emoji:'🐦', zh:'大嘴鳥', en:'Toucan',            desc:{zh:'大嘴鳥的嘴巴比身體還長！五顏六色！',en:'Toucans have beaks longer than their bodies — and so colorful!'},  detail:{zh:'大嘴鳥的大嘴巴是空心的，非常輕。它用來調節體溫，就像散熱器一樣。',en:'The toucan\'s large beak is hollow and very light. It regulates body temperature like a radiator.'} },
    { id:'woodpecker',     emoji:'🐦', zh:'啄木鳥', en:'Woodpecker',        desc:{zh:'啄木鳥每秒可以啄木頭 20 次，是森林醫生！',en:'Woodpeckers peck 20 times per second — the forest\'s doctor!'},     detail:{zh:'啄木鳥的頭骨有特殊構造可以吸震，避免腦震盪。牠們的舌頭可以伸到嘴外 10 公分捉蟲。',en:'Woodpecker skulls have shock-absorbing structures. Their tongues extend 10cm beyond the bill to catch insects.'} },
    { id:'crane',          emoji:'🐦', zh:'丹頂鶴', en:'Red-crowned Crane', desc:{zh:'丹頂鶴頭頂有紅色皇冠，是長壽的象徵！',en:'Red-crowned cranes have red crowns and symbolize longevity!'},     detail:{zh:'丹頂鶴可以活到 60-80 歲。在日本和中國文化中，牠象徵長壽、忠誠和吉祥。牠是瀕危動物。',en:'Can live 60-80 years. In Japanese and Chinese culture symbolizes longevity, loyalty, and good fortune. Endangered.'} },
    { id:'albatross',      emoji:'🦅', zh:'信天翁', en:'Albatross',         desc:{zh:'信天翁翼展可達 3 公尺，能飛幾萬公里不降落！',en:'Albatrosses have 3m wingspans and can fly tens of thousands of km without landing!'},  detail:{zh:'信天翁可以在空中滑翔數年不著陸，利用海面的氣流飛行，幾乎不需要拍翅。',en:'Albatrosses glide for years without landing, exploiting ocean updrafts, rarely needing to flap.'} },
    { id:'hornbill',       emoji:'🐦', zh:'犀鳥',   en:'Great Hornbill',    desc:{zh:'犀鳥嘴巴上面有像頭盔的角質突起，非常特別！',en:'Hornbills have helmet-like casques on top of their beaks!'},     detail:{zh:'大犀鳥是東南亞原住民的神聖動物。雌鳥在孵蛋期間會把自己封在樹洞裡，只留一個小縫讓雄鳥餵食。',en:'The great hornbill is sacred to Southeast Asian indigenous peoples. Females seal themselves in tree cavities while nesting.'} },
    { id:'pelican',        emoji:'🐦', zh:'鵜鶘',   en:'Pelican',           desc:{zh:'鵜鶘嘴巴下面有個大袋子，可以裝魚！',en:'Pelicans have large throat pouches for storing fish!'},           detail:{zh:'鵜鶘的喉囊可以裝 11 公升的水和魚。牠們常常合作捕魚，圍成半圓形把魚趕到一起。',en:'Pelican pouches hold 11 liters of water and fish. They cooperate to herd fish, forming semicircles while hunting.'} },
    { id:'macaw',          emoji:'🦜', zh:'金剛鸚鵡', en:'Scarlet Macaw',   desc:{zh:'金剛鸚鵡有鮮豔的紅黃藍羽毛，是最美的鸚鵡！',en:'Scarlet macaws have vivid red, yellow, and blue feathers — the most colorful parrot!'},  detail:{zh:'金剛鸚鵡可以活到 75 歲。牠們會彼此梳羽表達感情，配對後終生在一起。',en:'Scarlet macaws can live 75 years. They preen each other as affection. Mated pairs stay together for life.'} },
    { id:'puffin',         emoji:'🐦', zh:'海鸚',   en:'Atlantic Puffin',   desc:{zh:'海鸚有橘黃色的嘴巴，是「海洋小丑」！',en:'Puffins have orange beaks and are called "sea clowns"!'},         detail:{zh:'海鸚可以在一口中含著多達 60 條小魚。牠們是出色的游泳和潛水者，能潛入 60 公尺深的海裡。',en:'Puffins can carry up to 60 small fish in one beak-full. Expert divers reaching 60 meters depth.'} },
    { id:'flamingo_bird',  emoji:'🦩', zh:'火烈鳥', en:'Flamingo',          desc:{zh:'火烈鳥全身粉紅，單腳站立是牠的招牌！',en:'Flamingos are all-pink and their one-leg stance is iconic!'},      detail:{zh:'科學家認為火烈鳥單腳站立是為了省力，減少體熱散失。剛孵化的火烈鳥是灰白色的。',en:'Scientists believe one-legged standing conserves energy and reduces heat loss. Hatchlings are grayish-white.'} },
    { id:'barn_owl',       emoji:'🦉', zh:'倉鴞',   en:'Barn Owl',          desc:{zh:'倉鴞有心形臉，在黑暗中也能定位獵物！',en:'Barn owls have heart-shaped faces and can locate prey in total darkness!'},  detail:{zh:'倉鴞靠聲音就能在完全黑暗中定位獵物。牠們的心形面盤像衛星天線一樣收集聲音。',en:'Barn owls locate prey by sound alone in total darkness. Their heart-shaped face acts like a satellite dish.'} },
    { id:'secretary_bird', emoji:'🦅', zh:'蛇鷲',   en:'Secretarybird',     desc:{zh:'蛇鷲是用腳踢死眼鏡蛇的鳥！',en:'The secretarybird kicks cobras to death with its powerful legs!'},  detail:{zh:'蛇鷲的踢力極強，相當於自身體重的五倍。牠站在地上獵蛇，是非洲草原的特別鳥類。',en:'Secretarybird kicks with force 5x its body weight. It hunts snakes on foot across African savannas.'} }
  ],
  ocean: [
    { id:'dolphin',    emoji:'🐬', zh:'海豚',   en:'Dolphin',            desc:{zh:'海豚非常聰明，會用超聲波和同伴溝通！',en:'Dolphins are very smart and communicate with ultrasound!'},        detail:{zh:'海豚有名字！每隻海豚都有獨特的口哨聲，就像名字一樣。牠們的智商僅次於人類和某些靈長類。',en:'Dolphins have names! Each has a unique signature whistle. Their intelligence ranks just below humans and some primates.'} },
    { id:'whale',      emoji:'🐋', zh:'藍鯨',   en:'Blue Whale',         desc:{zh:'藍鯨是地球上有史以來最大的動物！',en:'The blue whale is the largest animal that has ever lived on Earth!'},  detail:{zh:'藍鯨的心臟和一輛小轎車一樣大，體重可達 200 公噸。藍鯨的叫聲是地球上最響的動物聲音之一。',en:'Blue whale hearts are car-sized, weighing up to 200 tonnes. Their calls are among the loudest animal sounds on Earth.'} },
    { id:'shark',      emoji:'🦈', zh:'鯊魚',   en:'Shark',              desc:{zh:'鯊魚牙齒會一直換，一生可以長 20000 顆牙！',en:'Sharks continuously regrow teeth — up to 20,000 in a lifetime!'},  detail:{zh:'鯊魚在地球上存在了 4 億年，比恐龍還早 2 億年。牠們能感應到 1 公里外的血腥味。',en:'Sharks have existed 400 million years — 200 million years before dinosaurs. They can detect blood 1km away.'} },
    { id:'octopus',    emoji:'🐙', zh:'章魚',   en:'Octopus',            desc:{zh:'章魚有八條手臂，非常聰明，會開罐子！',en:'Octopuses have eight arms, are very smart, and can open jars!'},   detail:{zh:'章魚有三個心臟和藍色的血液。牠們能在幾秒鐘內改變皮膚顏色和質地偽裝。死後器官會繼續動。',en:'Octopuses have 3 hearts and blue blood. They change skin color and texture in seconds for camouflage.'} },
    { id:'sea_turtle', emoji:'🐢', zh:'海龜',   en:'Sea Turtle',         desc:{zh:'海龜可以活超過 100 年，每年回到出生的海灘！',en:'Sea turtles live over 100 years and return to their birth beach!'},  detail:{zh:'海龜靠地球磁場來導航，可以穿越整個大洋回到出生地。牠們在地球上存在了超過 1 億年。',en:'Sea turtles navigate using Earth\'s magnetic field, crossing entire oceans. They\'ve existed on Earth for 100+ million years.'} },
    { id:'jellyfish',  emoji:'🪼', zh:'水母',   en:'Jellyfish',          desc:{zh:'水母沒有腦袋和骨頭，身體幾乎是水！',en:'Jellyfish have no brain or bones — they\'re almost all water!'},    detail:{zh:'水母沒有腦、心臟和骨骼。有一種「燈塔水母」被稱為「不死生物」，因為它可以不斷循環回到幼體狀態。',en:'Jellyfish have no brain, heart, or bones. The immortal jellyfish can revert to its juvenile form indefinitely.'} },
    { id:'starfish',   emoji:'⭐', zh:'海星',   en:'Starfish',           desc:{zh:'海星失去觸手後可以再長出來！',en:'Starfish can regrow their arms after losing them!'},              detail:{zh:'海星有驚人的再生能力，一個觸手可以長成一整隻新的海星。牠們有數百隻腳，靠水壓移動。',en:'A single arm can regenerate into a whole new starfish. They have hundreds of tube feet moved by water pressure.'} },
    { id:'crab',       emoji:'🦀', zh:'螃蟹',   en:'Crab',               desc:{zh:'螃蟹橫著走路，有強壯的大螯！',en:'Crabs walk sideways and have powerful claws!'},                  detail:{zh:'螃蟹是唯一橫著走路的動物之一。牠們的殼會定期蛻去更換，此時螃蟹非常脆弱。',en:'Crabs are among the few animals that walk sideways. They periodically shed their shells to grow new ones.'} },
    { id:'lobster',    emoji:'🦞', zh:'龍蝦',   en:'Lobster',            desc:{zh:'龍蝦可以活很久，越老越有力！',en:'Lobsters can live very long lives and get stronger with age!'},   detail:{zh:'龍蝦沒有固定的壽命，理論上可以永遠生長。已知最老的龍蝦超過 140 歲。牠們會換殼，每次換殼都更大。',en:'Lobsters have no fixed lifespan — theoretically growing forever. The oldest known was 140+ years. They grow with each molt.'} },
    { id:'seahorse',   emoji:'🌊', zh:'海馬',   en:'Seahorse',           desc:{zh:'海馬是由爸爸生小孩的特別動物！',en:'Seahorses are special — fathers give birth to the babies!'},     detail:{zh:'雄海馬有育兒袋，雌海馬把卵產進去，由雄海馬懷孕生產。一次可以生出 2000 隻小海馬！',en:'Male seahorses have brood pouches. Females deposit eggs inside and males carry the pregnancy — birthing up to 2,000 young!'} },
    { id:'manta_ray',  emoji:'🌊', zh:'魟魚',   en:'Manta Ray',          desc:{zh:'魟魚像在水中飛翔，有巨大的翼！',en:'Manta rays seem to fly underwater with enormous wings!'},         detail:{zh:'大型魟魚翼展可達 7 公尺，是最大的魚類之一。牠們每天跳出水面，原因科學家還未完全了解。',en:'Giant mantas have 7m wingspans. They leap from the water regularly — scientists don\'t fully understand why.'} },
    { id:'clownfish',  emoji:'🐠', zh:'小丑魚', en:'Clownfish',          desc:{zh:'小丑魚住在海葵裡面，互相保護！',en:'Clownfish live in sea anemones — they protect each other!'},     detail:{zh:'小丑魚身上有特殊黏液，讓牠們不會被海葵刺傷。有趣的是，所有小丑魚出生時都是雄性。',en:'Clownfish have special mucus preventing anemone stings. Interestingly, all clownfish are born male.'} },
    { id:'sea_lion',   emoji:'🦭', zh:'海獅',   en:'Sea Lion',           desc:{zh:'海獅很聰明，可以學雜技！',en:'Sea lions are intelligent and can learn acrobatic tricks!'},       detail:{zh:'海獅是少數能在陸地上使用後鰭行走的鰭腳類動物。牠們的記憶力非常好，可以記住訓練超過 10 年。',en:'Sea lions are among few pinnipeds that can use their hind flippers to "walk" on land. Memory persists for 10+ years.'} },
    { id:'orca',       emoji:'🐋', zh:'虎鯨',   en:'Orca',               desc:{zh:'虎鯨是黑白色的，也叫殺人鯨，但其實很聰明！',en:'Orcas are black and white — called killer whales but are highly intelligent!'},  detail:{zh:'虎鯨有家族文化，不同族群有不同的方言和獵捕技術，代代相傳。牠們是海洋頂級掠食者。',en:'Orcas have family cultures with dialects and hunting techniques passed down through generations. Apex predators.'} },
    { id:'seal',       emoji:'🦭', zh:'海豹',   en:'Harbor Seal',        desc:{zh:'海豹有可愛的大眼睛，游泳超快！',en:'Harbor seals have big cute eyes and are very fast swimmers!'},   detail:{zh:'海豹的眼睛很大，適合在水下昏暗的環境中看東西。牠們可以在水下憋氣長達 30 分鐘。',en:'Seal eyes are large for seeing in dim underwater environments. They can hold their breath for up to 30 minutes.'} },
    { id:'pufferfish', emoji:'🐡', zh:'河豚',   en:'Pufferfish',         desc:{zh:'河豚受到威脅時會膨脹成球！有毒！',en:'Pufferfish inflate into a ball when threatened — and are toxic!'},  detail:{zh:'河豚含有的河豚毒素比氰化物毒 1200 倍，沒有解毒劑。但日本廚師在嚴格訓練後可以料理河豚。',en:'Pufferfish toxin is 1,200 times more toxic than cyanide. No antidote. Japanese chefs train years to prepare it safely.'} },
    { id:'lionfish',   emoji:'🐟', zh:'獅子魚', en:'Lionfish',           desc:{zh:'獅子魚有美麗的條紋和毒刺！',en:'Lionfish have beautiful stripes and venomous spines!'},          detail:{zh:'獅子魚是太平洋和印度洋的原生魚類，被引入大西洋後成為入侵物種，對當地生態造成嚴重破壞。',en:'Native to Pacific and Indian Oceans, introduced to the Atlantic where it became an invasive species, devastating ecosystems.'} },
    { id:'eel',        emoji:'🐍', zh:'海鰻',   en:'Moray Eel',          desc:{zh:'海鰻住在岩石縫隙裡，有兩排牙齒！',en:'Moray eels hide in rock crevices and have two sets of teeth!'},  detail:{zh:'海鰻有兩副顎，外層顎咬住獵物，內層顎往後拉入喉嚨，就像電影《異形》一樣。',en:'Morays have two sets of jaws: outer jaws bite prey, inner "pharyngeal" jaws drag it inward — like the movie Alien.'} },
    { id:'blue_tang',  emoji:'🐠', zh:'藍刀魚', en:'Blue Tang',          desc:{zh:'藍刀魚是亮藍色的，就是多莉！',en:'Blue tangs are bright blue — they\'re Dory from Finding Nemo!'},  detail:{zh:'藍刀魚尾部有鋒利的刺可以防衛自己。牠們在礁石上吃藻類，是維持珊瑚礁健康的重要角色。',en:'Blue tangs have sharp spines at their tail for defense. They eat algae off reefs, crucial for reef health.'} },
    { id:'sea_horse',  emoji:'🌊', zh:'海馬',   en:'Dwarf Seahorse',     desc:{zh:'迷你海馬是世界上游得最慢的魚！',en:'Dwarf seahorses are the slowest fish in the world!'},          detail:{zh:'侏儒海馬每小時只能游 1.5 公尺，是金氏世界紀錄認定游得最慢的魚。牠們用背鰭的快速搖動游泳。',en:'Dwarf seahorses swim just 1.5m per hour — Guinness World Record\'s slowest fish. They use rapid dorsal fin vibration.'} }
  ]
};
// <!-- #END:PAGE-ZOO-DATA -->
```

- [ ] **Step 2: Commit animal data**

```bash
git add kids-companion/index.html
git commit -m "feat: zoo animal data (6 categories, 120 animals)"
```

---

## Task 5: Add Zoo JS Logic

**Files:**
- Modify: `kids-companion/index.html` — add after zoo data block, before `// <!-- #SECTION:PAGE-MONEY-JS -->`

- [ ] **Step 1: Add zoo state and shelf function**

```javascript
// <!-- #SECTION:PAGE-ZOO-JS -->
var zooState = {
  currentCategory: null,
  currentIdx: 0,
  quizPending: false,
  quizActive: false
};

function showZooShelf() {
  zooState.currentCategory = null;
  zooState.currentIdx = 0;
  var shelf = document.getElementById('zoo-shelf');
  var browse = document.getElementById('zoo-browse');
  var quiz = document.getElementById('zoo-quiz');
  var complete = document.getElementById('zoo-complete');
  if (shelf) shelf.style.display = '';
  if (browse) browse.style.display = 'none';
  if (quiz) quiz.style.display = 'none';
  if (complete) complete.classList.remove('show');
  document.getElementById('zoo-title').textContent = '🦁 動物園';
  document.getElementById('zoo-progress-label').textContent = '';
  document.getElementById('zoo-back-btn').onclick = function() { navigateTo('page-home'); };
  renderZooShelf();
}

function renderZooShelf() {
  var grid = document.getElementById('zoo-category-grid');
  if (!grid) return;
  var lang = APP.language || 'zh';
  var html = '';
  ANIMAL_CATEGORIES.forEach(function(cat) {
    var count = (ANIMALS[cat.id] || []).length;
    html += '<div class="zoo-category-card" onclick="openZooCategory(\'' + cat.id + '\')">';
    html += '<span class="zoo-category-icon">' + cat.emoji + '</span>';
    html += '<div class="zoo-category-name">' + cat.name[lang] + '</div>';
    html += '<div class="zoo-category-count">' + count + ' 種動物</div>';
    html += '</div>';
  });
  grid.innerHTML = html;
}

function zooBack() {
  if (zooState.currentCategory) {
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    showZooShelf();
  } else {
    navigateTo('page-home');
  }
}

function zooBackToShelf() {
  if ('speechSynthesis' in window) speechSynthesis.cancel();
  var complete = document.getElementById('zoo-complete');
  if (complete) complete.classList.remove('show');
  showZooShelf();
}

function zooRestart() {
  var complete = document.getElementById('zoo-complete');
  if (complete) complete.classList.remove('show');
  zooState.currentIdx = 0;
  zooState.quizPending = false;
  zooState.quizActive = false;
  showZooBrowse();
}
```

- [ ] **Step 2: Add openZooCategory and browse rendering**

```javascript
function openZooCategory(catId) {
  var cat = null;
  for (var i = 0; i < ANIMAL_CATEGORIES.length; i++) {
    if (ANIMAL_CATEGORIES[i].id === catId) { cat = ANIMAL_CATEGORIES[i]; break; }
  }
  if (!cat) return;
  zooState.currentCategory = catId;
  zooState.currentIdx = 0;
  zooState.quizPending = false;
  zooState.quizActive = false;

  var lang = APP.language || 'zh';
  document.getElementById('zoo-title').textContent = cat.emoji + ' ' + cat.name[lang];
  document.getElementById('zoo-back-btn').onclick = function() { showZooShelf(); };

  var shelf = document.getElementById('zoo-shelf');
  if (shelf) shelf.style.display = 'none';
  showZooBrowse();
}

function showZooBrowse() {
  var browse = document.getElementById('zoo-browse');
  var quiz = document.getElementById('zoo-quiz');
  if (browse) browse.style.display = '';
  if (quiz) quiz.style.display = 'none';
  zooState.quizActive = false;
  renderZooCard();
}

function renderZooCard() {
  var animals = ANIMALS[zooState.currentCategory] || [];
  var idx = zooState.currentIdx;
  var animal = animals[idx];
  if (!animal) return;

  var lang = APP.language || 'zh';
  var ag = APP.ageGroup;
  var isSmall = (ag === 'toddler' || ag === 'small');
  var isLarge = (ag === 'large');

  // Progress
  var total = animals.length;
  document.getElementById('zoo-progress-label').textContent = (idx + 1) + '/' + total;
  document.getElementById('zoo-browse-progress').textContent = (idx + 1) + ' / ' + total;

  // Nav buttons
  var prevBtn = document.getElementById('zoo-prev-btn');
  var nextBtn = document.getElementById('zoo-next-btn');
  if (prevBtn) prevBtn.style.display = idx === 0 ? 'none' : '';
  if (nextBtn) nextBtn.textContent = idx === total - 1 ? '完成 ✓' : '下一隻 →';

  // Build card HTML
  var imgSrc = (typeof IMG !== 'undefined' && IMG['zoo-' + animal.id]) ? IMG['zoo-' + animal.id] : '';
  var photoClass = isSmall ? 'zoo-animal-photo-large' : 'zoo-animal-photo';
  var html = '';

  if (imgSrc) {
    html += '<img src="' + imgSrc + '" class="' + photoClass + '" alt="' + animal[lang] + '" onclick="zooSpeak()" style="cursor:pointer">';
  } else {
    html += '<div class="' + photoClass + '" onclick="zooSpeak()" style="display:flex;align-items:center;justify-content:center;background:#f0ebe3;cursor:pointer;font-size:80px">' + animal.emoji + '</div>';
  }

  html += '<div class="zoo-animal-name" onclick="zooSpeak()" style="cursor:pointer">' + animal[lang] + '</div>';

  if (!isSmall) {
    html += '<div class="zoo-animal-name-en">' + animal.en + '</div>';
  }

  if (!isSmall && animal.desc) {
    html += '<div class="zoo-animal-desc">' + animal.desc[lang] + '</div>';
  }

  if (isLarge && animal.detail) {
    html += '<div class="zoo-animal-detail">' + animal.detail[lang] + '</div>';
  }

  document.getElementById('zoo-browse-card').innerHTML = html;

  // Auto-speak for toddler/small
  if (isSmall) {
    setTimeout(function() { zooSpeak(); }, 400);
  }
}

function zooSpeak() {
  var animals = ANIMALS[zooState.currentCategory] || [];
  var animal = animals[zooState.currentIdx];
  if (!animal) return;
  var lang = APP.language || 'zh';
  var ag = APP.ageGroup;
  var isSmall = (ag === 'toddler' || ag === 'small');
  var text = animal[lang];
  if (!isSmall && animal.desc) text += '。' + animal.desc[lang];
  if ('speechSynthesis' in window) {
    speechSynthesis.cancel();
    var u = new SpeechSynthesisUtterance(text);
    u.lang = lang === 'zh' ? 'zh-TW' : 'en-US';
    u.rate = 0.85; u.pitch = 1.2;
    speechSynthesis.speak(u);
  }
}

function zooPrev() {
  if (zooState.currentIdx > 0) {
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    zooState.currentIdx--;
    renderZooCard();
  }
}

function zooNext() {
  var animals = ANIMALS[zooState.currentCategory] || [];
  var ag = APP.ageGroup;
  var isSmall = (ag === 'toddler' || ag === 'small');
  if ('speechSynthesis' in window) speechSynthesis.cancel();

  // Check if quiz should trigger (every 5 animals for middle/large)
  var nextIdx = zooState.currentIdx + 1;
  var shouldQuiz = !isSmall && nextIdx % 5 === 0 && nextIdx < animals.length;

  if (nextIdx >= animals.length) {
    // End of category
    if (!isSmall && !zooState.quizPending) {
      zooState.quizPending = true;
      startZooQuiz();
    } else {
      showZooComplete();
    }
  } else if (shouldQuiz) {
    zooState.currentIdx = nextIdx;
    zooState.quizPending = true;
    startZooQuiz();
  } else {
    zooState.currentIdx = nextIdx;
    renderZooCard();
  }
}
```

- [ ] **Step 3: Add quiz logic**

```javascript
function startZooQuiz() {
  var browse = document.getElementById('zoo-browse');
  var quiz = document.getElementById('zoo-quiz');
  if (browse) browse.style.display = 'none';
  if (quiz) quiz.style.display = '';
  zooState.quizActive = true;

  var animals = ANIMALS[zooState.currentCategory] || [];
  var ag = APP.ageGroup;
  var isLarge = (ag === 'large');
  var numChoices = isLarge ? 4 : 2;
  var lang = APP.language || 'zh';

  // Pick question animal (current - 1 since we already advanced)
  var qIdx = zooState.currentIdx - 1;
  if (qIdx < 0) qIdx = 0;
  var qAnimal = animals[qIdx];

  // Build distractors (random animals from same category, different from answer)
  var distractors = [];
  var pool = animals.filter(function(a) { return a.id !== qAnimal.id; });
  var shuffled = pool.slice().sort(function() { return Math.random() - 0.5; });
  distractors = shuffled.slice(0, numChoices - 1);

  var choices = [qAnimal].concat(distractors).sort(function() { return Math.random() - 0.5; });

  // Get image for question
  var imgSrc = (typeof IMG !== 'undefined' && IMG['zoo-' + qAnimal.id]) ? IMG['zoo-' + qAnimal.id] : '';
  var html = '<div class="zoo-quiz-question">' + (lang === 'zh' ? '這是什麼動物？' : 'What animal is this?') + '</div>';

  if (imgSrc) {
    html += '<div style="text-align:center;margin-bottom:16px"><img src="' + imgSrc + '" style="width:min(200px,60vw);height:min(200px,60vw);object-fit:cover;border-radius:16px" alt="?"></div>';
  } else {
    html += '<div style="text-align:center;font-size:80px;margin-bottom:16px">' + qAnimal.emoji + '</div>';
  }

  html += '<div class="zoo-quiz-choices choices-' + numChoices + '">';
  choices.forEach(function(c) {
    html += '<button class="zoo-quiz-btn" onclick="zooQuizAnswer(this,' + (c.id === qAnimal.id ? 'true' : 'false') + ',\'' + qAnimal.id + '\')">' + c[lang] + '</button>';
  });
  html += '</div>';

  document.getElementById('zoo-quiz-area').innerHTML = html;

  // Speak question
  if ('speechSynthesis' in window) {
    speechSynthesis.cancel();
    var u = new SpeechSynthesisUtterance(lang === 'zh' ? '這是什麼動物？' : 'What animal is this?');
    u.lang = lang === 'zh' ? 'zh-TW' : 'en-US';
    u.rate = 0.85; u.pitch = 1.2;
    speechSynthesis.speak(u);
  }
}

function zooQuizAnswer(btn, isCorrect, correctId) {
  // Disable all buttons
  var area = document.getElementById('zoo-quiz-area');
  var btns = area.querySelectorAll('.zoo-quiz-btn');
  btns.forEach(function(b) { b.disabled = true; });

  var lang = APP.language || 'zh';
  var animals = ANIMALS[zooState.currentCategory] || [];
  var correctAnimal = null;
  for (var i = 0; i < animals.length; i++) {
    if (animals[i].id === correctId) { correctAnimal = animals[i]; break; }
  }

  if (isCorrect) {
    btn.classList.add('correct');
    playCorrectSound();
    if ('speechSynthesis' in window) {
      speechSynthesis.cancel();
      var msg = lang === 'zh' ? '答對了！是' + correctAnimal.zh + '！' : 'Correct! It\'s a ' + correctAnimal.en + '!';
      var u = new SpeechSynthesisUtterance(msg);
      u.lang = lang === 'zh' ? 'zh-TW' : 'en-US';
      u.rate = 0.85; u.pitch = 1.2;
      speechSynthesis.speak(u);
    }
    setTimeout(function() { zooAfterQuiz(); }, 1500);
  } else {
    btn.classList.add('wrong');
    playWrongSound();
    // Highlight correct answer
    btns.forEach(function(b) {
      if (b.textContent === (correctAnimal ? correctAnimal[lang] : '')) b.classList.add('correct');
    });
    if ('speechSynthesis' in window) {
      speechSynthesis.cancel();
      var msg2 = lang === 'zh' ? '哎呀，再試一次！是' + correctAnimal.zh + '喔！' : 'Oops! It\'s a ' + correctAnimal.en + '!';
      var u2 = new SpeechSynthesisUtterance(msg2);
      u2.lang = lang === 'zh' ? 'zh-TW' : 'en-US';
      u2.rate = 0.85; u2.pitch = 1.2;
      speechSynthesis.speak(u2);
    }
    setTimeout(function() { zooAfterQuiz(); }, 2000);
  }
}

function zooAfterQuiz() {
  zooState.quizPending = false;
  var animals = ANIMALS[zooState.currentCategory] || [];
  if (zooState.currentIdx >= animals.length) {
    showZooComplete();
  } else {
    showZooBrowse();
  }
}

function showZooComplete() {
  if ('speechSynthesis' in window) speechSynthesis.cancel();
  showCompleteScreen('zoo-complete');
  completeActivity('page-zoo');
}
// <!-- #END:PAGE-ZOO-JS -->
```

- [ ] **Step 4: Wire up navigateTo — add zoo shelf init**

Find the `navigateTo` function (around line containing `if (pageId === 'page-rhymes') showRhymesShelf();`) and add:

```javascript
if (pageId === 'page-zoo') showZooShelf();
```

- [ ] **Step 5: Commit JS logic**

```bash
git add kids-companion/index.html
git commit -m "feat: zoo activity JS — browse, quiz, age-adaptive modes"
```

---

## Task 6: Wire Up Home Page

**Files:**
- Modify: `kids-companion/index.html` — `#SECTION:PAGE-HOME` (探索 tab)

- [ ] **Step 1: Find explore tab content**

```bash
grep -n "tab-explore\|page-zoo\|動物園\|PAGE-HOME" kids-companion/index.html | head -20
```

- [ ] **Step 2: Add zoo activity card to explore tab**

Find the `<div class="tab-content" id="tab-explore">` section and add the zoo card:

```html
<div class="activity-card" onclick="navigateTo('page-zoo')">
  <span class="activity-icon">🦁</span>
  <span class="label">動物園</span>
</div>
```

- [ ] **Step 3: Add sticker slot for zoo**

Find the sticker grid (around `<div class="sticker-slot locked" data-sticker=`) and add:

```html
<div class="sticker-slot locked" data-sticker="page-zoo">🦁</div>
```

- [ ] **Step 4: Commit home page wiring**

```bash
git add kids-companion/index.html
git commit -m "feat: add zoo to explore tab and sticker board"
```

---

## Task 7: Final Test & Push

- [ ] **Step 1: Open in browser and verify**

Open `kids-companion/index.html` in a browser. Check:
- [ ] Zoo appears in 探索 tab
- [ ] Category shelf shows 6 categories with correct animal counts
- [ ] Clicking a category shows browse cards
- [ ] Photos display (or emoji fallback if images not yet embedded)
- [ ] Tap/click on card speaks animal name
- [ ] Prev/next navigation works
- [ ] Quiz triggers every 5 animals (middle/large age groups)
- [ ] toddler/small: no quiz, auto-speaks on each card
- [ ] Complete screen shows after viewing all animals
- [ ] "再看一次" replays from start; "換分類" returns to shelf

- [ ] **Step 2: Final commit and push**

```bash
git add kids-companion/index.html
git commit -m "feat: 動物園 activity — 6 categories, 120 animals, age-adaptive"
git push
```
