#!/usr/bin/env bash

# @path: sys/scripts/TouchPad.sh
# @author: redskaber
# @date: 2026-08-20

notif="$SWAYNC_IMAGES/ja.png"


# For disabling touchpad.
# Set $Touchpad_Device in sys/hardware/laptop.lua (run: hyprctl devices to find name)
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

enable_touchpad() {
  printf "true" >"$STATUS_FILE"
  "$NOTIFY" -u low -i $notif " Enabling" " touchpad"
  "$HYPRCTL" keyword '$TOUCHPAD_ENABLED' "true" -r
}

disable_touchpad() {
  printf "false" >"$STATUS_FILE"
  "$NOTIFY" -u low -i $notif " Disabling" " touchpad"
  "$HYPRCTL" keyword '$TOUCHPAD_ENABLED' "false" -r
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
