#!/usr/bin/env bash
# Waybar idle_inhibitor: toggle hypridle on/off.
# Config path must be absolute — hypridle runs in its own process context.

PROCESS="hypridle"
HYPRIDLE_CONF="$HOME/.config/hypr/sys/hypridle.conf"

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
