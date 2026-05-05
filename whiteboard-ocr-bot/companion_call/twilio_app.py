"""FastAPI TwiML server for companion_call.

Handles Twilio webhooks during a live call:
- /voice  : called when mom answers — play opener, redirect to /next
- /next   : called when mom finishes talking — pick next prompt or close
- /call-ended : status callback — log call outcome to Z_momSystem
- /inbound: if mom calls back the Twilio number — hang up politely
"""
from __future__ import annotations

import logging
import os
import random
import time
from datetime import datetime
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Form
from fastapi.responses import Response

from companion_call.shared import upsert_zmomsystem_description

logger = logging.getLogger(__name__)
app = FastAPI(title="companion_call TwiML server")

# In-memory call state: CallSid → {played_count, start_time, recent}
_state: dict[str, dict[str, Any]] = {}

OPENER = "prompt_01.wav"
CLOSER = "prompt_11.wav"
MIDDLE = [2, 3, 4, 5, 6, 7, 8, 9, 10, 12]   # prompt_02..10 + 12

# Local fallback log when iDempiere write fails (gitignored *.log catches it)
FAILED_LOG_PATH = Path(__file__).resolve().parent / "failed_writes.log"


def _audio_url(filename: str) -> str:
    base = os.environ["COMPANION_CALL_PUBLIC_URL"].rstrip("/")
    return f"{base}/audio/{filename}"


def _twiml_response(body: str) -> Response:
    xml = f'<?xml version="1.0" encoding="UTF-8"?><Response>{body}</Response>'
    return Response(content=xml, media_type="application/xml")


def _elapsed(call_sid: str) -> float:
    return time.time() - _state[call_sid]["start_time"]


@app.post("/voice")
async def voice(CallSid: str = Form(...)) -> Response:
    """Mom answers — play opener and start state."""
    _state[CallSid] = {
        "played_count": 1,
        "start_time": time.time(),
        "recent": set(),
    }
    body = f"<Play>{_audio_url(OPENER)}</Play>"
    body += '<Pause length="3"/>'
    body += "<Redirect>/next</Redirect>"
    return _twiml_response(body)


@app.post("/next")
async def next_prompt(CallSid: str = Form(...)) -> Response:
    """After mom finishes talking — play next prompt or close."""
    if CallSid not in _state:
        # Stale call sid — close gracefully
        body = f"<Play>{_audio_url(CLOSER)}</Play><Hangup/>"
        return _twiml_response(body)

    end_trigger = float(os.environ["COMPANION_CALL_END_TRIGGER_SEC"])
    if _elapsed(CallSid) >= end_trigger:
        body = f"<Play>{_audio_url(CLOSER)}</Play><Hangup/>"
        return _twiml_response(body)

    # Pick a middle prompt not in recent (best effort, falls back if all recent)
    state = _state[CallSid]
    candidates = [i for i in MIDDLE if i not in state["recent"]]
    if not candidates:
        candidates = list(MIDDLE)
    pick_idx = random.choice(candidates)
    pick = f"prompt_{pick_idx:02d}.wav"
    state["recent"].add(pick_idx)
    if len(state["recent"]) >= 3:
        # forget oldest by clearing — keep last unique
        state["recent"] = {pick_idx}
    state["played_count"] += 1

    body = f"<Play>{_audio_url(pick)}</Play>"
    body += '<Pause length="3"/>'
    body += "<Redirect>/next</Redirect>"
    return _twiml_response(body)


@app.post("/call-ended")
async def call_ended(
    CallSid: str = Form(...),
    CallStatus: str = Form(...),
    CallDuration: str = Form(default="0"),
) -> dict:
    """Twilio call-ended webhook → log to iDempiere or local fallback."""
    today = datetime.now().date()
    hh_mm = datetime.now().strftime("%H:%M")
    duration = int(CallDuration or 0)

    if CallStatus == "completed" and duration > 0:
        if duration < 5:
            line = f"[{today.isoformat()}|{hh_mm}] 陪聊 {duration}s(短)"
        else:
            line = f"[{today.isoformat()}|{hh_mm}] 陪聊 {duration}s"
    elif CallStatus in ("no-answer", "busy"):
        line = f"[{today.isoformat()}|{hh_mm}] 陪聊未接"
    elif CallStatus == "failed":
        line = f"[{today.isoformat()}|{hh_mm}] 陪聊失敗(twilio_failed)"
    else:
        line = f"[{today.isoformat()}|{hh_mm}] 陪聊 {CallStatus}"

    try:
        upsert_zmomsystem_description(today, line)
    except Exception as e:
        logger.exception("Failed to log to iDempiere: %s", e)
        FAILED_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(FAILED_LOG_PATH, "a") as f:
            f.write(f"{datetime.now().isoformat()}\t{line}\n")

    _state.pop(CallSid, None)
    return {"ok": True}


@app.post("/inbound")
async def inbound(CallSid: str = Form(...)) -> Response:
    """Mom (or anyone) called back the Twilio number — hang up politely."""
    body = '<Say language="zh-TW" voice="Polly.Hui">我先去忙，先這樣喔。</Say>'
    body += "<Hangup/>"
    return _twiml_response(body)
