"""OCR pipeline: phone photo → Gemini 2.5 Pro → iDempiere Z_momSystem write.

Entry point: process_image(path) → returns HTML-formatted summary for Telegram reply.
"""
import os, sys, re, json
from pathlib import Path
from datetime import datetime
from google import genai
from google.genai import types
import requests

from whiteboard_layout import WHITEBOARD_LAYOUT, WB_TO_IDEMPIERE
import config

# --- Config ---
GEMINI_KEY = config.GEMINI_API_KEY
GEMINI_MODEL = config.GEMINI_MODEL

IDEMPIERE_URL = config.IDEMPIERE_URL
IDEMPIERE_USER = config.IDEMPIERE_USER
IDEMPIERE_PASS = config.IDEMPIERE_PASS
IDEMPIERE_CLIENT = config.IDEMPIERE_CLIENT_ID
IDEMPIERE_ROLE = config.IDEMPIERE_ROLE_ID
TABLE = config.TARGET_TABLE

PENDING_NOTES_FILE = Path("/home/tom/tapo-caregiver/pending_notes.json")

def get_shift_tag(hour=None):
    """DAY (早班) / NIGHT (晚班) / GRAVEYARD (大夜)."""
    if hour is None:
        hour = datetime.now().hour
    if 7 <= hour < 18:
        return "DAY"        # 早班: 07:00 - 17:59
    elif 18 <= hour < 24:
        return "NIGHT"      # 晚班: 18:00 - 23:59
    else:
        return "GRAVEYARD"  # 大夜: 00:00 - 06:59

def format_note(text, ts=None):
    """Build a [SHIFT|HH:MM]content line."""
    if ts is None:
        ts = datetime.now()
    shift = get_shift_tag(ts.hour)
    return f"[{shift}|{ts.strftime('%H:%M')}]{text.strip()}"

def pending_load():
    if PENDING_NOTES_FILE.exists():
        try:
            return json.loads(PENDING_NOTES_FILE.read_text())
        except Exception:
            return []
    return []

def pending_save(items):
    PENDING_NOTES_FILE.write_text(json.dumps(items, ensure_ascii=False, indent=2))

def pending_add(line):
    items = pending_load()
    items.append({"line": line, "ts": datetime.now().isoformat()})
    pending_save(items)

def pending_drain():
    items = pending_load()
    pending_save([])
    return [it["line"] for it in items]

# Hard-coded facts (no OCR needed) — from config
PATIENT_NAME = config.PATIENT_NAME
BP_USER_ID = config.REPORTER_BPARTNER_ID

# --- OCR ---
_client = genai.Client(api_key=GEMINI_KEY)

def build_prompt():
    items_desc = []
    for key, boxes in WHITEBOARD_LAYOUT.items():
        box_spec = " | ".join(f"[{i+1}]{lbl}" for i, lbl in enumerate(boxes))
        items_desc.append(f"- {key}: {box_spec}")
    return f"""你是嚴謹的長照白板視覺分析工具。

# 白板結構
每個追蹤項目由兩行組成：
- 標題行：中文項目名
- 選項行：下方 3~4 個選項方格

# 白板 layout（權威，不要自己讀標籤）
{chr(10).join(items_desc)}

# 判斷順序（嚴格）
Step 1: 磁鐵跟標題文字**同一水平線**（即使靠近選項方格）→ box=null（待命）
Step 2: 磁鐵明顯壓在選項行的某個方格**內** → box=1/2/3/4
Step 3: 磁鐵在方格外、邊緣、看不到 → box=null

**寧缺勿錯**：任何不確定都回 null。醫療資料，漏 > 錯。

# 輸出（嚴格 JSON 無 markdown）
{{
  "items": {{
    "NightActivity": {{"box": 1|2|3|4|null, "confidence": "high|medium|low", "observation": "很短的描述"}},
    ... (12 項都要)
  }},
  "special_event": "底部特殊事件手寫文字" 或 null
}}"""

def run_ocr(image_path, model=None):
    if model is None: model = GEMINI_MODEL
    image_bytes = Path(image_path).read_bytes()
    resp = _client.models.generate_content(
        model=model,
        contents=[types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"), build_prompt()],
    )
    raw = resp.text
    cleaned = re.sub(r'^```(?:json)?\n?|\n?```$', '', raw.strip(), flags=re.MULTILINE)
    return json.loads(cleaned)

def map_to_idempiere(ocr_result):
    """Convert Gemini output → {iDempiere_field: id_value} + flags."""
    fields = {}
    issues = []
    per_item = {}
    for key, info in ocr_result.get("items", {}).items():
        box = info.get("box")
        conf = info.get("confidence", "low")
        obs = info.get("observation", "")
        layout = WHITEBOARD_LAYOUT.get(key, [])
        if box and isinstance(box, int) and 1 <= box <= len(layout):
            wb_label = layout[box - 1]
            idm_id = WB_TO_IDEMPIERE.get(key, {}).get(wb_label)
            if idm_id:
                per_item[key] = {"wb_label": wb_label, "idm_id": idm_id, "conf": conf, "obs": obs}
                # Only write HIGH confidence
                if conf == "high":
                    fields[key] = idm_id
                else:
                    issues.append(f"{key}={wb_label} (conf={conf})")
            else:
                issues.append(f"{key}={wb_label} (no mapping)")
                per_item[key] = {"wb_label": wb_label, "idm_id": None, "conf": conf, "obs": obs}
        else:
            per_item[key] = {"wb_label": None, "idm_id": None, "conf": conf, "obs": obs}
    return fields, issues, per_item

# --- iDempiere write ---
def idempiere_auth():
    r = requests.post(f"{IDEMPIERE_URL}/auth/tokens", json={
        "userName": IDEMPIERE_USER,
        "password": IDEMPIERE_PASS,
        "parameters": {
            "clientId": IDEMPIERE_CLIENT, "roleId": IDEMPIERE_ROLE,
            "organizationId": 0, "warehouseId": 0, "language": "zh_TW",
        }
    }, timeout=10)
    r.raise_for_status()
    return r.json()["token"]

def idempiere_get_description(token, record_id):
    """Fetch current Description field of a record."""
    r = requests.get(
        f"{IDEMPIERE_URL}/models/{TABLE}/{record_id}",
        headers={"Authorization": f"Bearer {token}"},
        params={"$select": "Description"},
        timeout=10,
    )
    if r.status_code >= 400:
        raise Exception(f"get desc {r.status_code}: {r.text[:200]}")
    return r.json().get("Description") or ""

def idempiere_prepend_notes(token, record_id, new_lines):
    """Prepend notes to Description (newest on top, \\n separated)."""
    existing = idempiere_get_description(token, record_id)
    merged = "\n".join(list(new_lines) + ([existing] if existing else []))
    r = requests.put(
        f"{IDEMPIERE_URL}/models/{TABLE}/{record_id}",
        headers={"Authorization": f"Bearer {token}"},
        json={"Description": merged},
        timeout=15,
    )
    if r.status_code >= 400:
        raise Exception(f"desc put {r.status_code}: {r.text[:200]}")
    return merged

def idempiere_find_today(token, date_str=None):
    """Return existing record id for today (patient=PATIENT_NAME), or None."""
    if date_str is None:
        date_str = datetime.now().strftime("%Y-%m-%d")
    # OData filter: DateDoc == today AND Name == PATIENT_NAME
    params = {
        "$filter": f"DateDoc eq '{date_str}' and Name eq '{PATIENT_NAME}'",
        "$top": 1,
    }
    r = requests.get(
        f"{IDEMPIERE_URL}/models/{TABLE}",
        headers={"Authorization": f"Bearer {token}"},
        params=params,
        timeout=10,
    )
    if r.status_code >= 400:
        raise Exception(f"find {r.status_code}: {r.text[:200]}")
    recs = r.json().get("records", [])
    return recs[0]["id"] if recs else None

def _build_field_payload(fields, include_base=False):
    """Payload for list-type/cleanable fields, not Description."""
    payload = {}
    if include_base:
        payload["Name"] = PATIENT_NAME
        payload["DateDoc"] = datetime.now().strftime("%Y-%m-%d")
        payload["C_BPartner_ID"] = {"id": BP_USER_ID}
    for col, id_val in fields.items():
        payload[col] = {"id": str(id_val)}
    return payload

def idempiere_create(token, fields, initial_description=None):
    payload = _build_field_payload(fields, include_base=True)
    if initial_description:
        payload["Description"] = initial_description
    r = requests.post(
        f"{IDEMPIERE_URL}/models/{TABLE}",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
        timeout=15,
    )
    if r.status_code >= 400:
        raise Exception(f"create {r.status_code}: {r.text[:300]}")
    return r.json()

def idempiere_update(token, record_id, fields):
    """PUT only the fields OCR actually read (nulls are skipped upstream)."""
    payload = _build_field_payload(fields, include_base=False)
    if not payload:
        return {"id": record_id, "updated": False}
    r = requests.put(
        f"{IDEMPIERE_URL}/models/{TABLE}/{record_id}",
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
        timeout=15,
    )
    if r.status_code >= 400:
        raise Exception(f"update {r.status_code}: {r.text[:300]}")
    return {"id": record_id, "updated": True}

def idempiere_attach_image(token, record_id, image_path):
    """Upload image as attachment. Unique filename via upload timestamp. 409 = already there, OK."""
    import base64
    orig = Path(image_path)
    # Inject current HH:MM:SS into filename to avoid 409 on retries
    ts = datetime.now().strftime("%H%M%S")
    fn = f"{orig.stem}_up{ts}{orig.suffix}"
    with open(image_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")
    url = f"{IDEMPIERE_URL}/models/{TABLE}/{record_id}/attachments"
    payload = {"name": fn, "data": b64}
    r = requests.post(
        url,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        json=payload,
        timeout=30,
    )
    if r.status_code == 409:
        return True  # duplicate filename — silently accept (shouldn't happen with HHMMSS suffix)
    if r.status_code >= 400:
        raise Exception(f"attach {r.status_code}: {r.text[:300]}")
    return True

# --- Reply formatting ---
def format_reply(per_item, issues, special_event, id_created=None, error=None, attached=False, mode=None, notes_added=0):
    lines = [f"📋 <b>{PATIENT_NAME}</b> — {datetime.now().strftime('%Y-%m-%d %H:%M')}"]
    written = 0
    skipped = 0
    for key, v in per_item.items():
        lbl = v["wb_label"]
        conf = v["conf"]
        if lbl is None:
            mark = "⏭️"
            display = "未填"
            skipped += 1
        elif v["idm_id"] and conf == "high":
            mark = "✅"
            display = lbl
            written += 1
        elif conf == "medium":
            mark = "🟡"
            display = lbl + " (待確認)"
            skipped += 1
        else:
            mark = "🔴"
            display = lbl + " (低信心)"
            skipped += 1
        short = {"NightActivity":"夜間活動","BeforeSleepStatus":"睡前","LastNightSleep":"昨夜睡眠",
                 "MorningMentalStatus":"起床精神","Breakfast":"早餐","Lunch":"午餐","Dinner":"晚餐",
                 "DailyActivity":"活動","outgoing":"外出","Companionship":"陪伴",
                 "ExcretionStatus":"排泄","Bathing":"洗澡"}[key]
        lines.append(f"{mark} {short}: <b>{display}</b>")
    if special_event:
        lines.append(f"📝 特殊事件: {special_event}")
    lines.append("")
    lines.append(f"✅ 已寫入 {written} 項 / ⚪ 略過 {skipped} 項")
    if id_created:
        mode_label = {"created": "🆕 新建", "updated": "🔄 更新", "dry_run": "🧪 DRY"}.get(mode, "")
        lines.append(f"{mode_label} iDempiere id = <code>{id_created}</code>")
    if attached:
        lines.append(f"📎 照片已附加")
    if notes_added:
        lines.append(f"📝 寫入 {notes_added} 則備註（待處理佇列 + 特殊事件）")
    if issues:
        lines.append(f"⚠️ 需複核: {len(issues)}")
    if error:
        lines.append(f"❌ 錯誤: {error}")
    return "\n".join(lines)

# --- Main entry ---
DRY_RUN = os.environ.get("DRY_RUN", "0") == "1"

def process_image(image_path):
    ocr = run_ocr(image_path)
    fields, issues, per_item = map_to_idempiere(ocr)
    special = ocr.get("special_event")
    id_created = None
    error = None
    attached = False
    mode = None
    notes_added = 0
    if DRY_RUN:
        id_created = "DRY_RUN"
        mode = "dry_run"
    else:
        try:
            token = idempiere_auth()
            # Drain any queued LINE notes + add special_event from OCR as a note
            new_notes = pending_drain()
            if special:
                new_notes.append(format_note(special))
            notes_added = len(new_notes)

            existing_id = idempiere_find_today(token)
            if existing_id:
                idempiere_update(token, existing_id, fields)
                if new_notes:
                    idempiere_prepend_notes(token, existing_id, new_notes)
                id_created = existing_id
                mode = "updated"
            else:
                initial_desc = "\n".join(new_notes) if new_notes else None
                created = idempiere_create(token, fields, initial_description=initial_desc)
                id_created = created.get("id")
                mode = "created"
            # Always attach the new photo
            if id_created:
                try:
                    idempiere_attach_image(token, id_created, image_path)
                    attached = True
                except Exception as att_err:
                    error = f"image attach failed: {str(att_err)[:120]}"
        except Exception as e:
            error = f"{type(e).__name__}: {str(e)[:150]}"
    return format_reply(per_item, issues, special, id_created, error, attached, mode, notes_added)

# --- Text-only entry point (for LINE reports sent as Telegram text) ---
def process_text(text):
    """Append a LINE caregiver note. If today's record exists, prepend to Description.
    If not, queue to pending_notes."""
    note_line = format_note(text)
    try:
        token = idempiere_auth()
        rec_id = idempiere_find_today(token)
        if rec_id:
            merged = idempiere_prepend_notes(token, rec_id, [note_line])
            return (f"✅ 已附加到 id=<code>{rec_id}</code>\n\n"
                    f"<code>{note_line}</code>")
        else:
            pending_add(note_line)
            count = len(pending_load())
            return (f"📝 今天還沒有紀錄，已排入待處理佇列（共 {count} 則）\n\n"
                    f"<code>{note_line}</code>\n\n"
                    f"等照片來時會一併寫入。")
    except Exception as e:
        # On failure, still save to pending so it's not lost
        pending_add(note_line)
        return f"⚠️ iDempiere 連線失敗但已暫存：\n<code>{note_line}</code>\n\n{type(e).__name__}: {str(e)[:120]}"

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/tapo/wb_phone3.jpg"
    print(process_image(path))
