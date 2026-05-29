# 👨‍👩‍👧 育兒長路 — 從備孕到國中的家長方法論

> ⚠️ 2026-05-29 啟動：本 handbook 是 `newborn-handbook` + `childcare-handbook` + 新增「學齡 × AI 協作」整併版。**Phase 1 進行中**（骨架 + 新章 anchor 已建），Phase 2 待遷入原 2 個 sub-project 內容。

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

但家長的時間軸是連續的 —— 你不會今天看一本明天換一本。**整併成單一 handbook 讓你一站式從備孕看到國中**，同時不被「跨手冊跳轉」打斷思路。

對齊 monorepo 規則 1：Phase 2 完成後 archive 原 2 個 sub-project，net portfolio 15 → 14（縮小）。

---

## 🎯 內容章節（4 tab）

### Tab 1: 備孕 → 新生兒
- 孕前健康檢查 / 14 次產檢時程 / 待產包 / 產後恢復 / 父親 5 步政府表單 / 母乳 vs 配方
- 來源：原 `newborn-handbook`（Phase 2 遷入）

### Tab 2: 托幼選擇（0-6 歲）
- 4 種托育類型對照 / 5W1H 方法論 / 看園所 checklist / 抽籤機制 / 文件 SOP
- 來源：原 `childcare-handbook`（Phase 2 遷入）

### Tab 3: 學齡 × AI 協作（6-15 歲）— **本次新建**
- 核心：她要 **own 自己的問題**，AI 是工具不是奶嘴
- 4 層 firewall：baseline / 鎖順序 / 結構化描述 / 程序性 firewall
- 各年齡層具體做法（小一-小二 / 小三-小五 / 小六-國中）

### Tab 4: 跨階段方法論 — **本次新建**
- 三明治世代（同時照顧失智長輩 + 育兒）
- 家庭 brain / skill / review 紀錄循環
- 4 層 firewall 詳細展開

---

## 👥 誰適合看

1. **正在備孕或孕中** → Tab 1
2. **0-6 歲孩子家長** → Tab 2 + Tab 4
3. **學齡孩子家長（6-15）** → Tab 3 + Tab 4
4. **三明治世代**（同時照顧失智長輩 + 幼兒）→ 含失智照護家庭專區（在 Tab 4）

---

## ⚠️ 兩種風格刻意保留

| Tab | 風格 | 為什麼 |
|------|------|--------|
| 1-2 | **SOP-first**（時間表 + 最安全預設） | 0-6 歲很多事是 deadline-driven（報名截止 / 預防接種），過了重來一年 |
| 3-4 | **方法論 + 紀錄**（沒有 SOP） | 6+ 歲核心是培養 ownership，**一 SOP 就破壞 ownership 的精神**，只能方法論 + 親自累積 |

tab 切換時頂部副標題會明確標示目前在哪種風格，避免混淆。

---

## 💾 本機資料（localStorage）

Storage key: `kidsHandbookState`

存在你裝置的：
- 當前 tab + 階段
- 收藏的章節
- 自己加的 case logs

支援匯出/匯入 JSON 備份，換裝置不丟資料。**不會上傳任何資料到雲端。**

---

## 🧰 技術

- **單檔 HTML**：`index.html` 一個檔案搞定，無 framework、無 build step
- **離線可用**：所有資源 inline
- **🔴 零外部 CDN 依賴**
- **繁體中文**
- **Emoji 相容性**：只用 Unicode ≤ 10.0

---

## 📚 內部結構（給 dev 看的）

```
kids-handbook/
├── README.md          # 本檔
├── CLAUDE.md          # 開發指引
├── AGENTS.md
├── index.html         # 4 tab 主體
├── docs/
│   ├── 00-spirit.md             # 跨階段方法論核心
│   ├── 01-pre-birth-to-newborn.md   # Tab 1 內容（Phase 2 遷入）
│   ├── 02-childcare-0-6.md          # Tab 2 內容（Phase 2 遷入）
│   ├── 03-school-age-6-15-ai.md     # Tab 3 內容（本次新建）
│   ├── 04-cross-stage/
│   │   ├── sandwich-generation.md
│   │   └── four-firewalls/
│   │       ├── baseline.md
│   │       ├── order-lock.md
│   │       ├── describe.md
│   │       └── verify-source.md
│   ├── brain/         # 你跟太太每週紀錄
│   ├── skill/         # 對齊後的做法
│   └── review/        # 月年回顧
```

---

## 🤝 貢獻

主要是 Tom 家自家用 + 朋友參考。歡迎 PR：
- 補各縣市資料（Tab 2）
- 補匿名化案例
- 補 Tab 4 三明治世代踩坑

---

## 📄 授權

MIT
