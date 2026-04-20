# health-drinks — CLAUDE.md

## 專案概述

市售健康/營養飲品成分分析網站，容量範圍 180–280ml。
部署於 GitHub Pages（`/docs` 資料夾）。隸屬上層 `dementia-care` 專案，
主要用途：幫助照護者快速比較市售飲品的熱量、糖分、鈉、蛋白質等成分。

## Domain Brain

> 讀這些再動工：`~/.claude/projects/-home-tom/memory/brain/`

- `health-drinks-data-entry.md` — **⚠️ 必讀** 飲品資料錄入原則、踩坑紀錄、欄位命名規範
- `design-principles.md` — 前端元件設計原則
- `python-crawler-data.md` — 爬蟲 / 資料處理注意事項（scripts/scraper.py）

## Domain Skill

> 無特定 iDempiere/後端 skill。前端實作直接按 design-principles。

## 技術棧

| 層級 | 技術 |
|------|------|
| UI | 單頁 HTML + Vanilla CSS + Vanilla JS |
| 圖表 | Chart.js 4 (CDN) |
| 字型 | Noto Sans TC (Google Fonts CDN) |
| 部署 | GitHub Pages (`/docs`) |
| 資料 | HARDCODE 於 `docs/index.html` 的 `DRINKS` 陣列 |
| 圖片 | `docs/images/` 本地靜態檔 |
| 爬蟲 | `scripts/scraper.py`（離線工具，不影響網站） |

## 資料策略

- **飲品數據是 hardcode**：市售產品成分穩定，直接寫在 `DRINKS` 陣列，不需動態載入。
- `docs/data/drinks.json` 是爬蟲輸出，**目前未被網頁讀取**（歷史檔，可忽略或刪除）。
- 圖片路徑格式：`images/<name>.jpg`，對應 `docs/images/` 資料夾。

## 已知問題（待修）

1. **比較矩陣右側空白** — `.compare-outer` 只有 `max-height` 沒有固定 `height`，
   flex 子元素的 `overflow-y/x: auto` 無法作用，表格被 `overflow: hidden` 裁掉。
   修法：`.compare-outer` 改用 `height: 480px`。

2. **所有圖片顯示「無圖片」** — `DRINKS` 陣列每筆 `"image": null`，
   但 `docs/images/` 已有對應圖片。需補回路徑如 `"image": "images/yakult.jpg"`。

3. **CSS 重複定義** — `.cell-best/.cell-good/.cell-warn/.cell-bad` 等定義了兩次
   （第 228–234 行 與 第 236–243 行），後者覆蓋前者，應刪除重複。

4. **`buildCompareTable` 多餘呼叫** — 第 701 行的 `buildCompareTable(DRINKS)` 多餘，
   `applyFilters()` 在第 639 行已呼叫一次。

## 核心功能說明

```
篩選器（搜尋 / 排序 / 類別）
  └─ applyFilters()
       ├─ renderStats(filtered)
       ├─ renderRankings(filtered)
       ├─ buildCharts(filtered)
       ├─ renderGrid(filtered)
       └─ buildCompareTable(filtered)   ← 比較矩陣跟篩選器連動，已實作
```

比較矩陣左欄（成分標籤）固定，右欄（各飲品數值）隨篩選結果動態更新。
最多顯示 20 筆（`list.slice(0, 20)`）。

## 檔案結構

```
health-drinks/
├── CLAUDE.md           ← 本文件
├── AGENTS.md           ← Agent team 設定
├── README.md
├── docs/
│   ├── index.html      ← 所有 UI + 資料（單一檔案）
│   ├── data/
│   │   └── drinks.json ← 爬蟲舊輸出，網頁未使用
│   └── images/         ← 飲品圖片（本地）
└── scripts/
    └── scraper.py      ← 離線爬蟲
```

## 開發規則

- 所有修改集中在 `docs/index.html`（UI）與 `docs/data/drinks.js`（資料）。
- 不引入 npm / build step，保持純靜態可直接在 GitHub Pages 部署。
- **每次新增飲品：標籤有什麼填什麼，包含所有微量元素，不可自行省略。**
- 資料以「每份體積」儲存，網站自動換算 per 100ml（除以 volume_ml）。
- 修 CSS 前先搜尋是否有重複定義。
