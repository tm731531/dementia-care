# Agent Team Configuration — kids-companion

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
