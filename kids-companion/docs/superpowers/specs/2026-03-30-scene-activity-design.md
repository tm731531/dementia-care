# 場景佈置活動 設計文件

## 目標

新增「場景佈置」活動（`page-scene`），讓 2–6 歲兒童選擇場景背景，從素材庫點擊放置並拖動調整位置，自由或任務式地佈置場景。這是「開放式創造」型活動。

## 架構

```
進入活動
  → 選場景（草地🌿 / 海邊🏖️ / 森林🌲）
  → 從素材列點擊放入場景 → 可拖動調整位置
  → 按「完成！」→ 回饋畫面 → 完成
```

## 三個場景 × 素材

### 草地🌿（12 種）

| ID | 中文 | 英文 | 類型 |
|----|------|------|------|
| sunflower | 向日葵 | Sunflower | plant |
| rose | 玫瑰 | Rose | plant |
| tulip | 鬱金香 | Tulip | plant |
| daisy | 雛菊 | Daisy | plant |
| oak_tree | 橡樹 | Oak tree | plant |
| cherry_blossom | 櫻花樹 | Cherry blossom | plant |
| rabbit | 兔子 | Rabbit | animal |
| butterfly | 蝴蝶 | Butterfly | animal |
| ladybug | 瓢蟲 | Ladybug | animal |
| sparrow | 小鳥 | Sparrow | animal |
| fence | 柵欄 | Fence | object |
| cottage | 小屋 | Cottage | object |

### 海邊🏖️（12 種）

| ID | 中文 | 英文 | 類型 |
|----|------|------|------|
| seashell | 貝殼 | Seashell | object |
| crab | 螃蟹 | Crab | animal |
| starfish | 海星 | Starfish | animal |
| tropical_fish | 熱帶魚 | Tropical fish | animal |
| dolphin | 海豚 | Dolphin | animal |
| coconut_tree | 椰子樹 | Coconut tree | plant |
| sailboat | 帆船 | Sailboat | object |
| lighthouse | 燈塔 | Lighthouse | object |
| seagull | 海鷗 | Seagull | animal |
| coral | 珊瑚 | Coral | plant |
| jellyfish | 水母 | Jellyfish | animal |
| octopus_s | 章魚 | Octopus | animal |

### 森林🌲（12 種）

| ID | 中文 | 英文 | 類型 |
|----|------|------|------|
| pine_tree | 松樹 | Pine tree | plant |
| mushroom_s | 蘑菇 | Mushroom | plant |
| squirrel | 松鼠 | Squirrel | animal |
| deer | 鹿 | Deer | animal |
| owl | 貓頭鷹 | Owl | animal |
| log_cabin | 木屋 | Log cabin | object |
| stream | 溪流 | Stream | object |
| fern | 蕨類 | Fern | plant |
| woodpecker | 啄木鳥 | Woodpecker | animal |
| hedgehog | 刺蝟 | Hedgehog | animal |
| acorn | 橡實 | Acorn | object |
| waterfall | 瀑布 | Waterfall | object |

## 年齡分級

### toddler — 自由擺放 + 角色回饋

- 素材列顯示 8 種（從該場景 12 種中隨機抽取）
- 最多放 6 樣
- 點擊素材 → 出現在場景中央附近（隨機偏移）→ 可拖動
- 按「完成！」→ 🦊「好漂亮的場景！」純正面鼓勵
- 語音自動念素材名稱

### small — 自由擺放 + 數量回饋

- 素材列顯示 10 種
- 最多放 8 樣
- 同 toddler 操作
- 回饋：🦊 + 「你放了 N 樣東西，好豐富！」
- 語音念名稱

### middle — 任務模式 + 簡單回饋

- 素材列顯示 12 種（全部）
- 最多放 10 樣
- 系統出任務，例如：
  - 「請在草地上放 3 棵植物和 2 隻動物」
  - 「請在海邊放至少 2 樣不同的動物」
  - 「請在森林裡放 1 間房子和 3 棵樹」
- 按「完成！」→ 檢查是否滿足 → 成功/提示
- 語音朗讀任務文字

### large — 複雜任務 + 星星評分

- 素材列顯示 12 種（全部）
- 最多放 12 樣
- 任務更複雜：
  - 「至少放 3 種不同類型的東西，總共 5 樣以上」
  - 「放 2 隻動物、2 棵植物和 1 個物件」
- 評分：
  - 未達標：⭐（1 星）+ 提示
  - 剛好達標：⭐⭐（2 星）
  - 超過（多放或多類型）：⭐⭐⭐（3 星）+ 慶祝動畫
- 只朗讀任務，不念選項

## 任務池

### 草地任務

| 任務文字 | 條件 |
|---------|------|
| 在草地上種 3 朵花 🌸 | plant >= 3 |
| 放 2 隻小動物到草地上 | animal >= 2 |
| 佈置一個有花、有動物、有房子的草地 | plant >= 1, animal >= 1, object >= 1 |
| 放 5 樣東西讓草地變熱鬧 | total >= 5 |

### 海邊任務

| 任務文字 | 條件 |
|---------|------|
| 放 3 隻海洋動物到海邊 | animal >= 3 |
| 佈置一個有椰子樹和帆船的海邊 | 需含 coconut_tree 和 sailboat |
| 放 2 棵植物和 2 隻動物 | plant >= 2, animal >= 2 |
| 放 5 樣東西讓海邊變熱鬧 | total >= 5 |

### 森林任務

| 任務文字 | 條件 |
|---------|------|
| 種 3 棵樹在森林裡 🌲 | plant >= 3 |
| 放 2 隻森林動物 | animal >= 2 |
| 蓋一間木屋，旁邊放樹和動物 | 需含 log_cabin, plant >= 1, animal >= 1 |
| 放 5 樣東西讓森林變熱鬧 | total >= 5 |

middle 從對應場景的任務池隨機抽 1 題。large 抽條件最複雜的（第 3 或第 4 題）。

## 操作方式

### 點擊放置
- 點擊素材列中的圖片 → 素材出現在場景區中央附近（隨機偏移 ±30px）
- 帶 pop 動畫（同餐盤）
- 再次點擊已放置的同一素材 → 從場景移除

### 拖動調整
- 場景區內的素材可拖動（pointer events，支援觸控）
- 拖動時素材稍微放大（scale 1.1）
- 放開後回到 scale 1.0

## UI 結構

### 場景選擇

```
[← 返回]  🎨 場景佈置

  ┌──────┐  ┌──────┐  ┌──────┐
  │  🌿  │  │  🏖️  │  │  🌲  │
  │ 草地  │  │ 海邊  │  │ 森林  │
  └──────┘  └──────┘  └──────┘
```

### 佈置畫面

```
[← 返回]  🌿 草地   [3/6]

  ┌─────────────────┐
  │                 │  ← 場景區（背景色漸層）
  │   🌻    🐰     │     素材可拖動
  │      🌷        │
  └─────────────────┘

  [🌻] [🌹] [🐰] [🦋] ...  ← 素材列（可捲動）

       [ 完成！✨ ]
```

## 場景背景

用 CSS 漸層，不需要圖片：
- 草地：`linear-gradient(180deg, #87CEEB 40%, #90EE90 40%)`（天空 + 草地）
- 海邊：`linear-gradient(180deg, #87CEEB 35%, #F5DEB3 35%, #F5DEB3 50%, #4169E1 50%)`（天空 + 沙灘 + 海）
- 森林：`linear-gradient(180deg, #6B8E6B 30%, #2E4E2E 30%)`（淺綠樹冠 + 深綠地面）

## 圖片來源

Wikipedia Commons，與動物園/食物相同方法：
- Wikipedia thumbnail API（200px）
- 轉 base64，存入 `#SECTION:IMAGES-SCENE` 區塊（檔案末尾）
- 使用 `Object.assign(IMG, { 'scene-sunflower': '...', ... })`
- 無法取得圖片時 fallback 為 emoji

## 語音規則

- toddler/small：點擊放置時自動念素材名稱；回饋完整朗讀
- middle：進入時朗讀任務文字；回饋朗讀
- large：只朗讀任務；回饋朗讀評語

## 遊戲化整合

- 完成活動：`completeActivity('page-scene')` → +1 星星
- 貼紙：🎨
- 首頁探索 tab 加入活動卡片

## 程式架構

| 區塊 | 錨點 |
|------|------|
| HTML 頁面 | `#SECTION:PAGE-SCENE` |
| 素材資料 | `#SECTION:PAGE-SCENE-DATA` |
| JS 邏輯 | `#SECTION:PAGE-SCENE-JS` |
| 圖片資料 | `#SECTION:IMAGES-SCENE`（檔案末尾） |

## 不在範圍內

- 場景儲存/匯出/截圖
- 素材縮放或旋轉
- 多圖層（所有素材同一層）
- 音效（只有語音）
