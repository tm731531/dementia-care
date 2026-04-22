# Agent Team Configuration — health-drinks

> 繼承母層規則：`../AGENTS.md`（共用 Model Selection、Debug Limit、Verification、Brain refs）。
> 下面只列 health-drinks 專案特有的內容。

## Perspective Inventory

| Perspective | Risk (0-3) | Scope (0-3) | Score | Notes |
|-------------|------------|-------------|-------|-------|
| User | 1 | 1 | 1 | 照護者比較飲品，操作介面需直覺 |
| PM | 1 | 1 | 1 | 符合 dementia-care 上層目標，資料維護易用 |
| Tester | 2 | 2 | 4 | 比較矩陣、篩選器、Modal、圖表各自正確性 |
| Implementer (HTML/CSS/JS) | 2 | 3 | 6 | 單一 HTML 檔但功能複雜，含 CSS layout + JS 互動 |
| Architect | 1 | 2 | 2 | 資料結構 DRINKS[]、applyFilters 資料流 |

**Score ≥ 6** → 專屬 agent：Implementer
**Score 3-5** → 可合併：Tester（折入 Implementer）
**Score 1-2** → 折入：User、PM、Architect

## Agents

| Agent | Model | Memory | Primary Perspectives | Folded Perspectives | Priority Order |
|-------|-------|--------|----------------------|---------------------|----------------|
| implementer | sonnet | 0.6 GB | Impl (HTML/CSS/JS), Tester | User, PM, Architect | Tester > Impl > User > PM > Architect |

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
