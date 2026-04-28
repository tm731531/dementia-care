"""
Playwright 自動化 Google Maps 唯一性驗證 774 個台灣親子景點。
每筆 ~10 秒,774 筆 ≈ 2.5 小時。

判斷邏輯（從 DOM 分析校正後）:
- h1 == "結果" 或 "Results"  → AMBIGUOUS（多結果清單）
- place_links > 0             → AMBIGUOUS（顯示多個 /maps/place/ 連結）
- 以上都不滿足 + h1 是地點名  → UNIQUE（顯示單一地點詳情）
- DUwDvf class 抓 Google 正式名稱

進度寫到 /tmp/validate_maps.log
結果寫到 /tmp/validate_maps.json (支援中斷續跑)
"""
import re, time, json
from urllib.parse import quote
from playwright.sync_api import sync_playwright

PATH = '/home/tom/Desktop/dementia-care/kids-weekend/index.html'
OUT = '/tmp/validate_maps.json'
LOG = '/tmp/validate_maps.log'

def log(msg):
    line = f'[{time.strftime("%H:%M:%S")}] {msg}'
    print(line, flush=True)
    with open(LOG, 'a') as f:
        f.write(line + '\n')

with open(PATH) as f:
    content = f.read()

m = re.search(r'const REGION_LABEL = \{([^}]+)\}', content)
REGION_LABEL = {}
for k, v in re.findall(r"(\w+):'([^']+)'", m.group(1)):
    REGION_LABEL[k] = v.replace('連江縣(馬祖)', '連江縣')

PLACE_RE = re.compile(r"\{id:'([^']+)', name:'([^']+)', emoji:'[^']*', area:'([^']+)', region:'(\w+)'")
places = []
for m in PLACE_RE.finditer(content):
    places.append({'id': m.group(1), 'name': m.group(2), 'area': m.group(3), 'region': m.group(4)})

log(f'總共 {len(places)} 筆景點要驗證')

try:
    with open(OUT) as f:
        results = json.load(f)
    done = len(results)
    log(f'已載入 {done} 筆已完成，繼續從斷點跑')
except:
    results = {}

def try_goto(page, url, retries=3):
    for attempt in range(retries):
        try:
            page.goto(url, wait_until='domcontentloaded', timeout=25000)
            return True
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(3)
    return False

def analyze_page(page):
    """
    判斷是唯一地點還是多結果清單。
    Key signals:
    - h1 == "結果"/"Results" → AMBIGUOUS
    - place_links > 0 (多個 /maps/place/ 連結) → AMBIGUOUS
    - 否則 → UNIQUE，從 DUwDvf 抓 Google 名稱
    """
    info = {}

    # h1 text
    try:
        h1 = page.query_selector('h1')
        info['h1'] = h1.inner_text().strip() if h1 else None
    except:
        info['h1'] = None

    # 計算 /maps/place/ 連結數（多結果清單才會有）
    try:
        place_links = page.query_selector_all('a[href*="/maps/place/"]')
        info['place_links'] = len(place_links)
    except:
        info['place_links'] = 0

    # DUwDvf 是 Google Maps 地點名稱的 class
    try:
        el = page.query_selector('.DUwDvf')
        info['google_name'] = el.inner_text().strip() if el else None
    except:
        info['google_name'] = None

    # 如果 DUwDvf 沒抓到，用 h1 當備用
    if not info['google_name'] and info['h1'] and info['h1'] not in ('結果', 'Results', 'Search results'):
        info['google_name'] = info['h1']

    info['final_url'] = page.url
    return info

def classify(info):
    """根據分析結果分類"""
    h1 = info.get('h1', '')
    place_links = info.get('place_links', 0)

    if h1 in ('結果', 'Results', 'Search results', None, ''):
        return 'ambiguous'
    if place_links > 0:
        return 'ambiguous'
    # h1 有地點名稱，place_links == 0 → unique
    return 'unique'

def name_compare(our_name, google_name):
    if not google_name:
        return None
    # 取斜線前第一個名稱，去掉括號
    primary = re.sub(r'（[^）]*）|\([^)]*\)', '', our_name.split('/')[0]).strip()
    g_clean = re.sub(r'[\s　]+', '', google_name)
    o_clean = re.sub(r'[\s　]+', '', primary)
    if not o_clean:
        return None
    if g_clean == o_clean:
        return 'exact'
    elif o_clean in g_clean or g_clean in o_clean:
        return 'partial'
    else:
        return 'different'

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(
        viewport={'width': 1280, 'height': 800},
        user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        locale='zh-TW',
    )
    page = context.new_page()

    for idx, pl in enumerate(places):
        if pl['id'] in results:
            continue

        query = f"{pl['name']} {pl['area']}"
        search_url = f"https://www.google.com/maps/search/{quote(query)}"

        try:
            ok = try_goto(page, search_url)
            if not ok:
                raise Exception("goto failed after 3 retries")

            # 等待 DOM 渲染（Google Maps 是 SPA，需要時間）
            time.sleep(3)

            info = analyze_page(page)
            url_type = classify(info)
            google_name = info.get('google_name')
            name_match = name_compare(pl['name'], google_name)

            result = {
                'name': pl['name'],
                'area': pl['area'],
                'region': pl['region'],
                'query': query,
                'url_type': url_type,
                'final_url': info['final_url'][:120],
                'h1': info.get('h1'),
                'place_links': info.get('place_links', 0),
                'google_name': google_name,
                'name_match': name_match,
            }
            results[pl['id']] = result

            # 每 10 筆存一次
            if (idx + 1) % 10 == 0:
                with open(OUT, 'w') as f:
                    json.dump(results, f, ensure_ascii=False, indent=2)

            # log
            flag = '✓' if url_type == 'unique' else '⚠'
            name_info = f' G={google_name[:15]}' if google_name else ''
            match_info = f' [{name_match}]' if name_match else ''
            primary = pl['name'].split('/')[0].split('(')[0].strip()
            log(f'{idx+1:3d}/{len(places)} {flag} [{url_type:9s}] {pl["id"][:22]:22s} {primary[:16]:18s}{name_info}{match_info}')

        except Exception as e:
            results[pl['id']] = {
                'name': pl['name'],
                'area': pl['area'],
                'region': pl['region'],
                'query': query,
                'url_type': 'error',
                'error': str(e)[:120],
            }
            log(f'{idx+1:3d}/{len(places)} ! [error    ] {pl["id"][:22]:22s} {str(e)[:60]}')

        time.sleep(1.5)  # 避免被 Google 限速

    browser.close()

# 最終存檔
with open(OUT, 'w') as f:
    json.dump(results, f, ensure_ascii=False, indent=2)

# 統計
unique_count = sum(1 for v in results.values() if v.get('url_type') == 'unique')
ambig_count  = sum(1 for v in results.values() if v.get('url_type') == 'ambiguous')
error_count  = sum(1 for v in results.values() if v.get('url_type') == 'error')
diff_count   = sum(1 for v in results.values() if v.get('name_match') == 'different')
partial_count = sum(1 for v in results.values() if v.get('name_match') == 'partial')

log(f'=== 完成 ===')
log(f'唯一地點 (unique): {unique_count}')
log(f'多結果 (ambiguous): {ambig_count}')
log(f'錯誤: {error_count}')
log(f'名字完全不同: {diff_count}')
log(f'名字部分匹配: {partial_count}')
log(f'結果寫到: {OUT}')
