# kids-weekend — 週末帶小孩去哪推薦工具

## 專案簡介
**全台 22 縣市 800+ 親子景點 + 路線規劃工具**。1 題 wizard(住哪)→ 預設 20 km 推薦 → 設目的地組多點路線 → 一鍵丟 Google Maps 多段導航。

## 為什麼做這個
週末為「該帶小孩去哪玩」煩惱時,媽媽社團爬 200 則訊息、Google Maps 收藏一堆從沒去過的點都不解決「**現在這個 km 範圍家附近,有什麼順路可以串成一日?**」這個具體問題。

## 主要使用者
- 全台家有 0-6 歲小孩的家庭(台北/新北/桃園/台中/高雄各區都涵蓋)
- v0 預設以新北土城為中心(Tom 自家),但 GPS / 縣市選可改任何位置
- 太太級用戶優先(藥師朋友的太太是測試者)

## 技術架構
- **單一 HTML**(`index.html`,~540 KB,含 800+ 景點 + 座標 + JS + CSS)
- **0 CDN**(隱私要求 — 字型用系統 fallback)
- localStorage key: `kidsWeekendState`(版本 schema 在 `STATE_VERSION`)
- Favicon: 🗺️
- 主色:橘色(#ff8c42)+ 海洋藍(#4a8fb8) — 跟其他子專案區隔

## 資料結構

### Wizard 1 問(2026-04 砍簡)
1. **住哪**:GPS 一鍵 / 縣市 + 區下拉

天氣晴雨家長自己看(原 Q2 砍掉)、年齡只是 informational tag(原 Q3 砍掉)、範圍預設 20 km(可拉滑桿改 5-400 km,原 Q4 砍掉)。

### 景點 schema(完整版)
```js
{
  id: 'sci-museum',                   // 唯一 ID,英數連字符
  name: '國立臺灣科學教育館',          // Google Maps 唯一可定位的點(Rule 1)
  emoji: '🔬',                         // 一個 emoji(系統字型 fallback)
  area: '台北士林',                    // 「縣市 + 區」格式
  region: 'taipei',                    // 對應 TAIWAN_DISTRICTS key
  indoor: true, outdoor: false,        // 室內/戶外(可同時 true)
  booking: true,                       // (選填) 親子館 / 托育中心 自動標
  weekend_jam: true,                   // (選填) 假日塞車黑名單(陽明山/九份/淡水)
  ages: ['2-3','3-6'],                 // ['0-2'|'2-3'|'3-6'] enum
  seasons: ['spring','summer','autumn','winter'],
  weathers: ['sunny','rainy'],
  types: ['室內','教育','文化'],       // 自由 tag,~63 個
  note: '簡介好處(不寫個人經驗)',
  warning: '致命條件 / 預約 / 季節限定',
  crowd: 'low' | 'mid' | 'high',       // 怕感冒 filter 用
  // 以下由爬蟲自動填(scripts/scrape_meta.py)
  hours: {                              // 7 天營業時間
    mon: '09:00-17:00',
    tue: '09:00-17:00',
    ...
    sun: 'closed' | '24h' | 'HH:MM-HH:MM',
  },
  website: 'https://...',              // 官網(預約 / 票價 / 公告)
}
```

座標另存 `PRECISE_COORDS` 物件:
```js
const PRECISE_COORDS = {
  'sci-museum': [25.0834, 121.5145],   // [lat, lng] WGS84
  ...
};
```

### Google Maps 連結邏輯
```js
const url = precise
  ? `https://www.google.com/maps/search/${encodeURIComponent(name + ' ' + city)}/@${lat},${lng},16z`
  : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(name + ' ' + city)}`;
```

## 設計原則
- **景點寫死在 HTML**:800 筆 + 座標 + hours + website 全 inline,不需要後端
- **「我家評語」空白**:user 自己 localStorage 填(不替 user 瞎掰個人經驗)
- **0 CDN**:Google Maps 連結是使用者主動點擊,不算違規
- **資料品質規格**:見 `PLACE_SPEC.md` — 8 條硬規則(name 必須 Google Maps 唯一定位的點 等)
- **穩 > 快**:大型批次任務(爬蟲 / schema 升級)跑完整輪驗證 sample 過再 apply,不上半成品

## 部署
- GitHub Pages: `https://tm731531.github.io/dementia-care/kids-weekend/`
- 純靜態,push main 自動部署(30-60 秒)

## Domain Brain
- `~/.claude/projects/-home-tom/memory/brain/design-principles.md`(通用原則 + 0 CDN + emoji 相容性)
- `~/.claude/projects/-home-tom-Desktop-dementia-care/memory/feedback_stability_over_speed.md`(穩 > 快)

## 相關文件
- `README.md` — 給使用者的入口
- `docs/使用手冊.md` — 完整功能說明 + 4 個情境範例
- `PLACE_SPEC.md` — 8 條景點品質硬規則 + 5 wave 擴點計畫
- `index.html` 內建「📚 使用說明」頁

---

## 擴點 SOP(以後加新景點要跑這套)

### Step 1:寫候選清單(Python script)
複製 `scripts/wave_template.py`(若沒有可從現有 wave_*_candidates.py 抄一份),寫候選 list:

```python
CANDIDATES = [
    # (id, name, emoji, area, region, ages, types, indoor, outdoor, note, crowd)
    ('id-1', '景點名', '🎨', '台北中山', 'taipei', ['2-3','3-6'], ['室內','文化'], True, False, '簡介', 'mid'),
    ...
]
```

### Step 2:Playwright 唯一性驗證(必)
```bash
python3 scripts/validate_uniqueness.py
```
此腳本會用 query「景點名 + 縣市 + 區」打 Google Maps,檢查:
- h1 = '結果' → ambig 多筆,**淘汰**
- place_links > 0 → 同樣淘汰
- h1 = 具體名字 + place_links = 0 → ✓ 唯一,採用

採用 Google 給的 h1 名字當 final name(更精確)。從 redirect URL `@lat,lng` 抓座標。

### Step 3:Apply 候選通過的景點到 PLACES + PRECISE_COORDS
寫 `apply_wave_N.py`(參考歷史 wave_*_changes.json 結構)。要做:
- 過濾去重(name 重複 / 座標 < 150m 視為 dup)
- 去廣告 / 郵遞區號 / 太短的 h1
- 寫入 `index.html` 的 `PLACES` 陣列(在最後一筆 `]` 之前)
- 寫入 `PRECISE_COORDS` 物件(在最後一筆之前)

### Step 4:爬 Google Maps metadata(hours + website)
**這步是 2026-04-28 加的,以後新景點都要跑**。

```bash
python3 scripts/scrape_meta.py
```

腳本會:
- 讀 `index.html` 抓所有 PLACE id
- 已在 `/tmp/scrape_meta.json` 的跳過(支援續跑)
- 對每筆景點打 Google Maps,搜尋 `<name> <city>`
- 抓:
  - `hours` 7 天營業時間(展開時間表 + parse 成 `{mon:'09:00-17:00',...}`)
  - `website` 官網連結
- 進度寫 `/tmp/scrape_meta.log`,結果寫 `/tmp/scrape_meta.json`
- 約 5-10 秒/筆,800 筆需 ~2 hr

時間表 parser 處理三種 case:
- `HH:MM-HH:MM`(`09:00-17:00`)
- `24 小時營業` → `24h`
- `休息` / `Closed` → `closed`

### Step 5:Apply scrape 結果到 index.html
```bash
python3 scripts/apply_meta.py
```

把 `/tmp/scrape_meta.json` 的 hours + website 寫進 `index.html` 每筆 PLACE 物件(在 `crowd:'X'` 之後)。

### Step 6:語法檢查
```bash
node -e "
const fs=require('fs'); const html=fs.readFileSync('kids-weekend/index.html','utf8');
const scripts=[...html.matchAll(/<script(?![^>]*type=[\"']application\/ld)[^>]*>([\s\S]*?)<\/script>/g)];
for(const m of scripts){if(m[1].length>200){try{new Function(m[1]);console.log('JS OK')}catch(e){console.log('FAIL:',e.message)}}}
"
```

### Step 7:Commit + Push
```bash
git add kids-weekend/index.html
git commit -m "feat(kids-weekend): vX.YZ Wave N — 主題 +N 景點"
git push
```

---

## 數據成果(2026-04-30 更新)

| 指標 | 數字 |
|--|--|
| 景點 | **851 筆** |
| 縣市覆蓋 | **22 縣市全到位** |
| Google Maps 唯一性 | 71%(剩 29% 是真泛稱:夜市、老街、月世界) |
| hours 灌入 | 484 筆(57%) |
| website 灌入 | 555 筆(65%) |
| 9 步 expert review | 全跑完(domain 識別 → 名字驗證 → 座標 → GPS 同系統 → UIUX) |
| Wave 擴點 | 5 wave +44 + 圖書館 wave A→C +33 = **+77 景點** |

## 圖書館擴點(2026-04-30 完成 Wave A→C)

| Wave | 內容 | 數量 | source |
|--|--|--|--|
| 既有 5 補 tag + #1 北投校正 | 補`圖書館` tag + 北投分館 name + coord 修 | 既有 | OSM Nominatim |
| 親子/兒童 | libstat 親子+兒童 keyword strict OSM verify | +4 | libstat + OSM |
| Wave A 縣市總館 | 22 縣市總館 候選 strict OSM verified | +6 | libstat + OSM |
| Wave B Playwright geocode | 23 候選 → Google Maps geocode → bbox 過濾 | +20 | libstat + Google Maps |
| Wave C 文學/繪本 | high-value(46 閱覽室全部 reject 避免雜訊)| +3 | libstat + Google Maps |

關鍵 lesson:**圖書館 ≠ 景點 precision contract**
- 景點(公園/山林/老街)area centroid 1-2km 噪音 OK
- **圖書館 = 單一建築,1km 偏差 = 不同樓棟 = 錯**,Tom 「我寧可放掉不精準的」
- 對圖書館 entry,**沒有 OSM verified or Google Maps geocode 的 bbox 過 → 直接 drop,不走 area centroid fallback**

## 政府開放資料 source(libstat)

`scripts/scrape_libstat.py` 抓 國家圖書館 全國圖書館統計系統(libstat.ncl.edu.tw)
- 22 縣市 hash + 圖書館類別 hash 過濾
- 每筆 detail page 拿 official address + 電話 + 官網
- **政府公開,不走 Maps,合規 source**

`scripts/geocode_libstat.py` 用 Playwright + Google Maps redirect URL 抓 @lat,lng
- throttle 5s + jitter ±2s(接近人類點擊節奏)
- 對 Tom self-use scope 屬「Selenium 驗證例外」(2026-04-30 memory 校正)
- **3 條 reject pattern**:
  1. 離島地址(連江)Google Maps 找不到
  2. 「樓層 + 描述性」(忠孝公園內 / 4 樓)地址 Google fallback
  3. 落到同個 default pin [24.9790, 121.4579] = false geocode signal

## 踩過的坑(歷史)
- **物件 literal 尾逗號陷阱**(2026-04-21 整頁 blank):新增 PLACES 必須每筆都帶逗號
- **Apostrophe 在 name**(`Cona's妮娜巧克力` 炸 JS):爬蟲必須 escape `'` → `\'`
- **Google h1 帶郵遞區號**(`222新北市深坑區深坑街`):過濾 `^\d{3,5}` 開頭
- **Google h1 抓到不同品牌**(日出鳳梨酥 → 郭元益):字元重疊 < 20% 視為錯抓 reject
- **Google 廣告塞 first place_link**(東眼山國家森林 → 東南旅遊三峽):同上 overlap 過濾
- **直線 corridor 跨河 / 繞山**(土城 → 觀音山直線跨淡水河,實際開車要繞 25 min):**接受誤差,不改駕駛時間版**(導遊建議,Tom 暫不做)
- **GPS 顯示經緯度醜**:必須 reverse geocode 成「📍 新北土城」
- **age filter 太死**(觀音山 ages=['3-6'] 卡掉 2-3 歲視角):2026-04-28 砍掉 age 從 wizard,變 informational tag
- **「@lat,lng 出現在 Google Maps URL」非 100% 可靠**(2026-04-30 Wave B):3 筆地址 Google 找不到 → fallback 到同個 default pin [24.9790, 121.4579],bbox 比對才 catch 出來。**未來地址 geocode 必跑 county bbox sanity**
- **OSM Taiwan POI 覆蓋率 ~40%**(Overpass amenity=library 853 筆 vs libstat 700+ 筆):name 太通用(「文化局圖書館」/「圖書館」)易 false match,**長度 ≥ 6 chars + ≤ 3km 距離 gate + reject 分館/閱覽室 後綴** 三條同時才 strict match
