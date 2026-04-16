#!/usr/bin/env bash
# sys/scripts/ChangeLayout.sh — Cycle layout: scrolling → dwindle → master → scrolling
#
# State machine (three states):
#   scrolling  →  dwindle   (enter tiling mode, bind J/K cycling, bind O togglesplit)
#   dwindle    →  master    (switch tiling style, unbind O)
#   master     →  scrolling (return to scrolling, unbind J/K cycling)
#
# J/K ownership:
#   scrolling — unbound here; hyprscrolling plugin handles column navigation
#   dwindle / master — bound to cyclenext / cyclenext,prev

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/sys/scripts"

LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str')

_enter_scrolling() {
    hyprctl keyword general:layout scrolling
    hyprctl keyword unbind SUPER,O  || true
    hyprctl keyword unbind SUPER,J  || true
    hyprctl keyword unbind SUPER,K  || true
    notify-send -e -u low -i "$notif" " Layout: Scrolling"
}

_enter_dwindle() {
    hyprctl keyword general:layout dwindle
    hyprctl keyword bind SUPER,O,togglesplit
    hyprctl keyword bind SUPER,J,cyclenext
    hyprctl keyword bind SUPER,K,cyclenext,prev
    notify-send -e -u low -i "$notif" " Layout: Dwindle"
}

_enter_master() {
    hyprctl keyword general:layout master
    hyprctl keyword unbind SUPER,O  || true
    hyprctl keyword bind SUPER,J,cyclenext
    hyprctl keyword bind SUPER,K,cyclenext,prev
    notify-send -e -u low -i "$notif" " Layout: Master"
}

case "$LAYOUT" in
"scrolling") _enter_dwindle  ;;
"dwindle")   _enter_master   ;;
"master")    _enter_scrolling ;;
*)
    # Unknown — reset to scrolling as canonical default
    notify-send -e -u low -i "$notif" " Layout: Scrolling (reset from $LAYOUT)"
    _enter_scrolling
    ;;
esac
