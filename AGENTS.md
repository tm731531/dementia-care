# dementia-care Agent Team Configuration (母層)

> 這份是**所有子專案共用的基礎規則**。子專案的 AGENTS.md 繼承這份，只列專案特有的 perspectives。
> 讀這份之前先讀 `~/.claude/projects/-home-tom/memory/brain/adaptive-agent-team-staffing.md`。

## 真實使用者 Stakeholder 目錄（全 repo 通用）

**重要**：abstract「User」perspective 容易讓 agent 變得 generic。審查時要挑出真實人類角色，每個角色有各自視角與約束。

| Stakeholder | 痛點 / 約束 | 出現在哪些專案 |
|--|--|--|
| 🧓 **失智者**（被照顧者）| 視力退化、認知波動、不能有壓力、不能有分數、不能快速閃爍、語音要慢、字要大 | dementia-companion v1/v2（體驗使用者）|
| 💝 **照顧者**（家人）| 內向、疲累、不擅做選擇、時間碎片、手機在廚房/廁所隨時要用 | dementia-companion v1/v2（操作者）、mom-clinic（回診 prep）、kids-companion（陪伴者）|
| 👷 **長照人員 / 居服員** | 白天照顧、用 LINE 回報、不想打字、照規範記事 | whiteboard-ocr-bot（LINE 轉傳來源）、mom-clinic（資料源頭）|
| 🩺 **醫生**（神經科）| 10-15 分鐘門診、要 2 分鐘內看完重點、raw data + 歸納都要、不接受無根據推論 | mom-clinic-companion（最終消費者）|
| 💊 **藥師**（Tom 的朋友）| 專業視角、會挑剔營養成分、要微量元素、需對比多品牌 | health-drinks（共同使用者 + 回饋者）|
| 🧒 **小孩 1-6 歲** | 注意力 < 5 分、不識字或識字少、手指不準、愛重複、怕大聲 | kids-companion（體驗使用者）|
| 👨‍👩‍👧 **家長**（陪伴者）| 想陪玩但怕 3 歲誤觸、設定要隱藏、擔心時長 | kids-companion（操作者）|
| 🛠️ **Tom** / Dev 自己 | 自己用、自己改、要快速、寧缺勿錯 | 全部專案（dev + 部分 end user）|

### Perspective 評分時必須至少挑 2 個真實角色
寫子專案 Perspective Inventory 時：
- 不要只寫「User」一行 → 拆成實際接觸該工具的角色
- 例：kids-companion 的 User 要拆成 **小孩**（體驗）+ **家長**（操作）
- 例：v2 的 User 要拆成 **失智者**（被陪伴）+ **照顧者**（決策）

每個角色的 Risk/Scope 通常不同（體驗使用者 vs 操作使用者）。

## 其他共用 Perspectives

| Perspective | 用途 | 處理原則 |
|--|--|--|
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
