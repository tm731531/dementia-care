# garden-handbook — 家庭可食植物手冊

## 專案簡介
一本**家庭可食植物種植手冊**,涵蓋陽台、窗邊、室內盆栽可食植物。每個植物一個 entry,包含種植方式、取得方式、步驟、等待時間、適合光/地點、常見問題。

**上位 mission**:這個手冊是 repo「**讓整個家忙起來**」策略的一部分 —— 用可食植物讓家裡有**生長中的東西、需要每天互動的動作、可以採來吃的成果**。特別是對有失智長輩的家庭,種植活動是 behavior redirection 的有效工具(詳見 Tom 的 blog「失智照顧半年的三個誤會」系列)。

## 技術架構
- **單一檔案**:`index.html`(所有植物內容都放裡面,純靜態)
- **純前端**:HTML + Vanilla CSS + 最少 JS(anchor 導航用)
- **離線可用**:所有資源 inline
- **🔴 零外部 CDN 依賴**:字型系統 fallback,不用 Google Fonts,詳見母層 CLAUDE.md
- **狀態**:無需(純閱讀內容,不存任何使用者資料)
- **Favicon**:SVG inline emoji(🌱)

## 內容結構(Schema)

**植物是 flexible schema** —— 不強制每個植物填同一組欄位,每個 entry 依該植物特性挑適合的 sections。

**推薦的常用 sections(非必填,依植物適合度挑)**:
- 為什麼適合家庭種植
- 取得方式(扦插 / 種子 / 塊莖 / ...)
- 種植步驟
- 等待時間
- 光線需求 / 適合地點
- 採收
- 失敗點與除錯
- 失智照護應用 Notes(本手冊特色 — 呼應 repo mission)

每個植物上方標示:**難度 / 季節 / 光線 / 建議地點**(快速掃描用)

## 目前 entries
- 🍃 **地瓜葉**(第一個 entry,2026-04-22 起草)

## 未來 entries(待擴充)
- 其他葉菜(空心菜、A 菜)
- 香草(薄荷、九層塔、羅勒)
- 果菜(小番茄、小黃瓜)

## 設計原則
- 文字繁體中文
- 大字、大行距(handbook 要能讀、能列印)
- 綠色 accent + 白底(跟植物氣質一致,不刺眼)
- **可列印**(print stylesheet)
- 閱讀體驗 > 花俏 UI
- 母層 CLAUDE.md 的「零外部 CDN」絕對遵守

## 開發指引
- 所有內容放 `index.html` 單檔
- 加新植物:在 `index.html` 內加一個 `<section class="plant-entry">` + 上方目錄加一條 anchor link
- 更新地瓜葉內容 = 直接編輯該 section,不要另開檔
- 發佈前跑 grep:`grep -n -E 'https?://[^"]*\.(com|net|org|io)' index.html | grep -v 'tomting\|github\|data:'` → 應該沒輸出

## 踩過的坑

### Emoji 相容性 — Unicode 14.0+ 會顯示豆腐框(□)
2026-04-23 踩到:薑 entry 用了 🫚(Unicode 14.0, 2021 才加),Chrome/Firefox/Edge 部分系統字型沒支援,渲染成空方框 □。使用者一眼看到首頁就是「怪怪的圖片」。

**原則:plant emoji 只用 Unicode 10.0 以下(2017 前)**
- ✅ 安全:🍃 🌳 🍅 🍓 🌿 🌱 🥬 🌵 🌸 🍋 🍊 🫑(11.0)🥒
- ⚠️ 邊緣(13.0):🪴(盆栽)— 新系統 OK,舊系統可能 fallback
- ❌ 避免(14.0+):🫚(薑)🫛(豆莢)🪹(空巢)🪺(有蛋巢)

**發佈新 plant entry 前檢查**:
```bash
# 從手冊 grep 所有 plant emoji
grep -E "^    emoji: '" index.html
```
然後用 https://emojipedia.org 查版本,或直接在**你最舊的裝置**(媽媽的平板、朋友的舊手機)開一次手冊確認。

**修法**:替換成 Unicode 6.0 等級的通用 emoji。薑現在用 🌱。

## Domain Brain
從 `~/.claude/projects/-home-tom/memory/brain/` 選:
- `design-principles.md`(必讀 — 通用設計規則)

## 檔案結構
```
garden-handbook/
  CLAUDE.md          # 本檔案
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用說明
  index.html         # 手冊主體(所有植物內容)
  docs/
    superpowers/
      plans/
        2026-04-22-current-state.md
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/garden-handbook/`
- 純靜態,push main 即部署
