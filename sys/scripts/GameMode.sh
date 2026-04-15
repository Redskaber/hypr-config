#!/usr/bin/env bash
# sys/scripts/GameMode.sh — Toggle game mode (state machine: on ↔ off)
# State is read from animations:enabled (1 = normal, 0 = game mode active).

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/sys/scripts"

GAMEMODE_ACTIVE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

_gamemode_on() {
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    swww kill
    notify-send -e -u low -i "$notif" " Gamemode:" " enabled"
}

_gamemode_off() {
    swww-daemon --format argb &
    sleep 0.3
    swww img "$HOME/.config/rofi/.current_wallpaper"
    sleep 0.1
    "${SCRIPTSDIR}/WallustSwww.sh"
    sleep 0.5
    hyprctl reload
    "${SCRIPTSDIR}/Refresh.sh"
    notify-send -e -u normal -i "$notif" " Gamemode:" " disabled"
}

# State machine: 1 = animations on (normal mode) → enter game mode
if [ "$GAMEMODE_ACTIVE" = "1" ]; then
    _gamemode_on
else
    _gamemode_off
fi
