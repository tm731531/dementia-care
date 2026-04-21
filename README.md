# Dementia Care Tools

一位很 I 的軟體工程師做的一組工具。主線是**失智照護生態系**——給失智長輩的陪伴遊戲、每日紀錄自動化、回診前的 prep 工具、為媽媽選醫療營養品的比較網站；支線是為 2023 年出生女兒做的學習平台。

純前端、單一 HTML 檔為主、零伺服器、零廣告、零追蹤、完全離線可用。
想做什麼就做什麼，用最純粹的技術，讓每個家庭都能免費使用。

---

## 工具列表

### 🧠 失智照護生態系

| 工具 | 對象 | 類型 | 說明 |
|------|------|------|------|
| [陪伴小幫手（原版）](./dementia-companion/) | 失智症長輩 + 照護者 | 互動遊戲 | 15 種認知訓練遊戲，8 級難度自動調整 |
| [陪伴小幫手 v2（試驗版）](./dementia-companion-v2/) | 失智症長輩 + 照護者 | 互動遊戲 | v1 同款遊戲，新設計：推薦式首頁 + 照護者陪伴指南 + 今日摘要分享 |
| [白板 OCR 紀錄 Bot](./whiteboard-ocr-bot/) | 家屬 + iDempiere | Telegram Bot | 每日照片 → Gemini 3 OCR → 自動寫入 iDempiere，每月回診給醫生看 |
| [就診小幫手](./mom-clinic-companion/) | 照護者 | 手機 Web App | 回診前 prep 工具：拉 iDempiere 紀錄、自動抓異常、症狀分類、診間錄音 |
| [健康飲品成分分析](./health-drinks/) | 照護者（買醫療營養品） | 網站 | 安素/葡勝納/倍速益/補體素成分比較。資料拍包裝 → AI 辨識 → 填 JSON |

### 🎨 其他家用工具

| 工具 | 對象 | 類型 | 說明 |
|------|------|------|------|
| [小朋友學習樂園](./kids-companion/) | 2–6 歲幼兒 + 家長 | 互動遊戲 | 25+ 種寓教於樂的學習活動 |

---

## 為什麼做這個

### 陪伴小幫手（原版）

陪伴失智家人時，想話題、找互動方式來促進腦部活動，對一個內向的人來說相當消耗腦力。所以做了這個工具——打開就能用，不用想話題，遊戲自動引導互動。希望幫助所有同樣辛苦的照護者。

### 陪伴小幫手 v2

v1 每天實際使用後，發現「10 格遊戲自己挑」的首頁其實又把決策成本丟回給已經很累的照護者。v2 換一個方向：首頁直接「今天一起做這個好嗎？」推薦一個活動，一鍵開始。同時多做兩個照護者支援功能——**45 條陪伴指南**（每個遊戲 3 條可直接對長輩說的話）跟**今日摘要分享**（完成活動後一鍵產出可貼 LINE 家族群的今日紀錄）。v1 並存沒被取代，可以對照比較。

### 白板 OCR 紀錄 Bot

每天拍一張白板照片傳給 Telegram bot，Gemini 3 Flash Preview 自動把磁鐵位置轉成結構化資料寫進 iDempiere。每月回診時直接打開 iDempiere 給醫生看趨勢。設計理念是 **human-as-verifier**：OCR 不完美沒關係，家屬每天就是那個最終檢查者。

### 就診小幫手

有了 iDempiere 的每日紀錄，還缺一個「帶媽媽去回診時用的手機工具」。這個 APP 不是資料查詢（平板上的 iDempiere UI 已經做這件事），是**回診前的 prep 工具**——幫照護者記憶、發現趨勢、準備要跟醫生討論的話題。

**關鍵設計**：
- **回診倒數** + 上次回診多久前
- **自動對比窗口**：用你登記的最近兩次回診當邊界（上次到今天 vs 上上次到上次），不是傻傻的「近 14 天」
- **趨勢異常偵測**：睡眠/精神/陪伴/活動/排泄/三餐 在窗口間變差多少
- **跨欄位同日組合**：失智照顧常見 pattern 例如「拒食+情緒不穩 = 情緒性拒食」、「睡差+隔天精神差」
- **連續天數 streak**：連續 4+ 天同一異常
- **症狀關鍵字分類**（13 群 regex pattern + 排除詞）從 Description 抓事件——解決「打」抓到「打招呼」的誤判
- **長期問題**偵測：不是變差，是一直不好
- **問題清單**：每一項異常都能一鍵「加進要問醫生的清單」
- **診間錄音**：Web Speech API 即時轉文字，回家同步回 iDempiere

**架構**：單一 HTML，純 JS + iDempiere REST API。前端自動偵測 localhost vs production。後端需 CORS filter（見 [CORS-MIGRATION.md](./mom-clinic-companion/CORS-MIGRATION.md)）。

<table>
<tr>
<td valign="top"><b>主畫面</b><br>
自動從 iDempiere 拉近 3 個月紀錄，用最近兩次回診當對比窗口算出變化，
關鍵字分類顯示症狀事件。<br><br>
<img src="./mom-clinic-companion/docs/screenshot-main.png" alt="就診小幫手主畫面" width="320">
</td>
<td valign="top"><b>回診清單管理</b><br>
每次回診完記一下，下次自動拿這兩次當比對邊界。<br><br>
<img src="./mom-clinic-companion/docs/screenshot-visits.png" alt="回診清單管理" width="320">
</td>
</tr>
</table>

### 小朋友學習樂園

為了 2023 年出生的女兒，想做一個跟她互動的遊戲。不想裝 app、不想看廣告、不想傳資料到外面。一個 HTML 檔，開了就能玩。班別從幼幼班到大班，選項數、語音輔助、字體大小都自動配合年齡調。

### 健康飲品成分分析

**這個工具其實也在失智照護線上**——照顧失智媽媽要買醫療營養品（亞培安素、葡勝納 SR、倍速益、補體素、倍力素這類），貨架前每瓶密密麻麻的成分表肉眼比不出來。市售比價 app 只給售價不給營養、塞廣告、還沒涵蓋台灣醫療品牌。所以自己做一個。

**資料不是爬的**：拍包裝標籤給 AI 辨識（Claude/Gemini）擷取成結構化 JSON，全欄位填包含微量元素（brain file 明訂）。比較矩陣左欄**動態生成**——某筆有填碘，那一列才出現。粉狀產品的 `volume_ml` 是沖調後體積，前端依此換算 per 100ml。

目前 21 筆，以醫療營養品為主，也有嬰幼兒配方、高蛋白補充品、雞精等家用分類。

---

## 技術特色

所有工具共用的哲學——**最純粹的技術，最低的門檻**：

- **前端工具用單一 HTML 檔**：`dementia-companion`、`dementia-companion-v2`、`kids-companion` 雙擊就能開，不用 npm、不用 build、不用伺服器
- **零追蹤、零廣告**：進度都存瀏覽器 localStorage，不送資料到外部分析服務
- **語音用瀏覽器內建**：Web Speech API，不依賴雲端 TTS
- **離線優先**：即使需要 API 的 `mom-clinic-companion`，也會 cache 最後同步版本給診間弱網使用
- **Python 後端只在真的需要時才用**：`whiteboard-ocr-bot` 走 Telegram + Gemini API，`health-drinks` 用 scraper 產靜態資料

---

## 各工具安裝 / 使用

每個 subdirectory 都有自己的 `README.md` 寫快速開始。摘要如下：

| 工具 | 怎麼用 |
|------|-------|
| [陪伴小幫手（原版）](./dementia-companion/) | 直接 `open dementia-companion/index.html` |
| [陪伴小幫手 v2](./dementia-companion-v2/) | 直接 `open dementia-companion-v2/index.html`（跟 v1 可以並用） |
| [小朋友學習樂園](./kids-companion/) | 直接 `open kids-companion/index.html` |
| [白板 OCR 紀錄 Bot](./whiteboard-ocr-bot/) | 先試玩 demo（`open index.html`）；正式版需 Python + Gemini API key |
| [就診小幫手](./mom-clinic-companion/) | 部署到 GitHub Pages，需 iDempiere 開 CORS（見 [CORS-MIGRATION.md](./mom-clinic-companion/CORS-MIGRATION.md)） |
| [健康飲品成分分析](./health-drinks/) | 跑 scraper 產資料，或用已上線 GitHub Pages 版本 |

或用本機伺服器一次跑所有純前端工具：

```bash
python3 -m http.server 8000
# 開 http://localhost:8000
```

---

## 支持這個專案

如果這些工具對你有幫助，歡迎請我喝杯咖啡：

**銀行轉帳 Bank Transfer (Taiwan):**
- 中國信託 CTBC Bank（822）
- 帳號 Account：204530014618

---

## 作者

**Tom Ting** — [blog.tomting.com](https://blog.tomting.com/)
