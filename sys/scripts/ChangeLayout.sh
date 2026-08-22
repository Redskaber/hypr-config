#!/usr/bin/env bash
# @path: sys/scripts/ChangeLayout.sh
# @author: redskaber
# @date: 2026-08-20
#
# Source shared library — SSOT paths + DI variables
source "$(dirname "$0")/lib/common.sh"

notif="$SWAYNC_IMAGES/ja.png"

# DEPRECATED: This script is replaced by the Lua state machine module (sys/statemachine/).
# Kept for reference only. Do not use — the SM module is called directly via hl.bind().
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

LAYOUT=$("$HYPRCTL" -j getoption general:layout | "$JQ" -r '.str')

_enter_scrolling() {
  "$HYPRCTL" keyword general:layout scrolling
  "$HYPRCTL" keyword unbind SUPER,O || true
  "$HYPRCTL" keyword unbind SUPER,J || true
  "$HYPRCTL" keyword unbind SUPER,K || true
  "$NOTIFY" -e -u low -i "$notif" " Layout: Scrolling"
}

_enter_dwindle() {
  "$HYPRCTL" keyword general:layout dwindle
  "$HYPRCTL" keyword bind SUPER,O,togglesplit
  "$HYPRCTL" keyword bind SUPER,J,cyclenext
  "$HYPRCTL" keyword bind SUPER,K,cyclenext,prev
  "$NOTIFY" -e -u low -i "$notif" " Layout: Dwindle"
}

_enter_master() {
  "$HYPRCTL" keyword general:layout master
  "$HYPRCTL" keyword unbind SUPER,O || true
  "$HYPRCTL" keyword bind SUPER,J,cyclenext
  "$HYPRCTL" keyword bind SUPER,K,cyclenext,prev
  "$NOTIFY" -e -u low -i "$notif" " Layout: Master"
}

case "$LAYOUT" in
"scrolling") _enter_dwindle ;;
"dwindle") _enter_master ;;
"master") _enter_scrolling ;;
*)
  # Unknown — reset to scrolling as canonical default
  "$NOTIFY" -e -u low -i "$notif" " Layout: Scrolling (reset from $LAYOUT)"
  _enter_scrolling
  ;;
esac
