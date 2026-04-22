# dementia-companion v2 — Agent Team Configuration

> 繼承母層規則：`../AGENTS.md`。只列 v2 特有 perspectives。

## Project-Specific Perspective Inventory

**真實使用者**（見母層 stakeholder 目錄）：
- 🧓 **失智者** = 體驗使用者（聽照顧者照陪伴指南對話，玩遊戲）
- 💝 **照顧者**（內向、疲累） = 操作 + 陪伴使用者（看推薦卡 + 用陪伴指南 + 發 LINE 摘要）

| Perspective | Risk | Scope | Score | Notes |
|--|--|--|--|--|
| 💝 照顧者（主要使用者）| 3 | 3 | 9 | 降低選擇癱瘓是 v2 核心。推薦卡要好按、陪伴指南要能照著說、LINE 摘要要想轉發 |
| 🧓 失智者（被陪伴者）| 3 | 2 | 6 | 視力/認知限制同 v1；陪伴指南的句子要真的能對長輩說 |
| PM | 2 | 3 | 6 | v2 是實驗版本，要對照 v1 蒐集回饋 |
| Tester | 2 | 2 | 4 | 15 個移植遊戲需跑一次確認沒壞 |
| Implementer (HTML/CSS/JS) | 2 | 2 | 4 | 沿用 v1 工具，加陪伴指南 + 摘要 |
| Architect | 2 | 2 | 4 | 推薦邏輯 + localStorage 獨立 key |
| Domain expert（失智照護 + UX）| 3 | 3 | 9 | 推薦策略是核心價值 |
| Copywriter | 3 | 2 | 6 | 45 條陪伴指南品質決定 v2 價值 |

## Agents

| Agent | Model | Memory | Primary | Folded | Priority |
|--|--|--|--|--|--|
| ux-domain | opus | 1.0 GB | Domain, User, PM | - | User > Domain > PM |
| copywriter | opus | 1.0 GB | Copywriter | Domain | Copy > Domain |
| implementer | sonnet | 0.6 GB | Impl, Tester, Arch | - | Arch > Tester > Impl |

總計 2.6 GB。

## Project-Specific Rules

### 推薦卡 C 位不動搖
首頁 1 張主推薦卡的主 CTA「好，開始 →」是橘色大按鈕。
次要選項（換一個 / 我想自己選）字級縮小、無底色。
**改 CSS 時不得讓次要按鈕跟主 CTA 同視覺權重**，否則違反 v2 核心設計。

### 新移植遊戲必須補 GAME_GUIDES
從 v1 搬任何遊戲過來，同步補 `GAME_GUIDES[gameId]` 三條：
- `onStart`、`onCorrect`、`onComplete`
少一條就不准 merge（會讓 banner 顯示空白，照護者失去使用指南）。

### 陪伴句寫作規範
每條都要是「可以直接照著對長輩說的完整句子」，不是抽象建議。
- ❌「鼓勵長輩回想」
- ✅「媽媽，妳以前最喜歡穿什麼顏色？」

句子 15-25 字，繁體中文，口語，有明確互動意圖。

### LINE 摘要純文字
不依賴 emoji 渲染（某些舊版 LINE 貼不進）。用 `・` 項目符號 + 文字。

## Re-Evaluation Triggers
- 推薦演算法有改動 → ux-domain agent 必須重看時段分布
- 移植新遊戲 → 加 copywriter 角色驗陪伴句
- 使用者回饋「推薦不準」→ 重檢時段規則 + recentActivities 排除邏輯
