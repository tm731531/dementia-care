"""把 /tmp/mrt_stations_geocoded.json inline 進 index.html

在 TAIWAN_DISTRICTS const 結束後插入 MRT_SYS_LABEL + MRT_STATIONS。
若 index.html 已有 MRT_STATIONS block,先 strip 舊的再寫新的(re-run safe)。
"""
import json, re

PATH = '/home/tom/Desktop/dementia-care/kids-weekend/index.html'
SRC = '/tmp/mrt_stations_geocoded.json'

SYS_LABEL = {
    'tpe': '台北捷運', 'khh': '高雄捷運',
    'tao': '桃園捷運', 'tch': '台中捷運', 'ntp': '新北捷運',
}


def fmt_station(s):
    name_safe = s['name'].replace("'", "\\'")
    district_safe = s['district'].replace("'", "\\'")
    lines_js = '[' + ','.join(f"'{l}'" for l in s['lines']) + ']'
    return (
        f"{{sys:'{s['sys']}',name:'{name_safe}',lines:{lines_js},"
        f"lat:{s['lat']},lng:{s['lng']},region:'{s['region']}',"
        f"district:'{district_safe}',last_verified:'{s['last_verified']}'}}"
    )


def main():
    data = [d for d in json.load(open(SRC)) if d.get('lat')]
    print(f"Applying {len(data)} stations")

    sys_label_js = 'const MRT_SYS_LABEL = {' + \
        ','.join(f"{k}:'{v}'" for k, v in SYS_LABEL.items()) + '};'
    stations_js = 'const MRT_STATIONS = [\n  ' + \
        ',\n  '.join(fmt_station(s) for s in data) + '\n];'

    block = (
        "\n// ========== 捷運站(5 系統 ~260 站,Playwright + bbox 校正)==========\n"
        + sys_label_js + '\n' + stations_js + '\n'
    )

    with open(PATH) as f:
        content = f.read()

    # Strip old block if present (re-run safe)
    content = re.sub(
        r'\n// ========== 捷運站.*?\nconst MRT_STATIONS = \[.*?\];\n',
        '',
        content, flags=re.DOTALL,
    )

    # Insert after TAIWAN_DISTRICTS closing `};`
    # Anchor: lienchiang block is the last entry in TAIWAN_DISTRICTS
    marker = "lienchiang: {label:'連江縣(馬祖)'"
    idx = content.find(marker)
    if idx < 0:
        raise SystemExit('TAIWAN_DISTRICTS marker not found')
    # Find first `\n};\n` after the marker (TAIWAN_DISTRICTS closing)
    end = content.find('\n};\n', idx)
    if end < 0:
        raise SystemExit('TAIWAN_DISTRICTS closing not found')
    insert_at = end + len('\n};\n')

    new_content = content[:insert_at] + block + content[insert_at:]
    with open(PATH, 'w') as f:
        f.write(new_content)
    print(f"Inserted at offset {insert_at}, new size: {len(new_content)} bytes")


if __name__ == '__main__':
    main()
