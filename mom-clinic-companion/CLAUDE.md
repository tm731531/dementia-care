# 就診小幫手 — 開發指引

## 專案簡介
帶長輩回診時的**手機 prep 工具**。照護者（內向、疲累）需要在回診前快速整理出「值得跟醫生討論的」，而不是在診間當場翻月報。

**不是**資料查詢工具（那是 iDempiere UI 的事），**是**把 raw data 歸納成照護者可以記住、可以問的內容。

## 技術架構
- **單一檔案**：`index.html`（~1,000+ 行）
- **純前端 + 後端 REST API**：iDempiere REST（TrekGlobal 插件，port 8080）
- **跨域**：iDempiere 需裝 Jetty `CrossOriginFilter`（照 `CORS-MIGRATION.md`）
- **狀態**：
  - Token：sessionStorage（登入後）
  - Cache：localStorage（離線可看最後同步版本）
- **Favicon**：SVG inline emoji（🩺）

## 使用情境（單一流程）
每月 1 次回診前 5-10 分鐘打開：
1. 🚨 **值得跟醫生討論的** — 規則引擎自動比對「上次回診到今天」vs「上上次到上次」
2. 💭 **這一個月媽媽發生過** — 從白板 OCR 的 Description 抓症狀關鍵字
3. 📋 **這次要問醫生** — 可從上面兩區一鍵「加進問題」，手動補其他
4. 🎙️ **診間錄音** — 醫生講的話 STT 轉字，回家同步回 iDempiere

## 資料來源
上游是 [白板 OCR 紀錄 Bot](../whiteboard-ocr-bot/)：
- 照護者每天在家用手機拍廚房白板
- Bot OCR 產出結構化資料寫進 iDempiere `Z_momSystem` 表
- 12 個欄位 × 每天一筆 × 30 天 = 月報 raw data

這個 app 讀 `Z_momSystem` 並做分析。

## 核心：回診日期比對
原本「一個月」是按日曆切，但實際回診頻率不規則（通常一個月，有時兩週）。
所以有 **回診日期列表**：
```js
APP.visits = ['2026-02-15','2026-03-14','2026-04-21', ...]
```
`computeWindows()` 產生最新兩段比對區間：
- 當前窗口：`last_visit → today`
- 上一窗口：`prev_visit → last_visit`

## 規則引擎（`detectAnomalies()`）
4 種異常偵測：
1. **window comparison**：數值型欄位（如睡眠比例）當前 vs 上次差 > 門檻
2. **co-occurrence**：同一天多個症狀一起出現（如「睡眠差 + 隔天精神差」）
3. **streak**：連續 N 天某狀態（如連續 5 天食慾差）
4. **chronic**：慢性累積（如本月 > 30% 天數發生）

每個規則產出一筆「值得討論」卡片，家長可一鍵加進「要問醫生」清單。

## 症狀關鍵字匹配（`matchSymptomGroups()`）
13 類分群 + 每類有 **include keywords** + **exclude keywords**：
```js
SYMPTOM_GROUPS = {
  '拒食': {
    include: ['不吃','拒絕','沒胃口','吐出'],
    exclude: ['吃不完','吃太多']   // 避免誤抓
  },
  ...
}
```
regex 對 OCR Description 掃描，排除詞優先（含 exclude 就不算 match）。

## iDempiere REST API 呼叫
- `POST /api/v1/auth/tokens` → 登入取 token
- `GET /api/v1/models/Z_momSystem?$filter=...` → 撈資料
- `POST /api/v1/models/Z_momSystem` → 寫回（診間錄音用）

Token 存 sessionStorage，30 分鐘有效，過期自動跳登入。

## 環境切換
```js
// 自動偵測 localhost vs 線上
const API_BASE = location.hostname === '127.0.0.1' || location.hostname === 'localhost'
  ? 'http://localhost:8080'
  : 'https://idempiere.tomting.com'
```

本機開發用 SuperUser/System，線上用 Tom/Tom。

## 離線策略
- 登入後把最近一個月資料存 localStorage
- 網路掛了：讀 cache + 顯示「離線版本，同步時間：...」
- 診間收訊不穩時照樣可以 prep 問題

## 設計原則
- **回診前 5 分鐘快速 prep** — 打開就看到重點，不用翻
- **一指操作** — 滑手機的姿勢可用，不需要精細點擊
- **卡片式** — 每個 insight 獨立一張卡，可加入問題清單
- **中文優先** — 所有文字繁體中文
- 保留診間可翻 raw data 的入口，但不是主流程

## 開發指引
- 改規則引擎：跑完必用真實歷史資料驗證（iDempiere 產品機）
- 改 API 呼叫：同時測 localhost 跟線上兩邊
- 症狀關鍵字：加 include 時一定要補 exclude 避免誤抓

## 踩過的坑
- **iDempiere CORS**：Jetty ee8 的 `CrossOriginFilter` path 是 `org.eclipse.jetty.ee8.servlets.CrossOriginFilter`（不是舊的 `org.eclipse.jetty.servlets`）
- **Token 跨 tab 共享**：用 sessionStorage 每個 tab 獨立，避免登入衝突
- **血壓欄位**：原本有但媽媽後來沒量了，記得顯示時 null 過濾

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/idempiere-rest-api.md` — iDempiere REST API 使用
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md`

## 檔案結構
```
mom-clinic-companion/
  CLAUDE.md                # 本檔案
  README.md                # 使用說明
  CORS-MIGRATION.md        # iDempiere 跨域設定指南
  index.html               # 應用主體
  docs/
    screenshot-main.png
    screenshot-visits.png
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/mom-clinic-companion/`
- 依賴：iDempiere production `idempiere.tomting.com` 必須跑著 + CORS filter 裝好
