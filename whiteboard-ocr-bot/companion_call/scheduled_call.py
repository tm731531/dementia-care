"""Outbound caller — entry point triggered by scheduler or manual run.

Run manually for self-test:
    python -m companion_call.scheduled_call
"""
from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from twilio.rest import Client

# Load .env when run as script (no-op if already in env)
load_dotenv(Path(__file__).resolve().parent / ".env")

logger = logging.getLogger(__name__)


def place_call() -> str:
    """Trigger one outbound call. Returns Twilio Call SID.

    Raises: twilio.base.exceptions.TwilioRestException on failure
    """
    sid = os.environ["TWILIO_ACCOUNT_SID"]
    token = os.environ["TWILIO_AUTH_TOKEN"]
    from_number = os.environ["TWILIO_FROM_NUMBER"]
    to_number = os.environ["MOM_PHONE_NUMBER"]
    public_url = os.environ["COMPANION_CALL_PUBLIC_URL"].rstrip("/")

    client = Client(sid, token)
    call = client.calls.create(
        from_=from_number,
        to=to_number,
        url=f"{public_url}/voice",
        status_callback=f"{public_url}/call-ended",
        status_callback_method="POST",
        status_callback_event=["completed", "no-answer", "failed", "busy"],
        timeout=30,
    )
    logger.info("Placed call %s to %s", call.sid, to_number)
    return call.sid


def main():
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    try:
        sid = place_call()
        print(f"Call placed: {sid}", file=sys.stderr)
    except Exception:
        logger.exception("Call failed")
        sys.exit(1)


if __name__ == "__main__":
    main()
