# care-handbook — 失智長照服務找法手冊

## 專案簡介
**找居服員 / 日照 / 喘息 / 機構 / 看護工 的方法論手冊**。對應於 `childcare-handbook`(找幼兒園),但對象是失智長照服務。

跟 `home-handbook` 的分工:
- **care-handbook(本)**:**找服務階段** — 怎麼選 / 比較 / 預算 / 簽約
- **home-handbook**:**已選好服務後** — 每天執行 SOP(居家日 / 日照日 / 緊急狀況)

## 主要使用者
- 失智家屬找新服務(剛確診 / 已有部分服務想擴增)
- 服務提供者(可能順便用對照 SOP)

## 為什麼做這個
家屬「親人接手照護」幾乎都失敗(親情無契約、不能投訴)。**手冊真正用途是:對「有付錢的服務提供者」拿來做 SOP 對照工具**。care-handbook 在「找的階段」做出選對人選對機構的決策工具。

## 技術架構
- **單一 HTML**(`index.html`),純前端,離線可用
- 0 CDN
- 結構複用 `childcare-handbook` 的 6 輪驗證 UX:Wizard / 比較籃 / Calendar / 預算試算
- localStorage key: `careHandbookState`
- Favicon: 🏥

## 涵蓋範圍

### 5 種服務類型
1. **居家照顧服務(居服員)** — 個人接案 / 居家照顧服務中心(政府) / 民間業者
2. **日間照顧中心(日照)** — 失智專責 / 一般日照
3. **短期住宿喘息** — 居家式 / 機構式
4. **長照機構**(住宿型,連 home-handbook/long-term)
5. **外籍看護工**(俗稱外勞,申請流程複雜)

### 附加章節
- 補助系統(長照 2.0 / 重大傷病 / 失能等級 / 喘息額度)
- 申請流程(撥 1966 → CMS 評估 → 照管專員 → 服務媒合)
- **失智專屬支援系統**(共照中心 + A 個管師 / GA07 家屬訓練諮商給付碼 / 巷弄失智據點)— 收件人是<strong>家屬本人</strong>,跟 5 大類給失能者的服務 orthogonal
- 觀察 / 面試 SOP(居服員面試 / 日照參訪 / 機構參訪)
- 跨服務組合(居家+日照+喘息怎麼搭,預算/時程)
- 「靠北」對照表(SOP 沒做怎麼投訴)

### handbook 分工 frame
- **home-handbook**:提醒「**有這些東西**」(awareness) — 家屬日常翻才 surface
- **care-handbook**:教「**怎麼用這些東西**」(SOP) — 要申請時來這找細節
- 失智專屬支援頁:home 短 pointer + cross-link → care 完整 SOP

## 互動工具(複用 childcare-handbook 模組)
- Wizard(失智程度 / 預算 / 急迫性 / 已有什麼)
- 比較籃(28 欄,對接服務提供者)
- Calendar(預約 / 排班 / 喘息額度倒數)
- 預算試算(長照補助 + 自費差)

## 設計原則
- 跟 home-handbook 互聯(找完後跳到執行 SOP)
- 給「服務提供者」用的觀察點明確標出(可拿來投訴)
- 失智程度連動建議(輕度 / 中度 / 重度推薦不同服務組合)

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md`(必讀)
- `~/.claude/projects/-home-tom-Desktop-dementia-care/memory/feedback_caregiver_handbook_sop_first.md`
- `~/.claude/projects/-home-tom-Desktop-dementia-care/memory/feedback_handbook_failure_prominence.md`

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/care-handbook/`
- 純靜態,push main 自動部署
