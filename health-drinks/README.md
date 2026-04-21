# 健康飲品成分分析 — 家樂福/大樹前的比較網站

> 在家樂福或大樹藥局貨架前猶豫要買哪瓶營養/能量飲時，打開手機掃一下熱量、糖、蛋白質。
> 市售 app 不是塞廣告就是要登入，所以自己做一個純前端網站。

資料從 [Open Food Facts](https://world.openfoodfacts.org/) 爬下來，容量限制 **180–280ml**（外出隨手一瓶的範圍，減少資料雜訊）。

🔗 **網站**：<https://tm731531.github.io/dementia-care/health-drinks/docs/>

---

## 為什麼做這個

每次去量販店想買點營養補充（B 群、膠原蛋白、機能飲料），貨架上滿滿幾十個品牌，每瓶成分表格都不一樣字。要比較哪瓶糖比較少、蛋白質比較多、熱量划不划算——**肉眼掃不了**。

市售 app：
- 有的要登入、要給位置權限
- 有的塞滿廣告
- 有的資料只有幾個品牌
- 沒有專門針對「容量小、外出喝」這個場景過濾

所以寫一個自己用：
- 爬 Open Food Facts 的開放資料
- 過濾容量 180–280ml
- 純靜態網站，GitHub Pages 部署
- 每 100ml 換算熱量/糖/蛋白質/鈉
- 表格可排序、比較矩陣可顏色標記

---

## 快速使用

### 直接開網站（最常用）

<https://tm731531.github.io/dementia-care/health-drinks/docs/>

手機在店內打開就能看，沒廣告、不登入。

### 本地執行

```bash
cd docs
python3 -m http.server 8080
# 開啟 http://localhost:8080
```

### 補/更新資料（爬蟲）

```bash
python3 scripts/scraper.py
```

爬蟲會：
- 從 [Open Food Facts](https://world.openfoodfacts.org/) 搜尋關鍵字（維他命、能量、機能、豆漿 等）
- 過濾容量 180–280ml 的產品
- 下載圖片到 `docs/images/`
- 輸出 `docs/data/drinks.json`

也可以手動補資料（拍瓶子成分表給 Claude 辨識後填 JSON，這個流程 Tom 本人常用）。

---

## 功能

- **排行表格**：依熱量、糖、蛋白質、鈉、價格排序
- **每 100ml 換算**：容量不同的飲品公平比較
- **比較矩陣**：選幾瓶並排看差異，格子自動顏色標記（綠=優，紅=劣）
- **圖片對照**：Open Food Facts 爬到的產品照

---

## 檔案結構

```
health-drinks/
├── README.md              # 本檔案
├── docs/                  # GitHub Pages 根目錄
│   ├── index.html         # 分析網站(單檔前端)
│   ├── data/
│   │   └── drinks.json    # 爬蟲/手動維護的飲品資料
│   └── images/            # 飲品包裝照
├── scripts/
│   ├── scraper.py         # Open Food Facts 爬蟲
│   ├── fetch_nutrition_images.py  # 補圖片
│   └── validate_extraction.py     # 驗證資料格式
└── staging/               # 待整理的新資料暫存
```

---

## 資料隱私

- 所有資料都是公開的食品成分資訊（Open Food Facts CC BY-SA 授權）
- 網站純前端，沒追蹤、沒廣告、沒登入
- 你在網站上看了什麼、點了什麼，**只有你自己知道**

---

## 資料來源

[Open Food Facts](https://world.openfoodfacts.org/) — 開放授權食品資料庫（CC BY-SA 3.0）

補充資料部分來自實際購買時拍下的包裝成分表，手動填進 JSON。

---

## 作者

**Tom Ting** — [blog.tomting.com](https://blog.tomting.com/)
