# kids-companion — Current State（2026-04-22）

## 現況：功能擴張中，單檔 9 MB 接近上限

1-6 歲學習 app，23 個活動跨 5 個 tab，4 個年齡層自適應深度。
單檔 `index.html` 已成長到 ~15,000 行 / 9 MB（gzipped 6.6 MB）。

## 已完成里程碑（近期 2026-04）

### 活動擴張（23 個）
- [x] 語言 tab：4 個（認中文字 / 英文字母 / 數數 / 詞彙學習）
- [x] 創作 tab：從 2 擴到 4（加塗鴉畫板 + 聲音配對）
- [x] 動腦 tab：3 個（拼圖 / 記憶翻牌 / 排序分類）
- [x] 故事 tab：5 個（互動繪本 / 童謠 / 猜謎 / 故事選擇題 / 配音遊戲）
- [x] 探索 tab：9 個（天氣 / 情境 / 理財 / 動物園 / 食物 / 數學 / 餐盤 / 場景 / 故事拼組）

### 年齡分級
- [x] 23 活動裡 20 個有完整 4 層分級
- [x] 童謠按 ageGroups 過濾 + large 有古詩（春曉 / 靜夜思）+ 詩人 + 小故事
- [x] 驗證所有活動在 4 年齡層跑通

### 動物園大改造
- [x] 好讚按鈕全拿掉
- [x] 下一隻按鈕放大 / 上一隻縮小 icon
- [x] 分類完畢自動換下一類別
- [x] 類別從 6 擴到 9（加昆蟲 / 極地 / 恐龍）
- [x] 新 46 隻動物補 Wikipedia 真圖
- [x] 搜尋功能（跨類別，點結果直接跳到動物）

### 食物原型
- [x] 搜尋功能（跟動物園共用樣式）

### 首頁 / UX
- [x] 最愛區塊（長按活動卡拖進來，最多 6 個）
- [x] 最愛編輯模式（長按 600ms → × 按鈕出現）
- [x] Language 切換從 header 搬進設定
- [x] 3 欄平板 / 2 欄手機 + 孤兒卡置中
- [x] ACTIVITY_LABELS 對齊（今日學習紀錄不再顯示 raw page-id）
- [x] SVG emoji favicon 🦊

## 進行中 / 待觀察

- [ ] **單檔大小** — 9 MB 接近實用上限，下次加內容前評估拆檔
- [ ] 聲音配對的 speechSynthesis 發音在不同瀏覽器品質不一
- [ ] 塗鴉畫板沒有「儲存作品」功能（只能當下玩）

## 優先序待決

### 若要加新活動
評估落在哪個 tab：
- 創作 4 張剛好不動
- 探索 9 張略多（拆成 2 個 sub-tab？）
- 動腦 3 張可加

### 若要加新動物
每隻 +~20 KB base64 圖。10 隻以上考慮：
- 拆圖片出 inline（放 images/ 資料夾）
- 或用 lazy loading（只載正在瀏覽的類別）

## 不做的事
- 不加帳號 / 登入（隱私 + 家長不想填）
- 不加外部網路資源依賴（離線優先）
- 不加廣告 / 內購（原則）

## 快速進場指引
1. 改活動前 `grep -n "#SECTION:PAGE-XXX"` 找錨點只讀該區塊（不讀整檔）
2. 加新活動記得同步 4 件事：
   - 加到對應 tab 的 `.activity-grid`（`<span class="icon">` 不可自創 class）
   - 加 `<div class="page" id="page-xxx">` + 錨點
   - `navigateTo` 裡加 page init 呼叫
   - **ACTIVITY_LABELS 加 label**（漏加會顯示 raw page id）
3. 加新資料進 IMG 物件前 **grep 前一筆確認結尾有逗號**（踩過坑）
4. 改完至少 Playwright/Selenium 跑 smoke test
5. commit 訊息 `feat:` / `fix:` / `chore:` 明確分類

## 踩過的坑（記錄）
1. Object literal 尾逗號陷阱（整頁 blank）
2. `.activity-card .icon` CSS 合約（不能自創 class）
3. ACTIVITY_LABELS 漏加（raw page-id 洩到 UI）
4. 動物 id 跨類重複（orca / puffin 搜尋出 2 筆）

詳見 `../../../CLAUDE.md` 與 `~/.claude/projects/-home-tom/memory/brain/design-principles.md`。

## 歷史 plan 索引
- `./2026-03-28-...` ~ `./2026-03-30-...` 動物園 / 食物 / 數學 / 餐盤 / 場景 / 故事拼組活動初建
- `./implementation-plan.md` 原始整體計畫
