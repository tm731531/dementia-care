"""對 mrt_stations_raw.json 每筆 Playwright Google Maps geocode 拿 lat/lng

對齊 geocode_libstat.py pattern (throttle 5s + jitter ±2s + resume support)。
加 3 條 MRT 特定 reject:
  1. no_geocode: 無 @coord redirect → reject
  2. out_of_bbox: lat/lng 落在系統 bbox 外 → reject
  3. default_pin: 完全相同 (lat,lng) 出現 2+ 次 → reject 後出現的

query 格式: "<sys-label> <name>站" e.g. "台北捷運 中山站"
高雄輕軌站若首次 query 無 @coord,自動 fallback 到 "高雄輕軌 <name>站"。

usage:
    python3 scripts/geocode_mrt.py --input /tmp/mrt_stations_raw.json -o /tmp/mrt_stations_geocoded.json
    python3 scripts/geocode_mrt.py --input /tmp/mrt_stations_raw.json -o /tmp/smoke.json --limit 5
"""
import argparse, json, random, re, sys, time, urllib.parse
from collections import Counter
from datetime import date
from playwright.sync_api import sync_playwright

COORD_RE = re.compile(r'@(-?\d+\.\d+),(-?\d+\.\d+)')
TODAY = date.today().isoformat()

SYS_LABEL = {
    'tpe': '台北捷運',
    'khh': '高雄捷運',
    'tao': '桃園捷運',
    'tch': '台中捷運',
    'ntp': '新北捷運',
}

SYS_BBOX = {
    'tpe': (24.95, 25.20, 121.40, 121.70),
    'khh': (22.40, 22.90, 120.20, 120.45),
    'tao': (24.95, 25.10, 121.20, 121.55),
    'tch': (24.05, 24.30, 120.55, 120.75),
    'ntp': (24.95, 25.30, 121.35, 121.65),  # 比 spec 寬:含淡海輕軌(北至 lat 25.18)+ 安坑輕軌(lng 121.42)
}

KHH_LRT_LINES = {'輕軌', 'C輕軌', '環狀輕軌'}


def is_lrt(entry):
    return any(l in KHH_LRT_LINES for l in entry.get('lines', []))


def in_bbox(sys_key, lat, lng):
    bb = SYS_BBOX.get(sys_key)
    if not bb:
        return True
    return bb[0] <= lat <= bb[1] and bb[2] <= lng <= bb[3]


def geocode_one(page, query, timeout_ms=20000):
    # /search/ 不是 /place/ — /place/ 對捷運站 query 會回 default pin
    url = f'https://www.google.com.tw/maps/search/{urllib.parse.quote(query)}'
    page.goto(url, wait_until='domcontentloaded', timeout=timeout_ms)
    try:
        page.wait_for_url(COORD_RE, timeout=12000)
    except Exception:
        pass
    time.sleep(1.5)  # 給 JS 一點時間穩定
    m = COORD_RE.search(page.url)
    if m:
        return float(m.group(1)), float(m.group(2)), page.url
    return None, None, page.url


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--input', required=True, help='input JSON (mrt_stations_raw.json)')
    ap.add_argument('-o', '--output', required=True, help='output JSON path')
    ap.add_argument('--throttle', type=float, default=5.0, help='req 間隔基準秒(預設 5s)')
    ap.add_argument('--jitter', type=float, default=2.0, help='隨機 jitter ±s(預設 2s)')
    ap.add_argument('--headed', action='store_true', help='非 headless(debug 用)')
    ap.add_argument('--limit', type=int, default=None, help='只跑前 N 筆(smoke 用)')
    args = ap.parse_args()

    all_entries = json.load(open(args.input))
    entries = all_entries[:args.limit] if args.limit else all_entries
    print(f"Input: {len(all_entries)} total, processing: {len(entries)}", file=sys.stderr)

    try:
        existing = {
            f"{e['sys']}-{e['name']}": e
            for e in json.load(open(args.output))
            if e.get('lat') is not None or e.get('reject_reason')
        }
        print(f"Resume: {len(existing)} already done", file=sys.stderr)
    except Exception:
        existing = {}

    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=not args.headed)
        ctx = browser.new_context(
            viewport={'width': 1280, 'height': 900},
            locale='zh-TW',
            user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
        )
        page = ctx.new_page()

        results = []
        for i, e in enumerate(entries, 1):
            key = f"{e['sys']}-{e['name']}"
            if key in existing:
                results.append(existing[key])
                print(f"[{i}/{len(entries)}] · skip {e['name']}", file=sys.stderr)
                continue

            entry = dict(e)
            label = SYS_LABEL.get(entry['sys'], entry['sys'])
            query = f"{label} {entry['name']}站"

            try:
                lat, lng, url = geocode_one(page, query)

                if lat is None and entry['sys'] == 'khh' and is_lrt(entry):
                    lrt_query = f"高雄輕軌 {entry['name']}站"
                    print(f"[{i}/{len(entries)}] ↻ fallback lrt: {lrt_query[:30]}", file=sys.stderr)
                    lat, lng, url = geocode_one(page, lrt_query)

                if lat is None:
                    entry['reject_reason'] = 'no_geocode'
                elif not in_bbox(entry['sys'], lat, lng):
                    entry['reject_reason'] = f'out_of_bbox ({lat:.4f},{lng:.4f})'
                else:
                    entry['lat'] = round(lat, 4)
                    entry['lng'] = round(lng, 4)
                    entry['matched_url'] = url
                    entry['last_verified'] = TODAY

                ok = '✓' if entry.get('lat') else '✗'
                desc = entry.get('reject_reason', f"{entry.get('lat')},{entry.get('lng')}")
                print(f"[{i}/{len(entries)}] {ok} {query[:30]} → {desc}", file=sys.stderr)

            except Exception as ex:
                entry['error'] = str(ex)[:120]
                print(f"[{i}/{len(entries)}] ! {ex.__class__.__name__}: {str(ex)[:80]}", file=sys.stderr)

            results.append(entry)

            with open(args.output, 'w', encoding='utf-8') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)

            if i < len(entries):
                wait = args.throttle + random.uniform(-args.jitter, args.jitter)
                wait = max(2.0, wait)
                time.sleep(wait)

        browser.close()

    coord_count = Counter(
        (e.get('lat'), e.get('lng')) for e in results if e.get('lat') is not None
    )
    seen_coords = set()
    for e in results:
        if e.get('lat') is None:
            continue
        c = (e['lat'], e['lng'])
        if coord_count[c] > 1:
            if c in seen_coords:
                e.pop('lat', None)
                e.pop('lng', None)
                e.pop('matched_url', None)
                e['reject_reason'] = f'default_pin (shared with {coord_count[c] - 1} others)'
            else:
                seen_coords.add(c)
        else:
            seen_coords.add(c)

    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    ok = sum(1 for e in results if e.get('lat') is not None)
    rej = sum(1 for e in results if e.get('reject_reason'))
    print(f"\nDone: {ok}/{len(results)} OK, {rej} rejected", file=sys.stderr)


if __name__ == '__main__':
    main()
