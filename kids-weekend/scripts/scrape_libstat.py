"""從 國家圖書館 全國圖書館統計系統 (libstat.ncl.edu.tw) 抓圖書館 official 資料

用途:為將來批量擴充 PLACES 提供乾淨來源(政府公開,不走 Google Maps ToS)。
抓:libCode + name + address + phone + website + opac_url

usage:
    python3 scripts/scrape_libstat.py --city 新北市 --cate 公共圖書館 -o /tmp/libstat_newtaipei.json
    python3 scripts/scrape_libstat.py --all-cities --cate 公共圖書館 -o /tmp/libstat_all.json
    python3 scripts/scrape_libstat.py --search 李科永 -o /tmp/libstat_likeyong.json

output JSON schema:
    [{"libCode":"L4941000", "city":"臺北市", "cate":"公共圖書館",
      "name":"臺北市立圖書館北投分館",
      "address":"臺北市北投區光明路251號", "phone":"(02)28977682",
      "website":"https://...", "opac_url":"https://book.tpml.edu.tw"}, ...]

note:libstat 沒有開放時間 / 經緯度欄位,要 hours/coord 走 OSM Nominatim 二次加工。
"""
import argparse, json, re, sys, time
from urllib.parse import urlencode
from urllib.request import Request, build_opener, HTTPCookieProcessor
from http.cookiejar import CookieJar

BASE = 'https://libstat.ncl.edu.tw'
INDEX = f'{BASE}/libraryData/dad8fffffcd64bee97b64520adb9d83e'
SEARCH = f'{BASE}/libraryData/search'
UA = 'kids-weekend-data-quality/1.0 (tonic16888@gmail.com)'

CITY_HASH = {
    '臺北市': '278642baa1904e7d86cac7be1f0e4e48',
    '新北市': '2340470f16764cd483844fd3437914cb',
    '桃園市': 'e24fadc5ccdb432ab4f5f3c4cc6762d7',
    '臺中市': '23f38b0c97bf466d97a07e8b2aa456bb',
    '臺南市': 'e6bf9c0c5b7744bc9149082b1e35b709',
    '高雄市': '8d2b69ecb71f48eb9f533f6835808403',
    '基隆市': '36b71abaa5d74d459507136e25c51377',
    '新竹市': '00bef746064c4a1f80c4f957e465930d',
    '新竹縣': 'e514ecaf91464c77bde6a4b3bd95018e',
    '苗栗縣': '616e75c0548d47658bc6c3edf5f806d6',
    '彰化縣': '22c2f46edf874babba7b9f9976720d3e',
    '南投縣': '1827c7bc2ee84cdea057c975b84b6cd0',
    '雲林縣': 'b495d0894073420c822e5c65234629c2',
    '嘉義市': 'b66070e5b57c496aad71118a59e3726b',
    '嘉義縣': 'ad4874eb41884ddebe0082edf29a2bd8',
    '屏東縣': '5e3d17403fe64817a3a2476a376c04c1',
    '宜蘭縣': '1b314b4abc0443ff907e8ffd37bf92e7',
    '花蓮縣': '4ec721d8e5b14786aa065acc63e21c2c',
    '臺東縣': 'f87434e25d394ddc96dda1f24cf45ef0',
    '澎湖縣': '145f68c4de0e4a1ab50f6f87f2289019',
    '金門縣': 'fc4f219c3acd4b69aded0ce3fd713b32',
    '連江縣': 'f81fefedaaa94d27b4d077a8ee7bfc9e',
}

CATE_HASH = {
    '國家圖書館': '186b6d40cc7d458b894894959234528b',
    '公共圖書館': '914b901418474567bf749a0347807cea',
    '大專校院圖書館': 'f177cc3ff0ff4637ace6b3b3017229c0',
    '高級中等學校圖書館': 'd115557de4464e46809a35de1e513499',
    '國民中學圖書館': '2f4edba4d579418c86ca74d4fbd541be',
    '國民小學圖書館': '0e0148cbf97d4209a7a897f3c320a815',
    '專門圖書館': 'c7aab385bbf443fdb0d177e2dbb065c8',
}

def make_session():
    cj = CookieJar()
    op = build_opener(HTTPCookieProcessor(cj))
    op.addheaders = [('User-Agent', UA)]
    return op

def fetch(opener, url, data=None, timeout=30):
    req = Request(url, data=data.encode() if data else None)
    with opener.open(req, timeout=timeout) as r:
        return r.read().decode('utf-8', errors='replace')

def get_csrf(opener):
    html = fetch(opener, INDEX)
    m = re.search(r'name="csrfToken"\s*value="([^"]+)"', html)
    if not m:
        raise RuntimeError('csrfToken not found in index page')
    return m.group(1)

def search_page(opener, city_hash='', cate_hash='', name='', page=1, page_size=10):
    csrf = get_csrf(opener)
    params = {
        'csrfToken': csrf,
        'libCity': city_hash,
        'basicCodeLibCate': cate_hash,
        'libCName': name,
        'page': str(page),
        'isPage': 'true',
        'pageSize': str(page_size),
    }
    return fetch(opener, SEARCH, urlencode(params))

def extract_lib_codes(html):
    return re.findall(r'/libraryDataDetail/([A-Za-z0-9]+)', html)

def fetch_detail(opener, lib_code):
    """抓 detail page 的 fields。libstat 用全形冒號(:)。"""
    html = fetch(opener, f'{BASE}/libraryDataDetail/{lib_code}')
    def find(pat, default=''):
        m = re.search(pat, html)
        return m.group(1).strip() if m else default
    return {
        'libCode': lib_code,
        'name': find(r'<h2 class="h2-page-title">([^<]+)</h2>'),
        'address': find(r'地址：([^<]+)'),
        'phone': find(r'讀者諮詢電話：([^<]+)'),
        'website': find(r'圖書館網站：<a href="([^"]+)"'),
        'opac_url': find(r'館藏查詢目錄：<a href="([^"]+)"'),
    }

def scrape(city='', cate='公共圖書館', name='', max_pages=50, throttle=1.0):
    op = make_session()
    city_hash = CITY_HASH.get(city, '')
    cate_hash = CATE_HASH.get(cate, '')
    seen, results = set(), []
    for page in range(1, max_pages + 1):
        try:
            html = search_page(op, city_hash, cate_hash, name, page, page_size=10)
        except Exception as e:
            print(f'[p{page}] search FAIL: {e}', file=sys.stderr)
            break
        codes = [c for c in extract_lib_codes(html) if c not in seen]
        if not codes:
            print(f'[p{page}] 0 new — stop', file=sys.stderr)
            break
        print(f'[p{page}] +{len(codes)} libraries', file=sys.stderr)
        for code in codes:
            seen.add(code)
            try:
                d = fetch_detail(op, code)
                d['city'] = city
                d['cate'] = cate
                results.append(d)
                print(f'  {code} {d.get("name","")[:60]}', file=sys.stderr)
            except Exception as e:
                print(f'  {code} FAIL: {e}', file=sys.stderr)
            time.sleep(throttle)
        time.sleep(throttle)
    return results

def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--city', help='縣市名稱(完整,例如「新北市」)')
    ap.add_argument('--cate', default='公共圖書館', help='類別(預設公共圖書館)')
    ap.add_argument('--search', default='', help='libCName 關鍵字搜')
    ap.add_argument('--all-cities', action='store_true', help='抓所有 22 縣市')
    ap.add_argument('-o', '--output', required=True, help='輸出 JSON 路徑')
    ap.add_argument('--max-pages', type=int, default=50)
    ap.add_argument('--throttle', type=float, default=1.0,
                    help='req 間隔秒(尊重 server,預設 1s)')
    args = ap.parse_args()

    if args.all_cities:
        results = []
        for city in CITY_HASH:
            print(f'\n=== {city} ===', file=sys.stderr)
            results.extend(scrape(city=city, cate=args.cate,
                                  max_pages=args.max_pages, throttle=args.throttle))
    elif args.city or args.search:
        results = scrape(city=args.city or '', cate=args.cate, name=args.search,
                         max_pages=args.max_pages, throttle=args.throttle)
    else:
        ap.error('需要 --city 或 --all-cities 或 --search')

    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print(f'\nWrote {len(results)} libraries → {args.output}', file=sys.stderr)

if __name__ == '__main__':
    main()
