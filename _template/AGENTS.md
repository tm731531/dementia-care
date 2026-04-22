# {{PROJECT_NAME}} — Agent Team Configuration

> 繼承母層規則：`../AGENTS.md`（共用 Model Selection、Debug Limit、Verification、Brain refs）。
> 下面只列本專案特有的內容。

## Project-Specific Perspective Inventory

**真實使用者**（必填，見母層 stakeholder 目錄）：
- 🧓 / 💝 / 👷 / 🩺 / 💊 / 🧒 / 👨‍👩‍👧 / 🛠️ → 挑 2-4 個實際會接觸此工具的人類角色
- **不要只寫「User」一行**。拆成操作者 vs 被照顧者 vs 最終消費者
- 每個角色的 Risk 要反映他會受影響的程度（體驗者通常 > 操作者 > 間接受眾）

| Perspective | Risk (0-3) | Scope (0-3) | Score | Notes |
|--|--|--|--|--|
| {{真實角色 1}} | | | | {{具體痛點 / 使用情境 / 約束}} |
| {{真實角色 2}} | | | | {{具體痛點 / 使用情境 / 約束}} |
| PM | | | | {{跟整個 repo 主線關係}} |
| Tester | | | | {{什麼會壞、edge cases}} |
| Implementer (per tech) | | | | {{每個主要技術棧一行}} |
| Architect | | | | {{跨檔/跨服務推理}} |
| Security | | | | {{若涉及 auth/PII/secrets}} |
| Ops | | | | {{部署/監控}} |
| Domain expert | | | | {{問題有領域深度時}} |

**Score = Risk × Scope**:
- ≥ 6 → 專屬 agent（opus 或 top sonnet）
- 3-5 → 專屬或配對（sonnet）
- 1-2 → 折入其他 agent prompt
- 0 → 承認但不派 agent

## Agents

| Agent | Model | Memory | Primary Perspectives | Folded Perspectives | Priority |
|--|--|--|--|--|--|
| {{agent-1}} | opus/sonnet | 1.0/0.6 GB | {{...}} | {{...}} | {{P1 > P2 > P3}} |

總計 GB，headroom 預留。

## Project-Specific Rules

### {{規則 1 標題}}
{{具體限制、為什麼、違反時拒絕的動作}}

### {{規則 2 標題}}
{{...}}

## Re-Evaluation Triggers
- {{什麼事件觸發重看 perspective 分數}}
- {{什麼情況下某個 folded perspective 要提升成專屬 agent}}
