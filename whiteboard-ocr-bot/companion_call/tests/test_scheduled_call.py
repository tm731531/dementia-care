"""Test scheduled_call.py outbound caller."""
from unittest.mock import MagicMock, patch


def test_place_call_invokes_twilio_create():
    fake_calls = MagicMock()
    fake_calls.create.return_value = MagicMock(sid="CAtest")
    fake_client = MagicMock()
    fake_client.calls = fake_calls

    with patch("companion_call.scheduled_call.Client", return_value=fake_client):
        from companion_call.scheduled_call import place_call
        sid = place_call()

    assert sid == "CAtest"
    fake_calls.create.assert_called_once()
    kwargs = fake_calls.create.call_args.kwargs
    assert kwargs["from_"] == "+15551234567"          # from fake env
    assert kwargs["to"] == "+886912345678"             # mom number from env
    assert kwargs["url"].endswith("/voice")
    assert "test.cfargotunnel.com" in kwargs["url"]
    assert kwargs["status_callback"].endswith("/call-ended")
    assert kwargs["timeout"] == 30


def test_place_call_uses_status_callback_events():
    """Twilio should be told which status events to call back on."""
    fake_calls = MagicMock()
    fake_calls.create.return_value = MagicMock(sid="CAtest")
    fake_client = MagicMock()
    fake_client.calls = fake_calls

    with patch("companion_call.scheduled_call.Client", return_value=fake_client):
        from companion_call.scheduled_call import place_call
        place_call()

    kwargs = fake_calls.create.call_args.kwargs
    events = kwargs["status_callback_event"]
    assert "completed" in events
    assert "no-answer" in events
    assert "failed" in events
    assert "busy" in events
