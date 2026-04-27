# Place Quality Spec v1.0

> 9-step expert review (2026-04-27) 後正式建立的景點品質規則。
> 新增景點前 / Code review 時必對照本 spec。違反任一條 = NG。

## 為什麼這份文件存在

歷次擴點累積踩過的坑:

1. **泛稱命名陷阱** — `土城親子館` 在 Google Maps 全台有 N 個結果,定位無意義。
2. **座標漂移** — 一開始用 area 中心粗估,實際景點離 area 中心 5-15 km。Tom 在現場 GPS 比對發現偏差。
3. **area / region 互不一致** — 陽明山系 6 筆 area=「新北烏來」,實際在台北北投 / 士林。
4. **ages enum 寫錯** — 寫 `'1-2'` 而不是 `'0-2'`,過濾失效。
5. **個人經驗瞎掰** — note 寫「小孩去過很喜歡」實際沒去過。

每條規則背後都有一次具體事故。

---

## 8 條硬規則(Rules)

### Rule 1 — name 必須是 Google Maps 唯一可定位的點
**Why**: name 同時是顯示名稱 + Google Maps 搜尋 query。如果是泛稱(`板橋親子館`),搜尋會跳出多個 pin,使用者點按鈕不知道要去哪。

**How to check**:
- Google Maps 搜尋 `<name> <city>`(例如 `板橋新板親子館 新北市`)
- 如果結果頁 h1 是「結果」(多筆) → ✗ NG,必須改成具體館名
- 如果是 place detail panel 且 h1 跟 name 名字 match (exact / partial) → ✓ OK

**Examples**:
- ✗ `土城親子館`(全台多個土城親子館)→ ✓ `廣福親子館`
- ✗ `板橋親子館` → ✓ `板橋新板親子館`
- ✗ `蘆洲親子館` → ✓ `蘆洲集賢親子館`

### Rule 2 — area 必須對應實際座標所在的「縣市 + 區」
**Why**: 範圍篩選用 `area` 推算距離 fallback,如果 area 寫錯,「範圍 30 km」會把實際 50 km 的景點也包進來。

**How to check**:
- 把 PRECISE_COORDS[id] 反查 nearestDistrict
- 比對 area 的「縣市 + 區」 prefix
- 不一致 → 改 area + region

**已知踩坑**:
- 朱銘美術館 area=台北北投 → 實際在新北金山(2026-04 修)
- 陽明山系 6 筆 area=新北烏來 → 實際在台北北投/士林(2026-04 修)

### Rule 3 — 經緯度必須在合理範圍
**Why**: 一次 Playwright 校正抓錯 query 把法國某地寫進來,範圍篩選炸掉。

**台灣本島**: 21.5 ≤ lat ≤ 26.5, 118 ≤ lng ≤ 122.5(含離島澎湖金門馬祖)

**How to check**:
```js
function inTaiwan(lat, lng) { return 21.5 <= lat && lat <= 26.5 && 118 <= lng && lng <= 122.5; }
```

### Rule 4 — region key 必須對應 area 首尾
**Why**: `region` 是粗篩 key(taipei / newtaipei / taoyuan / yilan / taichung...)。area 改了忘記改 region 會導致 region 篩選漏掉。

**How to check**:
- area 開頭兩字 (台北/新北/桃園/...) → 對應到 TAIWAN_DISTRICTS prefix → 取 region key

### Rule 5 — enum 欄位必須使用合法值
**ages**: `'0-2' | '2-3' | '3-6'`(寫 `'1-2'` 過濾不到)
**seasons**: `'spring' | 'summer' | 'autumn' | 'winter'`
**weathers**: `'sunny' | 'rainy'`
**crowd**: `'low' | 'mid' | 'high'`(怕感冒 filter 用)

**indoor / outdoor**: 都是 boolean,可同時 true(例如博物館有戶外庭園)

### Rule 6 — note 不寫個人經驗(避免瞎掰)
**Why**: AI 會幻覺寫「2025/3 帶孩子去過,小孩很喜歡」實際 AI 沒去過。

**Allowed in note**:
- 客觀景點特徵(「大草地 + 朱銘雕塑」)
- 季節 hint(「3-4 月海芋季」)
- 設施提示(「平緩無障礙步道,推娃娃車 OK」)

**Forbidden**:
- 「我家」「小孩」「上次」之類個人化敘述
- 主觀評價(「超好玩」「很值得」)

我家評語走 user-input localStorage,不寫死在 PLACES。

### Rule 7 — crowd 必填(怕感冒 filter 必要)
**Why**: 太太怕感冒 → 「人多」必須能排除。

- `'low'`:平日少人、深山步道、冷門景點
- `'mid'`:週末中等人潮、社區公園、地方文化景點
- `'high'`:熱門大景點(動物園、Xpark、巧虎夢想樂園、九份)

### Rule 8 — warning 寫致命條件,放動作前
**Why**: 「冬天封山」「需先預約」不能埋在 note 中段。會讓使用者白跑。

**用 warning field**(顯示在卡片上方,⚠️ 黃底):
- 季節限定(「夏季開放」「12-2 月封閉」)
- 預約限制(「需先跟林務局申請」「需 7 天前預約」)
- 體能門檻(「陡峭階梯多,適合 6 歲以上」)
- 安全警示(「夏季悶熱有蛇」)

---

## 擴點優先順序(Wave 1 → 5)

> 9-step expert review 觀察到的缺口。一次擴 25-30 個,每個都過 8 條規則。

### 缺口分析(2026-04-27 現有 774 筆統計)
| 類型 | 現有 | 目標 | 缺口 |
|--|--|--|--|
| 新北雨天室內(博物館/觀光工廠/圖書館) | ~30 | 60+ | **#1 補** |
| 0-2 歲友善(推車 + 平緩 + 爬行區) | ~80 | 150 | **#2 補** |
| 觀光工廠 / 農場 / 生態園 | ~60 | 100 | **#3 補** |
| Glamping 露營區(全家) | ~20 | 40 | #4 補 |
| 雲嘉南 / 高屏(中南部偏少) | ~150 | 200 | #5 補 |

### Wave 計畫
- **Wave 1**: 新北雨天室內 25 個(板橋/三重/中和/永和/新莊優先,室內可避雨)
- **Wave 2**: 0-2 歲友善 25 個(全台,重點補 toddler 適合的低門檻地點)
- **Wave 3**: 觀光工廠 + 農場 25 個(新竹/苗栗/彰化/雲林觀光工廠重鎮)
- **Wave 4**: Glamping 25 個(宜蘭/南投/苗栗主流露營區)
- **Wave 5**: 雲嘉南 + 高屏 30 個(中南部景點補強)

每一 wave 完成後要跑 validation:
1. `python3 /tmp/validate_maps_uniqueness.py` 驗證 Rule 1
2. Range/region check 驗證 Rule 2-4
3. Manual code review 過 Rule 5-8

---

## Code Review Checklist(每次新增景點要過)

- [ ] Rule 1: name 在 Google Maps 唯一可搜到
- [ ] Rule 2: PRECISE_COORDS 與 area 一致(差距 ≤ 5 km)
- [ ] Rule 3: lat/lng 在台灣範圍內
- [ ] Rule 4: region key 對應 area prefix
- [ ] Rule 5: ages / seasons / weathers / crowd enum 合法
- [ ] Rule 6: note 不寫個人經驗
- [ ] Rule 7: crowd 必填
- [ ] Rule 8: 致命條件放 warning 不要埋在 note
- [ ] 尾逗號:每筆 object 後一定 `,`(整頁 blank 慘案 2026-04-21)
