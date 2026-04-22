# pet-handbook — Current State(2026-04-23)

## 現況
**剛起步 · v0 發布**。原本寫成 `cat-handbook`,scope 擴大到所有家中寵物後重命名為 `pet-handbook`。Categories 改為按物種分類,貓的 6 個 topics 全部移到 🐱 貓 category 下。其他物種 tab 先空,之後擴充。

## 已完成里程碑
- [x] 2026-04-23:scaffold 完成(原 cat-handbook)
- [x] 2026-04-23:6 個核心 topics 完成(親訓新貓、多貓介紹 SOP、飼料挑選、貓草種植、疫苗時程、冬天保暖)
- [x] 2026-04-23:通用知識頁(罐頭碳水計算、飼料判讀、飲水公式、疫苗代號)
- [x] 2026-04-23:**scope 擴大 + 重命名** cat-handbook → pet-handbook,categories 改為物種(貓/狗/兔/鳥/倉鼠/魚)
- [x] 2026-04-23:加進母層 landing + monorepo roadmap 索引

## 進行中
- [ ] 刷新 live 確認排版
- [ ] Tom 決定要不要加「我家的貓」template(讓使用者 fork 填自己的貓)

## 優先序待決

### 🔴 高
- 無(剛起步)

### 🟡 中
- 加第二批 topics:剪指甲、抱貓訓練(訓練類)、結紮時程(醫療類)、罐頭評比(飲食類)
- 個人貓咪紀錄 template(用 memo 功能就夠,但可以寫 starter guide)

### 🟢 低 / Nice-to-have
- 貓齡階段 byLevel(幼貓/成貓/老貓)差異化內容
- 加飼料品牌比較表(2021 最佳 10 款那個)
- 其他資料(可能整合 WDJ 推薦)

## 不做的事(明確 out of scope)
- 不做獸醫急診建議(那要執照,我們只做日常照顧)
- 不做品牌推銷/購物連結
- 不做個別貓咪紀錄的「我家」public entry(Tom 家的兩隻不公開,讓使用者自己用 memo 寫)

## 下一次動工 Trigger
- Tom 家新貓加入、舊貓出狀況
- 讀者 PR 加新 topic
- HackMD 源筆記有重大更新

## 快速進場指引
1. 動工前必讀:`CLAUDE.md` + 母層 `../CLAUDE.md`
2. 加新 topic:在 `index.html` 的 `TOPICS` array push 一個 entry
3. Commit 格式:`feat(pet): 新增 X topic` / `docs(pet): 補 Y 紀錄` / `fix(pet): ...`

## 外部依賴
- 無(純前端單檔)
