"""End-to-end call orchestration: place → wait → fetch → log to iDempiere.

Replaces the FastAPI webhook architecture: instead of receiving a status_callback
from Twilio, mini PC polls Twilio API for call completion. No public endpoint
needed on mini PC.

Run manually (Phase 1 self-test):
    python -m companion_call.scheduled_call
"""
from __future__ import annotations

import logging
import os
import sys
import time
from datetime import date, datetime
from pathlib import Path

from dotenv import load_dotenv
from twilio.rest import Client

from companion_call.shared import upsert_zmomsystem_description

load_dotenv(Path(__file__).resolve().parent / ".env")

logger = logging.getLogger(__name__)

TERMINAL_STATUSES = {"completed", "busy", "failed", "no-answer", "canceled"}

# Local fallback log when iDempiere write fails
FAILED_LOG_PATH = Path(__file__).resolve().parent / "failed_writes.log"


def place_call() -> str:
    """Place an outbound call to MOM_PHONE_NUMBER. Returns Twilio Call SID.

    Twilio fetches TwiML from `<TWILIO_FUNCTIONS_BASE_URL>/voice` when answered.
    """
    sid = os.environ["TWILIO_ACCOUNT_SID"]
    token = os.environ["TWILIO_AUTH_TOKEN"]
    from_number = os.environ["TWILIO_FROM_NUMBER"]
    to_number = os.environ["MOM_PHONE_NUMBER"]
    base_url = os.environ["TWILIO_FUNCTIONS_BASE_URL"].rstrip("/")

    client = Client(sid, token)
    call = client.calls.create(
        from_=from_number,
        to=to_number,
        url=f"{base_url}/voice",
        timeout=30,   # ring timeout
    )
    logger.info("Placed call %s to %s", call.sid, to_number)
    return call.sid


def wait_for_completion(call_sid: str, max_wait_sec: int = 150,
                        poll_interval_sec: int = 15,
                        client: Client | None = None):
    """Poll Twilio for call completion. Returns the final Call object.

    Returns None if max_wait_sec exceeded without reaching terminal state.
    """
    if client is None:
        client = Client(
            os.environ["TWILIO_ACCOUNT_SID"],
            os.environ["TWILIO_AUTH_TOKEN"],
        )

    deadline = time.time() + max_wait_sec
    while time.time() < deadline:
        time.sleep(poll_interval_sec)
        call = client.calls(call_sid).fetch()
        if call.status in TERMINAL_STATUSES:
            logger.info(
                "Call %s reached terminal status %s, duration=%s",
                call_sid, call.status, call.duration,
            )
            return call

    logger.warning("Call %s did not reach terminal status within %ds",
                   call_sid, max_wait_sec)
    return None


def build_log_line(call, when: datetime | None = None) -> str:
    """Build Description line based on call status + duration."""
    when = when or datetime.now()
    today_str = when.strftime("%Y-%m-%d")
    hh_mm = when.strftime("%H:%M")

    if call is None:
        return f"[{today_str}|{hh_mm}] 陪聊失敗(timeout)"

    status = call.status
    duration = int(call.duration or 0)

    if status == "completed" and duration > 0:
        if duration < 5:
            return f"[{today_str}|{hh_mm}] 陪聊 {duration}s(短)"
        return f"[{today_str}|{hh_mm}] 陪聊 {duration}s"
    if status in ("no-answer", "busy"):
        return f"[{today_str}|{hh_mm}] 陪聊未接"
    if status == "failed":
        return f"[{today_str}|{hh_mm}] 陪聊失敗(twilio_failed)"
    if status == "canceled":
        return f"[{today_str}|{hh_mm}] 陪聊取消"
    return f"[{today_str}|{hh_mm}] 陪聊 {status}"


def log_to_idempiere(line: str, target_date: date | None = None) -> None:
    """Write a line to today's Z_momSystem.Description with local fallback."""
    target_date = target_date or datetime.now().date()
    try:
        upsert_zmomsystem_description(target_date, line)
    except Exception as e:
        logger.exception("iDempiere write failed: %s", e)
        FAILED_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(FAILED_LOG_PATH, "a") as f:
            f.write(f"{datetime.now().isoformat()}\t{line}\n")


def run_one_call() -> None:
    """Full single-call flow: place → wait → fetch → log."""
    sid = place_call()
    call = wait_for_completion(sid)
    line = build_log_line(call)
    log_to_idempiere(line)
    logger.info("Logged: %s", line)


def main():
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    try:
        run_one_call()
    except Exception:
        logger.exception("run_one_call failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
