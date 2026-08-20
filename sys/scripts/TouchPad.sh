#!/usr/bin/env bash
# For disabling touchpad.
# Set $Touchpad_Device in sys/hardware/laptop.lua (run: hyprctl devices to find name)
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


notif="$HOME/.config/swaync/images/ja.png"

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
