# childcare-handbook — 托嬰/幼兒園選擇方法論手冊

## 專案簡介
一本**托嬰中心 + 幼兒園選擇方法論手冊**,涵蓋 0-6 歲所有托育選項。

**4 種類型**:
- 托嬰(0-2 歲):公托 / 準公共 / 私立
- 幼兒園(2-6 歲):公幼 / 非營利 / 準公共 / 私立

跟「找最便宜」「找最近」不同 — 這本手冊教**怎麼系統性評估**,讓家長在「報名截止前」就知道「該看哪些點、該準備哪些東西、該追蹤哪些時間」。

**上位 mission**:repo 的「**讓整個家忙起來**」策略 — 但這個工具是給「家裡有 0-6 歲幼兒」的家庭用,特別是**三明治世代**(同時照顧失智長輩 + 幼兒)。

## 技術架構
- **單一檔案**:`index.html`(所有內容 + JS + CSS,純靜態)
- **純前端**:HTML + Vanilla CSS + Vanilla JS(no framework, no build)
- **離線可用**:所有資源 inline
- **🔴 零外部 CDN 依賴**
- **狀態**:localStorage(收藏園所、家庭模式、checklist 完成度),可匯出匯入 JSON
- **Favicon**:SVG inline emoji(🧒)

## 資料結構

### 全域狀態
```js
const STATE = {
  childAge: null,        // 'infant' (0-2) | 'toddler' (2-3) | 'preschool' (4-6)
  familyMode: 'normal',  // 'normal' | 'sandwich' (有失智長輩) | 'dual_income' | 'single_parent'
  favorites: [],         // 收藏的園所類型 ['public-kindergarten', 'nonprofit', ...]
  checklist: {},         // 文件 / 行動 checklist 完成度
  cases: [],             // 使用者自己加的案例(未來)
}
```

Storage key: `childcareHandbookState`

## 核心功能(v1)

### 🎯 年齡 + 階段選擇(首頁)
- 0-1 歲 → 主要看托嬰
- 2-3 歲 → 幼兒園 2 歲班 first batch
- 4-6 歲 → 大班、續讀評估
- 行動推薦:「離下次大波報名還有 X 個月」

### 🎯 4 種類型對照
| 類型 | 適用 | 費用 | 報名 | 抽籤 | 等候 |
|--|--|--|--|--|--|
| 公托/公幼 | 0-6 | 最低 | 各縣市網站 | 區域順位 | 1-3 年 |
| 非營利 | 2-6 | 第1胎 3000 | 統一網站 | 統一電腦 | 中等 |
| 準公共 | 0-6 | 第1胎 3000 上限 | 各園 | 各園自辦 | 中等 |
| 私立 | 0-6 | 8000-50000+ | 各園 | 名額制 | 即時 |

### 🎯 5W1H 方法論
6 個維度評估園所,首頁固定顯示:
- 👤 Who:你家狀況
- 🏫 What:選哪一類
- 📅 When:時程
- 📍 Where:地理
- 💡 Why:教學風格
- 🔧 How:報名/抽籤

### 🎯 看園所 Checklist(現場參觀必檢)
分維度:
- 🛡 安全
- 👩‍🏫 師資
- 🏠 環境
- 🍽 餐食
- 📚 教學
- 💰 隱形費用

### 🎯 失智照護家庭專區(差異化)
三明治世代專屬考量:
- 接送動線 vs 長輩生活圈
- 祖父母接孫可行性(認知功能評估)
- 喘息服務 + 日照中心 + 幼兒園 疊合

## 設計原則
- 文字繁體中文,第二人稱「你」
- 大字、大行距(handbook 要能讀)
- 紫色 accent + 白底(跟 pet-handbook 同色系,跟 garden 綠色區隔)
- **可列印**(print stylesheet)
- **🔴 SOP-first**:給時間表 + 最安全預設,不要求家長判斷
- **🔴 失敗條件顯眼**:過了報名截止、備取保留期太短這類「全盤失敗」前提必須放動作前
- **去識別化**:Tom 家的具體資料(土城青雲里、特定園所)→ 變「新北土城雙薪 2 歲」案例

## 開發指引

### 加新內容
1. 文件 checklist:加在 `CHECKLIST_TEMPLATE` array
2. 縣市網站:加在 `CITY_PORTALS` array
3. Failure points:加在「常見地雷」section,用 `<div class="callout warn">`
4. 案例:加在 case logs,需去識別化

### 修改既有內容
直接編輯該 section,不另開檔。

### 發佈前必跑檢查
```bash
# 1. HTML parse
python3 -c "import html.parser;p=html.parser.HTMLParser();p.feed(open('index.html').read());print('OK')"

# 2. CDN leak check
grep -n -E 'https?://[^"]*\.(com|net|org|io|co)/' index.html | grep -v 'tomting\|github\|kid123\|tp\.edu\|edu\.tw\|hpa\.gov\|data:'
# 應只剩政府/教育/官方網站

# 3. Emoji 13.0+ 警告
grep -E "🫚|🪴|🪲|🪼|🪿|🫏|🫛" index.html
# 應該沒輸出
```

## 踩過的坑
目前沒有(新專案)。遇到坑寫進來 + 同步寫進對應 Brain file。

## Domain Brain
從 `~/.claude/projects/-home-tom/memory/brain/` 選:
- `design-principles.md`(必讀 — 通用原則 + emoji 相容性 + 零 CDN)

從 `~/.claude/projects/-home-tom-Desktop-dementia-care/memory/` 選:
- `feedback_caregiver_handbook_sop_first.md`(SOP-first 哲學)
- `feedback_handbook_failure_prominence.md`(失敗條件顯眼處)

## 檔案結構
```
childcare-handbook/
  CLAUDE.md          # 本檔案(dev 指引)
  AGENTS.md          # Agent 團隊設定
  README.md          # 使用者說明
  index.html         # 手冊主體
  docs/
    superpowers/
      plans/
        2026-04-26-v1-skeleton.md
```

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/childcare-handbook/`
- 純靜態,push main 自動部署
