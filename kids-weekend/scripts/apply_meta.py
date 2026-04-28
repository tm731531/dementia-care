"""把 /tmp/scrape_meta.json 的 hours + website 寫入 index.html PLACES
- 每筆物件加 hours:{mon:'09:00-17:00',...} + website:'...'
- 跳過空的(ambig 景點抓不到)
"""
import json, re

PATH = '/home/tom/Desktop/dementia-care/kids-weekend/index.html'

with open('/tmp/scrape_meta.json') as f:
    meta = json.load(f)
with open(PATH) as f:
    content = f.read()

added_hours = 0
added_web = 0
def serialize_hours(h):
    if not h: return ''
    parts = [f"{k}:'{v}'" for k, v in h.items()]
    return '{' + ','.join(parts) + '}'

PLACE_LINE_RE = re.compile(r"(\{id:'([^']+)',[^}]*?), crowd:'([^']+)'(\})")

def upgrade(m):
    global added_hours, added_web
    pid = m.group(2)
    extras = []
    if pid in meta:
        d = meta[pid]
        # 跳過已有 hours/website 的(避免重複)
        if d.get('hours') and 'hours:{' not in m.group(0):
            extras.append(f"hours:{serialize_hours(d['hours'])}")
            added_hours += 1
        if d.get('website') and 'website:' not in m.group(0):
            # escape ' and \
            url = d['website'].replace("'", "\\'").replace('\\', '\\\\')
            extras.append(f"website:'{url}'")
            added_web += 1
    if not extras:
        return m.group(0)
    return m.group(1) + ', crowd:\'' + m.group(3) + "', " + ', '.join(extras) + m.group(4)

new_content = PLACE_LINE_RE.sub(upgrade, content)
with open(PATH, 'w') as f:
    f.write(new_content)

print(f'✓ 加 hours 到 {added_hours} 筆')
print(f'✓ 加 website 到 {added_web} 筆')
