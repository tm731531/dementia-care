"""Test shared iDempiere helpers."""
from datetime import date
from unittest.mock import patch

from companion_call.shared import (
    get_idempiere_token,
    upsert_zmomsystem_description,
)


class _FakeResponse:
    def __init__(self, status_code=200, payload=None):
        self.status_code = status_code
        self._payload = payload or {}
        self.text = str(payload)

    def json(self):
        return self._payload

    def raise_for_status(self):
        if self.status_code >= 400:
            raise RuntimeError(f"HTTP {self.status_code}")


def test_get_token_caches(monkeypatch):
    """Calling get_token twice should only POST /auth/tokens once."""
    call_count = {"n": 0}

    def fake_post(url, json=None, **kw):
        call_count["n"] += 1
        return _FakeResponse(payload={"token": "fake_jwt", "language": "zh_TW"})

    monkeypatch.setattr("companion_call.shared.requests.post", fake_post)

    t1 = get_idempiere_token()
    t2 = get_idempiere_token()

    assert t1 == t2 == "fake_jwt"
    assert call_count["n"] == 1


def test_upsert_prepends_to_existing_description(monkeypatch):
    """Same-day call should PUT existing record with new line on TOP (matching OCR convention)."""
    requests_log = []

    def fake_get(url, headers=None, params=None, **kw):
        requests_log.append(("GET", url, params))
        if "/123" in url:
            # Single record fetch
            return _FakeResponse(payload={
                "id": 123,
                "Description": "[2026-05-05|09:01] 陪聊 67s",
            })
        # Filter list
        return _FakeResponse(payload={
            "records": [{"id": 123, "Name": "TEST_PATIENT"}],
        })

    def fake_put(url, json=None, headers=None, **kw):
        requests_log.append(("PUT", url, json))
        return _FakeResponse(payload={"id": 123})

    monkeypatch.setattr("companion_call.shared.requests.get", fake_get)
    monkeypatch.setattr("companion_call.shared.requests.put", fake_put)
    monkeypatch.setattr(
        "companion_call.shared.get_idempiere_token", lambda: "fake_jwt"
    )

    upsert_zmomsystem_description(
        date(2026, 5, 5), "[2026-05-05|10:01] 陪聊 88s"
    )

    puts = [r for r in requests_log if r[0] == "PUT"]
    assert len(puts) == 1
    body = puts[0][2]
    desc = body["Description"]
    # Newest on top (OCR convention)
    lines = desc.split("\n")
    assert lines[0] == "[2026-05-05|10:01] 陪聊 88s"
    assert lines[1] == "[2026-05-05|09:01] 陪聊 67s"


def test_upsert_creates_when_no_record(monkeypatch):
    """No existing record → POST a new one with full base fields."""
    requests_log = []

    def fake_get(url, headers=None, params=None, **kw):
        requests_log.append(("GET", url))
        return _FakeResponse(payload={"records": []})

    def fake_post(url, json=None, headers=None, **kw):
        requests_log.append(("POST", url, json))
        return _FakeResponse(status_code=201, payload={"id": 999})

    monkeypatch.setattr("companion_call.shared.requests.get", fake_get)
    monkeypatch.setattr("companion_call.shared.requests.post", fake_post)
    monkeypatch.setattr(
        "companion_call.shared.get_idempiere_token", lambda: "fake_jwt"
    )

    upsert_zmomsystem_description(
        date(2026, 5, 5), "[2026-05-05|09:01] 陪聊 67s"
    )

    posts = [r for r in requests_log if r[0] == "POST"]
    assert len(posts) == 1
    body = posts[0][2]
    assert body["Description"] == "[2026-05-05|09:01] 陪聊 67s"
    assert body["Name"] == "TEST_PATIENT"
    assert body["DateDoc"] == "2026-05-05"
    assert body["C_BPartner_ID"] == {"id": 1000000}


def test_upsert_handles_empty_description(monkeypatch):
    """Existing record with no Description → just write the new line."""
    requests_log = []

    def fake_get(url, headers=None, params=None, **kw):
        if "/456" in url:
            return _FakeResponse(payload={"id": 456, "Description": None})
        return _FakeResponse(payload={"records": [{"id": 456}]})

    def fake_put(url, json=None, headers=None, **kw):
        requests_log.append(("PUT", url, json))
        return _FakeResponse(payload={"id": 456})

    monkeypatch.setattr("companion_call.shared.requests.get", fake_get)
    monkeypatch.setattr("companion_call.shared.requests.put", fake_put)
    monkeypatch.setattr(
        "companion_call.shared.get_idempiere_token", lambda: "fake_jwt"
    )

    upsert_zmomsystem_description(date(2026, 5, 5), "[2026-05-05|09:01] 陪聊 67s")

    puts = [r for r in requests_log if r[0] == "PUT"]
    assert puts[0][2]["Description"] == "[2026-05-05|09:01] 陪聊 67s"
