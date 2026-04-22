# _template — 新專案 scaffold 模板

這個資料夾是**工具**，不是產品。用來快速開新子專案或新功能頁面。

## 用法 1：開一個新子專案（加新資料夾）

```bash
cd /home/tom/Desktop/dementia-care

# 複製模板
cp -r _template my-new-project

# 客製化
cd my-new-project
# 1. 編輯 CLAUDE.md 把 {{PROJECT_NAME}}、{{EMOJI}} 等佔位換掉
# 2. 編輯 AGENTS.md 填 Perspective Inventory
# 3. 把 docs/superpowers/plans/current-state.md 改名為 `YYYY-MM-DD-current-state.md`
# 4. 寫 README.md（給使用者看的）
# 5. 建 index.html(HTML app) 或 main.py(Python)

# 同步到 landing 頁
# 編輯 ../index.html 把新專案加上卡片

# 同步到母層 roadmap
# 編輯 ../docs/superpowers/plans/2026-04-22-monorepo-roadmap.md 加到子專案索引

# commit
git add my-new-project ../index.html ../docs/superpowers/plans/
git commit -m "feat: 新增 my-new-project 子專案"
```

## 用法 2：為既有專案加新頁面/功能

不需要複製整個模板，只要在**該子專案內**：

```bash
cd existing-project

# 1. 在該專案的 CLAUDE.md 加一筆活動/功能說明
# 2. 若功能複雜，在 docs/superpowers/specs/ 建一個 design spec
# 3. 在 docs/superpowers/plans/ 建一個實作 plan
# 4. 寫程式
# 5. 更新該專案的 current-state.md「已完成里程碑」區
```

母層（root）的 CLAUDE.md / AGENTS.md / roadmap **通常不用動**——那些是跨專案共用的。

## 什麼情況該動母層

- 新增第 7 個子專案 → 更新 monorepo-roadmap 的子專案索引
- 發現跨專案共通的踩坑 → 寫進 `~/.claude/projects/-home-tom/memory/brain/design-principles.md`
- 改了共用的技術棧（例如所有 app 都加某個功能）→ 更新母層 CLAUDE.md 的「共用設計原則」

## 佔位變數對照表

複製 `_template` 後，grep 這些字串換掉：

| 佔位 | 換成什麼 | 範例 |
|--|--|--|
| `{{PROJECT_NAME}}` | 專案資料夾名稱 | `my-new-project` |
| `{{APP_KEY}}` | localStorage key | `myAppState` |
| `{{EMOJI}}` | favicon emoji | `🎯` |
| `{{agent-1}}` | 實際 agent 名稱 | `architect` |
| `{{規則 1 標題}}` | 專案限定規則名 | `寧缺勿錯原則` |
| `YYYY-MM-DD` | 建立日期 | `2026-04-22` |

```bash
# 一次性替換(小心檢查結果)
sed -i 's/{{PROJECT_NAME}}/my-new-project/g' CLAUDE.md AGENTS.md README.md
sed -i 's/{{EMOJI}}/🎯/g' CLAUDE.md
```

## 為什麼叫 `_template`（底線開頭）

- 底線開頭讓它在 `ls` 排最前面（容易找）
- 明確表示這是工具不是產品
- GitHub Pages 不會嘗試當成網站部署（沒 index.html 也不是子專案）
