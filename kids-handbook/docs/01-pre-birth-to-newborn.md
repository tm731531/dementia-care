# 01 · 備孕 → 新生兒（Tab 1）

> ⏳ **Phase 2 待遷入** — 內容從 `~/Desktop/dementia-care/newborn-handbook/index.html` 遷過來。

## 預計內容（來源：原 newborn-handbook）

### 🌱 孕前
- 健康檢查
- 懷孕日記
- 後援評估（特別三明治世代）

### 🤰 孕中（40 週）
- 10 種胎教
- 14 次產檢時程（8w-40w）
- 飲食指南（含子宮肌瘤患者特別注意）
- 月中 / 後援規劃決策樹

### 🎒 產前
- 家中物品 + 待產包 4 類 checklist（資料 / 日常 / 媽媽 / 可有可無）

### 💪 產後
- 自然產 5 點 / 剖腹產 8 點恢復重點

### 👨‍👧 出生後爸爸 5 步政府表單
- 戶政 → 區公所 → 公司 → 銀行 → 保險

### 🤱 母乳 / 配方乳
- 增加母乳 4 招
- 配方乳選擇

### 🏫 托嬰中心比較
- Tom 家土城 6 家公托/準公對比範例（接續 Tab 2 toddler 段）

---

## 風格：SOP-first

- 時間表 + 最安全預設 + 法規條件
- evidence-based（hpa.gov 公告、各縣市政府網站）
- **失敗條件顯眼**：過了報名 / 補助截止這類「全盤失敗」前提必須放動作前

## Phase 2 遷移注意

- 保留所有政府網站 / 法規連結
- localStorage migration：`newbornState` → 合進 `kidsHandbookState.tab1`
- 原 `newborn-handbook/index.html` archive 後加跳轉到本 tab 對應錨點

## 三明治世代特別考量

每章如有「家有失智長輩需特別注意」段落，保留並擴充到 `04-cross-stage/sandwich-generation.md`。
