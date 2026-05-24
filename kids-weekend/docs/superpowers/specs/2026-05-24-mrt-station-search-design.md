# Q1 wizard 加捷運站搜尋作為「家位置」精準輸入 — Design Spec

- **狀態**:Spec(待 user review)
- **日期**:2026-05-24
- **作者**:Tom + Claude(brainstorming session)
- **影響範圍**:`index.html` Q1 wizard input UI、`scripts/` 新增 2 個 Python 腳本
- **不影響**:結果頁、Google Maps 連結邏輯、PLACES 資料、STATE schema(0 新欄位)

---

## 1. 目的

現有 Q1 wizard 提供 2 種設「家位置」方式:GPS 自動定位 / 縣市+區下拉。**「區」太粗** — 例如「大同區」橫跨 4 公里,而中山站附近的生活圈跟雙連站附近其實不同。

加捷運站作為**第三種輸入方式**(主 UI),讓使用者用「站」這個更貼實際生活圈的單位設家位置。

> 「用中山站比 1 個大同區好用很多」— Tom 2026-05-24

## 2. Non-goals

明確**不做**(YAGNI):

- ❌ 不做高鐵 / 台鐵主站(留待用戶反映)
- ❌ 不做「我今天從這站出發」臨時 override(那是不同 feature)
- ❌ 不改結果頁顯示樣式(仍顯示 `📍 台北中山`,從 region+district reverse)
- ❌ 不改 Google Maps 連結邏輯
- ❌ 不改 STATE schema(0 新欄位)
- ❌ 不改 default 範圍 20km(就算搭捷運實際輻射可能更小)
- ❌ 不做 3 段下拉(系統→路線→站)

## 3. 設計

### 3.1 UI 改動 (Q1 wizard 「手動選」區)

`index.html` 第 2010-2021 行的「手動選」區整段改:

```
┌─────────────────────────────────────┐
│ 📍 用 GPS 自動定位             [按]  │ ← 不動 (line 2006)
├─────────────────────────────────────┤
│ — 或手動選 —                          │
│                                       │
│ 🚇 找捷運站                            │ ← 新主 UI
│ [輸入站名 (中山/板橋/左營...) ____]   │
│   ↓ autocomplete (max 8 筆)          │
│   ┌──────────────────────────────┐  │
│   │ 台北車站 · 台北捷運 板南/淡水信義│  │
│   │ 台北車站 · 桃園捷運 機場 A1      │  │
│   └──────────────────────────────┘  │
│                                       │
│ ▼ 沒有捷運?用縣市/區 (折疊,預設收)  │ ← 原 UI 收進去
└─────────────────────────────────────┘
```

**折疊行為**:用 `<details>` 元素(零 JS),預設關。click 展開後 user 看到既有的 county+district 下拉。

### 3.2 資料 schema(寫死 inline 在 `index.html`)

放在 `TAIWAN_DISTRICTS` 之後:

```js
const MRT_SYS_LABEL = {
  tpe: '台北捷運',
  khh: '高雄捷運',   // 含高雄輕軌(同公司營運)
  tao: '桃園捷運',   // 機場捷運
  tch: '台中捷運',
  ntp: '新北捷運',   // 環狀線
};

// 約 260 筆,~17 KB inline
const MRT_STATIONS = [
  // 台北捷運(~131 站,5 條線:板南/淡水信義/松山新店/中和新蘆/文湖)
  {sys:'tpe', name:'台北車站', lines:['板南','淡水信義'], lat:25.0478, lng:121.5170, region:'taipei', district:'中正', last_verified:'2026-05-24'},
  {sys:'tpe', name:'中山',     lines:['淡水信義','松山新店'], lat:25.0526, lng:121.5202, region:'taipei', district:'中山', last_verified:'2026-05-24'},
  // ...
  // 新北捷運(14 站,環狀線)
  {sys:'ntp', name:'景安',     lines:['環狀'], lat:24.9994, lng:121.5040, region:'newtaipei', district:'中和', last_verified:'2026-05-24'},
  // ...
  // 桃園捷運(22 站,機場捷運)
  {sys:'tao', name:'台北車站', lines:['機場 A1'], lat:25.0496, lng:121.5170, region:'taipei', district:'中正', last_verified:'2026-05-24'},
  // ...
  // 高雄捷運(38 站 + 高雄輕軌 38 站 = 76 站)
  {sys:'khh', name:'美麗島',   lines:['紅線','橘線'], lat:22.6314, lng:120.3017, region:'kaohsiung', district:'新興', last_verified:'2026-05-24'},
  // ...
  // 台中捷運(18 站,綠線)
  {sys:'tch', name:'高鐵台中站', lines:['綠線'], lat:24.1136, lng:120.6155, region:'taichung', district:'烏日', last_verified:'2026-05-24'},
];
```

欄位定義:

| 欄位 | 型別 | 說明 |
|--|--|--|
| `sys` | enum `tpe`/`khh`/`tao`/`tch`/`ntp` | 系統 key,對應 `MRT_SYS_LABEL` |
| `name` | string | 站名(不含「站」字,顯示時加) |
| `lines` | string[] | 經過路線 list(轉乘站多條) |
| `lat`, `lng` | number | WGS84,精度 4 位小數(~11m) |
| `region` | string | 對應 `TAIWAN_DISTRICTS` key,例 `taipei` |
| `district` | string | 對應 `TAIWAN_DISTRICTS[region].dists` key,例 `中山` |
| `last_verified` | YYYY-MM-DD | 對齊 PLACES schema(audit 用) |

### 3.3 搜尋邏輯(JS)

```js
function searchMrt(q) {
  if (!q || q.length < 1) return [];
  const matches = MRT_STATIONS.filter(s =>
    s.name.includes(q) || s.lines.some(l => l.includes(q))
  );
  // 排序:exact name match 優先 > region asc > sys order
  matches.sort((a, b) => {
    const aExact = a.name === q ? 0 : 1;
    const bExact = b.name === q ? 0 : 1;
    if (aExact !== bExact) return aExact - bExact;
    return a.region.localeCompare(b.region);
  });
  return matches.slice(0, 8);
}
```

**重名站處理**(跨系統真實重名:台北車站 / 景安 / 大坪林 / 頭前庄 / 新埔 / 三重 等):分開列,不合併:
- `台北車站 · 台北捷運 板南/淡水信義`
- `台北車站 · 桃園捷運 機場 A1`

理由:合併會讓使用者看不出區別,點選後 lat/lng 走哪邊有歧義(台北車站 TRTC 跟 A1 是不同樓層出入口,座標差 ~150m)。

### 3.4 點選處理(對齊既有 `onHomeDistrictChange`)

```js
function onMrtSelect(stationKey) {
  const s = MRT_STATIONS.find(x => `${x.sys}-${x.name}` === stationKey);
  if (!s) return;
  STATE.userProfile.home = s.region;
  STATE.userProfile.homeDistrict = s.district;
  STATE.userProfile.homeLat = s.lat;
  STATE.userProfile.homeLng = s.lng;
  delete STATE.userProfile.homeIsGps;
  saveState();
  renderWizard();
}
```

**STATE schema 零變動**。結果頁從 `STATE.userProfile.home` + `homeDistrict` 拼出 `📍 台北中山`,跟現在一模一樣 — 只是 lat/lng 從「中山區中心 25.0683, 121.5440」變「中山站 25.0526, 121.5202」,**精準了 ~2 km**。

### 3.5 資料來源 + 驗證(硬規則)

**對齊現有 PLACES 「Playwright 校正座標精準到 Google Maps 實際 place」原則**(commit 2026-04-27 v3.8)。MRT 經緯度走同等級嚴謹度:

#### Step 1: 抓站名 + 路線(政府公開資料)

寫 `scripts/scrape_mrt_stations.py`:
- 台北捷運:https://web.metro.taipei/(站列表 + 路線)
- 高雄捷運:KMRT 開放資料(含環狀輕軌)
- 桃園捷運:TYMC 開放資料
- 台中捷運:TMRT 綠線(目前只有綠線通車)
- 新北捷運:新北環狀線

輸出 `/tmp/mrt_stations_raw.json`(只有 sys/name/lines/region/district,**沒有 lat/lng**)。

#### Step 2: Playwright Google Maps geocode 驗證(必)

寫 `scripts/geocode_mrt.py`:
- 對每站 query `"<sys-label> <name>站"`(例「台北捷運 中山站」)
- 從 Google Maps redirect URL 抓 `@lat,lng`
- throttle 5s + jitter ±2s(對齊 libstat geocode 規範)

**3 條 reject pattern**(對齊 libstat 教訓):
1. **離島 / Google Maps 找不到** → drop,不 fallback
2. **bbox sanity**:lat/lng 必須落在該系統涵蓋區的 bbox 內(例 tpe 必須 25.0-25.2, 121.4-121.7),否則 reject
3. **default pin 偵測**:若多筆 station 落在完全相同的 [lat, lng] → reject(libstat Wave B 教訓:Google 找不到時會 fallback 同一 default pin)

#### Step 3: Random 20 站人工抽驗

從 220 站 random sample 20 站,Tom 點開 Google Maps 比對:
- 顯示的 place 確實是該捷運站(不是周邊的店或公園)
- 距離站體 < 100m

通過 → apply。沒通過 → 找出 root cause,重抓。

#### Step 4: 寫 `scripts/apply_mrt.py` inline 進 `index.html`

對齊現有 `apply_meta.py` 模式:讀 `mrt_stations.json`,在 `TAIWAN_DISTRICTS` 之後插入 `MRT_SYS_LABEL` + `MRT_STATIONS` 兩個 const。

### 3.6 範圍預設

不動。捷運使用者輻射範圍實際更小(3-5 km),但既有 20 km 預設讓使用者拉滑桿改。

## 4. State / Schema 影響

**0 個新欄位**。`STATE.userProfile` 仍是現有 `{home, homeDistrict, homeLat, homeLng, homeIsGps?, range?, ...}`。

捷運只是輸入手段。

## 5. 部署 / 檔案 / 大小影響

| 項目 | 影響 |
|--|--|
| `index.html` 大小 | +17 KB(~260 站 inline,~64 bytes/station) |
| 新檔 | `scripts/scrape_mrt_stations.py`、`scripts/geocode_mrt.py`、`scripts/apply_mrt.py` |
| 0 CDN 規則 | ✅ 不違反(無外部資源) |
| 隱私 | ✅ 不違反(MRT 資料 inline,無第三方請求) |
| GitHub Pages 自動部署 | ✅ 純靜態 push 即生效 |

## 6. 測試 / 驗證

1. **語法檢查**:現有 `node -e "..."` JS syntax 驗證腳本(CLAUDE.md 步驟 6)
2. **手動 smoke**:在台北中山 / 高雄左營 / 桃園機場捷運 三個區域各選一站,確認 result 頁顯示對的 region+district,景點推薦範圍正確圍繞捷運站
3. **重名站**:輸入「中山」應顯示 2 筆(台北 + 高雄),不合併
4. **不存在站**:輸入「abc」下拉應為空(不出錯)
5. **折疊區**:預設收起,點開可用既有 county+district 下拉(不可 regression)
6. **Random 20 站抽驗**:對隨機 20 站 Google Maps 開站名確認 < 100m 誤差

## 7. 風險 / 已知限制

| 風險 | mitigation |
|--|--|
| Google Maps geocode 對某站 fallback 到 default pin → 錯誤座標 | Step 2 bbox sanity + 同座標重複偵測 reject |
| 政府開放資料路線 schema 變動 | scrape script 標 `# AS OF 2026-05-24` 注釋,日後 break 時 grep 找得到 |
| 環狀輕軌(高雄)/ 環狀線(新北)/ 機捷 容易混淆 | `MRT_SYS_LABEL` 統一用「XX捷運」+ lines 帶顏色/編號(高雄輕軌歸 `khh`,lines 寫「輕軌 C1...」) |
| 高雄輕軌 38 站很密(平均 500m 一站),選錯隔壁站 | autocomplete 顯示路線 + 抽驗時注意 |
| 台北車站 vs 機場捷運 A1 「都叫台北車站」 | 視為跨系統重名站,分開列(座標差 ~150m) |

## 8. 踩過的坑 — 預先記下避免重蹈

- **Object literal 尾逗號陷阱** — `MRT_STATIONS` 每筆必須帶逗號(對齊 PLACES 教訓 2026-04-21)
- **Apostrophe in name** — 站名若含 `'` 必須 escape(對齊 PLACES 「Cona's妮娜巧克力」教訓)
- **Default pin fallback false geocode** — Wave B 教訓,bbox + 同座標重複都 reject
- **Selenium / Playwright 商業化禁忌** — geocode 屬「self-use 一次性」,符合 monorepo Selenium 例外規定(memory:project_monorepo_compliance_risks)

## 9. 完成定義

- [ ] `scripts/scrape_mrt_stations.py` 跑完,output `/tmp/mrt_stations_raw.json` 有 ~260 筆
- [ ] `scripts/geocode_mrt.py` 跑完,reject 數 < 10%
- [ ] Random 20 站 Tom 人工抽驗 ≥ 19 通過(95%+)
- [ ] `scripts/apply_mrt.py` 寫入 `index.html`,語法檢查 pass
- [ ] 手動 smoke 5 case 全 pass
- [ ] commit + push,GitHub Pages 部署生效
- [ ] 更新 `CLAUDE.md`「資料成果」段加入 MRT 數字

## 10. 不在這個 spec 解決,但可能後續做

- 高鐵 / 台鐵主站(若有使用者要)
- 「我今天從這站出發」臨時 override(另一個 feature spec)
- 捷運使用者預設範圍降到 5 km(需有使用回饋才動)
- MRT_STATIONS 拆獨立 JS 檔(若 inline 大小成為問題)
