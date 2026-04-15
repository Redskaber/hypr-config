#!/usr/bin/env bash
# For applying Animations from different users

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

# Variables
iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/sys/scripts"
animations_dir="$HOME/.config/hypr/sys/policy/animations"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
msg='❗NOTE:❗ Select an animation preset to apply'
# list of animation files, sorted alphabetically with numbers first
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

# Rofi Menu
chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

# Check if a file was selected
if [[ -n "$chosen_file" ]]; then
  full_path="$animations_dir/$chosen_file.conf"
  if [[ ! -f "$full_path" ]]; then
    notify-send -u critical -i "$iDIR/ja.png" "Animation not found" "$chosen_file"
    exit 1
  fi
  # Apply by sourcing via hyprctl keyword (no file copy needed in new arch)
  hyprctl keyword source "$full_path"
  notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Hyprland Animation Loaded"
fi

sleep 1
"$SCRIPTSDIR/RefreshNoWaybar.sh"
