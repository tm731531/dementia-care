# dementia-companion v1 — Agent Team Configuration

> 繼承母層規則：`../AGENTS.md`（Debug Limit、Verification、Model Selection、Mac Draft）。
> 本檔案只列 v1 專案特有的 perspectives 與 agents。

## Project-Specific Perspective Inventory

| Perspective | Risk | Scope | Score | Notes |
|--|--|--|--|--|
| User（失智長輩 + 照護者） | 3 | 3 | 9 | 視力/認知退化，最強約束，不能快速閃爍 |
| PM | 1 | 1 | 1 | v1 目前穩定，功能凍結中 |
| Tester | 2 | 2 | 4 | 改舊活動時要確認沒影響其他 14 個 |
| Implementer (HTML/CSS/JS) | 2 | 2 | 4 | 單檔 + 無框架，改動小 |
| Architect | 1 | 1 | 1 | 架構凍結，不再擴張 |
| Domain expert（失智照護）| 3 | 2 | 6 | 難度 1-8 對應認知程度，重要 |

## Agents

| Agent | Model | Memory | Primary | Folded | Priority |
|--|--|--|--|--|--|
| reviewer | opus | 1.0 GB | Domain expert, Architect | PM | Domain > Arch > PM |
| implementer | sonnet | 0.6 GB | Impl, Tester | User | Tester > User > Impl |

總計 1.6 GB，Headroom 充足。

## Project-Specific Rules

### 凍結中（不主動開發新功能）
v1 在 v2 穩定前維持 as-is。只接受：
- bug 修復（回報後才修）
- 安全性更新（無）
- 照護者回饋的微調（字體、音量之類）

### 改一個活動不得影響其他 14 個
15 個遊戲共用 `GAME_LIBRARY`、`selectGames(level)`、`autoReadQuestion()`、`bindOptionHover()`。
修改任一活動前先跑其他 14 個 smoke test。

### 難度 1-8 的語意
- 1-2 輕度（較難，只朗讀題目）
- 3-6 中度（朗讀題目 + hover 選項唸出）
- 7-8 重度（朗讀題目 + 所有選項，重複一次）

新活動必須對應 `min`/`max` 難度範圍，並實作這三層語音行為。

## Re-Evaluation Triggers
- v2 使用者回饋 → 決定 v1 是否退場
- 有人回報 v1 bug 或照護者需求變更
