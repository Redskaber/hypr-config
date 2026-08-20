#!/usr/bin/env bash
# sys/scripts/RainbowBorders.sh — Animated rainbow active border
# This is the system-provided implementation.
# To enable: add to user/startup.conf:
#   exec-once = $S/RainbowBorders.sh
# To use a custom version: place it at user/scripts/RainbowBorders.sh
# (Refresh.sh will prefer user/scripts/ over sys/scripts/).
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


function random_hex() {
  random_hex=("0xff$(openssl rand -hex 3)")
  echo $random_hex
}

# rainbow colors only for active window
"$HYPRCTL" keyword general:col.active_border $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) 270deg

# rainbow colors for inactive window (uncomment to take effect)
#hyprctl keyword general:col.inactive_border $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) $(random_hex) 270deg
