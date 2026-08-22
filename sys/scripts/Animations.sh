#!/usr/bin/env bash
# @path: sys/scripts/Animations.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Switch active animation preset via rofi.
#
# ARCHITECTURE (Round 104 — capability boundary):
#   Animation presets are .lua files in sys/policy/animations/. They cannot
#   be loaded from sh (no Lua bridge). So this script:
#     1. Lists .lua preset files (was buggy: looked for .conf)
#     2. Writes the chosen name to $HYPR_CONFIG_DIR/.active_animation
#     3. Calls hyprctl reload → user/policy/default.lua reads state file via
#        lib/active_policy.lua and requires the chosen preset.
#
#   Lua side (lib/active_policy.lua + user/policy/default.lua) is the SSOT
#   consumer; this script is just the UI (rofi picker).
#
# CAPABILITY BOUNDARY:
#   - rofi -dmenu (interactive picker) → cannot be done in Lua
#   - State file write → could be done in Lua, but sh is simpler here
#   - hyprctl reload → could be `hl.dispatch(...)` but we're in sh context

# Source shared library — provides DI for tool names + paths
source "$(dirname "$0")/lib/common.sh"

# Toggle rofi if already running (avoid stacking instances)
if pidof "$ROFI" >/dev/null; then
  pkill "$ROFI" 2>/dev/null || true
fi

# Variables
iDIR="$SWAYNC_IMAGES"
animations_dir="$HYPR_POLICY_DIR/animations"
rofi_theme="$ROFI_DIR/config-Animations.rasi"
state_file="$HYPR_CONFIG_DIR/.active_animation"
msg='❗NOTE:❗ Select an animation preset to apply'

# List .lua preset files (was buggy: looked for .conf in older versions)
# Sort numerically so default.lua appears first
animations_list=$(find -L "$animations_dir" -maxdepth 1 -type f -name '*.lua' \
  | sed 's|.*/||; s|\.lua$||' | sort -V)

if [ -z "$animations_list" ]; then
  dt_notify "Animations" "No animation presets found in $animations_dir" critical
  exit 1
fi

# Rofi Menu
chosen_file=$(printf '%s\n' "$animations_list" \
  | "$ROFI" -i -dmenu -config "$rofi_theme" -mesg "$msg")

# User pressed Escape — silent exit (not an error)
[ -z "$chosen_file" ] && exit 0

# Validate chosen preset exists
full_path="$animations_dir/$chosen_file.lua"
if [ ! -f "$full_path" ]; then
  dt_notify "Animation not found" "$chosen_file (preset file missing)" critical
  exit 1
fi

# Write chosen name to state file (read by lib/active_policy.lua on reload)
printf '%s\n' "$chosen_file" > "$state_file"

# Apply: reload Hyprland config (triggers user/policy/default.lua → active_policy)
"$HYPRCTL" reload

dt_notify "$chosen_file" "Hyprland Animation Loaded" low

# Refresh UI components (waybar/swaync may need reload for new colors)
sleep 1
"$HYPR_SCRIPTS_DIR/RefreshNoWaybar.sh" 2>/dev/null || true
