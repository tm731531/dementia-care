"""對全 800 筆景點抓 Google Maps metadata
- hours_raw:7 天 hours 表(parse 後 hours.mon, hours.tue, ...)
- website:官網(booking_url 候選)
- 中斷續跑 — 每 10 筆存 /tmp/scrape_meta.json
"""
import re, time, json, sys
from playwright.sync_api import sync_playwright

PATH = '/home/tom/Desktop/dementia-care/kids-weekend/index.html'
OUT = '/tmp/scrape_meta.json'
LOG = '/tmp/scrape_meta.log'

def log(msg):
    line = f'[{time.strftime("%H:%M:%S")}] {msg}'
    print(line, flush=True)
    with open(LOG, 'a') as f:
        f.write(line + '\n')

with open(PATH) as f:
    content = f.read()

REGION_LABEL = {'taipei':'台北市','newtaipei':'新北市','keelung':'基隆市','taoyuan':'桃園市',
                'hsinchu_city':'新竹市','hsinchu_county':'新竹縣','miaoli':'苗栗縣','taichung':'台中市',
                'changhua':'彰化縣','nantou':'南投縣','yunlin':'雲林縣','chiayi_city':'嘉義市',
                'chiayi_county':'嘉義縣','tainan':'台南市','kaohsiung':'高雄市','pingtung':'屏東縣',
                'yilan':'宜蘭縣','hualien':'花蓮縣','taitung':'臺東縣','penghu':'澎湖縣','kinmen':'金門縣','lienchiang':'連江縣'}

# 抓所有 PLACES 的 id + name + region
PLACE_RE = re.compile(r"\{id:'([^']+)', name:'([^']+)', emoji:'[^']*', area:'([^']+)', region:'(\w+)'")
places = []
for m in PLACE_RE.finditer(content):
    places.append({'id': m.group(1), 'name': m.group(2), 'area': m.group(3), 'region': m.group(4)})
log(f'總共 {len(places)} 筆景點要抓 metadata')

# 載入已完成的(支援續跑)
try:
    with open(OUT) as f:
        results = json.load(f)
    log(f'已載入 {len(results)} 筆')
except:
    results = {}

# 解析 hours_raw 成 per-day 結構
DAYS_TW = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日']
DAYS_EN = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
def parse_hours(raw):
    if not raw: return {}
    out = {}
    # 拆 | 分隔(每天一塊)
    chunks = raw.split('|')
    for c in chunks:
        c = c.strip()
        # 找出星期幾
        day_idx = -1
        for i, d in enumerate(DAYS_TW):
            if d in c:
                day_idx = i
                break
        if day_idx < 0: continue
        # 移除星期幾標籤 + 「(節日名)」+ 「營業時間可能不同」 噪音
        rest = c.replace(DAYS_TW[day_idx], '')
        rest = re.sub(r'\([^)]+\)', '', rest)
        rest = rest.replace('營業時間可能不同', '')
        # 提取 HH:MM–HH:MM 或 「24 小時營業」 或 「休息」
        rest = ' '.join(rest.split())  # collapse whitespace
        if '24 小時營業' in rest or '24 小时营业' in rest: out[DAYS_EN[day_idx]] = '24h'
        elif '休息' in rest or 'Closed' in rest: out[DAYS_EN[day_idx]] = 'closed'
        else:
            tm = re.search(r'(\d{1,2}:\d{2})\s*[–\-~]\s*(\d{1,2}:\d{2})', rest)
            if tm: out[DAYS_EN[day_idx]] = f'{tm.group(1)}-{tm.group(2)}'
            else: out[DAYS_EN[day_idx]] = rest[:30]
    return out

with sync_playwright() as pw:
    browser = pw.chromium.launch(headless=True)
    ctx = browser.new_context(viewport={'width':1280,'height':900}, locale='zh-TW',
                              user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36')
    page = ctx.new_page()

    for idx, pl in enumerate(places):
        if pl['id'] in results: continue
        primary = pl['name'].split('/')[0].strip()
        city = REGION_LABEL.get(pl['region'], '')
        url = f'https://www.google.com/maps/search/{primary} {city}'
        try:
            page.goto(url, wait_until='domcontentloaded', timeout=20000)
            try: page.wait_for_url(re.compile(r'@-?\d+\.\d+,-?\d+\.\d+'), timeout=10000)
            except: pass
            time.sleep(2.0)

            # h1
            try: h1 = page.locator('h1').first.inner_text(timeout=2000)
            except: h1 = ''

            # website
            website = ''
            try:
                w = page.locator('a[aria-label*="網站"], a[aria-label*="Website"]').first
                website = w.get_attribute('href', timeout=2000) or ''
            except: pass

            # hours - try expand first
            hours_raw = ''
            try:
                expander = page.locator('[aria-label*="營業時間"], [aria-label*="Hours"]').first
                try: expander.click(timeout=1500); time.sleep(0.6)
                except: pass
                rows = page.locator('table tbody tr').all()
                row_texts = []
                for r in rows[:7]:
                    try: row_texts.append(r.inner_text(timeout=800))
                    except: pass
                hours_raw = ' | '.join(row_texts)
            except: pass

            hours = parse_hours(hours_raw)

            results[pl['id']] = {
                'h1': h1,
                'website': website,
                'hours': hours,
            }
            mark = '✓' if (website or hours) else '·'
            log(f'{idx+1}/{len(places)} {mark} {pl["id"][:25]:25s} hours={len(hours)}d, web={"Y" if website else "-"}')

        except Exception as e:
            results[pl['id']] = {'error': str(e)[:80]}
            log(f'{idx+1}/{len(places)} ! {pl["id"]}: {str(e)[:60]}')

        # 每 10 筆存
        if (idx + 1) % 10 == 0:
            with open(OUT, 'w') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)

        time.sleep(0.8)

    browser.close()

with open(OUT, 'w') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

ok_w = sum(1 for v in results.values() if v.get('website'))
ok_h = sum(1 for v in results.values() if v.get('hours'))
log(f'=== 完成 === {len(results)}/{len(places)},website {ok_w},hours {ok_h}')
