"""抓全台 metro/light_rail 站清單(OSM Overpass)→ /tmp/mrt_stations_raw.json

OSM 給 name + operator + raw lat/lng + ref(站號可推路線)。
sys 從 operator 推。region/district 從 lat/lng 用 TAIWAN_DISTRICTS centroid 最近反查。

raw lat/lng 在此先寫入(後續 Task A2 由 Playwright 校正覆蓋)。

usage:
    python3 scripts/scrape_mrt_stations.py -o /tmp/mrt_stations_raw.json

output: [{sys, name, lines, region, district, lat_osm, lng_osm, source:'osm'}, ...]
"""
import argparse, json, sys, math, urllib.request, urllib.parse
from collections import Counter

OVERPASS = 'https://overpass-api.de/api/interpreter'
QUERY = '''[out:json][timeout:60];
area["name:zh"="臺灣"]->.tw;
(
  node["railway"="station"]["station"="subway"](area.tw);
  node["railway"="station"]["station"="light_rail"](area.tw);
  node["public_transport"="station"]["network:zh"~"捷運|機場捷運|輕軌"](area.tw);
);
out body;'''

# operator substring → sys key (按優先順序排,長字串放前面)
OPERATOR_MAP = [
    # 台北捷運
    ('臺北大眾捷運', 'tpe'), ('台北大眾捷運', 'tpe'),
    ('臺北捷運', 'tpe'), ('台北捷運', 'tpe'),
    ('Taipei Metro', 'tpe'), ('TRTC', 'tpe'),
    # 高雄捷運(含輕軌,都歸 khh)
    ('高雄捷運股份有限公司', 'khh'), ('高雄捷運公司', 'khh'),
    ('高雄捷運', 'khh'), ('KRTC', 'khh'),
    ('高雄輕軌', 'khh'), ('Kaohsiung LRT', 'khh'),
    # 桃園捷運(含機場捷運)
    ('桃園大眾捷運', 'tao'), ('桃園機場捷運', 'tao'),
    ('桃園捷運', 'tao'), ('機場捷運', 'tao'), ('TYMC', 'tao'),
    # 台中捷運
    ('臺中捷運', 'tch'), ('台中捷運', 'tch'), ('TMRT', 'tch'),
    # 新北捷運(環狀線 + 安坑輕軌等)
    ('新北大眾捷運', 'ntp'), ('新北捷運公司', 'ntp'),
    ('新北捷運', 'ntp'), ('NTPC', 'ntp'), ('New Taipei Metro', 'ntp'),
]

def map_sys(operator_str):
    """從 OSM operator/network 欄位推 sys key"""
    if not operator_str:
        return None
    for keyword, sk in OPERATOR_MAP:
        if keyword in operator_str:
            return sk
    return None

def extract_lines(sys_key, ref):
    """從 ref(站號)推路線名稱。
    ref 多條時用 ; 或 , 分隔(轉乘站),例 'BL12;G10' → ['板南','松山新店']
    khh 系統中 R=紅線, O=橘線, C=輕軌(與 TRTC 不同,用 sys 區分)
    新北 Y=環狀, V=淡海輕軌, K=安坑輕軌
    """
    if not ref:
        return []
    lines = set()
    for r in ref.replace(',', ';').split(';'):
        r = r.strip()
        # 擷取字母前綴(站號格式:前綴字母 + 數字,例 BL12)
        prefix = ''.join(c for c in r if c.isalpha()).upper()
        if not prefix:
            continue
        if sys_key == 'khh':
            if prefix.startswith('R'):
                lines.add('紅線')
            elif prefix.startswith('O'):
                lines.add('橘線')
            elif prefix.startswith('C'):
                lines.add('輕軌')
        elif sys_key == 'ntp':
            if prefix.startswith('Y'):
                lines.add('環狀線')
            elif prefix.startswith('V'):
                lines.add('淡海輕軌')
            elif prefix.startswith('K'):
                lines.add('安坑輕軌')
        elif sys_key == 'tao':
            if prefix.startswith('A'):
                lines.add('機場線')
        else:
            # TRTC / tpe 路線
            LINE_MAP = {
                'BL': '板南線', 'R': '淡水信義線', 'G': '松山新店線',
                'O': '中和新蘆線', 'BR': '文湖線', 'Y': '環狀線',
            }
            for code, name in LINE_MAP.items():
                if prefix.startswith(code) and len(prefix) <= len(code) + 1:
                    lines.add(name)
                    break
    return sorted(lines)


# ========== TAIWAN_DISTRICTS(直接從 index.html line 2124-2191 貼入,Python dict) ==========
TAIWAN_DISTRICTS = {
  'taipei': {'label': '台北市', 'prefix': '台北', 'dists': {
    '中正': [25.0418, 121.5197], '大同': [25.0631, 121.5135], '中山': [25.0683, 121.5440],
    '松山': [25.0497, 121.5746], '大安': [25.0263, 121.5436], '萬華': [25.0345, 121.4994],
    '信義': [25.0330, 121.5654], '士林': [25.0945, 121.5215], '北投': [25.1322, 121.5018],
    '內湖': [25.0823, 121.5944], '南港': [25.0552, 121.6065], '文山': [25.0028, 121.5703],
  }},
  'newtaipei': {'label': '新北市', 'prefix': '新北', 'dists': {
    '板橋': [25.0143, 121.4670], '三重': [25.0617, 121.4848], '中和': [24.9999, 121.4978],
    '永和': [25.0073, 121.5145], '新莊': [25.0359, 121.4329], '新店': [24.9676, 121.5409],
    '樹林': [24.9942, 121.4209], '鶯歌': [24.9555, 121.3543], '三峽': [24.9347, 121.3681],
    '土城': [24.9722, 121.4448], '蘆洲': [25.0863, 121.4732], '五股': [25.0824, 121.4385],
    '泰山': [25.0593, 121.4321], '林口': [25.0775, 121.3914], '深坑': [25.0019, 121.6157],
    '石碇': [24.9914, 121.6413], '坪林': [24.9376, 121.7113], '烏來': [24.8651, 121.5510],
    '八里': [25.1463, 121.4015], '淡水': [25.1690, 121.4406], '三芝': [25.2570, 121.5008],
    '石門': [25.2900, 121.5681], '金山': [25.2225, 121.6360], '萬里': [25.1797, 121.6890],
    '汐止': [25.0625, 121.6443], '瑞芳': [25.1083, 121.8093], '平溪': [25.0271, 121.7383],
    '雙溪': [25.0367, 121.8651], '貢寮': [25.0212, 121.9093],
  }},
  'keelung': {'label': '基隆市', 'prefix': '基隆', 'dists': {
    '中正': [25.1383, 121.7704], '中山': [25.1297, 121.7370], '仁愛': [25.1284, 121.7430],
    '信義': [25.1290, 121.7521], '安樂': [25.1287, 121.7261], '暖暖': [25.0962, 121.7349],
    '七堵': [25.0951, 121.7129],
  }},
  'taoyuan': {'label': '桃園市', 'prefix': '桃園', 'dists': {
    '桃園': [24.9938, 121.3010], '中壢': [24.9536, 121.2247], '龜山': [25.0030, 121.3382],
    '八德': [24.9275, 121.2805], '大溪': [24.8835, 121.2864], '復興': [24.7470, 121.3530],
    '蘆竹': [25.0461, 121.2922], '平鎮': [24.9433, 121.2188], '楊梅': [24.9081, 121.1454],
    '龍潭': [24.8634, 121.2155], '新屋': [24.9764, 121.1063], '觀音': [25.0339, 121.0762],
    '大園': [25.0617, 121.1973],
  }},
  'hsinchu_city': {'label': '新竹市', 'prefix': '新竹', 'dists': {
    '東區': [24.8019, 120.9747], '北區': [24.8060, 120.9651], '香山': [24.7656, 120.9314],
  }},
  'hsinchu_county': {'label': '新竹縣', 'prefix': '新竹', 'dists': {
    '竹北': [24.8385, 121.0117], '湖口': [24.9027, 121.0463], '新豐': [24.8930, 121.0367],
    '新埔': [24.8297, 121.0747], '關西': [24.7866, 121.1771], '芎林': [24.7765, 121.0786],
    '寶山': [24.7649, 121.0408], '竹東': [24.7374, 121.0911], '五峰': [24.6968, 121.0959],
    '橫山': [24.7220, 121.1166], '尖石': [24.7050, 121.1959], '北埔': [24.6983, 121.0616],
    '峨眉': [24.6862, 121.0152],
  }},
  'miaoli': {'label': '苗栗縣', 'prefix': '苗栗', 'dists': {
    '苗栗市': [24.5600, 120.8222], '頭份': [24.6852, 120.9091], '竹南': [24.6841, 120.8730],
    '通霄': [24.4885, 120.6781], '苑裡': [24.4448, 120.6481], '銅鑼': [24.4938, 120.7868],
    '三義': [24.3499, 120.7426], '公館': [24.4979, 120.8211], '大湖': [24.4225, 120.8662],
    '卓蘭': [24.3088, 120.8231], '後龍': [24.6105, 120.7857], '造橋': [24.6442, 120.8495],
    '頭屋': [24.5754, 120.8466], '西湖': [24.4480, 120.7353], '三灣': [24.6499, 120.9375],
    '南庄': [24.5950, 120.9979], '獅潭': [24.5571, 120.9596], '泰安': [24.3899, 121.0440],
  }},
  'taichung': {'label': '台中市', 'prefix': '台中', 'dists': {
    '中區': [24.1437, 120.6790], '東區': [24.1414, 120.6920], '南區': [24.1227, 120.6669],
    '西區': [24.1437, 120.6628], '北區': [24.1604, 120.6839], '北屯': [24.1827, 120.7124],
    '西屯': [24.1820, 120.6347], '南屯': [24.1379, 120.6427], '太平': [24.1262, 120.7234],
    '大里': [24.0998, 120.6797], '霧峰': [24.0608, 120.7008], '烏日': [24.1052, 120.6249],
    '豐原': [24.2422, 120.7173], '后里': [24.3072, 120.7124], '石岡': [24.2624, 120.7796],
    '東勢': [24.2547, 120.8220], '和平': [24.2843, 121.0068], '新社': [24.2308, 120.8073],
    '潭子': [24.2022, 120.7058], '大雅': [24.2290, 120.6479], '神岡': [24.2536, 120.6604],
    '大肚': [24.1535, 120.5407], '沙鹿': [24.2349, 120.5571], '龍井': [24.1949, 120.5448],
    '梧棲': [24.2552, 120.5311], '清水': [24.2685, 120.5618], '大甲': [24.3478, 120.6262],
    '外埔': [24.3349, 120.6515], '大安': [24.3497, 120.5873],
  }},
  'changhua': {'label': '彰化縣', 'prefix': '彰化', 'dists': {
    '彰化市': [24.0820, 120.5414], '員林': [23.9588, 120.5740], '和美': [24.1086, 120.4998],
    '鹿港': [24.0570, 120.4348], '溪湖': [23.9628, 120.4783], '田尾': [23.8908, 120.5251],
    '芳苑': [23.9243, 120.3217], '北斗': [23.8716, 120.5238], '二林': [23.8995, 120.3737],
    '田中': [23.8612, 120.5808], '秀水': [24.0334, 120.5005], '花壇': [24.0339, 120.5358],
    '埔心': [23.9530, 120.5443], '永靖': [23.9239, 120.5462],
  }},
  'nantou': {'label': '南投縣', 'prefix': '南投', 'dists': {
    '南投市': [23.9098, 120.6826], '草屯': [23.9755, 120.6802], '埔里': [23.9667, 120.9655],
    '仁愛': [24.0249, 121.1330], '魚池': [23.8950, 120.9407], '國姓': [24.0407, 120.8654],
    '水里': [23.8113, 120.8552], '信義': [23.7062, 120.8523], '鹿谷': [23.7437, 120.7521],
    '竹山': [23.7559, 120.6748], '名間': [23.8453, 120.6904], '集集': [23.8290, 120.7833],
  }},
  'yunlin': {'label': '雲林縣', 'prefix': '雲林', 'dists': {
    '斗六': [23.7095, 120.5460], '斗南': [23.6789, 120.4830], '虎尾': [23.7068, 120.4310],
    '西螺': [23.7990, 120.4612], '土庫': [23.6772, 120.3938], '北港': [23.5749, 120.3026],
    '古坑': [23.6437, 120.5589], '林內': [23.7588, 120.6115], '莿桐': [23.7619, 120.4992],
  }},
  'chiayi_city': {'label': '嘉義市', 'prefix': '嘉義', 'dists': {
    '東區': [23.4807, 120.4517], '西區': [23.4852, 120.4392],
  }},
  'chiayi_county': {'label': '嘉義縣', 'prefix': '嘉義', 'dists': {
    '太保': [23.4582, 120.3325], '朴子': [23.4641, 120.2470], '布袋': [23.3789, 120.1670],
    '大林': [23.6035, 120.4708], '民雄': [23.5544, 120.4271], '六腳': [23.4970, 120.3149],
    '水上': [23.4474, 120.4036], '中埔': [23.4209, 120.5232], '竹崎': [23.5301, 120.5511],
    '梅山': [23.5851, 120.5557], '番路': [23.4641, 120.5717], '阿里山': [23.5101, 120.7977],
    '新港': [23.5511, 120.3478],
  }},
  'tainan': {'label': '台南市', 'prefix': '台南', 'dists': {
    '中西': [22.9925, 120.2049], '東區': [22.9826, 120.2273], '南區': [22.9560, 120.1954],
    '北區': [23.0034, 120.2059], '安平': [22.9919, 120.1751], '安南': [23.0469, 120.1846],
    '永康': [23.0263, 120.2526], '歸仁': [22.9663, 120.2939], '新化': [23.0376, 120.3119],
    '仁德': [22.9701, 120.2519], '關廟': [22.9608, 120.3248], '麻豆': [23.1810, 120.2483],
    '佳里': [23.1657, 120.1771], '新營': [23.3104, 120.3164], '白河': [23.3508, 120.4153],
    '善化': [23.1369, 120.2966], '新市': [23.0772, 120.2960], '七股': [23.1456, 120.1395],
    '北門': [23.2666, 120.1255], '左鎮': [23.0588, 120.4081], '學甲': [23.2326, 120.1818],
    '東山': [23.3223, 120.4035], '鹽水': [23.3197, 120.2664],
  }},
  'kaohsiung': {'label': '高雄市', 'prefix': '高雄', 'dists': {
    '苓雅': [22.6225, 120.3091], '前金': [22.6266, 120.2939], '新興': [22.6310, 120.3025],
    '前鎮': [22.5912, 120.3192], '三民': [22.6485, 120.3025], '左營': [22.6839, 120.2942],
    '鼓山': [22.6376, 120.2766], '旗津': [22.6126, 120.2832], '鹽埕': [22.6244, 120.2868],
    '楠梓': [22.7281, 120.3267], '小港': [22.5654, 120.3577], '鳳山': [22.6262, 120.3573],
    '鳥松': [22.6541, 120.3623], '大寮': [22.6053, 120.3954], '大樹': [22.6932, 120.4341],
    '仁武': [22.6964, 120.3473], '岡山': [22.7969, 120.2956], '橋頭': [22.7565, 120.3074],
    '路竹': [22.8568, 120.2614], '湖內': [22.9070, 120.2118], '旗山': [22.8870, 120.4831],
    '美濃': [22.8979, 120.5430], '六龜': [22.9941, 120.6307], '桃源': [23.1652, 120.7589],
    '燕巢': [22.7943, 120.3614], '茂林': [22.8909, 120.6630],
  }},
  'pingtung': {'label': '屏東縣', 'prefix': '屏東', 'dists': {
    '屏東市': [22.6717, 120.4880], '潮州': [22.5497, 120.5408], '東港': [22.4654, 120.4517],
    '恆春': [22.0027, 120.7459], '萬丹': [22.5868, 120.4866], '萬巒': [22.5732, 120.5660],
    '內埔': [22.6087, 120.5667], '枋寮': [22.3656, 120.5950], '車城': [22.0710, 120.7106],
    '里港': [22.7793, 120.4946], '長治': [22.6800, 120.5275], '三地門': [22.7173, 120.6515],
    '泰武': [22.5938, 120.6388], '牡丹': [22.1287, 120.7975], '獅子': [22.1989, 120.6661],
    '霧台': [22.7457, 120.7307],
  }},
  'yilan': {'label': '宜蘭縣', 'prefix': '宜蘭', 'dists': {
    '宜蘭市': [24.7574, 121.7536], '羅東': [24.6770, 121.7705], '頭城': [24.8590, 121.8232],
    '礁溪': [24.8265, 121.7715], '員山': [24.7448, 121.7180], '五結': [24.6875, 121.7980],
    '冬山': [24.6346, 121.7926], '三星': [24.6735, 121.6624], '蘇澳': [24.5946, 121.8520],
    '大同': [24.6692, 121.6044], '南澳': [24.4651, 121.7997], '壯圍': [24.7437, 121.7793],
  }},
  'hualien': {'label': '花蓮縣', 'prefix': '花蓮', 'dists': {
    '花蓮市': [23.9871, 121.6015], '新城': [24.0276, 121.6404], '秀林': [24.1593, 121.6293],
    '吉安': [23.9694, 121.5811], '壽豐': [23.8703, 121.5092], '鳳林': [23.7513, 121.4538],
    '光復': [23.6675, 121.4175], '瑞穗': [23.4974, 121.3771], '玉里': [23.3354, 121.3133],
  }},
  'taitung': {'label': '臺東縣', 'prefix': '台東', 'dists': {
    '台東市': [22.7583, 121.1444], '卑南': [22.7884, 121.0822], '鹿野': [22.9145, 121.1356],
    '關山': [23.0468, 121.1622], '池上': [23.1234, 121.2185], '成功': [23.0987, 121.3776],
    '東河': [22.9755, 121.3025], '太麻里': [22.6112, 120.9874], '長濱': [23.3104, 121.4520],
    '綠島': [22.6604, 121.4878], '蘭嶼': [22.0539, 121.5404],
  }},
  'penghu': {'label': '澎湖縣', 'prefix': '澎湖', 'dists': {
    '馬公': [23.5651, 119.5786], '湖西': [23.5901, 119.6537], '白沙': [23.6612, 119.5973],
    '西嶼': [23.5844, 119.5079], '望安': [23.3623, 119.5048], '七美': [23.2061, 119.4244],
  }},
  'kinmen': {'label': '金門縣', 'prefix': '金門', 'dists': {
    '金城': [24.4321, 118.3164], '金沙': [24.4906, 118.4151], '金湖': [24.4385, 118.4181],
    '金寧': [24.4470, 118.3403], '烈嶼': [24.4220, 118.2387],
  }},
  'lienchiang': {'label': '連江縣(馬祖)', 'prefix': '馬祖', 'dists': {
    '南竿': [26.1539, 119.9300], '北竿': [26.2233, 120.0149],
    '莒光': [25.9787, 119.9474], '東引': [26.3633, 120.4878],
  }},
}


def fetch_osm():
    """用 Python urllib 打 Overpass。
    注意:curl 不帶 Content-Type 時會被 406;urllib 也需明確設定。
    """
    data = urllib.parse.urlencode({'data': QUERY}).encode()
    req = urllib.request.Request(OVERPASS, data=data, method='POST')
    req.add_header('User-Agent', 'kids-weekend-mrt-scraper/1.0')
    req.add_header('Accept', '*/*')
    req.add_header('Content-Type', 'application/x-www-form-urlencoded')
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())


def haversine_km(la1, ln1, la2, ln2):
    R = 6371.0
    p1, p2 = math.radians(la1), math.radians(la2)
    dp = math.radians(la2 - la1)
    dl = math.radians(ln2 - ln1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def find_nearest_district(lat, lng):
    """回傳 (region_key, district_name) — 找最近的區中心"""
    best_region = None
    best_dist = None
    best_km = 9999.0
    for region, cfg in TAIWAN_DISTRICTS.items():
        for dist_name, coords in cfg['dists'].items():
            km = haversine_km(lat, lng, coords[0], coords[1])
            if km < best_km:
                best_km = km
                best_region = region
                best_dist = dist_name
    return best_region, best_dist


def main():
    ap = argparse.ArgumentParser(description='Scrape MRT stations from OSM Overpass')
    ap.add_argument('-o', '--output', required=True, help='Output JSON path')
    args = ap.parse_args()

    print('Fetching OSM Overpass...', file=sys.stderr)
    osm = fetch_osm()
    nodes = osm['elements']
    print(f'OSM returned {len(nodes)} nodes', file=sys.stderr)

    if len(nodes) < 200:
        print(f'ERROR: Only {len(nodes)} nodes returned — OSM coverage insufficient. BLOCKED.', file=sys.stderr)
        sys.exit(1)

    stations_by_key = {}  # (sys_key, name) → station dict (合轉乘站 lines)
    skipped = 0
    skipped_reasons = Counter()

    for n in nodes:
        tags = n.get('tags', {})

        # 取中文名(優先 name:zh,次 name)
        name = tags.get('name:zh') or tags.get('name')
        if not name:
            skipped += 1
            skipped_reasons['no_name'] += 1
            continue

        # 站名可能含「站」字 → strip(避免重複/不一致)
        name = name.rstrip('站')

        # 推 sys key:從 operator → network → network:zh
        operator_str = (
            tags.get('operator:zh') or tags.get('operator') or
            tags.get('network:zh') or tags.get('network') or ''
        )
        sk = map_sys(operator_str)
        if not sk:
            skipped += 1
            skipped_reasons[f'no_sys_match:{operator_str[:30]}'] += 1
            continue

        lat = n['lat']
        lng = n['lon']
        region, district = find_nearest_district(lat, lng)
        if not region:
            skipped += 1
            skipped_reasons['no_region'] += 1
            continue

        ref = tags.get('ref', '')
        key = (sk, name)

        if key in stations_by_key:
            # 轉乘站(同 sys 同 name 多次出現) → 合併 lines
            existing = stations_by_key[key]
            new_lines = set(existing['lines']) | set(extract_lines(sk, ref))
            existing['lines'] = sorted(new_lines)
            continue

        stations_by_key[key] = {
            'sys': sk,
            'name': name,
            'lines': extract_lines(sk, ref),
            'region': region,
            'district': district,
            'lat_osm': round(lat, 5),
            'lng_osm': round(lng, 5),
            'source': 'osm',
        }

    out = list(stations_by_key.values())

    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    print(f'Wrote {len(out)} stations (skipped {skipped})', file=sys.stderr)
    print(f'By sys: {dict(Counter(s["sys"] for s in out).most_common())}', file=sys.stderr)

    if skipped_reasons:
        print('Skip reasons (top 5):', file=sys.stderr)
        for reason, count in skipped_reasons.most_common(5):
            print(f'  {count:3d}  {reason}', file=sys.stderr)


if __name__ == '__main__':
    main()
