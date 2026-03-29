# Dementia Care Tools

一位很 I 的軟體工程師做的兩個工具。一個給失智家人，一個給 2023 年出生的女兒。

純前端、單一 HTML 檔、零伺服器、零廣告、零追蹤、完全離線可用。
想做什麼就做什麼，用最純粹的技術，讓每個家庭都能免費使用。

---

## 工具列表

| 工具 | 對象 | 活動數 | 說明 |
|------|------|--------|------|
| [陪伴小幫手](./dementia-companion/) | 失智症長輩 + 照護者 | 15 種遊戲 | 認知訓練互動工具，8 級難度自動調整 |
| [小朋友學習樂園](./kids-companion/) | 2–6 歲幼兒 + 家長 | 25+ 種活動 | 寓教於樂的互動學習平台 |

---

## 為什麼做這個

### 陪伴小幫手

陪伴失智家人時，想話題、找互動方式來促進腦部活動，對一個內向的人來說相當消耗腦力。所以做了這個工具——打開就能用，不用想話題，遊戲自動引導互動。希望幫助所有同樣辛苦的照護者。

### 小朋友學習樂園

為了 2023 年出生的女兒，想做一個跟她互動的遊戲。不想裝 app、不想看廣告、不想傳資料到外面。一個 HTML 檔，開了就能玩。

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

<a href="https://www.buymeacoffee.com/tomting" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

---

## 作者

**Tom Ting** — [blog.tomting.com](https://blog.tomting.com/)
