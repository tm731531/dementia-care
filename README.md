# Dementia Care Tools

一位很 I 的軟體工程師做的一組工具。**上位 mission**:「**讓整個家忙起來**」—— 用工具、植物、寵物、結構化紀錄,讓家裡每天有事在發生、有生命陪伴。

- **主線**:失智照護生態系(4 個工具互相串聯成資料閉環)
- **支線 A**:為 2023 年出生女兒做的學習平台
- **支線 B**:原本自己挑奶粉用、後來擴展到失智媽媽醫療營養品跟藥師朋友共用的成分比較網站
- **支線 C**:家庭園藝 + 寵物手冊(2026-04 起步)—— **可食/觀葉植物讓長輩每天有事做、寵物提供情感陪伴**,呼應主線的 mission

純前端、單一 HTML 檔為主、零伺服器、零廣告、零追蹤、完全離線可用。
想做什麼就做什麼,用最純粹的技術,讓每個家庭都能免費使用。

---

## 工具列表

### 🧠 失智照護生態系

| 工具 | 對象 | 類型 | 說明 |
|------|------|------|------|
| [陪伴小幫手（原版）](./dementia-companion/) | 失智症長輩 + 照護者 | 互動遊戲 | 15 種認知訓練遊戲，8 級難度自動調整 |
| [陪伴小幫手 v2（試驗版）](./dementia-companion-v2/) | 失智症長輩 + 照護者 | 互動遊戲 | v1 同款遊戲，新設計：推薦式首頁 + 照護者陪伴指南 + 今日摘要分享 |
| [白板 OCR 紀錄 Bot](./whiteboard-ocr-bot/) | 家屬 + iDempiere | Telegram Bot | 每日照片 → Gemini 3 OCR → 自動寫入 iDempiere，每月回診給醫生看 |
| [就診小幫手](./mom-clinic-companion/) | 照護者 | 手機 Web App | 回診前 prep 工具：拉 iDempiere 紀錄、自動抓異常、症狀分類、診間錄音 |

### 🏠 其他家用工具

| 工具 | 對象 | 類型 | 說明 |
|------|------|------|------|
| [健康飲品成分分析](./health-drinks/) | Tom 自家 + 藥師朋友 + 他的客戶 | 網站 | 起源是挑奶粉，現在涵蓋嬰幼兒配方 + 醫療營養品 + 高蛋白等 |
| [小朋友學習樂園](./kids-companion/) | 2–6 歲幼兒 + 家長 | 互動遊戲 | 25+ 種寓教於樂的學習活動 |
| [家庭園藝手冊](./garden-handbook/) | 新手 + 失智照護者 + 爸媽 | 單檔 Web App | **25 種植物 × 6 類別**，10-section 完整 SOP + 🎯 5W1H 總覽 + 🎯 規劃模式 + 🛒 購物籃匯入 + 📅 24 節氣系統 + 🧠 失智照護 3 級連動 |
| [家中寵物手冊](./pet-handbook/) | 有寵物的家庭 + 失智照護者 | 單檔 Web App | **貓 / 狗 / 兔 / 鳥 / 魚 / 烏龜** 各類寵物照顧指南，含**失智照護適配度 matrix**(哪種寵物適合哪種失智階段) |

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

### 家庭園藝手冊

起源是**媽媽失智半年後發現的 pattern**：可食植物(地瓜葉、香草類)讓長輩「每天有事做」— 每天去陽台澆水、摘葉、採收，是 behavior redirection 的有效工具。觀葉植物(虎尾蘭、多肉類)是「照顧者累到不想顧時的後援」—— 幾乎不用照顧還是綠意。

這本手冊把這個策略系統化:每個 plant 有統一的 10-section 結構(why / obtain / pot-soil / steps / 完整時程表 / 施肥 SOP / 採收 / 失敗點 / **失智照護 byLevel** / 實測紀錄),meta 含 `bestStartMonths` / `seasons` / `fit tags`(新手友善/小空間/兒童可參與/寵物勿食等)。

**核心功能**:
- 🎯 **5 秒總覽(5W1H)** — 每個 plant 頁頂自動從資料抽 6 行摘要(Who / What / When / Where / Why / How)+ 適合情境 tag badges
- 🎯 **規劃模式** — 全域設定:只看「現在 + 未來 2 個月能下手 + 最愛」,月份過了自動進出
- 🛒 **購物籃** — 多個 plants 加進來,自動合併成一張**依來源分組**的採購清單(培養土加總 · 肥料共用 · 工具 dedup),匯出純文字可貼 LINE
- 📅 **24 節氣系統** — 比月曆更準的種植指南(清明開工、立冬停工),所有時程用「月份 × 節氣雙軌」
- 🌾 **施肥 SOP** — 預設固體緩釋肥(好康多 1 號),用量公式「盆邊每 10 cm = 3 粒」一眼對照,不用算濃度
- 🧠 **失智照護 byLevel** — 輕度(自主)/ 中度(單步引導)/ 重度(感官陪伴) 依設定頁切換

**哲學**:照護者沒時間觀察植物,所以所有時程寫成 SOP 日期表(記憶外包到 Google 行事曆),失敗條件放顯眼處(如「冬天扦插地瓜葉會死」要放第一眼,不能藏在附註)。

### 家中寵物手冊

同樣的 mission「讓家忙起來」,從植物延伸到動物。**失智長輩對「會主動靠近的活物」反應比植物更強**(貓跳到腿上、狗轉圈要吃、兔子抱進懷裡),這是情感連結而非只是活動安排。

這本手冊涵蓋 **貓 / 狗 / 兔 / 鳥 / 魚 / 烏龜** 6 類寵物,每類有完整照顧知識,**重點是「失智照護適配度 matrix」**:
- 哪種寵物適合輕度?(貓、狗 — 還能主動照顧)
- 哪種適合中度?(兔、烏龜 — 低維護、低移動,不會嚇到)
- 哪種適合重度?(魚 — 只需視覺陪伴,不會跑)
- 哪種**完全不適合**?(高維護或會受傷的寵物)

跟 garden-handbook 一樣有 🧠 失智照護 byLevel notes,讓照護者一眼知道「我家情況適合養這個嗎」,避免養到一半放棄或傷害動物。

### 健康飲品成分分析

**起源與演化**：

1. **🍼 為女兒挑奶粉**（起源）——各品牌蛋白質/鐵/DHA 排法不一肉眼比不出來
2. **🍼 小孩奶粉本身就要細比**（深化）——**1 歲 vs 3 歲配方差異大**，加上**小安素（亞培 PediaSure）這類特殊性兒童配方**要馬上認真比對
3. **💊 藥師朋友點醒老人端**（擴展）——他自己有客戶同樣需求（醫療營養品：安素、葡勝納、倍速益、補體素、倍力素），跟 Tom 講了之後 Tom 才意識到**這工具也能用在家裡的失智媽媽身上**（自己照顧媽媽卻沒自動聯想到的盲點）
4. 現在三重使用者：Tom 自家（女兒+媽媽）+ 藥師朋友 + 他的藥局客戶。`drinks.js` 裡**小安素歸類在「醫療營養品」**是橋接起源跟擴展的橋樑產品

真正兩個痛點：
1. **各品牌成分表排序、單位不統一**——有的先蛋白質、有的先熱量、單位 mg/mcg/per 份/per 100ml 混用。使用者原話：**「客戶有時候需求來我們比對來不及」**。櫃檯前要當場比對時，肉眼掃超容易漏行
2. **OCR 實務不可行**——賣家放 100 張商品圖可能只有 10 張真的是成分表，剩下是行銷圖、情境照。營養標示字小又常印在曲面上。所以務實做法是**親自到家樂福/大樹拍包裝**，用 Claude/Gemini 辨識成結構化 JSON

**資料流程**：拍包裝 → AI 擷取 → 手填 `drinks.js` → GitHub Pages 自動部署。比較矩陣左欄**動態生成**——某筆有填碘，那一列才出現。全欄位填含微量元素（brain file 明訂）。粉狀產品的 `volume_ml` 是沖調後體積，前端依此換算 per 100ml。

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
| [家庭園藝手冊](./garden-handbook/) | 直接 `open garden-handbook/index.html` 或上線版 `tm731531.github.io/dementia-care/garden-handbook/` |
| [家中寵物手冊](./pet-handbook/) | 直接 `open pet-handbook/index.html` 或上線版 `tm731531.github.io/dementia-care/pet-handbook/` |
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
