# dementia-care Agent Team Configuration (母層)

> 這份是**所有子專案共用的基礎規則**。子專案的 AGENTS.md 繼承這份，只列專案特有的 perspectives。
> 讀這份之前先讀 `~/.claude/projects/-home-tom/memory/brain/adaptive-agent-team-staffing.md`。

## 共用 Perspective Inventory（全 repo 通用）

| Perspective | 用途 | 處理原則 |
|--|--|--|
| User | 最終使用者（照護者/家長/自己）| 全部子專案共用 ——「內向、疲累、不擅長做選擇」|
| PM | 跟資料閉環的關係 | 白板 OCR → iDempiere → 就診 prep 是主線 |
| Tester | 跑 smoke test | 共用工具：Playwright / Selenium |
| Security | 有涉及 API/PII/帳密時 | iDempiere token、Gemini API key、Telegram bot token |
| Ops | 部署 | GitHub Pages 自動部署；Python 服務手動啟 |

子專案在自己的 AGENTS.md 補 Implementer(per tech)、Architect、Domain expert。

## 共用 Workflow Override Rules

### Model Selection（所有子專案通用）

| 任務類型 | 模型 | 記憶體/agent |
|--|--|--|
| 架構決策、cross-file 推理、code review、感官判斷 | **opus** | ~1.0 GB |
| CRUD、API、UI 實作、測試撰寫、文件寫作 | **sonnet** | ~0.6 GB |
| 檔案盤點、config 比對、簡單 lookup | **haiku** | ~0.4 GB |

口訣：**想→opus / 做→sonnet / 找→haiku**。Always use per-project AGENTS 的 Agents 表格。

### Debug Limit（共用）
同一個問題 fix 3 次失敗就 STOP：
- 不要 fix #4
- 報告：試過什麼、失敗原因、可能根因
- 等使用者回覆

### Branch Rule（共用）
這個 repo 就是 main 分支做 — 不用分 feature branch，push 前加好 smoke test。

### Verification（共用）
說「done/fixed/passing」前必須：
- 實際跑驗證指令（curl / grep / Playwright / Selenium）
- 貼實際輸出
- 沒證據不宣稱完成

### Subagent Context（共用）
subagent 沒有 session history，dispatch 時 prompt 必須包含：
- 明確的任務範圍
- 檔案路徑（絕對路徑）
- folded perspectives（例：「你同時扮 Tester 角色，幫我抓 edge cases」）

## 共用 Domain Brain

所有子專案動工前讀：
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md` — 通用設計、踩過的坑
- `~/.claude/projects/-home-tom/memory/brain/llm-conversation-grounding.md` — 避免瞎掰

依子專案挑：
- iDempiere 相關：`idempiere-rest-api.md`, `idempiere-osgi-bundle.md`, `idempiere-2pack.md`, `idempiere-po-model.md`
- Python LLM 相關：`python-llm-integration.md`
- 飲品資料：`health-drinks-data-entry.md`

## Memory Budget（16 GB 機器）

| 項目 | GB |
|--|--|
| 系統 + Docker 保留 | ~5.0 |
| Agent 可用上限 | ~11.0 |
| 單一子專案 team 建議 | ≤ 4 agents（Opus ×1 + Sonnet ×2-3 或 Sonnet ×4）|

若總和超 11 GB，先合併最低分 agents。

## Mac Draft Resource（共用）
Mac（gemma4:e4b）可幫忙生 boilerplate：
```bash
python3 ~/llm-benchmark/scripts/mac_draft.py "<task>"
```
適用：DTO、CRUD、SQL migration、test scaffold。
不適用：業務邏輯、安全敏感、跨檔 refactor。

## Re-Evaluation Triggers
Plan 中途變動時重跑 perspective inventory：
- 新需求冒出來
- folded 的 perspective 其實是主導（提升為專職 agent）
- 原本專職的 perspective 退位（折進其他 agent）

## 子專案 AGENTS.md 只寫什麼

**專案特有**的部分：
1. 專案 Perspective Inventory（補 Implementer/Architect/Domain expert）
2. Agents 表格（實際派哪幾個 agent，各吃什麼 perspective）
3. 專案限定規則（如 kids-companion 的「不得改壞其他活動」）

共用的（上面 3 個 override rules、Mac Draft、Brain refs）直接引用這份，不重複寫。
