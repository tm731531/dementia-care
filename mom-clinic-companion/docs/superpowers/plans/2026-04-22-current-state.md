# mom-clinic-companion — Current State（2026-04-22）

## 現況：正在生產使用

Tom 本人每月 1 次回診用。跑在 GitHub Pages + Tom 的 production iDempiere（`idempiere.tomting.com`）。
下次回診：**2026-04-23（兩天後）** ← 正式戰場。

## 已完成里程碑

### 資料接入
- [x] iDempiere REST API 登入 + token 管理
- [x] Jetty ee8 CrossOriginFilter 裝在 production
- [x] localhost:8080 / production 雙環境自動切換
- [x] `Z_momSystem` 表讀取

### 規則引擎（4 種異常）
- [x] Window comparison（上次回診 vs 上上次回診數值差）
- [x] Co-occurrence（同日多症狀）
- [x] Streak（連續 N 天某狀態）
- [x] Chronic（月累積占比）

### 症狀關鍵字
- [x] 13 類分群 + 每類 include / exclude 關鍵字
- [x] 從 OCR Description 欄抓 events

### UI
- [x] 三大卡片：「值得討論」/「這個月發生」/「要問醫生」
- [x] 一鍵「加進問題」
- [x] 回診日期列表（`APP.visits`）當作區間切分基準
- [x] 詳細 raw data 入口（給診間翻平板用）
- [x] 離線 cache（localStorage）+ 最後同步時間顯示
- [x] SVG emoji favicon 🩺

## 進行中 / 下次回診前必須確認

- [ ] **下次回診（2026-04-23）前跑一次完整 flow**
  - [ ] 登入 production 成功
  - [ ] 上次回診到今天的窗口資料撈到
  - [ ] 規則引擎產出合理的「值得討論」卡片
  - [ ] 加進問題清單 → 複製出來可帶進診間
  - [ ] 離線模式下也能看（診間收訊差）

## 已知觀察 / 待優化

- [ ] 症狀關鍵字會不會誤抓？例：「不吃飯」vs「不愛吃這個」
- [ ] 血壓欄位媽媽後來沒量了 → UI 上要 null 過濾掉不顯示
- [ ] 診間錄音功能：醫生講話轉字，回家同步回 iDempiere
  - [ ] STT 選 Web Speech API 還是 Whisper？（延到下次回診後回顧）

## 優先序

### 🔴 高（下次回診用到）
- 跑一次 prod 完整 smoke test
- 確認 CORS filter 沒失效（iDempiere 有沒有重啟過）

### 🟡 中（次次回診前）
- 症狀關鍵字誤抓率評估
- 規則引擎門檻微調（基於實際資料）

### 🟢 低（有空再做）
- 診間錄音 + STT
- 多個家人支援（目前單一 mom）

## 不做的事
- 不自己架 iDempiere（用 Tom 既有的）
- 不做 app / PWA（web 就好）
- 不分享給外人（隱私 + 資料屬個別家庭）

## 快速進場指引
1. 改規則引擎前用真資料跑一次看 before/after
2. 改 API 呼叫：兩個環境都測（localhost + prod）
3. 新增症狀類別一定要配 exclude 關鍵字
4. 改完留 5 分鐘跑完整 flow（登入 → 看異常 → 加問題 → 複製）

## 外部依賴
- iDempiere production 必須活著
- Jetty CORS filter 必須裝（裝法見 `../../../CORS-MIGRATION.md`）
- 上游資料：whiteboard-ocr-bot 每天要有寫 `Z_momSystem`
