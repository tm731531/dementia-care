"""
從品牌官方旗艦店爬取醫療營養飲品的成分表圖片。
目前支援：abbottmall.com.tw（亞培）。
自動過濾 180-280ml 產品，下載所有內容圖片到 staging/<品名>/ 資料夾。
成分表圖片在 ckeditor 內容區（通常是最後 3-5 張）。

用法：
  python3 scripts/fetch_nutrition_images.py           # 跑所有品牌
  python3 scripts/fetch_nutrition_images.py abbott    # 只跑 Abbott
"""

import sys
import os
import re
import time
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE    = Path(__file__).parent.parent
STAGING = BASE / "staging"
STAGING.mkdir(exist_ok=True)

VOL_RE = re.compile(r'(\d+(?:\.\d+)?)\s*(?:ml|毫升|mL)', re.IGNORECASE)

# 品牌設定：集合頁 URL 清單
BRANDS = {
    "abbott": {
        "name": "亞培 Abbott",
        "collections": [
            "https://www.abbottmall.com.tw/collections/安素即飲系列",
            "https://www.abbottmall.com.tw/collections/葡勝納即飲系列",
            "https://www.abbottmall.com.tw/collections/倍力素即飲系列",
        ],
        "product_img_selector": "img[src*='ckeditor']",
    },
}


def safe_name(s: str) -> str:
    s = re.sub(r'[^\w\u4e00-\u9fff\-]', '_', s)
    return s[:60].strip('_')


def in_range(text: str) -> bool:
    """文字裡有 180-280ml 就回 True"""
    for m in VOL_RE.finditer(text):
        v = float(m.group(1))
        if 180 <= v <= 280:
            return True
    return False


def get_product_links(page, collection_url: str) -> list[str]:
    page.goto(collection_url, wait_until="domcontentloaded", timeout=20000)
    time.sleep(2)
    links = page.eval_on_selector_all(
        "a[href*='/products/']",
        "els => [...new Set(els.map(e=>e.href))]"
    )
    return links


def scrape_product(page, product_url: str) -> dict | None:
    page.goto(product_url, wait_until="domcontentloaded", timeout=30000)
    time.sleep(2)

    title_raw = page.title()
    name = title_raw.split('|')[0].strip()

    # 過濾容量
    if not in_range(name) and not in_range(product_url):
        return None

    imgs = page.eval_on_selector_all(
        "img[src*='ckeditor']",
        "els => [...new Set(els.map(e=>e.src).filter(Boolean))]"
    )

    return {"name": name, "url": product_url, "images": imgs}


def download_images(page, product_info: dict) -> list[str]:
    name  = product_info["name"]
    imgs  = product_info["images"]
    slug  = safe_name(name)
    out   = STAGING / slug
    out.mkdir(exist_ok=True)

    saved = []
    for i, img_url in enumerate(imgs):
        try:
            resp = page.request.get(img_url, timeout=15000)
            if not resp.ok:
                continue
            ext = img_url.rsplit(".", 1)[-1].split("?")[0].lower()
            if ext not in ("jpg", "jpeg", "png", "webp"):
                ext = "jpg"
            path = out / f"{i+1:02d}.{ext}"
            path.write_bytes(resp.body())
            saved.append(str(path))
        except Exception as e:
            print(f"      ✗ 圖 {i+1}: {e}")

    print(f"   💾 {name[:50]}  → {len(saved)}/{len(imgs)} 張")
    return saved


def main():
    filter_brand = sys.argv[1].lower() if len(sys.argv) > 1 else None
    brands = {k: v for k, v in BRANDS.items()
              if not filter_brand or filter_brand in k.lower()}

    if not brands:
        print(f"⚠️  找不到品牌：{filter_brand}，可用：{list(BRANDS.keys())}")
        return

    total_products = 0
    total_images   = 0

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        pw_page = browser.new_page(
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                       "AppleWebKit/537.36 Chrome/120 Safari/537.36"
        )

        for brand_key, brand in brands.items():
            print(f"\n{'='*50}")
            print(f"📦 品牌：{brand['name']}")

            all_links: set[str] = set()
            for col_url in brand["collections"]:
                try:
                    links = get_product_links(pw_page, col_url)
                    print(f"   集合 {col_url.split('/')[-1]}：{len(links)} 個產品")
                    all_links.update(links)
                except Exception as e:
                    print(f"   ⚠️  集合頁失敗：{e}")

            print(f"   去重後共 {len(all_links)} 個產品")

            for link in sorted(all_links):
                try:
                    info = scrape_product(pw_page, link)
                    if not info:
                        continue

                    print(f"   ✓ {info['name'][:60]}  ({len(info['images'])} 張內容圖)")
                    saved = download_images(pw_page, info)
                    total_products += 1
                    total_images   += len(saved)
                    time.sleep(0.5)
                except Exception as e:
                    print(f"   ⚠️  {link[-60:]}: {e}")

        browser.close()

    print(f"\n{'='*50}")
    print(f"✅ 完成：{total_products} 筆產品，{total_images} 張圖片")
    print(f"   存於：{STAGING}/")


if __name__ == "__main__":
    main()
