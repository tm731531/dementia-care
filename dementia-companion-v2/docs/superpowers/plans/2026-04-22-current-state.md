# dementia-companion v2 — Current State（2026-04-22）

## 現況：實驗上線中

v2 首次部署在 2026-04-20。目前跟 v1 並存，透過 landing 頁讓使用者對照比較。
收集 2-3 個月使用回饋後決定 v1 是否退場。

## 已完成里程碑

- [x] 推薦邏輯（`recommendActivity()` 依時段 + 最近玩過排除 + 隨機 fallback）
- [x] 首頁主推薦卡 + 次要選項降低權重
- [x] 15 個遊戲從 v1 移植
- [x] 45 條陪伴指南（15 遊戲 × 3 時機：onStart/onCorrect/onComplete）
- [x] 每日摘要 LINE 可貼格式
- [x] localStorage 獨立 key（`dementiaAppV2`）不干擾 v1
- [x] SVG emoji favicon ✨（2026-04-21）

## 進行中

- [ ] **使用者回饋收集** — 找 2-3 個內向照護者試用 1 個月
- [ ] 回饋項目檢查清單：
  - [ ] 推薦卡推的活動合不合他的直覺
  - [ ] 陪伴指南是否真的能照著說
  - [ ] LINE 摘要是否真的會想轉發給家人
  - [ ] 次要選項是否意外常點（意味推薦不準）

## 近期優先修

### 🟡 若回饋提到「推薦不準」
- 檢查 `getTimeSlot()` 切時段是否合實際使用時間
- `recentActivities` 最多記 3 個，可能太少（特別是經常玩的人）
- 當前難度 level 不變的話會一直推同類型遊戲

### 🟡 若回饋提到「陪伴指南看不懂 / 不想說」
- Copywriter agent 重寫那條
- 檢查是否違反「15-25 字、可直接說、口語」原則

### 🟢 已知小 bug（待修）
- 某些舊版 LINE 貼不進含 emoji 的摘要 → 改純文字版
- 「我想自己選」完整清單沒有 v1 的類別分組 → 可補

## 不做的事（明確 out of scope）
- 不加帳號 / 雲端同步（隱私優先）
- 不加多使用者切換（單一照護者視角）
- 不改 v1 —— 並存才能對照

## 下一次動工 Trigger
- 使用者回饋滿 3 個月
- 推薦演算法需重大調整
- 新增遊戲從 v1 移植（必附 `GAME_GUIDES` 三條）

## 快速進場指引
1. 改推薦邏輯 → 先跑 `recommendActivity()` 100 次看時段分布
2. 加新遊戲 → 同時加 `GAME_GUIDES[newId]` 三條，reviewer 必驗
3. 改 UX → 主 CTA 不能被次要選項視覺蓋過
4. commit 訊息：`feat(v2): ...` / `fix(v2): ...` 明確標 v2

## 檔案索引
- `../../specs/2026-04-20-caregiver-support-design.md`
- `./2026-04-20-caregiver-support.md`
