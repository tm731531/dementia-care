# newborn-handbook — 新成員計畫手冊

## 專案簡介
**從備孕到新生兒的完整實戰 SOP 手冊**。涵蓋孕前準備、孕中(胎教/產檢/飲食)、產前(待產包/家中物品)、產後恢復(自然產/剖腹產)、出生後爸爸 5 步政府表單(戶口/健保/育兒津貼/育嬰停薪/銀行帳戶)、媽媽母乳增量,到托嬰中心比較。

**起源**:Tom 家 2023 出生女兒實戰整理 + HackMD 個人筆記彙總。給三明治世代(同時照顧失智長輩 + 育兒)家庭參考。

**跟 childcare-handbook 的區別**:
- **newborn-handbook(本)**:**孕前 → 0-3 個月 SOP** — 流程驅動,每個階段做什麼
- **childcare-handbook**:**0-6 歲托嬰 / 幼兒園選擇方法論** — 5W1H 評估方法

## 技術架構
- **單一檔案**:`index.html`(~1,500 行)
- **純前端**:HTML + Vanilla CSS + Vanilla JS,無框架,無 build
- **離線可用**:所有資源 inline
- **🔴 零外部 CDN 依賴**(對齊 monorepo 規則)
- **狀態**:`localStorage[newbornHandbookState]`(checklist 進度)
- **Favicon**:SVG inline emoji(👶)

## 核心結構

| H2 章節 | 內容 |
|--|--|
| 🗺️ 總流程地圖 | 未懷 → 全程 → 不公告期 → 媽媽穩定期 → 快速增長期 → 生命誕生 |
| 🌱 孕前準備 | 健康檢查 / 懷孕日記 / 三明治世代特別考量 |
| 🎵 孕中 10 種胎教 | 光照 / 營養 / 音樂 / 閱讀 / 遊戲 / 語言 / 情緒 / 美育 / 撫摸 / 閃字卡 |
| 🩺 14 次產檢時程 | 8w-40w 含補充檢查 / 健保補助 |
| 🥗 飲食指南 | 一般可吃 / 避開 + **肌瘤患者特別注意**(寒涼/發性/滋補/雌激素分四類) |
| 🏠 月中 / 後援規劃 | 有後援 / 沒後援 兩條路徑 + 三明治世代提醒 |
| 📦 產前準備 | 家中物品 + 待產包(資料 / 日常 / 媽媽 / 可有可無 4 類 checklist) |
| 💪 產後自然產 | 5 點恢復重點 |
| 🔪 產後剖腹產 | 8 點恢復重點 + **體內傷口要 2 個月** warning |
| 👨‍👧 爸爸 5 步政府表單 | 戶政 → 區公所 → 公司 → 銀行 → 保險 |
| 🤱 媽媽母乳 / 配方乳 | 增加母乳 4 招 + 配方乳選擇原則 |
| 🏫 托嬰中心比較 | Tom 家土城 6 家公托/準公比較表(範例,其他縣市套同維度) |
| 📚 育兒資源 | 教育理念 / 教具 / 親子共讀 / YouTube 學技能 / 週末出遊 |
| ❓ 疑難雜症 | 寶寶體重 / 水奶 vs 配方奶 |

## 設計原則
- **三明治世代 frame**:每章加入「若家有失智長輩需特別注意 ...」callout
- **checklist 持久化**:打勾 + localStorage 記住,不會丟
- **米白底深字**(`#faf6f0` / `#2d2520`):長輩 / 孕婦疲累時友善閱讀
- 連結到姊妹 handbook(care / home / childcare / garden / pet / mindset / kids-weekend)
- 政府補助金額 / 表單流程**會異動**,加 footer 提醒以**現場公告為準**

## 開發指引
- 所有內容在單一 `index.html`,checklist 用 `data-key` 標 unique id
- 新增章節時在 `<nav class="toc">` 同步加 anchor
- 改完跑 `node -e "..."` 檢查 JS syntax(雖然只 ~30 行 JS)

## 踩過的坑
無(2026-05-02 初版)。

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/newborn-handbook/`

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md`(0 CDN / 米白底深字 / SVG emoji / 單檔 HTML)

## 檔案結構
```
newborn-handbook/
  CLAUDE.md         # 本檔案
  README.md         # 給使用者的入口
  AGENTS.md         # 母層共用 + 此專案 specific agent rules
  index.html        # 主體
  docs/             # superpowers 規範
```
