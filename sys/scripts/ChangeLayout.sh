#!/usr/bin/env bash
# for changing Hyprland Layouts (Master or Dwindle) on the fly
# NOTE: scrolling layout (hyprscrolling) is not part of this toggle cycle.
#       If current layout is scrolling, switch to dwindle first.

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

case $LAYOUT in
"master")
  hyprctl keyword general:layout dwindle
  hyprctl keyword bind SUPER,O,togglesplit
  notify-send -e -u low -i "$notif" " Dwindle Layout"
  ;;
"dwindle")
  hyprctl keyword general:layout master
  hyprctl keyword unbind SUPER,O
  notify-send -e -u low -i "$notif" " Master Layout"
  ;;
"scrolling"|*)
  # scrolling or unknown: enter dwindle as the base tiling layout
  hyprctl keyword general:layout dwindle
  hyprctl keyword bind SUPER,O,togglesplit
  notify-send -e -u low -i "$notif" " Dwindle Layout (from $LAYOUT)"
  ;;
esac
