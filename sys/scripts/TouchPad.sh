#!/usr/bin/env bash
# @path: sys/scripts/TouchPad.sh
# @author: redskaber
# @date: 2026-08-22
# @description: Toggle touchpad on/off via hyprctl keyword.
#
# ARCHITECTURE (Round 110):
#   - hyprctl keyword (CLI — no Lua dispatcher for input device config)
#   - notify-send (notification — no Lua API)
#   - State file in $HYPR_CACHE_DIR (XDG-aware, Round 109 SSOT)
#   Stays in sh.
#
# Round 110 fixes:
#   - STATUS_FILE was using $XDG_RUNTIME_DIR (lost on reboot) → $HYPR_CACHE_DIR
#     (persists across reboots, XDG-aware)
#   - $TOUCHPAD_ENABLED was single-quoted (literal string, not variable) →
#     now properly expanded
#   - Added fallback for $TOUCHPAD_ENABLED (default: touchpad:touchpad:enabled)
#   - Quoted $notif (was unquoted)
#   - Quoted $(cat ...) (was unquoted)

# Source shared library — SSOT paths + DI variables
source "$(dirname "$0")/lib/common.sh"

notif="$SWAYNC_IMAGES/ja.png"

# For disabling touchpad.
# Set $Touchpad_Device in sys/hardware/laptop.lua (run: hyprctl devices to find name)
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

# Round 110: use $HYPR_CACHE_DIR (persists across reboots, XDG-aware)
# Was: $XDG_RUNTIME_DIR (lost on reboot, so touchpad state didn't persist)
STATUS_FILE="$HYPR_CACHE_DIR/touchpad.status"

# Round 110: $TOUCHPAD_ENABLED was single-quoted (literal '$TOUCHPAD_ENABLED')
# instead of expanding the variable. Now properly expanded with default.
TOUCHPAD_ENABLED="${TOUCHPAD_ENABLED:-touchpad:touchpad:enabled}"

enable_touchpad() {
  printf "true" >"$STATUS_FILE"
  "$NOTIFY" -u low -i "$notif" " Enabling" " touchpad"
  "$HYPRCTL" keyword "$TOUCHPAD_ENABLED" "true" -r
}

disable_touchpad() {
  printf "false" >"$STATUS_FILE"
  "$NOTIFY" -u low -i "$notif" " Disabling" " touchpad"
  "$HYPRCTL" keyword "$TOUCHPAD_ENABLED" "false" -r
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  current=$(cat "$STATUS_FILE" 2>/dev/null)
  if [ "$current" = "true" ]; then
    disable_touchpad
  elif [ "$current" = "false" ]; then
    enable_touchpad
  fi
fi
