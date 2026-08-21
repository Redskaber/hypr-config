#!/usr/bin/env bash
# wlogout (Power, Screen Lock, Suspend, etc)

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"




# @path: sys/scripts/Wlogout.sh
# @author: redskaber
# @date: 2026-08-20

# Set variables for parameters. First numbers corresponts to Monitor Resolution
# i.e 2160 means 2160p

A_2160=600
B_2160=600
A_1600=400
B_1600=400
A_1440=400
B_1440=400
A_1080=200
B_1080=200
A_720=50
B_720=50

# Check if wlogout is already running
if pgrep -x "wlogout" >/dev/null; then
  pkill -x "wlogout"
true  # exit removed: script exits naturally
fi

# Detect monitor resolution and scaling factor
resolution=$("$HYPRCTL" -j monitors | "$JQ" -r '.[] | select(.focused==true) | .height / .scale' | awk -F'.' '{print $1}')
hypr_scale=$("$HYPRCTL" -j monitors | "$JQ" -r '.[] | select(.focused==true) | .scale')

# Set parameters based on screen resolution and scaling factor
if ((resolution >= 2160)); then
  T_val=$(awk "BEGIN {printf \"%.0f\", $A_2160 * 2160 * $hypr_scale / $resolution}")
  B_val=$(awk "BEGIN {printf \"%.0f\", $B_2160 * 2160 * $hypr_scale / $resolution}")
  echo "Setting parameters for resolution >= 4k"
  "$LOGOUT_MENU" --protocol layer-shell -b 6 -T $T_val -B $B_val &
elif ((resolution >= 1600 && resolution < 2160)); then
  T_val=$(awk "BEGIN {printf \"%.0f\", $A_1600 * 1600 * $hypr_scale / $resolution}")
  B_val=$(awk "BEGIN {printf \"%.0f\", $B_1600 * 1600 * $hypr_scale / $resolution}")
  echo "Setting parameters for resolution >= 2.5k and < 4k"
  "$LOGOUT_MENU" --protocol layer-shell -b 6 -T $T_val -B $B_val &
elif ((resolution >= 1440 && resolution < 1600)); then
  T_val=$(awk "BEGIN {printf \"%.0f\", $A_1440 * 1440 * $hypr_scale / $resolution}")
  B_val=$(awk "BEGIN {printf \"%.0f\", $B_1440 * 1440 * $hypr_scale / $resolution}")
  echo "Setting parameters for resolution >= 2k and < 2.5k"
  "$LOGOUT_MENU" --protocol layer-shell -b 6 -T $T_val -B $B_val &
elif ((resolution >= 1080 && resolution < 1440)); then
  T_val=$(awk "BEGIN {printf \"%.0f\", $A_1080 * 1080 * $hypr_scale / $resolution}")
  B_val=$(awk "BEGIN {printf \"%.0f\", $B_1080 * 1080 * $hypr_scale / $resolution}")
  echo "Setting parameters for resolution >= 1080p and < 2k"
  "$LOGOUT_MENU" --protocol layer-shell -b 6 -T $T_val -B $B_val &
elif ((resolution >= 720 && resolution < 1080)); then
  T_val=$(awk "BEGIN {printf \"%.0f\", $A_720 * 720 * $hypr_scale / $resolution}")
  B_val=$(awk "BEGIN {printf \"%.0f\", $B_720 * 720 * $hypr_scale / $resolution}")
  echo "Setting parameters for resolution >= 720p and < 1080p"
  "$LOGOUT_MENU" --protocol layer-shell -b 3 -T $T_val -B $B_val &
else
  echo "Setting default parameters"
  "$LOGOUT_MENU" &
fi
