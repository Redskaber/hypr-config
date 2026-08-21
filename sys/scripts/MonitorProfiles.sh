#!/usr/bin/env bash
# For applying Pre-configured Monitor Profiles

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"




# @path: sys/scripts/MonitorProfiles.sh
# @author: redskaber
# @date: 2026-08-20

# Check if rofi is already running

if pidof "$ROFI" >/dev/null; then
  pkill "$ROFI"
fi

# Variables
iDIR="$SWAYNC_IMAGES"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
monitor_dir="$HYPR_CONFIG_DIR/sys/hardware/monitor-profiles"
target="$HYPR_CONFIG_DIR/sys/hardware/monitors.conf"
rofi_theme="$ROFI_DIR/config-Monitors.rasi"
msg='❗NOTE:❗ This will overwrite $HOME/.config/hypr/monitors.conf'

# Define the list of files to ignore
ignore_files=(
  "README"
)

# list of Monitor Profiles, sorted alphabetically with numbers first
mon_profiles_list=$(find -L "$monitor_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

# Remove ignored files from the list
for ignored_file in "${ignore_files[@]}"; do
  mon_profiles_list=$(echo "$mon_profiles_list" | grep -v -E "^$ignored_file$")
done

# Rofi Menu
chosen_file=$(echo "$mon_profiles_list" | "$ROFI" -i -dmenu -config $rofi_theme -mesg "$msg")
if [[ -n "$chosen_file" ]]; then
  full_path="$monitor_dir/$chosen_file.conf"
  cp "$full_path" "$target"

  "$NOTIFY" -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
${SCRIPTSDIR}/RefreshNoWaybar.sh &

