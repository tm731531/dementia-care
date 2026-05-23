# dementia-care monorepo — 開發指引

## 這個 repo 是什麼
**Tier 2 Personal toolkit**(自家用為主,不是 community product):14 個 HTML/Python 工具,圍繞「家人照顧」這件事:
- **失智長輩照護**(v1 / v2 / 就診 / OCR 白板)
- **兒童**(kids-companion / kids-weekend / childcare-handbook)
- **生活方法論手冊**(garden / pet / care / home / mindset)
- **營養飲品比較**(health-drinks)

全部走同一路線:**純前端、單檔 HTML、離線可用、零廣告、零 CDN、GitHub Pages 部署**(Python 專案是例外:whiteboard-ocr-bot 需要 server)。

起源:Tom 自己用。後來朋友(藥師)用,再延伸到社區照護者也可以用。**方法資訊** 透過 [blog.tomting.com](https://blog.tomting.com/) 分享(那是擴散渠道,工具不是)。

---

## 🛑 Tom 自我約束規則(2026-04-28 後加)

跨 6 domain expert review 共識項。寫進 CLAUDE.md 變強制規則,Tom 自己做時也守。

### 規則 1:凍結新 sub-project 60 天(到 2026-06-30)
**禁止建第 15 個 sub-project**,直到 2026-06-30。理由:
- PM 評估:14 個已過載,主軸佔比 < 35%
- wellbeing 評估:6 個月 441 commit,「持續產出 = 情緒迴避」紅旗
- 品牌評估:訪客看到 7 個 hat 找不到主軸

例外:**只允許 archive / 整併 / 刪除**(縮小 portfolio)。
解凍後若仍想開新工具,先在 blog 寫一篇「為什麼這值得開一個工具」,沒寫完不開。

> **2026-05-02 footnote**:Tom 主動 override 規則 1 + sub-rule(先 blog),
> 開第 15 個 sub-project `newborn-handbook`(從 HackMD 個人筆記轉)。
> 規則保留不刪 — 此次 override 是 explicit + ack risk。後續開 sub-project
> 仍應對齊原規則(凍結期到 2026-06-30 結束 + 之後解凍仍要 先寫 blog)。
> 已建 sub-project 累計:15 → 不得再開新的(規則 1 仍 active)。
>
> **2026-05-05 footnote**:`whiteboard-ocr-bot/` 擴充新增 `companion-call/`
> 子模組(Twilio 排程外撥陪聊媽媽,失智刺激用)。**不算新 sub-project**
> (仍 15 個底下擴充),但首次在 Python 例外 sub-project 內加第二個獨立 module。
> Tom 主動評估與主軸(mom 線資料閉環:OCR → Z_momSystem ← companion-call)
> 對齊,月費類別不變(已有 Gemini API,新增 Twilio Voice ~USD$8/月)。
> 既有 OCR pipeline 不動。**規則 1 在嚴格意義上未違反**,但留紀錄供未來 audit。

### 規則 2:Commit cap 20 / 天(soft warning)
任何一天 commit 數超過 20:
- pre-commit hook 跳出對話框問「今天你媽吃幾餐、女兒抱了你幾次、你笑了幾次」
- 不是 hard block,但提醒。失智照護者 burnout 是 monorepo 結構性 SPOF
- **Tom 倒下 = mom-clinic 朋友家屬可能誤診 = 整個生態系凍結**

### 規則 3:每週一個下午全關
不寫 code、不寫 blog、不規劃 feature。陪女兒、發呆、睡覺都行。
「讓整個家忙起來」mission 不該包含 Tom 自己一刻不停。

### 規則 4:0 CDN 機器化守門
`.github/workflows/monorepo-cdn-ban.yml` 自動掃所有 *.html。違反即擋 push。
不再靠人記得。

### 規則 5:不主動推工具,只分享方法
- 工具是 personal toolkit,維護優先順序看 Tom 當下需要
- 不主動推給陌生使用者(避免讓人對「會被維護」產生錯誤期待)
- 朋友(藥師)是「資訊交流」不是「使用者」,不發配工具帳號
- 方法寫成 blog,blog 才是擴散渠道

## 子專案一覽

| 專案 | 路徑 | 用途 | 技術 | URL |
|--|--|--|--|--|
| 🫶 Landing | `index.html` | 入口頁面，列出所有工具 | 單檔 HTML | `/dementia-care/` |
| 💭 陪伴小幫手 v1 | `dementia-companion/` | 失智長輩 15 個認知遊戲，難度 1-8 | 單檔 HTML | `/dementia-care/dementia-companion/` |
| ✨ 陪伴小幫手 v2 | `dementia-companion-v2/` | 推薦式首頁 + 陪伴指南 + LINE 摘要 | 單檔 HTML | `/dementia-care/dementia-companion-v2/` |
| 🦊 小朋友學習樂園 | `kids-companion/` | 1-6 歲 23 個活動，4 年齡層自適應深度 | 單檔 HTML（9MB）| `/dementia-care/kids-companion/` |
| 🩺 就診小幫手 | `mom-clinic-companion/` | 回診前 prep 工具，從 iDempiere 抓歸納 | HTML + iDempiere REST | `/dementia-care/mom-clinic-companion/` |
| 📋 白板 OCR Bot | `whiteboard-ocr-bot/` | Telegram bot 拍白板 → iDempiere | Python + Gemini | (不部署，自己跑) |
| 🧃 健康飲品比較 | `health-drinks/` | 19 款醫療營養品 + 嬰幼兒配方 + 高蛋白補充品比較 | 單檔 HTML(Chart.js CDN 例外) | `/dementia-care/health-drinks/` |
| 👶 新成員計畫 | `newborn-handbook/` | 從備孕到新生兒實戰 SOP(2026-05-02 規則 1 override 開) | 單檔 HTML | `/dementia-care/newborn-handbook/` |

## 共用設計原則

所有 HTML app 遵守：
- **單檔**：HTML + CSS + JS 全塞 `index.html`，不拆檔
- **離線**：所有資源 inline（SVG favicon、base64 圖、不依賴 CDN 就能跑）
- **🔴 零外部 CDN 依賴**（強制）：**禁止**任何 `fonts.googleapis.com` / `cdnjs` / `unpkg` / `jsdelivr` / Google Fonts / Analytics / 外部 script 或 CSS。原因：使用者載入網頁時瀏覽器會從**使用者裝置直接**發請求到 CDN 伺服器,洩漏 IP + User-Agent + 時間給第三方,違反 **COPPA（兒童）/ GDPR-K / 個資法**。Cloudflare 部署擋不住這個（Cloudflare 只快取 HTML,外部字型請求還是瀏覽器從使用者端發）。字型靠系統 fallback (PingFang TC / Microsoft JhengHei),要自訂字型就 base64 inline 或自家域名。
- **零建置步驟**：不進 npm、不進 build step
- **繁體中文**：所有文字
- **大字 + 大按鈕**：觸控友善，最小點擊區 48×48px
- **SVG data URL emoji favicon**：離線也有 tab icon

> ⚠️ **「純黑底 + 純白字 = 適合低視力長輩」是錯的 frame**(2026-04-28 27-domain review 校正)
>
> 既有 14 個工具沿用「純黑底 + 純白字」,實際對**中度白內障**(monorepo 主場景)會因 forward light scatter 引發 **halation/glare**,可讀性反而下降(WAI-Aging Guideline §4 + 眼科 evidence)。21:1 是 over-shoot,不是越高越好。
>
> Evidence-based 替代:**米白底深字**(#222 on #f5f5f5)/ **深底淺字**(#e8e8e8 on #1a1a1a)/ 字級 ≥ 24px / line-height ≥ 1.6。維持 WCAG AAA(7:1+)但消除極端 glare。
>
> **新工具請用 evidence-based 對比**;**既有 14 個工具不擅自改 CSS**(等 Tom 決定)。詳細 evidence:`~/.claude/projects/-home-tom/memory/brain/design-principles.md` 「最大對比 = 最適合低視力對白內障是錯的 frame」。
>
> 同類陷阱:**Web Speech API pitch > 1.0** 對老年聽力(presbycusis 高頻損失)反而降辨識率,應 ≤ 1.0。

### 每次動工必跑的 CDN 檢查
```bash
grep -n -E 'https?://[^"]*\.(com|net|org|io|co)/' index.html | grep -v 'github.io\|tomting.com\|data:'
# 任何輸出 = 違規,必須移除再 push
```

## 資料閉環（最重要的一條線）
```
[居服員 / Tom]
    ↓ 拍照傳 Telegram
whiteboard-ocr-bot
    ↓ Gemini OCR + 人工 confirm
iDempiere Z_momSystem（每天一筆）
    ↓ REST API
mom-clinic-companion
    → 回診前產出「今天要問醫生的 3 件事」
```
這是失智照護主線。其他工具（v1/v2/kids/drinks）是周邊。

## 技術棧總覽
- **前端**：Vanilla HTML + CSS + JS（無框架）
- **圖表**：Chart.js 4 CDN（僅 health-drinks）
- **語音**：Web Speech API
- **後端**：iDempiere REST API（僅 mom-clinic）
- **OCR**：Gemini 3 Flash Preview（僅 whiteboard-ocr-bot）
- **部署**：GitHub Pages（自動從 main 分支同步）
- **Python**：3.x，`python-telegram-bot` + `google-generativeai`（僅 bot）

## 共用知識（讀這些再動工）

Domain Brain 在 `~/.claude/projects/-home-tom/memory/brain/`：
- `design-principles.md` — 通用設計規則（踩過的坑 + 通用原則）
- `health-drinks-data-entry.md` — 飲品資料錄入原則
- `idempiere-rest-api.md` — iDempiere REST 使用
- `llm-conversation-grounding.md` — LLM 對話接地（避免瞎掰）
- `ai-tooling-cookbook-trap.md` — AI 工具菜譜化陷阱

專案記憶 `~/.claude/projects/-home-tom/memory/`：
- `project_kids_companion_philosophy.md` — kids 自適應深度哲學

## 跨專案規範

### 新增/修改 HTML app 時
1. 如果還沒有子專案 CLAUDE.md → 建一份（參考現有任一個）
2. 改 CSS/JS 前先 grep 錨點（`#SECTION:XXX`）只讀目標區塊，不整包讀
3. 新增圖片資料進 IMG 物件時，**一定先檢查前一筆有沒有尾逗號**（不然 SyntaxError 整頁 blank，踩過坑）
4. 改完至少用 Playwright/Selenium 跑 smoke test 確認沒 console error

### 寫進 iDempiere 時
1. CORS filter 必須裝（`org.eclipse.jetty.ee8.servlets.CrossOriginFilter`）
2. Token 存 sessionStorage 不是 localStorage
3. 同日 upsert 要先 GET 看有沒有再 PATCH/POST

### 跨專案引用
Landing `index.html` 列出所有工具，改子專案名稱或新增時同步更新卡片。

## 部署流程
```bash
git add ... && git commit -m "..." && git push
# GitHub Pages 自動部署,30-60s 生效
# 等待:gh api repos/tm731531/dementia-care/pages/builds/latest --jq '.status'
```

## 踩過的坑（跨專案）
見 `~/.claude/projects/-home-tom/memory/brain/design-principles.md` 的「踩過的坑」章節。近期的：
- Object literal 尾逗號陷阱（2026-04-21 kids-companion 整頁 blank）
- Lookup Map fallback 洩 raw id 到 UI
- Two-table sticky 對齊 / 雙向捲動同步（health-drinks）
- `.activity-card .icon` CSS 合約（kids-companion）

## 兩種擴充情境

### 情境 1：為既有專案加新頁面/功能（90% 情況）
**只改那個子專案**，母層通常不用動。
- 編輯 `該專案/CLAUDE.md` 加功能說明
- 寫程式
- 更新 `該專案/docs/superpowers/plans/current-state.md`「已完成里程碑」

### 情境 2：開一個新子專案（新資料夾）
**複製模板 + 同步母層索引**：
```bash
cp -r _template my-new-project
cd my-new-project
# 改 CLAUDE.md / AGENTS.md / README.md 的佔位變數(見 _template/README.md)
# 在 ../index.html landing 頁加卡片
# 在 ../docs/superpowers/plans/2026-04-22-monorepo-roadmap.md 加索引
```

模板位於 `_template/`，複製後用 `{{PROJECT_NAME}}` / `{{EMOJI}}` 等佔位取代。

### 什麼情況該動母層
- 新增第 7 個子專案 → 更新 monorepo-roadmap 子專案索引
- 發現跨專案共通踩坑 → 寫進 Brain (`design-principles.md`)
- 共用技術棧變動（例：所有 app 都換 X）→ 更新母層 CLAUDE.md

## 檔案結構
```
dementia-care/
  CLAUDE.md                    # 本檔案(monorepo 導覽)
  AGENTS.md                    # 母層共用 agent 規則
  README.md                    # 給使用者的專案介紹
  index.html                   # Landing page(6 個工具卡片)
  LICENSE
  _template/                   # 新專案 scaffold 模板
  docs/superpowers/plans/      # 母層 roadmap
  dementia-companion/          # v1
  dementia-companion-v2/       # v2
  kids-companion/              # 兒童學習
  mom-clinic-companion/        # 就診 prep
  whiteboard-ocr-bot/          # Python Telegram bot
  health-drinks/               # 營養飲品比較
```

每個子專案都有自己的 `CLAUDE.md` + `AGENTS.md` + `docs/superpowers/plans/`。
進子資料夾時以子層為主，這份母層只作為 monorepo 總覽 + 共用規則來源。
