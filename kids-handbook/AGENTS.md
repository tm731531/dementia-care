# kids-handbook — Agent Team Configuration

> 繼承母層規則：`../AGENTS.md`（共用 Model Selection、Debug Limit、Verification、Brain refs）。
> 下面只列本專案特有的內容。

## Project-Specific Perspective Inventory

| Perspective | Risk (0-3) | Scope (0-3) | Score | Notes |
|--|--|--|--|--|
| 👨‍👩‍👧 家長（Tom + 太太） | 3 | 3 | 9 | 主要使用者，0-15 歲全程都會翻 |
| 🧒 女兒（被照顧者） | 3 | 2 | 6 | Tab 3-4 ownership 的核心對象，間接受眾 |
| 🧓 失智照護家庭（三明治世代） | 2 | 2 | 4 | Tab 4 sandwich-generation 章節對象 |
| 🛠️ Implementer (HTML) | 1 | 3 | 3 | 單檔 HTML + tab 切換 + localStorage |
| Architect | 2 | 2 | 4 | Tab 1-2 SOP / Tab 3-4 方法論 兩種風格整合 |
| Tester | 1 | 2 | 2 | 4 tab 切換、localStorage migration（Phase 2）、CDN 檢查 |
| Security | 1 | 1 | 1 | 純前端 localStorage，無 PII 上雲 |

**Score = Risk × Scope**:
- ≥ 6 → 專屬 agent
- 3-5 → 專屬或配對
- 1-2 → 折入其他 agent prompt

## Agents

待填（Phase 2 大遷移時配置 agent team）。Phase 1 由 Tom + Claude 主對話完成，不需要分工。

## Project-Specific Rules

### 規則 1：Tab 3-4 內容禁止 AI 代寫具體場景

AI 只給 frame（章節骨架、4 層 firewall 結構），**不替 Tom + 太太寫「我家女兒昨天 XXX」這種具體場景**。
理由：
- handbook 本身在示範 ownership —— 「自己想怎麼養小孩」是核心
- AI 代寫場景 = 違反 ownership 精神 = 自我矛盾

違反時拒絕的動作：不要在 brain/skill/review 寫進虛構場景。Tom 沒提供時就留空殼。

### 規則 2：Tab 1-2 內容必須有出處

從 `newborn-handbook` / `childcare-handbook` 遷入時保留原引用（hpa.gov / 教育部 / 各縣市網站）。
新增的法規 / 補助金額 / 時程必須附公告連結。
理由：SOP-first 風格本質上要 evidence-based。

### 規則 3：風格切換要明確標示

tab 1-2 跟 tab 3-4 兩種風格，切換時頂部副標題要寫清楚：
- Tab 1-2：「以下是 SOP，時間表 + 最安全預設」
- Tab 3-4：「以下是方法論 + 紀錄，沒有標準答案」

避免家長混淆「為什麼這頁沒給我答案」。

## Re-Evaluation Triggers

- Phase 2 開始時（遷既有 sub-project）→ 重看 perspective 配置，可能需要 implementer / architect 專屬 agent
- 「brain/ 內容超過 20 筆」時 → 加入 reviewer perspective（協助識別 pattern）
- 整併後使用者反饋有「兩種風格混淆」抱怨 → 風格切換 UX 要重做
