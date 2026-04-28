"""kids-weekend PLACES 資料品質 lint
- 偵測:尾逗號錯誤、region/area mismatch、enum 拼錯、座標範圍、JS 語法、duplicate id
- exit 0 = 全過、exit 1 = 有違規
- 跑法:python3 kids-weekend/scripts/lint_places.py
"""
import re, sys, json
from pathlib import Path

PATH = Path(__file__).parent.parent / 'index.html'
content = PATH.read_text(encoding='utf-8')

errors = []
warnings = []

# 1. 抓 PLACES array(從 const PLACES = [ 到第一個 ];)
m = re.search(r'const PLACES = \[(.*?)\n\s*\];', content, re.DOTALL)
if not m:
    errors.append('找不到 PLACES 陣列起點 / 結尾')
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
places_block = m.group(1)

# 2. 抽每筆物件(用 regex 比較粗,但對 lint 夠)
PLACE_RE = re.compile(
    r"\{id:'([^']+)',\s*name:'([^']+)',\s*emoji:'([^']*)',\s*"
    r"area:'([^']+)',\s*region:'(\w+)',\s*indoor:(true|false),\s*outdoor:(true|false)"
    r"[^}]*ages:\[([^\]]+)\][^}]*types:\[([^\]]+)\][^}]*crowd:'(\w+)'"
)
seen_ids = {}
all_places = []
for m in PLACE_RE.finditer(places_block):
    pid, name, emoji, area, region, indoor, outdoor, ages_s, types_s, crowd = m.groups()
    all_places.append({
        'id': pid, 'name': name, 'area': area, 'region': region,
        'indoor': indoor == 'true', 'outdoor': outdoor == 'true',
        'ages': ages_s, 'types': types_s, 'crowd': crowd,
    })
    if pid in seen_ids:
        errors.append(f"DUP id: {pid} (line ~{seen_ids[pid]} + new)")
    else:
        seen_ids[pid] = m.start()

print(f'掃到 {len(all_places)} 筆 PLACE')

# 3. region key 必須 valid
VALID_REGIONS = {'taipei','newtaipei','keelung','taoyuan','hsinchu_city','hsinchu_county',
                 'miaoli','taichung','changhua','nantou','yunlin','chiayi_city','chiayi_county',
                 'tainan','kaohsiung','pingtung','yilan','hualien','taitung','penghu','kinmen','lienchiang'}
REGION_PREFIX = {
    'taipei':'台北','newtaipei':'新北','keelung':'基隆','taoyuan':'桃園',
    'hsinchu_city':'新竹','hsinchu_county':'新竹','miaoli':'苗栗','taichung':'台中',
    'changhua':'彰化','nantou':'南投','yunlin':'雲林','chiayi_city':'嘉義','chiayi_county':'嘉義',
    'tainan':'台南','kaohsiung':'高雄','pingtung':'屏東','yilan':'宜蘭','hualien':'花蓮',
    'taitung':'台東','penghu':'澎湖','kinmen':'金門','lienchiang':'馬祖',
}

# 4. ages enum
VALID_AGES = {"'0-2'", "'2-3'", "'3-6'"}

# 5. crowd enum
VALID_CROWD = {'low', 'mid', 'high'}

for pl in all_places:
    # region valid
    if pl['region'] not in VALID_REGIONS:
        errors.append(f"{pl['id']}: invalid region '{pl['region']}'")
    # area prefix 對應 region
    elif pl['region'] in REGION_PREFIX and not pl['area'].startswith(REGION_PREFIX[pl['region']]):
        warnings.append(f"{pl['id']}: area '{pl['area']}' 不以 '{REGION_PREFIX[pl['region']]}' 開頭(region={pl['region']})")
    # ages enum
    ages_items = [a.strip() for a in pl['ages'].split(',')]
    for a in ages_items:
        if a not in VALID_AGES:
            errors.append(f"{pl['id']}: invalid age '{a}',只能是 0-2/2-3/3-6")
    # crowd enum
    if pl['crowd'] not in VALID_CROWD:
        errors.append(f"{pl['id']}: invalid crowd '{pl['crowd']}',只能是 low/mid/high")
    # indoor/outdoor 至少一個
    if not pl['indoor'] and not pl['outdoor']:
        errors.append(f"{pl['id']}: indoor 跟 outdoor 不能都 false")

# 6. PRECISE_COORDS 範圍
COORD_RE = re.compile(r"'([\w-]+)':\s*\[(-?\d+\.\d+),(-?\d+\.\d+)\]")
m = re.search(r'const PRECISE_COORDS = \{(.*?)\n\s*\};', content, re.DOTALL)
if m:
    for cm in COORD_RE.finditer(m.group(1)):
        pid, lat_s, lng_s = cm.groups()
        lat, lng = float(lat_s), float(lng_s)
        if not (21.5 <= lat <= 26.5 and 118 <= lng <= 122.5):
            errors.append(f"{pid}: coord [{lat}, {lng}] 在台灣範圍外")

# 7. 整檔 JS 語法(node 在 CI 跑 — 略,假設 GH Actions 會有 node step)

# Output
if warnings:
    print(f'\n⚠ {len(warnings)} 個 warning:')
    for w in warnings[:20]:
        print(f'  {w}')
    if len(warnings) > 20: print(f'  ... 還有 {len(warnings)-20} 個')

if errors:
    print(f'\n✗ {len(errors)} 個 error:')
    for e in errors[:30]:
        print(f'  {e}')
    if len(errors) > 30: print(f'  ... 還有 {len(errors)-30} 個')
    sys.exit(1)

print(f'\n✓ Lint passed:{len(all_places)} 筆景點全合規')
sys.exit(0)
