notif="$HOME/.config/swaync/images/ja.png"
#!/usr/bin/env bash
# DEPRECATED: This script is replaced by the Lua state machine module (sys/statemachine/).
# Kept for reference only. Do not use — the SM module is called directly via hl.bind().
# sys/scripts/GameMode.sh — Toggle game mode (state machine: on ↔ off)
# State is read from animations:enabled (1 = normal, 0 = game mode active).
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


SCRIPTSDIR="$HYPR_SCRIPTS_DIR"

GAMEMODE_ACTIVE=$("$HYPRCTL" getoption animations:enabled | awk 'NR==1{print $2}')

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
  "$NOTIFY" -e -u low -i "$notif" " Gamemode:" " enabled"
}

_gamemode_off() {
  "$WALLPAPER_DAEMON" --format argb &
  sleep 0.3
  awww img "$HOME/.config/rofi/.current_wallpaper"
  sleep 0.1
  "${SCRIPTSDIR}/WallustSwww.sh"
  sleep 0.5
  "$HYPRCTL" reload
  "${SCRIPTSDIR}/Refresh.sh"
  "$NOTIFY" -e -u normal -i "$notif" " Gamemode:" " disabled"
}

# State machine: 1 = animations on (normal mode) → enter game mode
if [ "$GAMEMODE_ACTIVE" = "1" ]; then
  _gamemode_on
else
  _gamemode_off
fi
