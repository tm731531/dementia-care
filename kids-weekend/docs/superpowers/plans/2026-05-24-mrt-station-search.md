# MRT Station Search Q1 Wizard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Q1 wizard 加捷運站搜尋作為第三種「家位置」精準輸入(主 UI),取代區下拉作為生活圈表達方式。STATE schema 零變動,結果頁/Maps 全不動。

**Architecture:** 兩階段。Phase A 用 Python 腳本抓 5 系統捷運站 + Playwright Google Maps geocode + bbox sanity 驗證 → inline 進 `index.html` 成為 `MRT_STATIONS` const。Phase B 在 Q1 wizard 加 input + autocomplete,折疊既有縣市/區下拉。

**Tech Stack:**
- Frontend: Vanilla HTML + CSS + JS(無框架,單檔 `index.html`)
- Scripts: Python 3 + `playwright` + `requests`
- 0 CDN(MRT 資料 inline)、0 build step、純靜態 GitHub Pages 部署

**Spec:** [kids-weekend/docs/superpowers/specs/2026-05-24-mrt-station-search-design.md](../specs/2026-05-24-mrt-station-search-design.md)

**Working directory:** `/home/tom/Desktop/dementia-care/kids-weekend/`

---

## File Structure

**Create:**
- `scripts/scrape_mrt_stations.py` — 抓 5 系統站名 + 路線 + 區
- `scripts/geocode_mrt.py` — Playwright Google Maps geocode + bbox sanity
- `scripts/apply_mrt.py` — JSON inline 進 index.html

**Intermediate(不 commit):**
- `/tmp/mrt_stations_raw.json` — scrape 結果(無 lat/lng)
- `/tmp/mrt_stations_geocoded.json` — 加 lat/lng + validation flag

**Modify:**
- `index.html` — Q1 wizard markup + MRT_STATIONS const + searchMrt/onMrtSelect JS
- `CLAUDE.md` — 更新「資料成果」段加入 MRT 數字

---

## Phase A: Data Pipeline

### Task A1: Scrape stations via OSM Overpass(單一 query 抓全台 metro)

**Files:**
- Create: `kids-weekend/scripts/scrape_mrt_stations.py`

**Background:** OSM Overpass 一個 query 可抓全台所有 metro/light_rail 站,含 name + operator + lat/lng + ref(站號)。比逐個系統爬政府開放資料省工(每系統 CSV/JSON schema 都不同,寫 5 個 parser 太煩),且 OSM 對 metro 涵蓋接近 100%。

**重要**:OSM 拿到的 lat/lng 是 raw,**仍會在 Task A2 經 Playwright Google Maps 校正**(對齊 PLACES 「Playwright 校正座標精準到 Google Maps 實際 place」 原則)。OSM 在這 task 只是「站清單來源」,座標只當 bbox sanity 的 reference。

- [ ] **Step A1.1: 測試 OSM Overpass query**

先手動測 query 拿回站數估算:

```bash
curl -s "https://overpass-api.de/api/interpreter" \
  --data-urlencode 'data=[out:json][timeout:60];
area["name:zh"="臺灣"]->.tw;
(
  node["railway"="station"]["station"="subway"](area.tw);
  node["railway"="station"]["station"="light_rail"](area.tw);
  node["public_transport"="station"]["network:zh"~"捷運|機場捷運|輕軌"](area.tw);
);
out body;' | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['elements']))"
```

Expected: 數字 ≥ 200(若 < 200 表示 OSM 涵蓋有缺,需配合 Wikipedia/政府資料補,**整個 task 暫停**問 user)。

- [ ] **Step A1.2: 寫 scrape script**

Create `scripts/scrape_mrt_stations.py`:

```python
"""抓全台 metro/light_rail 站清單(OSM Overpass)→ /tmp/mrt_stations_raw.json

OSM 給 name + operator + raw lat/lng + ref(站號可推路線)。
sys 從 operator 推。region/district 從 lat/lng 用 TAIWAN_DISTRICTS centroid 最近反查。

raw lat/lng 在此先寫入(後續 Task A2 由 Playwright 校正覆蓋)。

usage:
    python3 scripts/scrape_mrt_stations.py -o /tmp/mrt_stations_raw.json

output: [{sys, name, lines, region, district, lat_osm, lng_osm, source:'osm'}, ...]
"""
import argparse, json, sys, math, urllib.request, urllib.parse

OVERPASS = 'https://overpass-api.de/api/interpreter'
QUERY = '''[out:json][timeout:60];
area["name:zh"="臺灣"]->.tw;
(
  node["railway"="station"]["station"="subway"](area.tw);
  node["railway"="station"]["station"="light_rail"](area.tw);
  node["public_transport"="station"]["network:zh"~"捷運|機場捷運|輕軌"](area.tw);
);
out body;'''

# operator → sys key
OPERATOR_MAP = [
    ('臺北捷運', 'tpe'), ('台北捷運', 'tpe'), ('Taipei Metro', 'tpe'), ('TRTC', 'tpe'),
    ('新北捷運', 'ntp'), ('NTPC', 'ntp'), ('New Taipei Metro', 'ntp'),
    ('桃園捷運', 'tao'), ('機場捷運', 'tao'), ('TYMC', 'tao'),
    ('臺中捷運', 'tch'), ('台中捷運', 'tch'), ('TMRT', 'tch'),
    ('高雄捷運', 'khh'), ('KRTC', 'khh'),
    ('高雄輕軌', 'khh'), ('Kaohsiung LRT', 'khh'),  # 輕軌歸 khh
]

# ref prefix → 路線(從站號推路線,例 BL12 → 板南線)
LINE_MAP = {
    'BL':'板南','R':'淡水信義','G':'松山新店','O':'中和新蘆','BR':'文湖','Y':'環狀',  # TRTC + NTPC
    'A':'機場',  # TYMC
    'O':'橘線','R':'紅線',  # KRTC (R 跟 TRTC 衝,以 sys 區分)
    'C':'輕軌',  # KLRT
    # TMRT 綠線無 ref prefix 慣例,留空
}

def fetch_osm():
    data = urllib.parse.urlencode({'data': QUERY}).encode()
    req = urllib.request.Request(OVERPASS, data=data,
                                  headers={'User-Agent':'Mozilla/5.0 kids-weekend'})
    return json.loads(urllib.request.urlopen(req, timeout=90).read())

def map_sys(operator):
    """從 OSM operator 推 sys key"""
    if not operator: return None
    for keyword, sk in OPERATOR_MAP:
        if keyword in operator:
            return sk
    return None

def extract_lines(sys_key, ref):
    """從 ref(站號)推路線,例 'BL12' → ['板南']
    ref 多條時用 ; 分隔(轉乘站),例 'BL12;G10' → ['板南','松山新店']
    """
    if not ref: return []
    lines = set()
    for r in ref.replace(',',';').split(';'):
        r = r.strip()
        # 抓字母 prefix
        prefix = ''.join(c for c in r if c.isalpha()).upper()
        if sys_key == 'khh' and prefix == 'R':
            lines.add('紅線')
        elif sys_key == 'khh' and prefix == 'O':
            lines.add('橘線')
        elif prefix in LINE_MAP:
            lines.add(LINE_MAP[prefix])
    return sorted(lines)

# region/district lookup — copy from index.html TAIWAN_DISTRICTS centroid
# 為避免 plan 太長,這 dict 在 script 內也要有(從 index.html 抓 + maintain 同步)
# 簡化:直接 require engineer copy index.html TAIWAN_DISTRICTS object 到 script 一份
TAIWAN_DISTRICTS = {
    # ... 從 index.html line 2124-2191 整 dict copy 過來,或用 import trick
    # (CLI 命令在 Step A1.3 給)
}

def haversine_km(la1, ln1, la2, ln2):
    R = 6371.0
    p1, p2 = math.radians(la1), math.radians(la2)
    dp = math.radians(la2 - la1); dl = math.radians(ln2 - ln1)
    a = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

def find_nearest_district(lat, lng):
    """回 (region, district) 最近的"""
    best = (None, None, 9999)
    for region, cfg in TAIWAN_DISTRICTS.items():
        for dist, (dlat, dlng) in cfg['dists'].items():
            km = haversine_km(lat, lng, dlat, dlng)
            if km < best[2]:
                best = (region, dist, km)
    return best[0], best[1]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-o','--output', required=True)
    args = ap.parse_args()

    print('Fetching OSM Overpass…', file=sys.stderr)
    osm = fetch_osm()
    nodes = osm['elements']
    print(f'OSM returned {len(nodes)} nodes', file=sys.stderr)

    stations_by_key = {}  # (sys, name) → station dict (合轉乘站 lines)
    skipped = 0
    for n in nodes:
        tags = n.get('tags', {})
        name = tags.get('name:zh') or tags.get('name')
        if not name: skipped += 1; continue
        # OSM 站名可能含「站」字 → strip
        name = name.rstrip('站')
        operator = tags.get('operator:zh') or tags.get('operator') or tags.get('network:zh') or tags.get('network')
        sk = map_sys(operator)
        if not sk: skipped += 1; continue
        lat, lng = n['lat'], n['lon']
        region, district = find_nearest_district(lat, lng)
        if not region: skipped += 1; continue
        key = (sk, name)
        if key in stations_by_key:
            # 轉乘站(同 sys 同 name 多次出現),合 lines
            existing = stations_by_key[key]
            new_lines = set(existing['lines']) | set(extract_lines(sk, tags.get('ref','')))
            existing['lines'] = sorted(new_lines)
            continue
        stations_by_key[key] = {
            'sys': sk, 'name': name,
            'lines': extract_lines(sk, tags.get('ref','')),
            'region': region, 'district': district,
            'lat_osm': round(lat, 5), 'lng_osm': round(lng, 5),
            'source': 'osm',
        }

    out = list(stations_by_key.values())
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    from collections import Counter
    print(f'Wrote {len(out)} stations (skipped {skipped})', file=sys.stderr)
    print('By sys:', Counter(s['sys'] for s in out), file=sys.stderr)

if __name__ == '__main__':
    main()
```

- [ ] **Step A1.3: 將 `TAIWAN_DISTRICTS` 從 index.html 抓進 script**

```bash
cd /home/tom/Desktop/dementia-care/kids-weekend
# 用 python 從 index.html 摳出 TAIWAN_DISTRICTS 整個 object,轉成 Python dict
python3 <<'EOF'
import re, json
html = open('index.html').read()
# 抓 const TAIWAN_DISTRICTS = {...};
m = re.search(r'const TAIWAN_DISTRICTS = (\{.*?\n\};)', html, re.DOTALL)
js = m.group(1).rstrip(';')
# JS object → Python: 'taipei:' → '"taipei":', 'label:' → '"label":' etc
# 簡單轉:單引號 → 雙引號,key 加 ""
py = re.sub(r"(\w+):", r'"\1":', js)
py = py.replace("'", '"')
# trailing comma 砍掉
py = re.sub(r',(\s*[}\]])', r'\1', py)
districts = json.loads(py)
# Inject 進 scrape script — 用 python repr 寫進去
print(f'len: {len(districts)} regions')
with open('/tmp/tw_districts.py','w') as f:
    f.write(f'TAIWAN_DISTRICTS = {repr(districts)}\n')
EOF
```

然後在 `scrape_mrt_stations.py` 的 TAIWAN_DISTRICTS 那一段改成:
```python
# 從 /tmp/tw_districts.py exec 進來(在 main 開頭跑一次)
exec(open('/tmp/tw_districts.py').read())
```

(或者更乾淨:把 `/tmp/tw_districts.py` 內容直接貼進 script。前者快,後者乾淨,二選一。)

- [ ] **Step A1.4: 跑 script 拿 raw json**

```bash
python3 scripts/scrape_mrt_stations.py -o /tmp/mrt_stations_raw.json
```

Expected: stderr 顯示 `Wrote XXX stations` + `By sys: Counter({'tpe': ~131, 'khh': ~76, 'tao': ~22, 'tch': ~18, 'ntp': ~14})`,total ≥ 250。

如果某 sys 數字明顯不對(e.g. tch=0):
1. OSM 該 system operator tag 命名跟 `OPERATOR_MAP` 不 match → 加進去重跑
2. 或該 system OSM 涵蓋差 → 寫 fallback(Wikipedia 列表頁 / 政府開放資料)
3. **暫停** 問 user 怎麼處理

- [ ] **Step A1.5: 驗證 raw json**

```bash
python3 -c "
import json
data = json.load(open('/tmp/mrt_stations_raw.json'))
print(f'Total: {len(data)}')
from collections import Counter
print('By sys:', Counter(d['sys'] for d in data))
missing = [d for d in data if not all(k in d for k in ['sys','name','region','district','lat_osm','lng_osm'])]
print(f'Missing fields: {len(missing)}')
no_lines = [d for d in data if not d['lines']]
print(f'No lines: {len(no_lines)} (前 5: {[d[\"name\"] for d in no_lines[:5]]})')
assert len(data) >= 250, f'too few: {len(data)}'
assert not missing, missing[:3]
"
```

Expected: Total ≥ 250、各 sys count 合理、Missing fields: 0、no lines 可能有少數(台中綠線 + 高雄輕軌 部分,可接受)。

- [ ] **Step A1.6: Commit script**

```bash
git add kids-weekend/scripts/scrape_mrt_stations.py
git commit -m "feat(kids-weekend): scripts/scrape_mrt_stations.py — OSM Overpass 抓全台 metro"
```

---

### Task A2: Playwright geocode + bbox sanity + reject patterns

**Files:**
- Create: `kids-weekend/scripts/geocode_mrt.py`

對齊 `geocode_libstat.py` pattern,加 MRT 特定的 reject 規則。

- [ ] **Step A2.1: 寫 geocode script**

Create `scripts/geocode_mrt.py`:

```python
"""對 mrt_stations_raw.json 每筆 Playwright Google Maps geocode 拿 lat/lng

對齊 geocode_libstat.py pattern (throttle 5s + jitter ±2s + resume support)。
加 3 條 MRT 特定 reject:
  1. bbox sanity: lat/lng 必須落在該系統 bbox 內
  2. default pin 偵測: 完全相同 (lat,lng) 出現 2+ 次 → reject 後出現的
  3. Google 找不到 (無 @coord redirect) → reject

query 格式: "<sys-label> <name>站" e.g. "台北捷運 中山站"

usage:
    python3 scripts/geocode_mrt.py --input /tmp/mrt_stations_raw.json -o /tmp/mrt_stations_geocoded.json
"""
import argparse, json, random, re, sys, time, urllib.parse
from collections import Counter
from playwright.sync_api import sync_playwright

COORD_RE = re.compile(r'@(-?\d+\.\d+),(-?\d+\.\d+)')

SYS_LABEL = {'tpe':'台北捷運', 'khh':'高雄捷運', 'khh-lrt':'高雄輕軌',
             'tao':'桃園捷運', 'tch':'台中捷運', 'ntp':'新北捷運'}

# 各系統 bbox (lat_min, lat_max, lng_min, lng_max) — 寬鬆預設,以避免錯誤 reject
SYS_BBOX = {
    'tpe':     (24.95, 25.20, 121.40, 121.70),
    'khh':     (22.40, 22.90, 120.20, 120.45),
    'khh-lrt': (22.55, 22.70, 120.25, 120.35),
    'tao':     (24.95, 25.10, 121.20, 121.55),
    'tch':     (24.05, 24.30, 120.55, 120.75),
    'ntp':     (24.95, 25.10, 121.45, 121.55),
}

def in_bbox(sys_key, lat, lng):
    bb = SYS_BBOX.get(sys_key)
    if not bb: return True
    return bb[0] <= lat <= bb[1] and bb[2] <= lng <= bb[3]

def geocode_one(page, query, timeout_ms=20000):
    url = f'https://www.google.com.tw/maps/place/{urllib.parse.quote(query)}'
    page.goto(url, wait_until='domcontentloaded', timeout=timeout_ms)
    try:
        page.wait_for_url(COORD_RE, timeout=12000)
    except Exception:
        pass
    time.sleep(1.5)
    m = COORD_RE.search(page.url)
    if m:
        return float(m.group(1)), float(m.group(2)), page.url
    return None, None, page.url

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--input', required=True)
    ap.add_argument('-o','--output', required=True)
    ap.add_argument('--throttle', type=float, default=5.0)
    ap.add_argument('--jitter', type=float, default=2.0)
    ap.add_argument('--headed', action='store_true')
    args = ap.parse_args()

    entries = json.load(open(args.input))
    print(f"Input: {len(entries)}", file=sys.stderr)

    # Resume
    try:
        existing = {f"{e['sys']}-{e['name']}": e for e in json.load(open(args.output))
                    if e.get('lat') is not None or e.get('reject_reason')}
        print(f"Resume: {len(existing)} done", file=sys.stderr)
    except Exception:
        existing = {}

    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=not args.headed)
        ctx = browser.new_context(viewport={'width':1280,'height':900}, locale='zh-TW',
                                   user_agent='Mozilla/5.0 (X11; Linux x86_64) Chrome/120.0.0.0 Safari/537.36')
        page = ctx.new_page()
        results = []
        for i, e in enumerate(entries, 1):
            key = f"{e['sys']}-{e['name']}"
            if key in existing:
                results.append(existing[key])
                continue
            query = f"{SYS_LABEL.get(e['sys'], e['sys'])} {e['name']}站"
            try:
                lat, lng, url = geocode_one(page, query)
                if lat is None:
                    e['reject_reason'] = 'no_geocode'
                elif not in_bbox(e['sys'], lat, lng):
                    e['reject_reason'] = f'out_of_bbox ({lat:.3f},{lng:.3f})'
                else:
                    e['lat'] = round(lat, 4)
                    e['lng'] = round(lng, 4)
                    e['matched_url'] = url
                e.setdefault('last_verified', '2026-05-24')
                ok = '✓' if e.get('lat') else '✗'
                print(f"[{i}/{len(entries)}] {ok} {query[:30]} → {e.get('lat','-')},{e.get('lng','-')} {e.get('reject_reason','')}", file=sys.stderr)
            except Exception as ex:
                e['error'] = str(ex)[:120]
                print(f"[{i}/{len(entries)}] ! {ex.__class__.__name__}", file=sys.stderr)
            results.append(e)
            with open(args.output,'w',encoding='utf-8') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)
            if i < len(entries):
                time.sleep(args.throttle + random.uniform(-args.jitter, args.jitter))

    # Post-process: default pin reject (same lat,lng 出現 2+ 次 → 後出現的 reject)
    coord_count = Counter((e.get('lat'), e.get('lng')) for e in results if e.get('lat'))
    seen = set()
    for e in results:
        if not e.get('lat'): continue
        c = (e['lat'], e['lng'])
        if coord_count[c] > 1:
            if c in seen:
                e.pop('lat', None); e.pop('lng', None)
                e['reject_reason'] = f'default_pin (shared with {coord_count[c]-1} others)'
            seen.add(c)
    with open(args.output,'w',encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    ok = sum(1 for e in results if e.get('lat'))
    rej = sum(1 for e in results if e.get('reject_reason'))
    print(f"\nDone: {ok}/{len(results)} OK, {rej} rejected", file=sys.stderr)

if __name__ == '__main__':
    main()
```

- [ ] **Step A2.2: 安裝 playwright(若無)**

```bash
pip install playwright && playwright install chromium
```

Expected: chromium downloaded (~150MB)。

- [ ] **Step A2.3: 跑 geocode(預估 ~25 分鐘)**

```bash
cd /home/tom/Desktop/dementia-care/kids-weekend
python3 scripts/geocode_mrt.py \
  --input /tmp/mrt_stations_raw.json \
  --output /tmp/mrt_stations_geocoded.json 2>&1 | tee /tmp/mrt_geocode.log
```

Expected: stderr 顯示逐站進度 + 最後 `Done: X/Y OK, Z rejected`。

**通過條件**:OK rate ≥ 90% (例如 235/260)。如果 < 90%:
1. 看 `/tmp/mrt_geocode.log` 找 reject pattern
2. 常見 root cause:
   - bbox 太緊 → 放寬 `SYS_BBOX` 重跑(resume 會跳過已通過的)
   - query 格式 user-agent 被擋 → 試另一個 UA
   - 某系統名 Google 認不出 → 改 query e.g. "高雄輕軌" → "凱旋公園"
3. 改完 resume 重跑

- [ ] **Step A2.4: 驗證 geocode 結果**

```bash
python3 -c "
import json
data = json.load(open('/tmp/mrt_stations_geocoded.json'))
ok = [d for d in data if d.get('lat')]
rej = [d for d in data if d.get('reject_reason')]
print(f'OK: {len(ok)}, rejected: {len(rej)}')
print(f'OK rate: {len(ok)/len(data)*100:.1f}%')
# 顯示前 5 reject reasons
from collections import Counter
print('Reject reasons:', Counter(d.get('reject_reason') for d in rej).most_common())
assert len(ok)/len(data) >= 0.9, 'OK rate < 90%'
"
```

Expected: OK rate ≥ 90%。

- [ ] **Step A2.5: Commit script**

```bash
git add kids-weekend/scripts/geocode_mrt.py
git commit -m "feat(kids-weekend): scripts/geocode_mrt.py — Playwright + bbox + default-pin reject"
```

---

### Task A3: Random 20-station 人工抽驗

**Files:** 無 code 改動,純驗證

- [ ] **Step A3.1: random sample 20 站**

```bash
python3 -c "
import json, random
random.seed(42)
data = [d for d in json.load(open('/tmp/mrt_stations_geocoded.json')) if d.get('lat')]
sample = random.sample(data, 20)
for s in sample:
    print(f\"{s['sys']:8} {s['name']:8} {s['lat']},{s['lng']}  https://www.google.com/maps/place/{s['lat']},{s['lng']}\")
"
```

- [ ] **Step A3.2: Tom 點開每個 Google Maps URL,比對是否為該站**

通過標準:Google Maps 顯示的 place 即為該捷運站(出入口或站體中心),距離站體 < 100m。

填驗證表:
```
sys | name | URL | OK / FAIL / 距離米數 | 備註
```

**通過條件**:≥ 19/20 PASS(95%+)。

未通過站手動修 `/tmp/mrt_stations_geocoded.json` lat/lng,或加進 reject list。

- [ ] **Step A3.3: 若需修正,寫入 manual override(避免重跑覆蓋)**

若 sample 中發現某站座標明顯錯,可在 `geocode_mrt.py` 加 `MANUAL_OVERRIDE` dict:
```python
MANUAL_OVERRIDE = {
  'tpe-中山': (25.0526, 121.5202),  # Google 抓到隔壁出入口,改成站體中心
}
```
然後在 `geocode_one()` 前先 check。重跑此站(刪 cached entry → resume 重抓)。

---

### Task A4: Apply geocoded JSON 進 index.html

**Files:**
- Create: `kids-weekend/scripts/apply_mrt.py`
- Modify: `kids-weekend/index.html`(在 `TAIWAN_DISTRICTS` 之後加 `MRT_SYS_LABEL` + `MRT_STATIONS`)

- [ ] **Step A4.1: 寫 apply script**

Create `scripts/apply_mrt.py`:

```python
"""把 /tmp/mrt_stations_geocoded.json inline 進 index.html

在 TAIWAN_DISTRICTS const 結束後插入 MRT_SYS_LABEL + MRT_STATIONS。
若 index.html 已有 MRT_STATIONS,先 strip 舊的再寫新的。
"""
import json, re

PATH = '/home/tom/Desktop/dementia-care/kids-weekend/index.html'
SRC = '/tmp/mrt_stations_geocoded.json'

SYS_LABEL = {
    'tpe':'台北捷運','khh':'高雄捷運','khh-lrt':'高雄輕軌',
    'tao':'桃園捷運','tch':'台中捷運','ntp':'新北捷運'
}

def fmt_station(s):
    lines_js = '[' + ','.join(f"'{l}'" for l in s['lines']) + ']'
    return (f"{{sys:'{s['sys']}',name:'{s['name']}',lines:{lines_js},"
            f"lat:{s['lat']},lng:{s['lng']},region:'{s['region']}',"
            f"district:'{s['district']}',last_verified:'{s['last_verified']}'}}")

def main():
    data = [d for d in json.load(open(SRC)) if d.get('lat')]
    print(f"Applying {len(data)} stations")

    sys_label_js = 'const MRT_SYS_LABEL = {' + \
        ','.join(f"{k}:'{v}'" for k,v in SYS_LABEL.items()) + '};'
    stations_js = 'const MRT_STATIONS = [\n  ' + \
        ',\n  '.join(fmt_station(s) for s in data) + '\n];'

    block = f"\n// ========== 捷運站(5 系統 ~260 站,Playwright + bbox 校正)==========\n" + \
            f"{sys_label_js}\n{stations_js}\n"

    with open(PATH) as f:
        content = f.read()

    # Strip old if exists
    content = re.sub(
        r'\n// ========== 捷運站.*?\nconst MRT_STATIONS = \[.*?\];\n',
        '',
        content, flags=re.DOTALL
    )

    # Insert after TAIWAN_DISTRICTS closing (尋找對應 `};` 後面緊接 blank line)
    # TAIWAN_DISTRICTS 結束在 `lienchiang:` block 後的 `};`
    marker = "lienchiang: {label:'連江縣(馬祖)'"
    idx = content.find(marker)
    if idx < 0:
        raise SystemExit('TAIWAN_DISTRICTS marker not found')
    # 從 marker 往後找到第一個 `};` (TAIWAN_DISTRICTS 結束)
    end = content.find('\n};\n', idx)
    if end < 0:
        raise SystemExit('TAIWAN_DISTRICTS closing not found')
    insert_at = end + len('\n};\n')

    new_content = content[:insert_at] + block + content[insert_at:]
    with open(PATH, 'w') as f:
        f.write(new_content)
    print(f"Inserted at offset {insert_at}, new size: {len(new_content)} bytes")

if __name__ == '__main__':
    main()
```

- [ ] **Step A4.2: 跑 apply**

```bash
cd /home/tom/Desktop/dementia-care/kids-weekend
python3 scripts/apply_mrt.py
```

Expected: `Applying 235+ stations` + `Inserted at offset XXXXX`。

- [ ] **Step A4.3: 語法檢查**

```bash
node -e "
const fs=require('fs');
const html=fs.readFileSync('/home/tom/Desktop/dementia-care/kids-weekend/index.html','utf8');
const scripts=[...html.matchAll(/<script(?![^>]*type=[\"']application\/ld)[^>]*>([\\s\\S]*?)<\/script>/g)];
for(const m of scripts){
  if(m[1].length>200){
    try{ new Function(m[1]); console.log('JS OK',m[1].length,'chars'); }
    catch(e){ console.log('FAIL:', e.message); process.exit(1); }
  }
}
"
```

Expected: `JS OK XXXXX chars` 無 FAIL。

如果 FAIL: 90% 是站名含 `'`(apostrophe)。修 `fmt_station` 加 escape:
```python
name_safe = s['name'].replace("'", "\\'")
```

- [ ] **Step A4.4: 驗證 inline 進去了**

```bash
grep -c "^  {sys:" /home/tom/Desktop/dementia-care/kids-weekend/index.html
```

Expected: ≥ 235(等於 data 站數)。

- [ ] **Step A4.5: Commit apply script + index.html 變動**

```bash
git add kids-weekend/scripts/apply_mrt.py kids-weekend/index.html
git commit -m "feat(kids-weekend): MRT_STATIONS inline ~260 站 + apply 腳本"
```

---

## Phase B: UI(Q1 Wizard)

### Task B1: 改 Q1 wizard markup — 加 MRT input + 折疊 county/district

**Files:**
- Modify: `kids-weekend/index.html` lines 2010-2021(renderWizardQ('home') 的「手動選」段)

- [ ] **Step B1.1: 替換現有 markup**

替換 lines 2009-2021(從 `<div style="text-align:center;color:var(--muted);font-size:13px;margin:8px 0;">— 或手動選 —</div>` 到 county/district 整段)為:

```html
      <div style="text-align:center;color:var(--muted);font-size:13px;margin:8px 0;">— 或手動選 —</div>
      <div style="background:#fff;border:1px solid var(--border);border-radius:8px;padding:14px;margin-bottom:10px;">
        <label style="display:block;margin-bottom:6px;font-weight:600;">🚇 找捷運站</label>
        <input type="search" id="mrt-search" oninput="onMrtSearch(event)" autocomplete="off"
               placeholder="輸入站名 (中山/板橋/左營/桃機...)"
               style="width:100%;padding:10px;border:1px solid var(--border);border-radius:6px;font-size:15px;" />
        <div id="mrt-results" style="margin-top:6px;"></div>
        <p style="font-size:13px;color:var(--muted);margin:10px 0 0;">用站體位置當粗估(精準 ~100m,比區中心精準很多)</p>
      </div>
      <details style="background:#fff;border:1px solid var(--border);border-radius:8px;padding:0;margin-bottom:0;">
        <summary style="cursor:pointer;padding:12px 14px;font-size:14px;color:var(--muted);">🏙️ 沒有捷運?點這選縣市/區</summary>
        <div style="padding:0 14px 14px;">
          <label style="display:block;margin-bottom:6px;font-weight:600;">縣市</label>
          <select id="home-county" onchange="onHomeCountyChange()" style="width:100%;padding:10px;border:1px solid var(--border);border-radius:6px;font-size:15px;margin-bottom:14px;">
            <option value="">-- 選縣市 --</option>
            ${countyOpts}
          </select>
          <label style="display:block;margin-bottom:6px;font-weight:600;">鄉鎮市區</label>
          <select id="home-district" onchange="onHomeDistrictChange()" style="width:100%;padding:10px;border:1px solid var(--border);border-radius:6px;font-size:15px;" disabled>
            <option value="">-- 先選縣市 --</option>
          </select>
          <p style="font-size:13px;color:var(--muted);margin:10px 0 0;">用區中心當粗估(誤差 ±2 km)</p>
        </div>
      </details>
```

精準位置:在 `index.html` 的 `renderWizardQ('home')` 內,從 `<div style="text-align:center;...">— 或手動選 —</div>` 開始 到 `<p style="font-size:13px;color:var(--muted);margin:10px 0 0;">用區中心當粗估(誤差 ±2 km)。GPS 比較準。</p></div>` 結束 整段替換。

- [ ] **Step B1.2: 瀏覽器目視確認 UI**

```bash
xdg-open /home/tom/Desktop/dementia-care/kids-weekend/index.html
```

清掉 localStorage:DevTools → Application → Local Storage → 刪 `kidsWeekendState`,reload。
Expected:
- 看到 GPS 按鈕(不動)
- 看到「🚇 找捷運站」input
- 看到「🏙️ 沒有捷運?」折疊區(預設收起)
- 點折疊區可展開,看到既有 county/district 下拉

- [ ] **Step B1.3: Commit**

```bash
git add kids-weekend/index.html
git commit -m "feat(kids-weekend): Q1 wizard UI — 捷運搜尋為主, 縣市/區折疊備援"
```

---

### Task B2: 加 `onMrtSearch()` + autocomplete render

**Files:**
- Modify: `kids-weekend/index.html`(在 `onHomeDistrictChange()` 函式之後加)

- [ ] **Step B2.1: 加 JS functions**

在 `onHomeDistrictChange()`(line 2089-2102 結束 `}`)**之後** 加:

```javascript

// ============ MRT 搜尋 ============
function onMrtSearch(e) {
  const q = (e.target.value || '').trim();
  const box = document.getElementById('mrt-results');
  if (!q) { box.innerHTML = ''; return; }
  const matches = MRT_STATIONS.filter(s =>
    s.name.includes(q) || s.lines.some(l => l.includes(q))
  );
  // exact name match 優先 → region asc
  matches.sort((a, b) => {
    const ax = a.name === q ? 0 : 1;
    const bx = b.name === q ? 0 : 1;
    if (ax !== bx) return ax - bx;
    return a.region.localeCompare(b.region);
  });
  const top = matches.slice(0, 8);
  if (top.length === 0) {
    box.innerHTML = `<div style="padding:10px;color:var(--muted);font-size:14px;">沒找到「${escapeHtml(q)}」的捷運站</div>`;
    return;
  }
  const more = matches.length > 8 ? `<div style="padding:6px 10px;color:var(--muted);font-size:12px;">還有 ${matches.length - 8} 筆,請打更精確</div>` : '';
  box.innerHTML = top.map(s => {
    const sysLabel = MRT_SYS_LABEL[s.sys] || s.sys;
    const linesStr = s.lines.join('/');
    const key = `${s.sys}-${s.name}`;
    return `<div onclick="onMrtSelect('${key}')" style="padding:10px;border-top:1px solid var(--border);cursor:pointer;font-size:15px;" onmouseover="this.style.background='var(--primary-light)'" onmouseout="this.style.background=''">
      <strong>${escapeHtml(s.name)}</strong> · <span style="color:var(--muted);">${escapeHtml(sysLabel)} ${escapeHtml(linesStr)}</span>
    </div>`;
  }).join('') + more;
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}
```

- [ ] **Step B2.2: 重 reload + 測搜尋**

清 localStorage → reload → 在 MRT input 打「中山」。

Expected:
- 出現 ≥ 1 筆 match(至少 台北中山,可能也有桃園機捷 A1 = 不是中山,但有其他重名)
- 顯示格式:`中山 · 台北捷運 淡水信義/松山新店`
- 打「abc」→ 顯示「沒找到」
- 打「板南」→ 顯示走板南線的站(西門/台北車站/...)

- [ ] **Step B2.3: Commit**

```bash
git add kids-weekend/index.html
git commit -m "feat(kids-weekend): MRT search + autocomplete (max 8 + exact-match priority)"
```

---

### Task B3: 加 `onMrtSelect()` — 點選後 setHome

**Files:**
- Modify: `kids-weekend/index.html`(緊接 B2 加的 functions 後)

- [ ] **Step B3.1: 加 select handler**

在 `escapeHtml()` 之後加:

```javascript
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

- [ ] **Step B3.2: 測 end-to-end 點選**

清 localStorage → reload → 在 MRT input 打「中山」→ 點選 `中山 · 台北捷運 ...`

Expected:
- Q1 wizard 消失,跳到 result 頁
- result 頁顯示 `📍 台北中山`
- 景點推薦範圍以 25.0526, 121.5202 為中心
- DevTools localStorage `kidsWeekendState` 內 `homeLat:25.0526, homeLng:121.5202, home:'taipei', homeDistrict:'中山'`

- [ ] **Step B3.3: 測「改地點」reset 後重選**

result 頁按「改地點」→ 回 Q1 → 用 MRT 搜尋選另一站(例:板橋)→ 再回 result 確認位置變了。

- [ ] **Step B3.4: Commit**

```bash
git add kids-weekend/index.html
git commit -m "feat(kids-weekend): onMrtSelect — 捷運站 setHome 走既有 region/district/lat/lng schema"
```

---

### Task B4: Smoke test 5 case + 折疊行為確認

**Files:** 無 code 改動,純手動驗證

- [ ] **Step B4.1: 5 case smoke test 清單**

依序測:

| # | Case | 預期 |
|--|--|--|
| 1 | 打「台北車站」 | 至少 2 筆(TRTC + 桃機 A1),分開顯示 |
| 2 | 打「左營」 | 至少 1 筆 高雄捷運(R 紅線) |
| 3 | 打「凱旋公園」 | 至少 1 筆 高雄輕軌 |
| 4 | 打「象山」→ 選 | result 顯示 📍 台北信義,景點範圍含信義/虎山步道附近 |
| 5 | 折疊「沒有捷運?」展開 → 用 county/district 選台東池上 | result 顯示 📍 台東池上(不 regression 既有行為) |

每 case 在瀏覽器執行,清 localStorage 從乾淨 state 開始。

- [ ] **Step B4.2: console error 檢查**

DevTools Console 在每 case 都不能有紅色 error。常見會出問題:
- `MRT_STATIONS is not defined` → Phase A4 沒跑成功
- `Cannot read properties of null (reading 'name')` → escapeHtml input 為 null
- `setHome is not defined` → 函式名拼錯

- [ ] **Step B4.3: 若全 pass,標 milestone OK**

無 commit(沒 code 改動)。

---

## Phase C: Docs + 部署

### Task C1: 更新 CLAUDE.md「資料成果」段

**Files:**
- Modify: `kids-weekend/CLAUDE.md`(line 196-209 「數據成果」表附近)

- [ ] **Step C1.1: 加 MRT 統計行**

在「數據成果」表底下加一段:

```markdown
## 捷運站搜尋(2026-05-24 新增)

| 項目 | 數字 |
|--|--|
| 系統 | 5 (台北/高雄含輕軌/桃園/台中/新北環狀) |
| 站數 | XXX (geocode 後通過站數,填實際) |
| Geocode 通過率 | XX.X% (Playwright + bbox sanity + default-pin reject) |
| 人工抽驗 | 20/20 random sample 通過 (≥ 95% 標準) |
| inline 大小 | ~17 KB |

關鍵 lesson:**捷運站精準度走 PLACES 同等級**(每站 Playwright geocode + bbox + default-pin reject)。
比區中心精準 ~2 km — Tom 「中山站比 1 個大同區好用很多」是這專案 v3.9 主軸。
```

(實際數字從 `/tmp/mrt_stations_geocoded.json` + 抽驗結果填)

- [ ] **Step C1.2: Commit**

```bash
git add kids-weekend/CLAUDE.md
git commit -m "docs(kids-weekend): CLAUDE.md 加 MRT 數據成果段"
```

---

### Task C2: Final push + 部署驗證

- [ ] **Step C2.1: Push 到 main(若在 dev branch,先 merge)**

當前 branch 是 `dev`(從 system context)。先 push dev:

```bash
git push origin dev
```

若 user 確認 ready ship,merge 到 main:

```bash
git checkout main && git merge dev && git push origin main && git checkout dev
```

(這步**需 user 確認再做**,因為 push main 等於上線)

- [ ] **Step C2.2: 等 GitHub Pages 部署生效**

```bash
sleep 60 && gh api repos/tm731531/dementia-care/pages/builds/latest --jq '{status, updated_at}'
```

Expected: `status: "built"`。

- [ ] **Step C2.3: 上線版 smoke**

打開 `https://tm731531.github.io/dementia-care/kids-weekend/` →
- Q1 看到捷運搜尋 input
- 打「中山」有結果
- 選擇後跳 result 頁顯示對的位置

---

## Definition of Done

- [ ] Phase A 全完成,`MRT_STATIONS` inline ≥ 235 站
- [ ] Phase B 全完成,5 case smoke test 全 pass
- [ ] Phase C CLAUDE.md 更新 + 上線 smoke pass
- [ ] 0 CDN 規則仍 pass (`grep -n -E 'https?://[^"]*\.(com|net|org|io|co)/' index.html | grep -v 'github.io\|tomting.com\|data:'` 無新增違規)
- [ ] STATE schema 零變動驗證:localStorage 內無新欄位
- [ ] Result 頁 + Maps 連結邏輯零改動
