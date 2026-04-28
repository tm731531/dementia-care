"""
從圖片自動提取營養成分，與 drinks.js 手動核實數據比對。
用途：驗證 vision 提取流程的準確率。
"""

import anthropic
import base64
import json
import os
import re
import sys

BASE     = os.path.join(os.path.dirname(__file__), "..")
IMG_DIR  = os.path.join(BASE, "docs/images")
DATA_FILE = os.path.join(BASE, "docs/data/drinks.js")

client = anthropic.Anthropic()

# ── 讀取 ground truth（從 drinks.js 解析） ──
def load_ground_truth():
    with open(DATA_FILE, encoding="utf-8") as f:
        js = f.read()
    # 去掉 const DRINKS = ... 包裝，取出 JSON 陣列
    m = re.search(r"const DRINKS\s*=\s*(\[.*\]);", js, re.DOTALL)
    if not m:
        raise ValueError("無法解析 drinks.js")
    # JS 物件鍵不加引號，先加上引號讓 JSON 可解析
    raw = m.group(1)
    raw = re.sub(r'(\w+):', r'"\1":', raw)       # 鍵加引號
    raw = re.sub(r',\s*\}', '}', raw)             # 去掉尾逗號
    raw = re.sub(r',\s*\]', ']', raw)
    return json.loads(raw)

# ── 呼叫 Claude vision 提取成分 ──
EXTRACT_PROMPT = """
這是一張台灣市售飲品或食品的圖片，可能包含營養標示。

請從圖中找到營養標示表格，提取所有數值。
回傳格式：JSON 物件，鍵為成分名稱（中文，含單位，如 "熱量(kcal)"），值為每100ml的數字。
若找不到營養標示，回傳 {}。
若標示單位是「每份/每瓶」而非每100ml，請換算成每100ml。

只回傳 JSON，不要其他文字。
"""

def extract_from_image(img_path):
    ext = img_path.rsplit(".", 1)[-1].lower()
    mime_map = {"jpg": "image/jpeg", "jpeg": "image/jpeg",
                "png": "image/png", "webp": "image/webp"}
    mime = mime_map.get(ext, "image/jpeg")

    with open(img_path, "rb") as f:
        b64 = base64.standard_b64encode(f.read()).decode()

    resp = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": [
                {"type": "image", "source": {"type": "base64", "media_type": mime, "data": b64}},
                {"type": "text", "text": EXTRACT_PROMPT}
            ]
        }]
    )
    raw = resp.content[0].text.strip()
    # 清理 markdown code block
    raw = re.sub(r"```(?:json)?", "", raw).strip().rstrip("`").strip()
    try:
        return json.loads(raw)
    except Exception:
        print(f"  [警告] JSON 解析失敗：{raw[:80]}")
        return {}

# ── 數值比對 ──
def compare(ground, extracted):
    results = []
    all_keys = set(ground) | set(extracted)
    for k in sorted(all_keys):
        g = ground.get(k)
        e = extracted.get(k)
        if g is None and e is None:
            continue
        if g is None:
            results.append({"成分": k, "手動": "—", "自動": e, "狀態": "多餘"})
        elif e is None:
            results.append({"成分": k, "手動": g, "自動": "—", "狀態": "缺漏"})
        else:
            try:
                diff = abs(float(e) - float(g))
                pct  = diff / float(g) * 100 if float(g) != 0 else (0 if diff == 0 else 999)
                ok   = "✅" if pct <= 5 else ("⚠️" if pct <= 15 else "❌")
                results.append({"成分": k, "手動": g, "自動": e,
                                 "差異%": f"{pct:.1f}%", "狀態": ok})
            except Exception:
                results.append({"成分": k, "手動": g, "自動": e, "狀態": "?"})
    return results

# ── 主程式 ──
def main():
    drinks = load_ground_truth()
    print(f"載入 {len(drinks)} 筆 ground truth\n")

    summary = []

    for d in drinks:
        img_rel  = d.get("image", "")
        img_path = os.path.join(BASE, "docs", img_rel) if img_rel else None

        print(f"{'─'*60}")
        print(f"🥤 {d['name']}  ({d['brand']})")

        if not img_path or not os.path.exists(img_path):
            print(f"   ⚠️  圖片不存在：{img_rel}")
            continue

        print(f"   圖片：{os.path.basename(img_path)}")
        extracted = extract_from_image(img_path)

        if not extracted:
            print("   ❌ 無法從圖片提取成分")
            summary.append({"name": d["name"], "matched": 0, "total": len(d.get("nutrients", {})), "ok": False})
            continue

        rows = compare(d.get("nutrients", {}), extracted)
        ok_count = sum(1 for r in rows if r.get("狀態") == "✅")
        total    = sum(1 for r in rows if r.get("狀態") in ("✅","⚠️","❌"))

        for r in rows:
            print(f"   {r.get('狀態','?'):2}  {r['成分']:20s}  手動={r['手動']:>8}  自動={r['自動']:>8}  {r.get('差異%','')}")

        print(f"   → 準確率（±5%）：{ok_count}/{total}")
        summary.append({"name": d["name"], "matched": ok_count, "total": total, "ok": total > 0 and ok_count == total})

    print(f"\n{'═'*60}")
    print("總結")
    print(f"{'═'*60}")
    for s in summary:
        icon = "✅" if s["ok"] else ("⚠️" if s["matched"] > 0 else "❌")
        print(f"  {icon}  {s['name']}  {s['matched']}/{s['total']}")

if __name__ == "__main__":
    main()
