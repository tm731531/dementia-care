# 就診小幫手 — 帶長輩回診的手機陪伴工具

> 一位內向的照護者帶媽媽去回診時，常常在診間才想起「對，媽媽上週那個⋯」已經忘了要問什麼。
> iDempiere 裡有每天的白板紀錄，但要當下翻月報找異常太慢。
> 所以做了這個工具——不是資料查詢，是**回診前的 prep 工具**。

純前端、單檔 HTML、iDempiere REST API 後端、部署 GitHub Pages。

---

## 這個工具做什麼

每個月帶失智家人去神經科回診時，**打開手機就看到**：

1. **🚨 值得跟醫生討論的** — 規則引擎自動算「上次回診到今天」vs「上上次到上次」的差異
2. **💭 這一個月媽媽發生過** — 從白板 OCR 紀錄的 Description 欄抓症狀關鍵字（13 類分群 + 排除詞）
3. **📋 這次要問醫生** — 可以從上面兩區一鍵「加進問題」，手動輸入也可
4. **🎙️ 診間錄音** — 醫生講的話即時轉文字，回家同步回 iDempiere

![主畫面](./docs/screenshot-main.png)

---

## 快速開始

### 前置條件

這個工具依賴 [白板 OCR 紀錄 Bot](../whiteboard-ocr-bot/) 已經在跑——iDempiere `Z_momSystem` 表裡有日常紀錄才有資料可分析。

### iDempiere 需要先開 CORS

因為前端部署在 GitHub Pages（`tm731531.github.io`），REST API 在另一個 domain（`idempiere.tomting.com`），瀏覽器會擋跨域呼叫。

**照這份 guide 設定一次就好**：[CORS-MIGRATION.md](./CORS-MIGRATION.md)（改一個 `web.xml` 加 Jetty `CrossOriginFilter`，重啟 iDempiere）。

### 登入使用

1. 開 <https://tm731531.github.io/dementia-care/mom-clinic-companion/>
2. 輸入 iDempiere 帳號密碼（本機開發自動切成 SuperUser/System + localhost:8080）
3. Token 存在 sessionStorage，資料 cache 在 localStorage（離線時也能看最後同步的版本）

---

## 為什麼做這個

### 平板 + iDempiere UI 已經在做「給醫生看 raw data」這件事

每個月回診時，Tom 會帶平板打開 iDempiere UI 秀 `Z_momSystem` 月報給醫生看：12 個欄位 × 30 天的完整紀錄，看各項目比例跟特殊事件。這件事平板做得好、不需要再做一次。

### 但**照護者自己**要怎麼記得要問什麼？

照護者痛點：
- 診間時間短（10–15 分鐘），不能慢慢找資料
- 一個月 30 天的紀錄太多，肉眼很難一次掃完
- 在廚房/廁所發生的事件當下記下來，一個月後在診間又忘了
- 醫生問「最近有變差嗎？」，沒有算過怎麼答？

這個工具不取代 iDempiere UI，是補上「**把 raw data 歸納成照護者可以記住、可以問的內容**」這一層。

### 為什麼不用 Gemini API

嘗試過，但最後選擇**純 JS 規則引擎**：

- **快**：打開就顯示，不等 API
- **離線 OK**：診間網路爛也能看 cache
- **零成本**：不消耗 Gemini quota
- **可預測**：邏輯你看得懂、改得動、不會幻覺
- **準確**：規則可以包含精確的醫療領域知識（例如「拒食+坐立不安」的組合意義）

---

## 規則引擎：四層偵測

所有分析都從 iDempiere 拉下來的 `Z_momSystem` 紀錄（2026-01-01 起全部，~4 個月 baseline）跑出來。

### 1. 趨勢變差（comparison window）

用「**最近兩次回診**」當 window 邊界（不是寫死的「近 14 天」）：
- recent = 上次回診 → 今天
- baseline = 上上次回診 → 上次回診

對 5 個欄位（睡眠／精神／陪伴／活動／排泄）算「不好值」比例，若 recent 比 baseline 增加 ≥ 20% 且 recent ≥ 30%，就警示。

### 2. 跨欄位同日組合（co-occurrence）

失智照顧的重要 insight 常常是「多個欄位一起看才有意義」：
- **拒食 + 坐立不安** → 情緒性拒食？
- **睡眠差 + 隔天精神差** → 睡眠藥物該調？
- **便秘 + 食慾差** → 腸胃問題？
- **精神差 + 日間活動未完成** → 藥物過度或失智進程？

這幾組 co-occurrence 近 window 裡出現 ≥ minDays 天就警示。

### 3. 連續天數異常（streak）

從今天往回看，連續 ≥ 4 天某欄位都是 bad value 就警示。例：「睡眠連續 5 天斷續」。

### 4. 長期問題（chronic baseline）

某欄位從 1/1 起 ≥ 60% 都不理想——不是變差，是本來就差。這種提醒醫生「從根本調整」。

---

## 症狀關鍵字：13 類 regex 分群 + 排除詞

Description 欄位是照護者的自由文字備註。要從裡面抓「值得提醒」的事件，不能只用 substring match（不然「**打**招呼」「**打**電話」「**打**開」都會誤判）。

升級成 regex pattern + exclude：

```js
{ key: '攻擊行為', severity: 'high',
  patterns: [/打人/, /要打/, /想打/, /動手/, /揮拳/, /咬人/],
  exclude: [/打招呼/, /打電話/, /打開/, /打掃/, /打扮/, /打字/, /打針/] }
```

13 個分類：
| 類別 | Severity | 範例 pattern |
|------|---------|-------------|
| 攻擊行為 | high | 打人 / 要打 / 咬人 |
| 疼痛 | high | 痛 / 酸痛 / 不舒服 |
| 身體功能 | high | 無法 / 抬不起 / 站不起來 |
| 跌倒撞擊 | high | 摔 / 跌 / 撞到 |
| 吞嚥口腔 | mid | 嗆到 / 咬到 / 流口水 |
| 大腦認知 | mid | 忘記 / 迷路 / 叫不出 |
| 發燒暈眩 | high | 發燒 / 頭暈 / 昏倒 |
| 抽搐顫抖 | high | 抽搐 / 顫抖 |
| 腸胃失禁 | mid | 便秘 / 失禁 / 嘔吐 |
| 嗜睡呼吸 | mid | 嗜睡 / 呼吸困難 / 咳嗽 |
| 情緒失控 | mid | 大哭 / 崩潰 / 歇斯底里 |
| 飲食異常 | mid | 拒食 / 吃不下 / 吐出來 |
| 皮膚傷口 | low | 傷口 / 破皮 / 瘀青 |

**重複出現加徽章**：某類近 30 天出現 ≥ 2 次時顯示 `×N` 徽章，一眼看出哪類問題反覆發生。

---

## 回診日期管理

![回診管理](./docs/screenshot-visits.png)

每次回診後記一下日期（一次 3 秒），系統自動：
- **倒數下次回診**：2 天後、明天、今天、已過 X 天
- **計算比對窗口**：用最近兩次回診當邊界做差異分析
- 0 次 → fallback 近 14 天 vs 之前
- 1 次 → baseline 從 1/1 到那次
- 2+ 次 → 真實週期對比

---

## 診間錄音

Web Speech API 即時轉繁中文字，不用第三方服務、不送錄音到外部。錄完存 localStorage，回家按「同步到 iDempiere」寫回 `Z_momSystem.Description` 欄位。

**為什麼存 local 不即時上傳**：診間 4G 訊號常常爛，錄到一半斷線反而損失資料。

---

## 架構

```
┌────────────────────────────────────────┐
│  GitHub Pages (tm731531.github.io)    │
│  mom-clinic-companion/index.html       │
│  ├─ 規則引擎(純 JS)                    │
│  ├─ Web Speech API 錄音                 │
│  └─ localStorage 快取 + 問題清單         │
└───────────┬────────────────────────────┘
            │ HTTPS + Bearer token
            │ (CORS 已開白名單)
            ▼
┌────────────────────────────────────────┐
│  idempiere.tomting.com                 │
│  ├─ Cloudflare proxy                   │
│  ├─ iDempiere REST API (TrekGlobal)    │
│  │  + Jetty CrossOriginFilter          │
│  └─ Z_momSystem 資料表                 │
└────────────────────────────────────────┘
                ▲
                │ 每天 20:00 寫入
                │
┌────────────────────────────────────────┐
│  TAPO 攝影機 → Gemini 3 Flash OCR      │
│  (whiteboard-ocr-bot 自動 pipeline)    │
└────────────────────────────────────────┘
```

**前端自動切換 endpoint**：
- `localhost` / `127.0.0.1` → 本機開發 iDempiere (`localhost:8080`，SuperUser/System)
- 其他 → production (`idempiere.tomting.com`，Tom/Tom)

---

## 檔案結構

```
mom-clinic-companion/
├── index.html                 # 單檔 app（~1,350 行）
├── README.md                  # 本檔案
├── CORS-MIGRATION.md          # iDempiere 後端 CORS 設定 guide
└── docs/
    ├── screenshot-main.png    # 主畫面截圖
    └── screenshot-visits.png  # 回診管理截圖
```

---

## 資料隱私

- **Token** 存 `sessionStorage`，分頁關掉就消失
- **回診清單／問題／錄音** 存 `localStorage`，從沒上傳到外部
- **診間錄音語音辨識** 用瀏覽器內建 Web Speech API，資料流交給 OS / 瀏覽器廠商（Chrome 會送 Google）— 如果你對這點介意可以不用錄音功能
- **iDempiere 資料** 只存在你自己的 server

---

## 相關閱讀（失智照顧系列）

- [失智家人確診後的第一週，先做這 5 件事](https://blog.tomting.com/2026/04/23/dementia-first-week-5-things/) — 法律 / 醫療 / 防走失 完整清單
- [失智照顧半年的三個誤會](https://blog.tomting.com/2026/04/22/dementia-care-three-misunderstandings/)
- [失智長輩為什麼一直到處走](https://blog.tomting.com/2026/04/22/dementia-mother-finding-home/)

---

## 作者

**Tom Ting** — [blog.tomting.com](https://blog.tomting.com/)
