#!/usr/bin/env bash
# @path: sys/scripts/ChangeBlur.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Toggle Hyprland decoration blur passes (1↔2) via hyprctl + notify-send
#
# Script for changing blurs on the fly
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

STATE=$("$HYPRCTL" -j getoption decoration:blur:passes | "$JQ" ".int")

if [ "${STATE}" == "2" ]; then
  "$HYPRCTL" keyword decoration:blur:size 2
  "$HYPRCTL" keyword decoration:blur:passes 1
  "$NOTIFY" -e -u low -i "$SWAYNC_IMAGES/note.png" " Less Blur"
else
  "$HYPRCTL" keyword decoration:blur:size 5
  "$HYPRCTL" keyword decoration:blur:passes 2
  "$NOTIFY" -e -u low -i "$SWAYNC_IMAGES/ja.png" " Normal Blur"
fi
