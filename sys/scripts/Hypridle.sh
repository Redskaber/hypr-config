#!/usr/bin/env bash
# @path: sys/scripts/Hypridle.sh
# @author: redskaber
# @date: 2026-08-20

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

PROCESS="$IDLE_DAEMON"
HYPRIDLE_CONF="$HYPR_CONFIG_DIR/sys/hypridle.conf"

if [[ "$1" == "status" ]]; then
  sleep 1
  if pgrep -x "$PROCESS" >/dev/null; then
    echo '{"text": "RUNNING", "class": "active", "tooltip": "idle_inhibitor NOT ACTIVE\nLeft Click: Activate\nRight Click: Lock Screen"}'
  else
    echo '{"text": "NOT RUNNING", "class": "notactive", "tooltip": "idle_inhibitor is ACTIVE\nLeft Click: Deactivate\nRight Click: Lock Screen"}'
  fi
elif [[ "$1" == "toggle" ]]; then
  if pgrep -x "$PROCESS" >/dev/null; then
    pkill "$PROCESS"
  else
    "$PROCESS" -c "$HYPRIDLE_CONF" &
  fi
else
  echo "Usage: $0 {status|toggle}"
  exit 1
fi
