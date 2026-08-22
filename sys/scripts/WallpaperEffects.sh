#!/usr/bin/env bash
# @path: sys/scripts/WallpaperEffects.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Apply ImageMagick effects (blur/charcoal/sepia/etc) to wallpaper via rofi menu (interactive, no Lua API)
#
# Wallpaper Effects using ImageMagick (SUPER SHIFT W)

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

# Variables — override terminal via HYPR_TERMINAL env var (set in user/env.conf)

terminal="${HYPR_TERMINAL:-"$TERMINAL"}"
# SCRIPT-35 fix: use $HYPR_WALLUST_DIR DI var (set in lib/common.sh from
# sys/const.lua) instead of hardcoding "$HYPR_CONFIG_DIR/wallust_effects".
wallpaper_current="$HYPR_WALLUST_DIR/.wallpaper_current"
wallpaper_output="$HYPR_WALLUST_DIR/.wallpaper_modified"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
focused_monitor=$("$HYPRCTL" monitors -j | "$JQ" -r '.[] | select(.focused) | .name')
rofi_theme="$ROFI_DIR/config-wallpaper-effect.rasi"

# Directory for swaync
iDIR="$SWAYNC_IMAGES"
# SCRIPT-25 fix: removed dead `iDIRi="$SWAYNC_ICONS"` assignment — variable
# was never read anywhere in this script.

# awww transition config
FPS=60
TYPE="wipe"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Define ImageMagick effects
declare -A effects=(
  ["No Effects"]="no-effects"
  ["Black & White"]="$IMAGE_MAGICK $wallpaper_current -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
  ["Blurred"]="$IMAGE_MAGICK $wallpaper_current -blur 0x10 $wallpaper_output"
  ["Charcoal"]="$IMAGE_MAGICK $wallpaper_current -charcoal 0x5 $wallpaper_output"
  ["Edge Detect"]="$IMAGE_MAGICK $wallpaper_current -edge 1 $wallpaper_output"
  ["Emboss"]="$IMAGE_MAGICK $wallpaper_current -emboss 0x5 $wallpaper_output"
  ["Frame Raised"]="$IMAGE_MAGICK $wallpaper_current +raise 150 $wallpaper_output"
  ["Frame Sunk"]="$IMAGE_MAGICK $wallpaper_current -raise 150 $wallpaper_output"
  ["Negate"]="$IMAGE_MAGICK $wallpaper_current -negate $wallpaper_output"
  ["Oil Paint"]="$IMAGE_MAGICK $wallpaper_current -paint 4 $wallpaper_output"
  ["Posterize"]="$IMAGE_MAGICK $wallpaper_current -posterize 4 $wallpaper_output"
  ["Polaroid"]="$IMAGE_MAGICK $wallpaper_current -polaroid 0 $wallpaper_output"
  ["Sepia Tone"]="$IMAGE_MAGICK $wallpaper_current -sepia-tone 65% $wallpaper_output"
  ["Solarize"]="$IMAGE_MAGICK $wallpaper_current -solarize 80% $wallpaper_output"
  ["Sharpen"]="$IMAGE_MAGICK $wallpaper_current -sharpen 0x5 $wallpaper_output"
  ["Vignette"]="$IMAGE_MAGICK $wallpaper_current -vignette 0x3 $wallpaper_output"
  ["Vignette-black"]="$IMAGE_MAGICK $wallpaper_current -background black -vignette 0x3 $wallpaper_output"
  ["Zoomed"]="$IMAGE_MAGICK $wallpaper_current -gravity Center -extent 1:1 $wallpaper_output"
)

# Function to apply no effects
# Round 105 fix: removed broken `wait $!` pattern (was no-op after foreground
# command — $! is empty since no background process was started). The `&&`
# chain already provides sequential execution.
no-effects() {
  "$WALLPAPER_CLIENT" img -o "$focused_monitor" "$wallpaper_current" $SWWW_PARAMS || return 1
  "$COLOR_GEN" run "$wallpaper_current" -s || return 1
  # Refresh rofi, waybar, wallust palettes
  sleep 2
  "$SCRIPTSDIR/Refresh.sh"
  "$NOTIFY" -u low -i "$iDIR/ja.png" "No wallpaper" "effects applied"
  # copying wallpaper for rofi menu
  cp "$wallpaper_current" "$wallpaper_output"
}

# Function to run rofi menu
main() {
  # Populate rofi menu options
  options=("No Effects")
  for effect in "${!effects[@]}"; do
    [[ "$effect" != "No Effects" ]] && options+=("$effect")
  done

  choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | "$ROFI" -dmenu -i -config $rofi_theme)

  # Process user choice
  if [[ -n "$choice" ]]; then
    if [[ "$choice" == "No Effects" ]]; then
      no-effects
    elif [[ "${effects[$choice]+exists}" ]]; then
      # Apply selected effect
      "$NOTIFY" -u normal -i "$iDIR/ja.png" "Applying:" "$choice effects"
      eval "${effects[$choice]}"

      # intial kill process
      for pid in swaybg mpvpaper; do
        killall -SIGUSR1 "$pid"
      done

      sleep 1
      "$WALLPAPER_CLIENT" img -o "$focused_monitor" "$wallpaper_output" $SWWW_PARAMS &

      sleep 2

      "$COLOR_GEN" run "$wallpaper_output" -s &
      sleep 1
      # Refresh rofi, waybar, wallust palettes
      "${SCRIPTSDIR}/Refresh.sh"
      "$NOTIFY" -u low -i "$iDIR/ja.png" "$choice" "effects applied"
    else
      echo "Effect '$choice' not recognized."
    fi
  fi
}

# Check if rofi is already running and kill it
if pidof "$ROFI" >/dev/null; then
  pkill "$ROFI"
fi

main

# SCRIPT-18 fix: replaced ~40-line duplicated SDDM prompt block with call to
# shared helper. Outer $choice guard preserved — prompt only fires after a
# successful effect selection.
[[ -n "$choice" ]] && dt_sddm_prompt "$terminal" "$SCRIPTSDIR"
