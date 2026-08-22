#!/usr/bin/env bash
# @path: sys/scripts/MonitorProfiles.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Apply pre-configured monitor profiles via rofi menu + cp to monitors.conf (interactive, no Lua API)
#
# For applying Pre-configured Monitor Profiles

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

# Check if rofi is already running.
# NOTE: pkill "$ROFI" kills ALL rofi instances. This is intentional — rofi is
# a one-shot launcher (each invocation takes over the singleton display),
# so any lingering rofi process is stale and must be cleaned before we
# open a new menu. (SCRIPT-42: by-design behaviour, documented for clarity.)
if pidof "$ROFI" >/dev/null; then
  pkill "$ROFI"
fi

# Variables
iDIR="$SWAYNC_IMAGES"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
monitor_dir="$HYPR_CONFIG_DIR/sys/hardware/monitor-profiles"
target="$HYPR_CONFIG_DIR/sys/hardware/monitors.conf"
rofi_theme="$ROFI_DIR/config-Monitors.rasi"
# SCRIPT-22 fix: $HOME must be interpolated, not literal. Use double-quoted
# string with "${HOME}" so the user's actual home path appears in the message.
msg="❗NOTE:❗ This will overwrite \"${HOME}/.config/hypr/monitors.conf\""

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
# SCRIPT-23 fix: quote "$rofi_theme" so paths with spaces / special chars work.
chosen_file=$(echo "$mon_profiles_list" | "$ROFI" -i -dmenu -config "$rofi_theme" -mesg "$msg")
if [[ -n "$chosen_file" ]]; then
  full_path="$monitor_dir/$chosen_file.conf"
  cp "$full_path" "$target"

  "$NOTIFY" -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
# SCRIPT-41 fix: disown the background job so it survives the parent script
# exit (otherwise SIGHUP could kill it if the shell exits quickly).
"${SCRIPTSDIR}/RefreshNoWaybar.sh" &
disown
