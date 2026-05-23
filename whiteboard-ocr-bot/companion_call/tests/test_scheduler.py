"""Test scheduler logic."""
from datetime import datetime
from zoneinfo import ZoneInfo

import yaml
from freezegun import freeze_time


SAMPLE_YAML = {
    "weekly": {
        "tuesday": ["09:00", "10:00"],
        "thursday": ["15:00"],
        "monday": [],
        "wednesday": [],
        "friday": [],
        "saturday": [],
        "sunday": [],
    },
    "exceptions": {
        "2026-05-12": {"skip": True},
        "2026-05-15": {"override": ["10:00", "14:00"]},
    },
    "defaults": {"timezone": "Asia/Taipei"},
}


def test_load_schedule_reads_yaml(tmp_path):
    from companion_call.companion_scheduler import load_schedule

    f = tmp_path / "s.yaml"
    f.write_text(yaml.safe_dump(SAMPLE_YAML))
    s = load_schedule(f)
    assert s["weekly"]["tuesday"] == ["09:00", "10:00"]


@freeze_time("2026-05-05 01:00:30")   # UTC = Tue 09:00:30 Taipei
def test_is_slot_now_hits_tuesday():
    from companion_call.companion_scheduler import is_slot_now
    now = datetime.now(tz=ZoneInfo("UTC"))
    assert is_slot_now(SAMPLE_YAML, now) is True


@freeze_time("2026-05-05 01:30:30")   # UTC = Tue 09:30:30 Taipei (no slot)
def test_is_slot_now_misses_when_no_match():
    from companion_call.companion_scheduler import is_slot_now
    now = datetime.now(tz=ZoneInfo("UTC"))
    assert is_slot_now(SAMPLE_YAML, now) is False


@freeze_time("2026-05-12 01:00:30")   # UTC = Tue 09:00 Taipei but skip exception
def test_is_slot_now_respects_skip_exception():
    from companion_call.companion_scheduler import is_slot_now
    now = datetime.now(tz=ZoneInfo("UTC"))
    assert is_slot_now(SAMPLE_YAML, now) is False


@freeze_time("2026-05-15 02:00:30")   # UTC = Fri 10:00 Taipei (no weekly) but override
def test_is_slot_now_respects_override_exception():
    from companion_call.companion_scheduler import is_slot_now
    now = datetime.now(tz=ZoneInfo("UTC"))
    assert is_slot_now(SAMPLE_YAML, now) is True


@freeze_time("2026-05-15 01:00:30")   # UTC = Fri 09:00 Taipei (override only 10/14)
def test_is_slot_now_override_only_at_listed_times():
    from companion_call.companion_scheduler import is_slot_now
    now = datetime.now(tz=ZoneInfo("UTC"))
    assert is_slot_now(SAMPLE_YAML, now) is False


def test_scheduler_triggers_place_call_once_per_minute(tmp_path):
    """Same minute shouldn't fire twice."""
    from companion_call.companion_scheduler import SchedulerLoop

    f = tmp_path / "s.yaml"
    f.write_text(yaml.safe_dump(SAMPLE_YAML))
    triggers = []

    def fake_place_call():
        triggers.append(datetime.now())
        return "CAxxx"

    loop = SchedulerLoop(schedule_path=f, place_call_fn=fake_place_call)

    with freeze_time("2026-05-05 01:00:10"):   # UTC = Tue 09:00 Taipei
        loop.tick()
    with freeze_time("2026-05-05 01:00:50"):   # same minute
        loop.tick()
    with freeze_time("2026-05-05 01:01:10"):   # 09:01 Taipei (no slot)
        loop.tick()

    assert len(triggers) == 1


def test_scheduler_reloads_yaml_each_tick(tmp_path):
    """Editing yaml mid-run is picked up next tick."""
    from companion_call.companion_scheduler import SchedulerLoop

    f = tmp_path / "s.yaml"
    f.write_text(yaml.safe_dump({
        "weekly": {"tuesday": ["09:00"], "monday": [], "wednesday": [],
                    "thursday": [], "friday": [], "saturday": [], "sunday": []},
        "exceptions": {},
        "defaults": {"timezone": "Asia/Taipei"},
    }))
    triggers = []
    loop = SchedulerLoop(
        schedule_path=f,
        place_call_fn=lambda: (triggers.append(1), "CA")[1],
    )

    # First tick at 10:00 Taipei = 02:00 UTC — no slot
    with freeze_time("2026-05-05 02:00:10"):
        loop.tick()
    assert triggers == []

    # Edit yaml to add 10:00
    f.write_text(yaml.safe_dump({
        "weekly": {"tuesday": ["09:00", "10:00"], "monday": [], "wednesday": [],
                    "thursday": [], "friday": [], "saturday": [], "sunday": []},
        "exceptions": {},
        "defaults": {"timezone": "Asia/Taipei"},
    }))

    with freeze_time("2026-05-05 02:00:50"):   # same minute (10:00 Taipei)
        loop.tick()
    assert len(triggers) == 1
