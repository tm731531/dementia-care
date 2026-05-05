"""Shared pytest fixtures for companion_call tests."""
from pathlib import Path

import pytest

BASE_DIR = Path(__file__).resolve().parent.parent


@pytest.fixture(autouse=True)
def fake_env(monkeypatch):
    """每個測試自動套假 env vars，避免讀到真值。"""
    monkeypatch.setenv("TWILIO_ACCOUNT_SID", "ACtest_sid")
    monkeypatch.setenv("TWILIO_AUTH_TOKEN", "test_token")
    monkeypatch.setenv("TWILIO_FROM_NUMBER", "+15551234567")
    monkeypatch.setenv("MOM_PHONE_NUMBER", "+886912345678")
    monkeypatch.setenv("TWILIO_FUNCTIONS_BASE_URL", "https://test-deploy.twil.io")
    monkeypatch.setenv("IDEMPIERE_URL", "http://test.example/api/v1")
    monkeypatch.setenv("IDEMPIERE_USER", "test")
    monkeypatch.setenv("IDEMPIERE_PASS", "test")
    monkeypatch.setenv("IDEMPIERE_CLIENT_ID", "1000000")
    monkeypatch.setenv("IDEMPIERE_ROLE_ID", "1000000")
    monkeypatch.setenv("IDEMPIERE_ORG_ID", "0")
    monkeypatch.setenv("IDEMPIERE_WAREHOUSE_ID", "0")
    monkeypatch.setenv("PATIENT_NAME", "TEST_PATIENT")
    monkeypatch.setenv("REPORTER_BPARTNER_ID", "1000000")
    monkeypatch.setenv("TARGET_TABLE", "z_momsystem")
    monkeypatch.setenv("COMPANION_CALL_DURATION_SEC", "90")
    monkeypatch.setenv("COMPANION_CALL_END_TRIGGER_SEC", "80")
    monkeypatch.setenv("LOG_LEVEL", "DEBUG")


@pytest.fixture
def base_dir():
    return BASE_DIR


@pytest.fixture(autouse=True)
def clear_token_cache():
    """Reset shared._token_cache between tests to prevent leakage."""
    try:
        from companion_call import shared
        shared._token_cache.clear()
    except ImportError:
        pass
    yield
    try:
        from companion_call import shared
        shared._token_cache.clear()
    except ImportError:
        pass
