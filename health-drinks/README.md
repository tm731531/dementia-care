# 市售健康飲品成分分析

> 容量 180–280ml 的市售健康/營養飲品成分分析網站，部署於 GitHub Pages。

🔗 **網站**：`https://<你的帳號>.github.io/<repo名稱>/`

## 專案結構

```
trai/
├── docs/               # GitHub Pages 根目錄
│   ├── index.html      # 分析網站
│   ├── data/
│   │   └── drinks.json # 爬蟲產生的飲品資料
│   └── images/         # 飲品圖片
└── scripts/
    └── scraper.py      # Open Food Facts 爬蟲
```

## 使用方式

### 1. 執行爬蟲抓取資料

```bash
python3 scripts/scraper.py
```

爬蟲會：
- 從 [Open Food Facts](https://world.openfoodfacts.org/) 搜尋健康飲品
- 過濾容量 180–280ml 的產品
- 下載圖片到 `docs/images/`
- 輸出 `docs/data/drinks.json`

### 2. 本地預覽

```bash
cd docs
python3 -m http.server 8080
# 開啟 http://localhost:8080
```

### 3. 部署到 GitHub Pages

```bash
git init
git add .
git commit -m "init: 健康飲品分析網站"
git remote add origin https://github.com/<你的帳號>/<repo名稱>.git
git push -u origin main
```

然後在 GitHub repo → Settings → Pages → Source 選 `main` branch，資料夾選 `/docs`。

## 資料來源

[Open Food Facts](https://world.openfoodfacts.org/) — 開放授權食品資料庫（CC BY-SA）
