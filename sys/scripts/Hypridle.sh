#!/usr/bin/env bash
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


# @path: sys/scripts/Hypridle.sh
# @author: redskaber
# @date: 2026-08-20

PROCESS="hypridle"
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
true  # exit removed: script exits naturally
fi
