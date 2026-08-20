#!/usr/bin/env bash
# Script for changing blurs on the fly
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


notif="$HOME/.config/swaync/images"

STATE=$("$HYPRCTL" -j getoption decoration:blur:passes | "$JQ" ".int")

if [ "${STATE}" == "2" ]; then
  "$HYPRCTL" keyword decoration:blur:size 2
  "$HYPRCTL" keyword decoration:blur:passes 1
  "$NOTIFY" -e -u low -i "$notif/note.png" " Less Blur"
else
  "$HYPRCTL" keyword decoration:blur:size 5
  "$HYPRCTL" keyword decoration:blur:passes 2
  "$NOTIFY" -e -u low -i "$notif/ja.png" " Normal Blur"
fi
