# 👨‍👩‍👧 育兒長路 — 從備孕到國中的家長方法論

> ⚠️ 2026-05-29 啟動：本 handbook 是 `newborn-handbook` + `childcare-handbook` + 新增「學齡 × AI 協作」整併版。**Phase 1 進行中**（Tab 3-4 已 ship，Tab 1-2 待從原 sub-project 遷入）。

給家裡有 **0-15 歲孩子** 的家長，從備孕到國中的縱貫線方法論手冊。

---

## 🌐 線上看

**https://tm731531.github.io/dementia-care/kids-handbook/**

---

## 🎯 為什麼整併

原本三本獨立：
- `newborn-handbook`（備孕 → 新生兒）
- `childcare-handbook`（0-6 歲托幼選擇）
- 「學齡 × AI 協作」（6-15 歲，本次新建）

但家長的時間軸是連續的 —— 你不會今天看一本明天換一本。**整併成單一 handbook 讓你一站式從備孕看到國中**。

對齊 monorepo 規則 1：Phase 2 完成後 archive 原 2 個 sub-project，net portfolio 15 → 14（縮小）。

---

## 🎯 4 個 Tab

| Tab | 內容 | 風格 | 狀態 |
|-----|------|------|------|
| 1 | 備孕 → 新生兒 | SOP-first | Phase 2 待遷 |
| 2 | 托幼選擇（0-6） | SOP-first | Phase 2 待遷 |
| 3 | 學齡 × AI 協作（6-15） | 方法論 + 紀錄 | ✅ 已 ship |
| 4 | 跨階段方法論（4 層 firewall） | 方法論 + 紀錄 | ✅ 已 ship |

---

## ⚠️ 兩種風格刻意保留

- **Tab 1-2 維持 SOP-first**（時間表 + 最安全預設）—— 0-6 歲很多事 deadline-driven，過了重來一年
- **Tab 3-4 是方法論 + 紀錄**（沒有 SOP）—— 6+ 歲核心是培養 ownership，**一 SOP 就破壞 ownership**

每個 tab 頂部明確標示風格，避免混淆。

---

## 💾 本機資料（localStorage）

Storage key: `kidsHandbookState`

存的是：你目前在哪個 tab。**不上傳任何資料到雲端。**

---

## 🧰 技術

- **單檔 HTML**：`index.html` —— **內容、樣式、互動全部 inline**，無 framework、無 build step
- **離線可用**：所有資源 inline
- **🔴 零外部 CDN 依賴**
- **繁體中文**
- **米白底深字**（對中度白內障友善，避免純黑底純白字的 glare）
- **可列印**（print stylesheet）

---

## 📁 內部結構

```
kids-handbook/
├── README.md          # 本檔
├── CLAUDE.md          # 開發指引
├── AGENTS.md
├── index.html         # ⭐ 所有家長閱讀內容都在這裡（single source of truth）
└── docs/
    ├── brain/         # 你跟另一半每週紀錄區（內部累積，不對外）
    ├── skill/         # 對齊後的家庭做法（內部）
    └── review/        # 月年回顧（內部）
```

**家長閱讀的內容 100% 在 `index.html` 內。** docs/ 底下只是給家長自己的累積區，不是文章。

---

## 🤝 貢獻

主要是自家用 + 朋友參考。歡迎 PR：
- 補各縣市資料（Tab 2）
- 補匿名化案例
- 補 Tab 4 三明治世代踩坑

---

## 📄 授權

MIT
