# Agent Team Configuration — health-drinks

> 繼承母層規則：`../AGENTS.md`（共用 Model Selection、Debug Limit、Verification、Brain refs）。
> 下面只列 health-drinks 專案特有的內容。

## Perspective Inventory

**真實使用者**（見母層 stakeholder 目錄）：
- 💊 **藥師**（Tom 的朋友）= 專業視角，會挑剔成分，用來跟客戶推薦或自用
- 💝 **Tom（照顧者）**= 家用視角，給女兒 / 長輩選配方奶粉或營養補充
- 🧓 **失智者 / 長輩**（間接受眾）= 有特殊營養需求（糖尿病配方、濃縮蛋白）

| Perspective | Risk | Scope | Score | Notes |
|--|--|--|--|--|
| 💊 藥師（專業使用者）| 3 | 2 | 6 | 微量元素必須齊全，排序要合邏輯，可比對多品牌同類產品 |
| 💝 Tom（家用使用者）| 2 | 2 | 4 | 用手機/平板看，挑小孩 or 長輩的配方，要快速比較 |
| 🧓 長輩（間接受眾）| 2 | 1 | 2 | 最終喝的人，營養成分要符合醫療需求（糖尿病、腎病配方）|
| PM | 1 | 1 | 1 | 符合 dementia-care 上層目標 |
| Tester | 2 | 2 | 4 | 比較矩陣、篩選器、Modal、圖表各自正確性 |
| Implementer (HTML/CSS/JS) | 2 | 3 | 6 | 單一 HTML 檔但功能複雜 |
| Architect | 1 | 2 | 2 | 資料結構 DRINKS[]、applyFilters 資料流 |
| Data entry（拍標籤 + AI 錄入）| 3 | 2 | 6 | 微量元素不可省、標籤有什麼就填什麼 |

## Agents

| Agent | Model | Memory | Primary Perspectives | Folded Perspectives | Priority |
|--|--|--|--|--|--|
| implementer | sonnet | 0.6 GB | Impl, Tester | Tom, Architect | Tester > Impl > Tom |
| data-reviewer | opus | 1.0 GB | Data entry, 藥師 | 長輩 | 藥師 > Data > 長輩 |

## Memory Budget

| Item | GB |
|------|-----|
| System + Docker reserve | ~5.0 |
| Max available for agents | ~11.0 |
| **This team's total** | 0.6 |
| **Headroom** | 10.4 |

> 此專案單一前端檔案，一個 implementer agent 即足夠。
> 若同時需要重構資料結構（DRINKS 陣列大改）+ UI 大改，可拆成兩個 sonnet agent 並行。

## Re-Evaluation Triggers

- DRINKS 陣列擴充至 50+ 筆 → 考慮改為 fetch drinks.json，需加 Architect agent
- 引入 build step（Vite/Webpack）→ 需加 Ops agent
- 比較矩陣改為後端 API → 需加 Architect + Backend agent

---

## Workflow Override Rules

### Model Selection
- sonnet → 所有 HTML/CSS/JS 實作、資料修改、CSS 修復
- opus → 需要跨元件重構或架構決策時才升級
- haiku → 掃描檔案、diff 確認用

### Debug Limit
3 次修同一問題失敗 → STOP，回報嘗試過的方法，等 user 指示。

### Branch Rule
非 main/master branch → 不需確認直接 commit。

### Verification
說「完成」前必須：
- 用 `python3 -m http.server` 在本地開啟確認頁面正常
- 或貼出修改的 diff 讓 user 確認

### 單一檔案注意事項
`docs/index.html` 包含 CSS、JS、HTML 三合一。
修改前必須先 Read 整份檔案，避免用舊內容覆蓋。

---

## Mac Draft Resource

| Task type | Use Mac draft? |
|-----------|---------------|
| HTML 結構骨架 | ✅ YES |
| CSS layout 樣板 | ✅ YES |
| DRINKS[] 新資料筆 | ✅ YES |
| 比較矩陣邏輯 | ❌ NO — 直接實作 |
| 健康評分演算法 | ❌ NO — 直接實作 |
| Chart.js 設定 | ❌ NO — 需配合現有 charts 物件 |

```bash
python3 ~/llm-benchmark/scripts/mac_draft.py "write HTML card template for drink product"
```
