#!/usr/bin/env bash
# Install the companion-call systemd unit (scheduler only).
# Single service — replaces the prior 3-service architecture (server/scheduler/tunnel).
#
# Usage:
#   bash companion_call/install_systemd.sh

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$HERE/.env" ]; then
  echo "ERROR: $HERE/.env not found." >&2
  echo "Create it first: cp companion_call/.env.example companion_call/.env && nano companion_call/.env" >&2
  exit 1
fi

if [ ! -f "$HERE/companion-call.service" ]; then
  echo "ERROR: companion-call.service not found in $HERE" >&2
  exit 1
fi

echo ">> Installing systemd unit"
sudo cp "$HERE/companion-call.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable companion-call.service
sudo systemctl restart companion-call.service

echo ">> Status:"
systemctl status companion-call.service --no-pager -l | head -20

echo ""
echo "Tail logs:  journalctl -u companion-call -f"
