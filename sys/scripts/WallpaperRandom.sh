#!/usr/bin/env bash
# @path: sys/scripts/WallpaperRandom.sh
# @author: redskaber
# @date: 2026-08-22
# @description: Set a random wallpaper from the wallpaper directory.
#
# ARCHITECTURE (Round 105 — capability boundary):
#   - find + shuf (random pick from filesystem — no Lua API for file listing)
#   - "$WALLPAPER_CLIENT" query/img (wallpaper daemon CLI — no Lua API for wallpaper)
#   - hyprctl monitors -j (JSON query — no Lua API in sh)
#   Stays in sh.
#
# Round 105 fix: removed broken `wait $!` pattern (was no-op after foreground
# command — $! is empty since no background process was started). Added div-by-
# zero guard when wallDIR is empty.

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

wallDIR="${HYPR_WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
iDIR="$SWAYNC_IMAGES"

focused_monitor=$("$HYPRCTL" monitors -j | "$JQ" -r '.[] | select(.focused) | .name')
[ -z "$focused_monitor" ] && {
  dt_notify "WallpaperRandom" "Could not detect focused monitor" critical
  exit 1
}

# Read wallpapers into array
mapfile -t PICS < <(find -L "${wallDIR}" -type f \( \
  -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.pnm" -o \
  -name "*.tga" -o -name "*.tiff" -o -name "*.webp" -o -name "*.bmp" -o \
  -name "*.farbfeld" -o -name "*.gif" \) 2>/dev/null)

# Round 105 fix: guard against div-by-zero when wallDIR is empty
if [ ${#PICS[@]} -eq 0 ]; then
  dt_notify "WallpaperRandom" "No wallpapers found in $wallDIR" critical
  exit 1
fi

RANDOMPICS="${PICS[$RANDOM % ${#PICS[@]}]}"

# Transition config
FPS=30
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Apply wallpaper ("$WALLPAPER_CLIENT" query checks daemon is running; does NOT restart it)
"$WALLPAPER_CLIENT" query 2>/dev/null && "$WALLPAPER_CLIENT" img -o "$focused_monitor" "${RANDOMPICS}" $SWWW_PARAMS

# Regenerate wallust colors + refresh UI
# Round 124 fix: pass RANDOMPICS explicitly to WallustSwww.sh so it doesn't
# need to read from awww cache (which may not be written yet — race condition).
# Was: "$SCRIPTSDIR/WallustSwww.sh" (no path arg → tries awww cache → empty → exit 1)
"$SCRIPTSDIR/WallustSwww.sh" "${RANDOMPICS}" || true
sleep 2
"$SCRIPTSDIR/Refresh.sh"

exit 0
