# 02 · 托幼選擇（0-6 歲）（Tab 2）

> ⏳ **Phase 2 待遷入** — 內容從 `~/Desktop/dementia-care/childcare-handbook/index.html` 遷過來。

## 預計內容（來源：原 childcare-handbook）

### 4 種托育類型 × 兩個年齡段

| 類型 | 適用年齡 | 費用 | 報名 |
|--|--|--|--|
| 公托 / 公幼 | 0-6 | 最低 | 各縣市網站抽籤 |
| 非營利幼兒園 | 2-6 | 第 1 胎 3000 | 統一網站，電腦抽籤 |
| 準公共 | 0-6 | 第 1 胎 3000 上限 | 各園自辦 |
| 私立 | 0-6 | 8000-50000+ | 各園自辦 |

### 主要章節
- 首頁：你的孩子幾歲？推薦該做什麼
- 5W1H 方法論（6 個維度評估園所）
- 4 類型詳細比較
- 看園所 checklist（6 大維度：安全 / 師資 / 環境 / 餐食 / 教學 / 隱形費用）
- 時程地圖（0-6 歲每年該做什麼）
- 文件 SOP（戶口名簿 / 預防接種卡 / 健保卡 / 家長證）
- 抽籤機制（正取 / 備取 / 備取保留期）
- 常見地雷（全盤失敗的前提條件）
- 失智照護家庭專區（接續 Tab 4 sandwich-generation）
- 案例 logs（去識別化）

---

## 風格：SOP-first

- 「動作之前」就告訴你坑（不用踩過才知道）
- 時間表 + checklist + 條件式建議
- 縣市資料持續補進（PR welcome）

## Phase 2 遷移注意

- localStorage migration：`childcareHandbookState` → 合進 `kidsHandbookState.tab2`
- 保留 `CITY_PORTALS` array 結構
- 保留 `CASE_STUDIES` array（去識別化案例）
- 原 `childcare-handbook/index.html` archive 後加跳轉到本 tab 對應錨點

## 三明治世代特別考量

「接送動線 vs 長輩生活圈」「祖父母接孫可行性（認知功能評估）」「喘息服務 + 日照中心 + 幼兒園疊合」三段移到 `04-cross-stage/sandwich-generation.md`，這裡留 link。
