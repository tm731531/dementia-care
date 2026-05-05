"""Scheduler daemon — reads schedule.yaml each tick, fires Twilio call on hit.

systemd entry point. Runs forever, ticking every ~30 seconds.
schedule.yaml is hot-reloaded on each tick (no restart needed for changes).
"""
from __future__ import annotations

import logging
import os
import time
from datetime import datetime
from pathlib import Path
from typing import Callable, Optional
from zoneinfo import ZoneInfo

import yaml

logger = logging.getLogger(__name__)

WEEKDAY_NAMES = [
    "monday", "tuesday", "wednesday", "thursday",
    "friday", "saturday", "sunday",
]


def load_schedule(path: Path) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def is_slot_now(schedule: dict, now: datetime) -> bool:
    """Check if current minute is a scheduled call slot.

    Args:
        schedule: parsed schedule.yaml dict
        now: timezone-aware datetime (any tz, will convert to schedule tz)

    Rules:
    - exceptions[YYYY-MM-DD].skip=True → False regardless of weekly
    - exceptions[YYYY-MM-DD].override=[HH:MM,...] → match against override
    - else weekly[<day>] match
    """
    tz_name = schedule.get("defaults", {}).get("timezone", "Asia/Taipei")
    tz = ZoneInfo(tz_name)
    if now.tzinfo is None:
        # Defensive: assume naive datetime is in target tz
        now = now.replace(tzinfo=tz)
    local_now = now.astimezone(tz)
    hh_mm = local_now.strftime("%H:%M")
    date_str = local_now.strftime("%Y-%m-%d")
    weekday = WEEKDAY_NAMES[local_now.weekday()]

    exceptions = schedule.get("exceptions") or {}
    if date_str in exceptions:
        ex = exceptions[date_str]
        if ex.get("skip"):
            return False
        if "override" in ex:
            return hh_mm in ex["override"]

    weekly = schedule.get("weekly", {})
    return hh_mm in (weekly.get(weekday) or [])


class SchedulerLoop:
    def __init__(
        self,
        schedule_path: Path,
        place_call_fn: Optional[Callable[[], str]] = None,
    ):
        self.schedule_path = Path(schedule_path)
        if place_call_fn is None:
            from companion_call.scheduled_call import place_call
            place_call_fn = place_call
        self.place_call_fn = place_call_fn
        self._last_fired_minute: Optional[str] = None

    def tick(self) -> None:
        """One scheduler iteration. Called every ~30 seconds."""
        try:
            schedule = load_schedule(self.schedule_path)
        except Exception:
            logger.exception("Failed to load schedule, skipping tick")
            return

        tz_name = schedule.get("defaults", {}).get("timezone", "Asia/Taipei")
        tz = ZoneInfo(tz_name)
        local_now = datetime.now(tz=tz)
        minute_key = local_now.strftime("%Y-%m-%d %H:%M")

        if minute_key == self._last_fired_minute:
            return  # already fired this minute

        if is_slot_now(schedule, local_now):
            try:
                sid = self.place_call_fn()
                logger.info("Slot hit %s, placed call %s", minute_key, sid)
            except Exception:
                logger.exception("place_call failed at slot %s", minute_key)
            finally:
                self._last_fired_minute = minute_key

    def run_forever(self, sleep_sec: int = 30) -> None:
        logger.info("Scheduler loop started (sleep=%ds)", sleep_sec)
        while True:
            self.tick()
            time.sleep(sleep_sec)


def main():
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).resolve().parent / ".env")
    logging.basicConfig(
        level=os.getenv("LOG_LEVEL", "INFO"),
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    schedule_path = Path(__file__).resolve().parent / "schedule.yaml"
    loop = SchedulerLoop(schedule_path=schedule_path)
    loop.run_forever(sleep_sec=30)


if __name__ == "__main__":
    main()
