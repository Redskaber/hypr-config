#!/usr/bin/env bash
# For Searching via web browsers

# Read $Search_Engine from user/const.conf (defined there in new arch)
config_file="$HOME/.config/hypr/user/const.conf"

if [[ ! -f "$config_file" ]]; then
  echo "Error: Configuration file not found: $config_file"
  exit 1
fi

# Extract $Search_Engine value from Hyprland-style variable assignment
Search_Engine=$(grep -E '^\$Search_Engine\s*=' "$config_file" | sed -E 's/^\$Search_Engine\s*=\s*//' | tr -d '"' | xargs)

if [[ -z "$Search_Engine" ]]; then
  echo "Error: \$Search_Engine is not set in $config_file"
  exit 1
fi

# Rofi theme and message
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='‼️ **note** ‼️ search via default web browser'

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
  pkill rofi
fi

# Open Rofi and pass the selected query to xdg-open for Google search
echo "" | rofi -dmenu -config "$rofi_theme" -mesg "$msg" | xargs -I{} xdg-open $Search_Engine

