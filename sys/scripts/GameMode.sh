#!/usr/bin/env bash
# @path: sys/scripts/GameMode.sh
# @author: redskaber
# @date: 2026-08-20
#
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

notify_icon="$SWAYNC_IMAGES/ja.png"

# DEPRECATED: This script is replaced by the Lua state machine module (sys/statemachine/).
# Kept for reference only. Do not use — the SM module is called directly via hl.bind().
# sys/scripts/GameMode.sh — Toggle game mode (state machine: on ↔ off)
# State is read from animations:enabled (1 = normal, 0 = game mode active).

GAMEMODE_ACTIVE=$("$HYPRCTL" -j getoption animations:enabled | "$JQ" ".bool")

_gamemode_on() {
  "$HYPRCTL" --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
  "$HYPRCTL" keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
  awww kill
  "$NOTIFY" -e -u low -i "$notify_icon" " Gamemode:" " enabled"
}

_gamemode_off() {
  # awww-daemon already running (started by sys/startup.lua)
  sleep 0.3
  awww img "$ROFI_DIR/.current_wallpaper"
  sleep 0.1
  "${HYPR_SCRIPTS_DIR}/WallustSwww.sh"
  sleep 0.5
  "$HYPRCTL" reload
  "${HYPR_SCRIPTS_DIR}/Refresh.sh"
  "$NOTIFY" -e -u normal -i "$notify_icon" " Gamemode:" " disabled"
}

# State machine: 1 = animations on (normal mode) → enter game mode
if [ "$GAMEMODE_ACTIVE" == "true" ]; then
  _gamemode_on
else
  _gamemode_off
fi
