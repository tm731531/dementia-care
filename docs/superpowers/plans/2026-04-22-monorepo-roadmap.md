# dementia-care monorepo Roadmap（母層 plan）

> 跨專案的 roadmap。子專案各自的 `current-roadmap.md` 記自己的細項。

**Goal**: 維持 6 個子專案健康運作，確保「失智照護資料閉環」主線不中斷。

---

## 主線：失智照護資料閉環

```
[家庭白板] → whiteboard-ocr-bot → iDempiere Z_momSystem → mom-clinic-companion → [醫生]
```

這條線是整個 repo 的核心價值。其他子專案（v1/v2/kids/drinks）是**相關但可獨立**的工具。

**關鍵健康指標**：
- iDempiere production 正常運作（`idempiere.tomting.com`）
- CORS filter 存活（Jetty ee8 的 `CrossOriginFilter`）
- Telegram bot 活著（白板照片每天有進 `Z_momSystem`）
- 就診小幫手 GitHub Pages 可讀 iDempiere

## 近期共通事項（Q2 2026）

### 🟢 已完成（2026-04）
- [x] 所有 HTML app 加 SVG emoji favicon（2026-04-21）
- [x] 所有子專案 CLAUDE.md 補齊（2026-04-22）
- [x] 母子層 AGENTS.md 架構建立（2026-04-22）
- [x] kids-companion 自適應深度重整（4 年齡層、23 活動、166 隻動物）
- [x] dementia-companion-v2 首次部署（推薦式首頁 + 陪伴指南）

### 🟡 進行中
- [ ] kids-companion 9 MB 單檔問題 — 接近 GitHub Pages 單檔上限 100MB，但初次載入慢。未來若再加圖片/活動要考慮拆檔或用 image sprite
- [ ] mom-clinic-companion 離線 cache 策略需跑過一次完整「收訊不穩的診間」情境
- [ ] whiteboard-ocr-bot Gemini prompt 準度 benchmark 需要定期跑（新版 Gemini 出來時）

### 🔵 待評估
- [ ] health-drinks 加飲品需求（朋友/藥師回饋累積中）
- [ ] kids-companion 若再加新活動需先評估 tab 分類（創作 tab 4 張剛好，探索 tab 9 張偏多）
- [ ] v1 vs v2 使用者回饋收集 → 決定 v1 是否退場

## 跨專案共用原則（每次動工時 enforce）

### HTML app（v1/v2/kids/clinic/drinks/landing）
- 單檔 HTML，不拆檔
- SVG data URL favicon inline
- GitHub Pages 部署
- 離線可用

### Python 服務（whiteboard-ocr-bot）
- human-in-loop：LLM 猜不準就 null，不瞎掰
- 寧缺勿錯

### iDempiere 整合（clinic / bot）
- Jetty ee8 CrossOriginFilter
- Token 存 sessionStorage
- 同日 upsert：GET → 存在則 PATCH，不存在則 POST

## 部署通道

單一 pipeline：
```bash
git push → GitHub Pages 自動部署 → 30-60s 生效
# 驗證:gh api repos/tm731531/dementia-care/pages/builds/latest --jq '.status'
```

Python 服務（bot）目前手動啟，未來可考慮 systemd service。

## 需要決定的事（open questions）

| 議題 | Impact | 需決定時機 |
|--|--|--|
| v1 是否退場由 v2 取代 | UX 決策 | 等 v2 滿 3 個月使用回饋 |
| kids-companion 圖片是否從 inline 拆出 | 檔案大小 vs 離線 tradeoff | 再加 50+ 圖片時 |
| 朋友要自己架還是共用 Tom 的 iDempiere | 資料隱私 | 有朋友明確要求時 |
| 是否開放社區貢獻者 | 維護成本 vs 覆蓋面 | 月活超過 100 人時 |

## 子專案 plan 索引
- `dementia-companion/docs/superpowers/plans/` — v1 各次改動歷史 + current
- `dementia-companion-v2/docs/superpowers/plans/` — v2 推薦邏輯歷史 + current
- `kids-companion/docs/superpowers/plans/` — 各活動歷史 + current
- `mom-clinic-companion/docs/superpowers/plans/` — 回診 prep 邏輯 + current
- `whiteboard-ocr-bot/docs/superpowers/plans/` — OCR prompt + current
- `health-drinks/docs/superpowers/plans/` — 資料錄入 + 比較矩陣 + current

## Re-review Triggers
本 roadmap 什麼時候重看：
- 任一子專案有重大功能上線（例：新工具、廢棄 v1）
- 資料閉環主線斷掉（任一環節掛掉）
- Brain 有新共通踩坑加入
- 使用者回饋導致某工具優先序變動
