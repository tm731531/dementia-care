"""對 libstat 政府地址 forward geocode 拿 lat/lng

用 Playwright 跑 Google Maps,從 redirect URL 抓 @lat,lng (既有 scrape_meta.py
pattern incremental 套用)。

throttle 5s + 隨機 jitter ±2s(避免規律請求,接近人類點擊節奏)。

usage:
    python3 scripts/geocode_libstat.py --input /tmp/wave_b_worksheet.json -o /tmp/wave_b_geocoded.json

input JSON:[{libCode, name, address, ...}, ...]
output JSON:同 input + 加 lat / lng / matched_url 欄位

note:對 self-use scope (kids-weekend 自用工具,非商業) — incremental 套用既有
pattern,enforcement risk 接近零。商業化 / 對外推 場景請改 Maps API 付費。
"""
import argparse, json, random, re, sys, time, urllib.parse
from playwright.sync_api import sync_playwright

COORD_RE = re.compile(r'@(-?\d+\.\d+),(-?\d+\.\d+)')

def geocode_one(page, address, timeout_ms=20000):
    """跑一個 address,回 (lat, lng) or None。"""
    url = f'https://www.google.com.tw/maps/place/{urllib.parse.quote(address)}'
    page.goto(url, wait_until='domcontentloaded', timeout=timeout_ms)
    # Wait for URL to update with @lat,lng (place detail loaded)
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
    ap.add_argument('--input', required=True, help='input JSON (worksheet)')
    ap.add_argument('-o', '--output', required=True, help='output JSON path')
    ap.add_argument('--throttle', type=float, default=5.0, help='req 間隔基準秒(預設 5s)')
    ap.add_argument('--jitter', type=float, default=2.0, help='隨機 jitter ±s(預設 2s)')
    ap.add_argument('--headed', action='store_true', help='非 headless(debug 用)')
    args = ap.parse_args()

    entries = json.load(open(args.input))
    print(f"Input: {len(entries)} entries", file=sys.stderr)

    # Resume support
    try:
        existing = {e.get('libCode'): e for e in json.load(open(args.output))
                    if e.get('lat') is not None}
        print(f"Resume: {len(existing)} already done", file=sys.stderr)
    except Exception:
        existing = {}

    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=not args.headed)
        ctx = browser.new_context(
            viewport={'width': 1280, 'height': 900}, locale='zh-TW',
            user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36'
        )
        page = ctx.new_page()

        results = []
        for i, e in enumerate(entries, 1):
            code = e.get('libCode', f'_{i}')
            if code in existing:
                results.append(existing[code])
                print(f"[{i}/{len(entries)}] · skip (cached) {e.get('name', '')[:40]}", file=sys.stderr)
                continue
            addr = e.get('address', '')
            if not addr:
                e['error'] = 'no address'
                results.append(e)
                continue
            try:
                lat, lng, final_url = geocode_one(page, addr)
                if lat is not None:
                    e['lat'] = lat
                    e['lng'] = lng
                    e['matched_url'] = final_url
                    print(f"[{i}/{len(entries)}] ✓ [{lat:.4f}, {lng:.4f}] {e.get('name', '')[:40]}", file=sys.stderr)
                else:
                    e['lat'] = None
                    e['lng'] = None
                    e['matched_url'] = final_url
                    print(f"[{i}/{len(entries)}] ✗ no @coord redirect: {addr[:40]}", file=sys.stderr)
            except Exception as ex:
                e['error'] = str(ex)[:120]
                print(f"[{i}/{len(entries)}] ! {ex.__class__.__name__}: {str(ex)[:80]}", file=sys.stderr)
            results.append(e)

            # Save every entry (resume safety)
            with open(args.output, 'w', encoding='utf-8') as f:
                json.dump(results, f, ensure_ascii=False, indent=2)

            # Throttle (skip after last)
            if i < len(entries):
                wait = args.throttle + random.uniform(-args.jitter, args.jitter)
                wait = max(2.0, wait)
                time.sleep(wait)

        browser.close()

    ok = [r for r in results if r.get('lat')]
    miss = [r for r in results if not r.get('lat')]
    print(f"\n=== Done: {len(ok)}/{len(results)} geocoded ===", file=sys.stderr)
    if miss:
        print(f"\n--- 沒抓到 (likely 地址太模糊或 @ 沒在 URL) ---", file=sys.stderr)
        for m in miss:
            print(f"  {m.get('name', '')[:40]} | {m.get('address', '')[:40]}", file=sys.stderr)

if __name__ == '__main__':
    main()
