#!/usr/bin/env bash
# Deploy Twilio Functions + Assets for companion-call.
# Run from anywhere; this script cd's into the right place.
#
# Prerequisites:
#   1. Node 18+ installed
#   2. twilio CLI installed: npm i -g twilio-cli
#   3. Serverless plugin: twilio plugins:install @twilio-labs/plugin-serverless
#   4. Logged in: twilio login
#
# Usage:
#   bash companion_call/deploy_functions.sh

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FN_DIR="$HERE/twilio_functions"
AUDIO_SRC="$HERE/audio"

if [ ! -d "$FN_DIR" ]; then
  echo "ERROR: $FN_DIR not found" >&2
  exit 1
fi

if [ ! -d "$AUDIO_SRC" ]; then
  echo "ERROR: $AUDIO_SRC not found (need 12 prompt_*.wav)" >&2
  exit 1
fi

# Check twilio CLI
if ! command -v twilio >/dev/null 2>&1; then
  cat <<EOF >&2
ERROR: twilio CLI not installed.

Install:
  npm i -g twilio-cli
  twilio plugins:install @twilio-labs/plugin-serverless
  twilio login
EOF
  exit 1
fi

# Copy audio assets (Twilio CLI needs them in the Functions project)
echo ">> Copying audio to assets/"
mkdir -p "$FN_DIR/assets"
cp "$AUDIO_SRC"/prompt_*.wav "$FN_DIR/assets/"
ls -1 "$FN_DIR/assets"/prompt_*.wav | wc -l | xargs -I{} echo ">> {} files copied"

# Optional: pass END_TRIGGER_SEC from .env so functions know when to switch to closer
END_TRIGGER="80"
if [ -f "$HERE/.env" ]; then
  END_TRIGGER=$(grep '^COMPANION_CALL_END_TRIGGER_SEC=' "$HERE/.env" | cut -d= -f2 || echo "80")
fi

echo ">> Deploying with END_TRIGGER_SEC=$END_TRIGGER"
cd "$FN_DIR"

twilio serverless:deploy \
  --runtime node18 \
  --override-existing-project \
  --env "END_TRIGGER_SEC=$END_TRIGGER"

cat <<EOF

================================================================================
✅ Deploy complete.

Next steps:
1. 從上面輸出找這行: "Functions: ... .twil.io/voice"
2. 拿前面的 base URL (e.g. https://companion-call-1234-dev.twil.io)
3. 編輯 $HERE/.env 把 TWILIO_FUNCTIONS_BASE_URL=<那個 URL>
4. 跑一通測試: cd <whiteboard-ocr-bot> && python -m companion_call.scheduled_call
================================================================================
EOF
