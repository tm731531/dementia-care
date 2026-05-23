"""Tests for scheduled_call: full call orchestration flow."""
from datetime import datetime
from unittest.mock import MagicMock, patch

import pytest


def test_place_call_uses_functions_url(monkeypatch):
    """place_call should hit Twilio Functions URL (not mini PC)."""
    monkeypatch.setenv("TWILIO_FUNCTIONS_BASE_URL", "https://test-deploy.twil.io")

    fake_calls = MagicMock()
    fake_calls.create.return_value = MagicMock(sid="CAtest")
    fake_client = MagicMock()
    fake_client.calls = fake_calls

    with patch("companion_call.scheduled_call.Client", return_value=fake_client):
        from companion_call.scheduled_call import place_call
        sid = place_call()

    assert sid == "CAtest"
    kwargs = fake_calls.create.call_args.kwargs
    assert kwargs["from_"] == "+15551234567"
    assert kwargs["to"] == "+886912345678"
    assert kwargs["url"] == "https://test-deploy.twil.io/voice"
    assert kwargs["timeout"] == 30
    # Should NOT use status_callback (we poll instead)
    assert "status_callback" not in kwargs


def test_wait_for_completion_returns_when_terminal():
    """Polling should stop when status reaches a terminal value."""
    from companion_call.scheduled_call import wait_for_completion

    statuses = iter(["in-progress", "in-progress", "completed"])

    def fake_fetch():
        return MagicMock(status=next(statuses), duration="65")

    fake_call_resource = MagicMock()
    fake_call_resource.fetch = fake_fetch
    fake_client = MagicMock()
    fake_client.calls.return_value = fake_call_resource

    with patch("time.sleep"):
        call = wait_for_completion("CAtest", max_wait_sec=60,
                                   poll_interval_sec=1, client=fake_client)
    assert call.status == "completed"


def test_wait_for_completion_returns_none_on_timeout():
    """If max_wait elapses without terminal status, return None."""
    from companion_call.scheduled_call import wait_for_completion

    fake_call_resource = MagicMock()
    fake_call_resource.fetch = lambda: MagicMock(status="in-progress")
    fake_client = MagicMock()
    fake_client.calls.return_value = fake_call_resource

    with patch("time.sleep"):
        # max_wait = 0.5s, poll every 1s → loop exits immediately
        call = wait_for_completion("CAtest", max_wait_sec=0,
                                   poll_interval_sec=1, client=fake_client)
    assert call is None


def test_build_log_line_completed_normal():
    from companion_call.scheduled_call import build_log_line
    call = MagicMock(status="completed", duration="67")
    when = datetime(2026, 5, 5, 15, 3)
    line = build_log_line(call, when=when)
    assert line == "[2026-05-05|15:03] 陪聊 67s"


def test_build_log_line_completed_short():
    from companion_call.scheduled_call import build_log_line
    call = MagicMock(status="completed", duration="3")
    when = datetime(2026, 5, 5, 9, 0)
    line = build_log_line(call, when=when)
    assert "陪聊 3s(短)" in line


def test_build_log_line_no_answer():
    from companion_call.scheduled_call import build_log_line
    call = MagicMock(status="no-answer", duration="0")
    when = datetime(2026, 5, 5, 10, 30)
    line = build_log_line(call, when=when)
    assert "陪聊未接" in line


def test_build_log_line_failed():
    from companion_call.scheduled_call import build_log_line
    call = MagicMock(status="failed", duration="0")
    when = datetime(2026, 5, 5, 11, 0)
    line = build_log_line(call, when=when)
    assert "陪聊失敗" in line


def test_build_log_line_timeout_when_call_none():
    from companion_call.scheduled_call import build_log_line
    when = datetime(2026, 5, 5, 16, 0)
    line = build_log_line(None, when=when)
    assert "timeout" in line


def test_log_to_idempiere_calls_upsert(monkeypatch):
    from companion_call import scheduled_call
    captured = []
    monkeypatch.setattr(
        scheduled_call, "upsert_zmomsystem_description",
        lambda d, line: captured.append((d, line)),
    )
    scheduled_call.log_to_idempiere("[2026-05-05|10:00] 陪聊 60s")
    assert len(captured) == 1
    assert captured[0][1] == "[2026-05-05|10:00] 陪聊 60s"


def test_log_to_idempiere_falls_back_to_local(monkeypatch, tmp_path):
    """If upsert raises, write to FAILED_LOG_PATH."""
    from companion_call import scheduled_call
    fallback = tmp_path / "failed_writes.log"
    monkeypatch.setattr(scheduled_call, "FAILED_LOG_PATH", fallback)

    def fake_upsert(d, line):
        raise RuntimeError("iDempiere down")
    monkeypatch.setattr(scheduled_call, "upsert_zmomsystem_description", fake_upsert)

    scheduled_call.log_to_idempiere("[2026-05-05|10:00] 陪聊 60s")
    assert fallback.exists()
    assert "陪聊 60s" in fallback.read_text()


def test_run_one_call_orchestrates_full_flow(monkeypatch):
    """run_one_call: place → wait → log."""
    from companion_call import scheduled_call

    monkeypatch.setattr(scheduled_call, "place_call", lambda: "CAtest")
    monkeypatch.setattr(
        scheduled_call,
        "wait_for_completion",
        lambda sid, **kw: MagicMock(status="completed", duration="80"),
    )
    captured = []
    monkeypatch.setattr(
        scheduled_call, "upsert_zmomsystem_description",
        lambda d, line: captured.append((d, line)),
    )

    scheduled_call.run_one_call()
    assert len(captured) == 1
    assert "陪聊 80s" in captured[0][1]
