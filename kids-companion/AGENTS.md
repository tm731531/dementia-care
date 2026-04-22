# Agent Team Configuration — kids-companion

> 繼承母層規則：`../AGENTS.md`（共用 Model Selection、Debug Limit、Verification、Brain refs）。
> 下面只列 kids-companion 專案特有的內容。

## Roles

| Agent | Model | Role | Phase |
|-------|-------|------|-------|
| architect | opus | 跨活動架構決策、全域狀態設計、技術選型 | 設計 |
| implementer | sonnet | 活動實作、CSS 樣式、遊戲邏輯 | 實作 |
| spec-reviewer | opus | 規格合規審查（對照 design spec） | 審查 |
| quality-reviewer | sonnet | 程式碼品質審查、回歸測試 | 審查 |
| user-reviewer | sonnet | 從家長 & 3–6 歲孩子角度驗收 | 審查 |

## Workflow Override Rules

### Model Selection (overrides subagent-driven-development skill)
- opus → 架構決策、跨活動推理、規格審查
- sonnet → 所有實作任務（活動、CSS、遊戲邏輯、動畫）
- haiku → 檔案掃描、目錄清單 ONLY

### Single-File Rule（最高優先）
**所有程式碼必須在 `index.html` 內。** 嚴禁建立額外的 `.js`、`.css` 檔案。
任何 subagent 違反此規則，reviewer 必須拒絕並要求修正。

### Anchor Rule（維護性 — 強制）

`index.html` 是 6800+ 行的單一大檔案。**錨點系統是唯一讓未來維護者（人類或 AI）不需讀取整個檔案就能精確定位程式碼的機制。**

#### 格式

HTML/CSS 區塊：
```html
<!-- #SECTION:NAME -->
...content...
<!-- #END:NAME -->
```

JS 區塊（在 `<script>` 內）：
```javascript
// <!-- #SECTION:NAME -->
...content...
// <!-- #END:NAME -->
```

#### Implementer 必須遵守

每一個新增到 `index.html` 的程式碼區塊，**必須**包在錨點內。無例外。
- 新活動 HTML → `PAGE-{ACTIVITY-NAME}`
- 新活動 JS → `PAGE-{ACTIVITY-NAME}-JS`
- 新 CSS 區塊 → 適當的系統區塊名稱
- 任何工具函式群組 → 對應的系統區塊名稱

沒有錨點的新增程式碼 = 不可維護的技術債。

#### Reviewer 必須執行

**拒絕**任何缺少錨點的新增程式碼。具體驗證：
1. 執行 `grep -n "#SECTION:" index.html` 確認新區塊的錨點存在
2. 確認起始與結束錨點名稱完全一致
3. 如果新程式碼沒有錨點，要求 implementer 補上後才能合併

#### 標準定位工作流程

```bash
# 找目標區塊
grep -n "#SECTION:PAGE-MEMORY" index.html
# → 3241:<!-- #SECTION:PAGE-MEMORY -->

grep -n "#END:PAGE-MEMORY" index.html
# → 3350:<!-- #END:PAGE-MEMORY -->

# 只讀取該範圍（110 行，不是 6800 行）
# Read lines 3241–3350
```

**禁止整包讀取 index.html。**

### Size Awareness Rule（大區塊警示）

在讀取任何區塊之前，先確認其行數範圍：

```bash
# 先確認起始與結束行號
grep -n "#SECTION:PAGE-MEMORY" index.html   # → start line
grep -n "#END:PAGE-MEMORY" index.html       # → end line
# 計算行數 = end - start
```

規則：
- **單次最多讀取 400 行**。如果區塊超過 400 行，分多次讀取（用 offset/limit）。
- **區塊超過 300 行**，考慮是否需要拆分成子區塊（用巢狀錨點）。
- 不要在沒有確認行數的情況下直接讀取大區塊。

### No-Regression Rule
每個任務完成後，user-reviewer subagent 必須：
1. 確認新功能正常
2. 確認所有已存在的活動未受影響
3. 確認全域 APP 狀態正確

### Age Group Rule
每個遊戲活動**必須**有四個分支：`toddler`（幼幼班）、`small`（小班）、`middle`（中班）、`large`（大班）。
沒有完整四個等級的實作視為不完整。

### Debug Limit (overrides systematic-debugging skill)
同一個問題 3 次修復失敗後：
- STOP，不再嘗試第 4 次
- 回報：嘗試過什麼、失敗原因、懷疑的根本原因
- 等待使用者指示

### Branch Rule
若目前分支非 main 或 master：無需確認，直接操作。

### Verification (reinforces verification-before-completion skill)
說「完成」之前：
- 在同一個回應中執行驗證指令
- 貼上實際輸出
- 不憑感覺宣稱完成

### Subagent Context
每個 subagent 從零開始，沒有任何對話歷史。
所有關鍵規則必須在此檔案或 CLAUDE.md 中，不能只靠對話傳達。
