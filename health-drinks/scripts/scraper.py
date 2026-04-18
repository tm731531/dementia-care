"""
健康飲品資料爬蟲 v2
策略：
  1. 優先從 Open Food Facts JSONL 資料集（本地或下載）篩選
  2. 備用：直接查詢已知條碼清單
  3. 下載圖片到 docs/images/

Open Food Facts 目前對匿名 API 請求有速率限制，
建議先下載完整資料集：
  https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz
  （約 10GB，解壓後逐行篩選）

或使用本腳本的「已知條碼」模式快速取得示範資料。
"""

import json
import time
import urllib.request
import urllib.parse
import os
import re
import gzip
import sys

BASE = os.path.join(os.path.dirname(__file__), "..")
DATA_FILE = os.path.join(BASE, "docs/data/drinks.json")
IMG_DIR   = os.path.join(BASE, "docs/images")

# ── 已知健康飲品條碼（可自行擴充）──
KNOWN_BARCODES = [
    "4902102141109",  # Yakult
    "4902102141116",  # Yakult Light
    "4901085615744",  # Calpis Water
    "4902102072090",  # Yakult 400
    "0049000028904",  # Coca-Cola 200ml
    "5449000131805",  # Sprite 250ml
    "5000112637922",  # Lucozade Sport 250ml
    "5000112548167",  # Lucozade Energy 250ml
    "4006381333498",  # Capri-Sun 200ml
    "4006381333504",  # Capri-Sun Orange 200ml
    "3228857000166",  # Innocent Smoothie 250ml
    "5011546300017",  # Ribena 250ml
    "5000112548174",  # Lucozade Orange 250ml
    "4902102072106",  # Yakult 400LT
    "8710398519306",  # Optimel 200ml
    "3155251205110",  # Actimel 100ml (示範，會被過濾)
    "3155251205127",  # Actimel Strawberry
    "4005808727582",  # Nivea (非飲品，測試過濾)
    "8718452011427",  # Fristi 200ml
    "5000112548181",  # Lucozade Berry 250ml
    "4902102072113",  # Yakult Ace
    "4902102072120",  # Yakult Ace Light
    "0049000028928",  # Fanta 200ml
    "5449000131812",  # Fanta Orange 250ml
    "4006381333511",  # Capri-Sun Multivitamin
    "3228857000173",  # Innocent Kids 180ml
    "5011546300024",  # Ribena Light 250ml
    "8710398519313",  # Optimel Drink
    "4902102072137",  # Yakult Joie
    "5000112637939",  # Lucozade Sport Orange 250ml
]

def fetch_product(barcode):
    url = f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json"
    req = urllib.request.Request(url, headers={
        "User-Agent": "HealthDrinkAnalyzer/2.0 (https://github.com/user/trai; contact@example.com)"
    })
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        print(f"  [錯誤] {barcode}: {e}")
        return None

def parse_volume_ml(quantity_str):
    if not quantity_str:
        return None
    q = quantity_str.lower().replace(" ", "")
    m = re.search(r"(\d+(?:\.\d+)?)\s*ml", q)
    if m:
        return float(m.group(1))
    m = re.search(r"(\d+(?:\.\d+)?)\s*cl", q)
    if m:
        return float(m.group(1)) * 10
    m = re.search(r"(\d+(?:\.\d+)?)\s*fl\.?oz", q)
    if m:
        return float(m.group(1)) * 29.5735
    return None

def download_image(url, product_id):
    if not url:
        return None
    ext = url.split(".")[-1].split("?")[0]
    if ext not in ("jpg", "jpeg", "png", "webp"):
        ext = "jpg"
    filename = f"{product_id}.{ext}"
    filepath = os.path.join(IMG_DIR, filename)
    if os.path.exists(filepath):
        return f"images/{filename}"
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "HealthDrinkAnalyzer/2.0 (https://github.com/user/trai)"
        })
        with urllib.request.urlopen(req, timeout=10) as resp:
            with open(filepath, "wb") as f:
                f.write(resp.read())
        print(f"    ✓ 圖片：{filename}")
        return f"images/{filename}"
    except Exception as e:
        print(f"    ✗ 圖片失敗：{e}")
        return None

def extract_nutrients(n):
    mapping = {
        "energy-kcal_100g": "熱量(kcal)",
        "sugars_100g":       "糖(g)",
        "sodium_100g":       "鈉(mg)",
        "proteins_100g":     "蛋白質(g)",
        "fat_100g":          "脂肪(g)",
        "carbohydrates_100g":"碳水化合物(g)",
        "vitamin-c_100g":    "維生素C(mg)",
        "caffeine_100g":     "咖啡因(mg)",
    }
    result = {}
    for k, label in mapping.items():
        v = n.get(k)
        if v is None and k == "energy-kcal_100g":
            # fallback: kJ -> kcal
            kj = n.get("energy_100g")
            if kj:
                v = round(kj / 4.184, 1)
        if v is not None:
            if label == "鈉(mg)":
                v = round(v * 1000, 1)
            result[label] = round(v, 2)
    return result

def process_from_jsonl(jsonl_path):
    """從本地 JSONL 資料集篩選（適合大量資料）"""
    drinks = {}
    opener = gzip.open if jsonl_path.endswith(".gz") else open
    print(f"📂 讀取本地資料集：{jsonl_path}")
    with opener(jsonl_path, "rt", encoding="utf-8", errors="ignore") as f:
        for i, line in enumerate(f):
            if i % 100000 == 0:
                print(f"  已處理 {i:,} 筆，找到 {len(drinks)} 筆符合...")
            try:
                p = json.loads(line)
            except Exception:
                continue
            if not p.get("product_name"):
                continue
            vol = parse_volume_ml(p.get("quantity", ""))
            if vol is None or not (180 <= vol <= 280):
                continue
            cats = p.get("categories_tags", [])
            if not any(kw in c for c in cats for kw in ("beverage","drink","juice","tea","water","milk","smoothie")):
                continue
            pid = p.get("id") or p.get("_id", "")
            if not pid or pid in drinks:
                continue
            drinks[pid] = {
                "id": pid,
                "name": p["product_name"].strip(),
                "brand": p.get("brands", ""),
                "volume_ml": vol,
                "ingredients": p.get("ingredients_text", ""),
                "nutrients": extract_nutrients(p.get("nutriments", {})),
                "image": None,  # 不下載圖片（資料集太大）
                "categories": [c.replace("en:","").replace("-"," ") for c in cats[:5]],
            }
    return list(drinks.values())

def process_from_barcodes():
    """從已知條碼清單逐一查詢"""
    drinks = {}
    print(f"🔍 查詢 {len(KNOWN_BARCODES)} 個已知條碼...")
    for barcode in KNOWN_BARCODES:
        print(f"  查詢：{barcode}")
        data = fetch_product(barcode)
        if not data or data.get("status") != 1:
            print(f"    ✗ 找不到")
            time.sleep(0.5)
            continue
        p = data.get("product", {})
        name = p.get("product_name", "").strip()
        if not name:
            time.sleep(0.5)
            continue
        vol = parse_volume_ml(p.get("quantity", ""))
        if vol is None or not (180 <= vol <= 280):
            print(f"    ✗ 容量不符：{p.get('quantity')} ({vol}ml)")
            time.sleep(0.5)
            continue
        img = download_image(p.get("image_url"), barcode)
        drinks[barcode] = {
            "id": barcode,
            "name": name,
            "brand": p.get("brands", ""),
            "volume_ml": vol,
            "ingredients": p.get("ingredients_text", ""),
            "nutrients": extract_nutrients(p.get("nutriments", {})),
            "image": img,
            "categories": [c.replace("en:","").replace("-"," ") for c in p.get("categories_tags", [])[:5]],
        }
        print(f"    ✓ {name} ({vol}ml)")
        time.sleep(1)
    return list(drinks.values())

def main():
    os.makedirs(IMG_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)

    # 如果有本地 JSONL 資料集，優先使用
    jsonl_candidates = [
        os.path.join(BASE, "openfoodfacts-products.jsonl.gz"),
        os.path.join(BASE, "openfoodfacts-products.jsonl"),
        "/tmp/openfoodfacts-products.jsonl.gz",
    ]
    jsonl_path = next((p for p in jsonl_candidates if os.path.exists(p)), None)

    if jsonl_path:
        result = process_from_jsonl(jsonl_path)
    else:
        print("💡 提示：若要取得更多資料，可下載完整資料集：")
        print("   wget https://static.openfoodfacts.org/data/openfoodfacts-products.jsonl.gz")
        print("   放到專案根目錄後重新執行此腳本\n")
        result = process_from_barcodes()

    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"\n✅ 完成！共收集 {len(result)} 筆飲品資料")
    print(f"   資料儲存：{DATA_FILE}")

if __name__ == "__main__":
    main()
