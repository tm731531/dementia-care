# kids-handbook — 育兒長路（0-15 歲家長方法論手冊）開發指引

## 專案簡介

整併版 handbook，涵蓋 0-15 歲完整育兒縱貫線：備孕、新生兒、托幼選擇、學齡學習、國中 AI 協作。

**整併歷史（2026-05-29）：**
- `newborn-handbook`（備孕→新生兒）→ Tab 1（待 Phase 2 遷入）
- `childcare-handbook`（0-6 歲托幼）→ Tab 2（待 Phase 2 遷入）
- 新增「學齡 × AI 協作」→ Tab 3 + Tab 4（已 ship）

**對齊 monorepo 規則 1**：Phase 2 完成後 archive 原 2 個 sub-project，net portfolio 15 - 2 + 1 = **14**（縮小）。

## 🔴 最重要規則：Single Source of Truth = index.html

**所有家長閱讀的內容 100% 在 `index.html` 內**（HTML semantic markup + 內嵌 CSS + 內嵌 JS）。

**不能：**
- 寫 markdown 文章給家長看（瀏覽器不渲染，不是給人讀的格式）
- 把內容拆到 `docs/*.md` 然後 link 過去（雙來源 → 修正性差）
- 用「請看 docs/foo.md」這種引導

**可以：**
- `docs/brain/`、`docs/skill/`、`docs/review/` 的 README.md（這是 Tom + 另一半內部累積區的引導，**不是家長閱讀的文章**）

## 技術架構
- **單一檔案**：`index.html`（HTML + CSS + JS 全部 inline）
- **純前端**、**離線可用**、**零外部 CDN**
- **狀態**：localStorage key `kidsHandbookState`（只存 currentTab）
- **Favicon**：SVG inline 👨‍👩‍👧

## 內容結構 — 4 tab

| Tab | 內容 | 風格 | 狀態 |
|--|--|--|--|
| 1 | 備孕 → 新生兒 | SOP-first | Phase 2 待遷 |
| 2 | 托幼選擇（0-6） | SOP-first | Phase 2 待遷 |
| 3 | 學齡 × AI 協作（6-15） | 方法論 + 紀錄 | ✅ 已 ship |
| 4 | 跨階段方法論 | 方法論 + 紀錄 | ✅ 已 ship |

## 修正性設計（每段 article 都有 stable id）

未來 review 時可以講「請改 `#tab3-stage-9-11` 那段第三條」精準定位：

```
Tab 1 sections: #tab1-overview, #tab1-prepregnancy, #tab1-pregnancy, #tab1-prebirth, #tab1-postpartum, #tab1-paperwork, #tab1-feeding, #tab1-sections, #tab1-types
Tab 2 sections: #tab2-overview, #tab2-types, #tab2-sections
Tab 3 sections: #tab3-core-question, #tab3-stages, #tab3-stage-6-8, #tab3-stage-9-11, #tab3-stage-12-15, #tab3-ai-rules, #tab3-failure-signals
Tab 4 sections: #tab4-spirit, #tab4-tensions, #tab4-ownership, #tab4-firewall-1, #tab4-firewall-2, #tab4-firewall-3, #tab4-firewall-4, #tab4-sandwich, #tab4-records, #tab4-timeline
```

加新章節時：用 `<article id="tabN-section-name">` 命名一致。

## 設計原則

### 風格切換為什麼刻意保留

- **Tab 1-2 維持 SOP-first**（時間表 + 最安全預設）
- **Tab 3-4 是方法論 + 紀錄**（ownership / 4 層 firewall）
- 每個 tab 頂部有 `<span class="style-badge sop|method">` 明確標示風格

### 為什麼不統一風格

- 0-6 歲很多事是 deadline-driven，**適合 SOP**
- 6+ 歲核心是培養 ownership，**一 SOP 就破壞 ownership**，只能方法論 + 親自累積
- 強行統一 = 強行毀掉一邊

### 內容作者

- **Tab 1-2**：SOP 內容，遷入時保留原引用（hpa.gov / 教育部 / 各縣市網站）
- **Tab 3-4**：本次新建，文章寫給家長看
- `docs/brain/skill/review/`：Tom + 另一半內部累積，AI 不介入

## 文件結構

```
kids-handbook/
├── README.md          # 給家長 + 訪客
├── CLAUDE.md          # 本檔，給 dev / 未來的 Claude
├── AGENTS.md          # Agent team config
├── index.html         # ⭐ Single source of truth, 4 tab + 所有文章內容
└── docs/
    ├── brain/         # 內部累積區
    │   └── README.md  # 怎麼紀錄
    ├── skill/         # 內部
    │   └── README.md
    ├── review/        # 內部
    │   └── README.md
    └── superpowers/
        └── plans/
            └── current-state.md
```

## 開發路線圖

### Phase 1（2026-05-29 已 ship）
- [x] 複製 `_template` → `kids-handbook`
- [x] 寫 README / CLAUDE / AGENTS
- [x] `index.html` 4 tab 完整 HTML（Tab 3-4 完整內容，Tab 1-2 placeholder + 大綱）
- [x] localStorage `kidsHandbookState`（記住 currentTab）
- [x] `docs/brain/skill/review/README.md`（內部累積區引導）
- [x] CDN check 通過
- [x] HTML parse 通過

### Phase 2（待 Tom review 後）
- [ ] 遷 `newborn-handbook/index.html` 內容 → Tab 1（HTML 章節 inline）
- [ ] 遷 `childcare-handbook/index.html` 內容 → Tab 2（HTML 章節 inline）
- [ ] 統一 localStorage migration（newborn state + childcare state → kidsHandbook state）
- [ ] **archive** 原 2 個 sub-project（首頁加跳轉，**不刪檔**，URL 保留）
- [ ] 更新母 `~/Desktop/dementia-care/index.html` landing（移舊卡片、加新卡片）
- [ ] 更新母 `~/Desktop/dementia-care/CLAUDE.md`（紀錄整併動作 + 更新 sub-project 數 15 → 14）
- [ ] Tom 寫 blog 說明（規則 1 解凍要求）

### Phase 3（持續累積）
- Tom + 另一半每週寫 `docs/brain/YYYY-MM-DD.md`
- 每月寫 `docs/skill/*.md` 對齊
- 每年寫 `docs/review/YYYY.md` 回顧

## 風格規矩

繼承 monorepo CLAUDE.md：
- 文字繁體中文
- **米白底深字**（`--bg: #f5f5f5; --fg: #222`），不用純黑底純白字
- 字級 18px+（mobile 17px），line-height 1.75
- 觸控友善（最小點擊區 48×48px，nav button 56px min-height）
- 可列印（print stylesheet 把 nav / TOC 隱藏，每 tab 分頁）

## 開發指引

### 改 index.html
1. 改前 grep stable id（例：`#tab3-stage-9-11`）只讀目標 article
2. **新增 JS 物件時注意尾逗號**（kids-companion 踩過坑，整頁 blank）
3. 改完用瀏覽器 smoke test：4 tab 切換、localStorage 記住、scroll to top
4. 必跑：HTML parse + CDN 檢查
   ```bash
   python3 -c "from html.parser import HTMLParser; p=HTMLParser(); p.feed(open('index.html').read()); print('OK')"
   grep -n -E 'https?://[^"]*\.(com|net|org|io|co)/' index.html | grep -v 'tomting\|github\|edu\.tw\|hpa\.gov\|data:'
   ```

### 加新章節
- 在對應 tab `<section>` 內新增 `<article id="tabN-section-name">`
- 標題用 `<h3>`，副標題用 `<h4>`
- 如果是「階段卡片」（年齡層說明），用 `<article class="stage-card">`
- 如果是「重要警告」，用 `<div class="callout warn|info|note">`
- TOC 內也要加新 entry（`<nav class="toc">`）

### 刪內容
- 內容刪掉時，id 不要保留空殼（避免錨點 link 指向空）
- 同步檢查有沒有其他 article 引用這個 id

## 踩過的坑
- **2026-05-29 markdown 雙來源陷阱**：初版把章節內容拆成 `docs/*.md`，index.html 只 link 過去 → 違反 monorepo「單檔 HTML」原則 + .md 在瀏覽器不渲染 + 雙來源修正性差。修正：所有家長閱讀內容遷進 `index.html`，刪除 markdown 文章。

## Domain Brain
- `design-principles.md`（必讀 — 通用原則 + emoji 相容性 + 零 CDN + 對比度）
- `llm-conversation-grounding.md`（避免 AI 幫寫 Tab 1-2 遷入內容時瞎掰）
- `llm-handbook-writing-pitfalls.md`（handbook 寫作 9 個失敗模式）

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/kids-handbook/`
- 純靜態，push main 自動部署（30-60s）
