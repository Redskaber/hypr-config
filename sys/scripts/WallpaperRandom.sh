#!/usr/bin/env bash
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


# @path: sys/scripts/WallpaperRandom.sh
# @author: redskaber
# @date: 2026-08-20

wallDIR="${HYPR_WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"

focused_monitor=$("$HYPRCTL" monitors -j | "$JQ" -r '.[] | select(.focused) | .name')

PICS=($(find -L ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.pnm" -o -name "*.tga" -o -name "*.tiff" -o -name "*.webp" -o -name "*.bmp" -o -name "*.farbfeld" -o -name "*.gif" \)))
RANDOMPICS=${PICS[$RANDOM % ${#PICS[@]}]}

# Transition config
FPS=30
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

awww query 2>/dev/null && awww img -o $focused_monitor ${RANDOMPICS} $SWWW_PARAMS

wait $!
"$SCRIPTSDIR/WallustSwww.sh" &&
  wait $!
sleep 2
"$SCRIPTSDIR/Refresh.sh"
