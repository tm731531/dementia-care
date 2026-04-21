# Dementia Care Tools

一位很 I 的軟體工程師做的兩個工具。一個給失智家人，一個給 2023 年出生的女兒。

純前端、單一 HTML 檔、零伺服器、零廣告、零追蹤、完全離線可用。
想做什麼就做什麼，用最純粹的技術，讓每個家庭都能免費使用。

---

## 工具列表

| 工具 | 對象 | 類型 | 說明 |
|------|------|------|------|
| [陪伴小幫手](./dementia-companion/) | 失智症長輩 + 照護者 | 互動遊戲 | 15 種認知訓練遊戲，8 級難度自動調整 |
| [小朋友學習樂園](./kids-companion/) | 2–6 歲幼兒 + 家長 | 互動遊戲 | 25+ 種寓教於樂的學習活動 |
| [白板 OCR 紀錄 Bot](./whiteboard-ocr-bot/) | 家屬 + iDempiere | Telegram Bot | 每日照片 → Gemini 3 OCR → 自動寫入 iDempiere，每月回診給醫生看 |
| [就診小幫手](./mom-clinic-companion/) | 照護者 | 手機 Web App | 回診前 prep 工具：拉 iDempiere 記錄、自動抓異常、症狀分類、診間錄音 |

---

## 為什麼做這個

### 陪伴小幫手

陪伴失智家人時，想話題、找互動方式來促進腦部活動，對一個內向的人來說相當消耗腦力。所以做了這個工具——打開就能用，不用想話題，遊戲自動引導互動。希望幫助所有同樣辛苦的照護者。

### 小朋友學習樂園

為了 2023 年出生的女兒，想做一個跟她互動的遊戲。不想裝 app、不想看廣告、不想傳資料到外面。一個 HTML 檔，開了就能玩。

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

---

## 技術特色

- **單一檔案**：每個工具就是一個 `index.html`，所有 HTML + CSS + JS 都在裡面
- **零依賴**：不需要 npm、不需要 build、不需要伺服器（雙擊開檔案就能用）
- **完全離線**：所有圖片內嵌 base64，語音用瀏覽器內建 Web Speech API
- **零資料外傳**：進度存在瀏覽器 localStorage，不送任何東西到外部

---

## 快速使用

直接用瀏覽器開檔案就能用：

```bash
# 失智照護工具
open dementia-companion/index.html

# 兒童學習平台
open kids-companion/index.html
```

或用本機伺服器：

```bash
npx serve dementia-companion -l 8002
npx serve kids-companion -l 8003
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
