# dementia-care monorepo — 開發指引

## 這個 repo 是什麼
6 個互相關聯的 HTML/Python 小工具，圍繞「家人照顧」這件事：
- **失智長輩照護**（v1 / v2 / 就診 / OCR 白板）
- **兒童學習**（kids-companion）
- **營養飲品比較**（health-drinks）

全部走同一路線：**純前端、單檔 HTML、離線可用、零廣告、GitHub Pages 部署**（Python 專案是例外：whiteboard-ocr-bot 需要 server）。

起源：Tom 自己用。後來朋友（藥師）要類似的東西。再延伸到社區其他照護者也可以用。

## 子專案一覽

| 專案 | 路徑 | 用途 | 技術 | URL |
|--|--|--|--|--|
| 🫶 Landing | `index.html` | 入口頁面，列出所有工具 | 單檔 HTML | `/dementia-care/` |
| 💭 陪伴小幫手 v1 | `dementia-companion/` | 失智長輩 15 個認知遊戲，難度 1-8 | 單檔 HTML | `/dementia-care/dementia-companion/` |
| ✨ 陪伴小幫手 v2 | `dementia-companion-v2/` | 推薦式首頁 + 陪伴指南 + LINE 摘要 | 單檔 HTML | `/dementia-care/dementia-companion-v2/` |
| 🦊 小朋友學習樂園 | `kids-companion/` | 1-6 歲 23 個活動，4 年齡層自適應深度 | 單檔 HTML（9MB）| `/dementia-care/kids-companion/` |
| 🩺 就診小幫手 | `mom-clinic-companion/` | 回診前 prep 工具，從 iDempiere 抓歸納 | HTML + iDempiere REST | `/dementia-care/mom-clinic-companion/` |
| 📋 白板 OCR Bot | `whiteboard-ocr-bot/` | Telegram bot 拍白板 → iDempiere | Python + Gemini | (不部署，自己跑) |
| 🧃 健康飲品比較 | `health-drinks/` | 21 款市售飲品成分對照 | 單檔 HTML | `/dementia-care/health-drinks/` |

## 共用設計原則

所有 HTML app 遵守：
- **單檔**：HTML + CSS + JS 全塞 `index.html`，不拆檔
- **離線**：所有資源 inline（SVG favicon、base64 圖、不依賴 CDN 就能跑）
- **零外部依賴**：不進 npm、不進 build step
- **繁體中文**：所有文字
- **大字 + 大按鈕**：觸控友善，最小點擊區 48×48px
- **SVG data URL emoji favicon**：離線也有 tab icon

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

## 檔案結構
```
dementia-care/
  CLAUDE.md                    # 本檔案(monorepo 導覽)
  README.md                    # 給使用者的專案介紹
  index.html                   # Landing page(6 個工具卡片)
  LICENSE
  dementia-companion/          # v1
  dementia-companion-v2/       # v2
  kids-companion/              # 兒童學習
  mom-clinic-companion/        # 就診 prep
  whiteboard-ocr-bot/          # Python Telegram bot
  health-drinks/               # 營養飲品比較
```

每個子專案都有自己的 `CLAUDE.md` + `README.md`。進子資料夾時以子 CLAUDE 為主，這份只作為 monorepo 總覽。
