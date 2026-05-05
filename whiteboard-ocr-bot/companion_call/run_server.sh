#!/usr/bin/env bash
# Start companion_call FastAPI server.
# Called by systemd unit; can also run manually.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$(dirname "$HERE")"   # whiteboard-ocr-bot/

source venv/bin/activate

# Load .env so uvicorn child process inherits
set -a
source companion_call/.env
set +a

exec uvicorn companion_call.twilio_app:app \
    --host 0.0.0.0 \
    --port "${COMPANION_CALL_PORT:-8004}" \
    --log-level "${LOG_LEVEL,,}"
