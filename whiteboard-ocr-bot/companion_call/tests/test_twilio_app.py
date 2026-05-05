"""Test FastAPI TwiML server."""
from xml.etree import ElementTree as ET

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from companion_call.twilio_app import app
    return TestClient(app)


@pytest.fixture(autouse=True)
def reset_state():
    from companion_call.twilio_app import _state
    _state.clear()
    yield
    _state.clear()


def parse_twiml(text: str) -> ET.Element:
    return ET.fromstring(text)


def test_voice_endpoint_plays_opener(client):
    """First Twilio webhook returns TwiML with prompt_01 + redirect to /next."""
    r = client.post("/voice", data={"CallSid": "CAtest1"})
    assert r.status_code == 200
    twiml = parse_twiml(r.text)
    plays = twiml.findall("Play")
    assert len(plays) == 1
    assert "prompt_01.wav" in plays[0].text
    redirects = twiml.findall("Redirect")
    assert len(redirects) == 1
    assert "/next" in redirects[0].text


def test_voice_initializes_state(client):
    from companion_call.twilio_app import _state
    client.post("/voice", data={"CallSid": "CAtest1"})
    assert "CAtest1" in _state
    assert _state["CAtest1"]["played_count"] == 1
    assert _state["CAtest1"]["start_time"] > 0


def test_next_endpoint_plays_middle_prompt(client):
    """After opener, next prompt should be one of prompt_02..10 or 12."""
    client.post("/voice", data={"CallSid": "CAtest2"})
    r = client.post("/next", data={"CallSid": "CAtest2"})
    assert r.status_code == 200
    twiml = parse_twiml(r.text)
    plays = twiml.findall("Play")
    assert len(plays) == 1
    text = plays[0].text
    assert "prompt_01.wav" not in text   # not opener
    assert "prompt_11.wav" not in text   # not closer


def test_next_switches_to_closer_after_threshold(client):
    """After accumulated time ≥ END_TRIGGER_SEC, must play prompt_11 + Hangup."""
    from companion_call.twilio_app import _state
    client.post("/voice", data={"CallSid": "CAtest3"})
    # Force accumulated time over threshold
    _state["CAtest3"]["start_time"] -= 100   # 100s ago

    r = client.post("/next", data={"CallSid": "CAtest3"})
    twiml = parse_twiml(r.text)
    plays = twiml.findall("Play")
    assert len(plays) == 1
    assert "prompt_11.wav" in plays[0].text
    assert twiml.find("Hangup") is not None


def test_next_handles_unknown_call_sid(client):
    """If state doesn't exist (stale call), should close gracefully."""
    r = client.post("/next", data={"CallSid": "CAghost"})
    assert r.status_code == 200
    twiml = parse_twiml(r.text)
    # Should have a closer + hangup or just hangup
    assert twiml.find("Hangup") is not None


def test_call_ended_logs_to_idempiere(client, monkeypatch):
    """call-ended webhook should call upsert_zmomsystem_description."""
    from companion_call.twilio_app import _state
    captured = []

    def fake_upsert(d, line):
        captured.append((d, line))

    monkeypatch.setattr(
        "companion_call.twilio_app.upsert_zmomsystem_description", fake_upsert
    )

    _state["CAtestEnd"] = {"played_count": 5, "start_time": 1700000000.0}

    r = client.post("/call-ended", data={
        "CallSid": "CAtestEnd",
        "CallStatus": "completed",
        "CallDuration": "67",
    })
    assert r.status_code == 200
    assert len(captured) == 1
    line = captured[0][1]
    assert "陪聊" in line
    assert "67s" in line


def test_call_ended_short_call(client, monkeypatch):
    """Duration < 5s gets (短) suffix."""
    captured = []
    monkeypatch.setattr(
        "companion_call.twilio_app.upsert_zmomsystem_description",
        lambda d, line: captured.append((d, line)),
    )

    r = client.post("/call-ended", data={
        "CallSid": "CAshort",
        "CallStatus": "completed",
        "CallDuration": "3",
    })
    assert r.status_code == 200
    assert "(短)" in captured[0][1]


def test_call_ended_no_answer(client, monkeypatch):
    captured = []
    monkeypatch.setattr(
        "companion_call.twilio_app.upsert_zmomsystem_description",
        lambda d, line: captured.append((d, line)),
    )

    r = client.post("/call-ended", data={
        "CallSid": "CAnoans",
        "CallStatus": "no-answer",
        "CallDuration": "0",
    })
    assert r.status_code == 200
    assert "陪聊未接" in captured[0][1]


def test_call_ended_failure_logs_local_when_idempiere_breaks(
    client, monkeypatch, tmp_path
):
    """If iDempiere write throws, fallback to local log file."""
    def fake_upsert(d, line):
        raise RuntimeError("iDempiere down")

    monkeypatch.setattr(
        "companion_call.twilio_app.upsert_zmomsystem_description", fake_upsert
    )
    fallback_log = tmp_path / "failed_writes.log"
    monkeypatch.setattr(
        "companion_call.twilio_app.FAILED_LOG_PATH", fallback_log
    )

    r = client.post("/call-ended", data={
        "CallSid": "CAfail",
        "CallStatus": "completed",
        "CallDuration": "23",
    })
    assert r.status_code == 200
    assert fallback_log.exists()
    assert "陪聊 23s" in fallback_log.read_text()


def test_inbound_hangs_up(client):
    """If mom calls back the Twilio number, hang up immediately."""
    r = client.post("/inbound", data={"CallSid": "CAinbound"})
    twiml = parse_twiml(r.text)
    assert twiml.find("Hangup") is not None
