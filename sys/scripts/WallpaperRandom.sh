#!/usr/bin/env bash
# Script for Random Wallpaper ( CTRL ALT W)
# Override wallpaper dir via env var HYPR_WALLPAPER_DIR (set in user/env.conf)
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


wallDIR="${HYPR_WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
SCRIPTSDIR="$HOME/.config/hypr/sys/scripts"

focused_monitor=$("$HYPRCTL" monitors -j | "$JQ" -r '.[] | select(.focused) | .name')

PICS=($(find -L ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.pnm" -o -name "*.tga" -o -name "*.tiff" -o -name "*.webp" -o -name "*.bmp" -o -name "*.farbfeld" -o -name "*.gif" \)))
RANDOMPICS=${PICS[$RANDOM % ${#PICS[@]}]}

# Transition config
FPS=30
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

awww query || "$WALLPAPER_DAEMON" --format argb && awww img -o $focused_monitor ${RANDOMPICS} $SWWW_PARAMS

wait $!
"$SCRIPTSDIR/WallustSwww.sh" &&
  wait $!
sleep 2
"$SCRIPTSDIR/Refresh.sh"
