"""Telegram bot: receive whiteboard photos from Tom, run OCR, write to iDempiere.

Usage: ./venv/bin/python telegram_bot.py
Runs long-polling. Stop with Ctrl-C. Safe to restart.
"""
import os, sys, time, json, re, traceback
from pathlib import Path
from datetime import datetime
import requests

import config
BOT_TOKEN = config.TELEGRAM_BOT_TOKEN
ALLOWED_USER_IDS = set(config.ALLOWED_USER_IDS)

_HERE = Path(__file__).parent
INBOX = _HERE / "inbox"
INBOX.mkdir(parents=True, exist_ok=True)
OFFSET_FILE = _HERE / "telegram_offset.txt"
BASE = f"https://api.telegram.org/bot{BOT_TOKEN}"

def tg(method, **params):
    r = requests.post(f"{BASE}/{method}", json=params, timeout=40)
    r.raise_for_status()
    return r.json()

def get_file(file_id, dest):
    info = tg("getFile", file_id=file_id)
    fp = info["result"]["file_path"]
    url = f"https://api.telegram.org/file/bot{BOT_TOKEN}/{fp}"
    r = requests.get(url, timeout=60)
    r.raise_for_status()
    dest.write_bytes(r.content)
    return dest

def reply(chat_id, text, reply_to=None):
    params = {"chat_id": chat_id, "text": text, "parse_mode": "HTML"}
    if reply_to: params["reply_to_message_id"] = reply_to
    try:
        tg("sendMessage", **params)
    except Exception as e:
        print(f"reply fail: {e}")

def load_offset():
    if OFFSET_FILE.exists():
        return int(OFFSET_FILE.read_text().strip() or 0)
    return 0

def save_offset(v):
    OFFSET_FILE.write_text(str(v))

def process_photo(chat_id, user_id, message_id, file_id, caption=""):
    ts = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    dest = INBOX / f"{ts}_u{user_id}.jpg"
    try:
        get_file(file_id, dest)
    except Exception as e:
        reply(chat_id, f"❌ 下載失敗: {e}", reply_to=message_id)
        return
    reply(chat_id, f"📥 收到照片 <code>{dest.name}</code>\n🔍 OCR 中...", reply_to=message_id)
    try:
        from ocr_pipeline import process_image
        result = process_image(str(dest))
        reply(chat_id, result, reply_to=message_id)
    except Exception as e:
        traceback.print_exc()
        reply(chat_id, f"❌ OCR/寫入失敗: {type(e).__name__}: {str(e)[:200]}", reply_to=message_id)

def handle_update(upd):
    msg = upd.get("message") or upd.get("edited_message")
    if not msg: return
    from_user = msg.get("from", {})
    user_id = from_user.get("id")
    chat_id = msg["chat"]["id"]
    message_id = msg["message_id"]

    # Auth check
    if ALLOWED_USER_IDS and user_id not in ALLOWED_USER_IDS:
        reply(chat_id, f"⛔ 未授權使用者 ID={user_id}\n請在白名單中加入此 ID 後重試。")
        return

    # Handle photo
    photos = msg.get("photo")
    if photos:
        # Telegram sends multiple sizes, pick largest
        biggest = max(photos, key=lambda p: p.get("file_size", 0))
        process_photo(chat_id, user_id, message_id, biggest["file_id"],
                      caption=msg.get("caption", ""))
        return

    # Handle document (sometimes photos are sent as files)
    doc = msg.get("document")
    if doc and doc.get("mime_type", "").startswith("image/"):
        process_photo(chat_id, user_id, message_id, doc["file_id"],
                      caption=msg.get("caption", ""))
        return

    # Text commands
    text = msg.get("text", "").strip()
    if text == "/start":
        reply(chat_id, (
            f"👋 你好 (user_id=<code>{user_id}</code>)\n\n"
            f"📸 傳白板照片 → 自動 OCR 寫入 iDempiere\n"
            f"📝 傳文字（LINE 回報）→ 加到今天紀錄的 Description\n"
            f"   若今天還沒紀錄，會暫存等照片來時一起寫\n\n"
            f"指令：\n"
            f"/pending - 看待處理佇列\n"
            f"/clear - 清空待處理佇列\n"
            f"/id - 看你的 user id"
        ), reply_to=message_id)
    elif text == "/id":
        reply(chat_id, f"your user_id = <code>{user_id}</code>", reply_to=message_id)
    elif text == "/pending":
        from ocr_pipeline import pending_load
        items = pending_load()
        if not items:
            reply(chat_id, "📭 佇列空", reply_to=message_id)
        else:
            msg_txt = f"📥 待處理 {len(items)} 則:\n\n"
            msg_txt += "\n".join(f"{i+1}. <code>{it['line']}</code>" for i, it in enumerate(items))
            reply(chat_id, msg_txt, reply_to=message_id)
    elif text == "/clear":
        from ocr_pipeline import pending_save
        pending_save([])
        reply(chat_id, "🗑️ 佇列已清空", reply_to=message_id)
    elif text:
        # Non-command text = LINE caregiver report to append
        try:
            from ocr_pipeline import process_text
            result = process_text(text)
            reply(chat_id, result, reply_to=message_id)
        except Exception as e:
            traceback.print_exc()
            reply(chat_id, f"❌ 處理失敗: {type(e).__name__}: {str(e)[:200]}", reply_to=message_id)

def main():
    print(f"🤖 Bot starting, allowed users: {ALLOWED_USER_IDS or 'ANY (whitelist empty!)'}")
    offset = load_offset()
    while True:
        try:
            data = tg("getUpdates", offset=offset, timeout=30)
            for upd in data.get("result", []):
                offset = upd["update_id"] + 1
                handle_update(upd)
                save_offset(offset)
        except requests.exceptions.ReadTimeout:
            pass
        except Exception as e:
            print(f"loop err: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
