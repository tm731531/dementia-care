# kids-handbook — 育兒長路（0-15 歲家長方法論手冊）開發指引

## 專案簡介

整併版 handbook，涵蓋 0-15 歲完整育兒縱貫線：備孕、新生兒、托幼選擇、學齡學習、國中 AI 協作。

**整併歷史（2026-05-29）：**
- `newborn-handbook`（備孕→新生兒）→ Tab 1（待 Phase 2 遷入）
- `childcare-handbook`（0-6 歲托幼）→ Tab 2（待 Phase 2 遷入）
- 新增「學齡 × AI 協作」→ Tab 3 + Tab 4（本次新建）

**對齊 monorepo 規則 1**：Phase 2 完成後 archive 原 2 個 sub-project，net portfolio 15 - 2 + 1 = **14**（縮小）。

## 技術架構
- **單一檔案**：`index.html`（HTML + CSS + JS inline）
- **純前端**、**離線可用**、**零外部 CDN**
- **狀態**：localStorage key `kidsHandbookState`
- **Favicon**：SVG inline 👨‍👩‍👧

## 內容結構 — 4 tab

| Tab | 內容 | 風格 | 來源 |
|--|--|--|--|
| 1 | 備孕 → 新生兒 | SOP-first | 原 newborn-handbook |
| 2 | 托幼選擇（0-6） | SOP-first | 原 childcare-handbook |
| 3 | 學齡 × AI 協作（6-15） | 方法論 + 紀錄 | 本次新建 |
| 4 | 跨階段方法論 | 方法論 + 紀錄 | 本次新建 |

## 設計原則

### 風格切換為什麼刻意保留

- **Tab 1-2 維持 SOP-first**（時間表 + 最安全預設，沿用既有 newborn / childcare 設計原則）
- **Tab 3-4 是方法論 + 紀錄**（ownership / 4 層 firewall / family brain 紀錄循環）
- 混在同一 handbook 但每個 tab 頂部明確標示風格（色塊區隔 / 副標題），不混淆

### 為什麼不統一風格

- 0-6 歲很多事是 deadline-driven（報名截止 / 預防接種），過了重來一年，**適合 SOP**
- 6+ 歲核心是培養 ownership，**一 SOP 就破壞 ownership 的精神**，只能方法論 + 你跟太太親自累積
- 強行統一 = 強行毀掉一邊

### 內容作者

- **Tab 1-2**：SOP 內容，可參考公開資料（hpa.gov / 教育部 / 各縣市網站）整理
- **Tab 3-4**：**Tom + 太太自己累積**，AI 只給結構，不替你們寫具體場景
- `docs/brain/` / `docs/skill/` / `docs/review/`：**完全是 Tom + 太太自己寫**，AI 不應介入

## 文件結構

```
kids-handbook/
├── README.md
├── CLAUDE.md          # 本檔
├── AGENTS.md
├── index.html         # 4 tab 主體
├── docs/
│   ├── 00-spirit.md
│   ├── 01-pre-birth-to-newborn.md    # placeholder, Phase 2 遷
│   ├── 02-childcare-0-6.md           # placeholder, Phase 2 遷
│   ├── 03-school-age-6-15-ai.md
│   ├── 04-cross-stage/
│   │   ├── sandwich-generation.md
│   │   └── four-firewalls/
│   │       ├── baseline.md
│   │       ├── order-lock.md
│   │       ├── describe.md
│   │       └── verify-source.md
│   ├── brain/         # 每週紀錄（Tom + 太太自己寫）
│   ├── skill/         # 對齊（Tom + 太太自己寫）
│   └── review/        # 月年回顧（Tom + 太太自己寫）
```

## 開發路線圖

### Phase 1（2026-05-29 進行中）
- [x] 複製 `_template` → `kids-handbook`
- [x] 寫 README / CLAUDE / AGENTS
- [x] 寫 `docs/00-spirit.md`（anchor）
- [x] 寫 `docs/03-school-age-6-15-ai.md`（新章 anchor）
- [ ] 寫 `docs/04-cross-stage/four-firewalls/*.md`（4 層 frame）
- [ ] `brain/skill/review/` README 引導
- [ ] `index.html` 4 tab 骨架（tab 3-4 連到 docs，tab 1-2 placeholder）

### Phase 2（待 Tom review phase 1 後）
- [ ] 遷 `newborn-handbook/index.html` 內容 → Tab 1
- [ ] 遷 `childcare-handbook/index.html` 內容 → Tab 2
- [ ] 統一 localStorage migration（newborn state + childcare state → kidsHandbook state）
- [ ] **archive** 原 2 個 sub-project（首頁加跳轉，**不刪檔**，URL 保留）
- [ ] 更新母 `~/Desktop/dementia-care/index.html` landing（移舊卡片、加新卡片）
- [ ] 更新母 `~/Desktop/dementia-care/CLAUDE.md`（紀錄整併動作 + 更新 sub-project 數 15 → 14）
- [ ] Tom 寫 blog 說明（規則 1 解凍後要求的「為什麼這值得開一個工具」對應動作）

### Phase 3（持續累積）
- Tom + 太太每週寫 `brain/YYYY-MM-DD.md`
- 每月寫 `skill/*.md` 對齊
- 每年寫 `review/YYYY.md` 回顧

## 風格規矩

繼承 monorepo CLAUDE.md：
- 文字繁體中文
- 大字 + 大行距
- **米白底深字** 或 **深底淺字**（不要純黑底純白字 —— 對中度白內障 halation/glare）
- 字級 ≥ 24px，line-height ≥ 1.6
- 觸控友善（最小點擊區 48×48px）
- 可列印（print stylesheet）

## 開發指引

### 改 index.html
1. 改前 grep 錨點（`#TAB:X` / `#SECTION:XXX`）只讀目標區塊
2. **新增 JS 物件時注意尾逗號**（kids-companion 踩過坑，整頁 blank）
3. 改完用 Playwright/Selenium smoke test，確認沒 console error
4. CDN 檢查必跑：
   ```bash
   grep -n -E 'https?://[^"]*\.(com|net|org|io|co)/' index.html | grep -v 'tomting\|github\|edu\.tw\|hpa\.gov\|data:'
   ```

### 加新 docs
- 純 markdown，不需 build
- 引用其他章節用相對 link `[baseline](04-cross-stage/four-firewalls/baseline.md)`
- 標題用 `# 00 · 標題名` 格式（編號 + 中點 + 名稱）

## 踩過的坑
無（新專案）。遇到坑 → 修完寫進來 + 同步寫進 Brain。

## Domain Brain
- `design-principles.md`（必讀 — 通用原則 + emoji 相容性 + 零 CDN）
- `llm-conversation-grounding.md`（避免 AI 幫寫 Tab 3-4 時瞎掰）
- `llm-handbook-writing-pitfalls.md`（handbook 寫作 9 個失敗模式）

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/kids-handbook/`
- 純靜態，push main 自動部署
