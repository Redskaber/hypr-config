#!/usr/bin/env bash
# Wallpaper Effects using ImageMagick (SUPER SHIFT W)

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"




# @path: sys/scripts/WallpaperEffects.sh
# @author: redskaber
# @date: 2026-08-20

# Variables — override terminal via HYPR_TERMINAL env var (set in user/env.conf)

terminal="${HYPR_TERMINAL:-"$TERMINAL"}"
wallpaper_current="$HYPR_CONFIG_DIR/wallust_effects/.wallpaper_current"
wallpaper_output="$HYPR_CONFIG_DIR/wallust_effects/.wallpaper_modified"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
focused_monitor=$("$HYPRCTL" monitors -j | "$JQ" -r '.[] | select(.focused) | .name')
rofi_theme="$ROFI_DIR/config-wallpaper-effect.rasi"

# Directory for swaync
iDIR="$SWAYNC_IMAGES"
iDIRi="$SWAYNC_ICONS"

# awww transition config
FPS=60
TYPE="wipe"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

# Define ImageMagick effects
declare -A effects=(
  ["No Effects"]="no-effects"
  ["Black & White"]="magick $wallpaper_current -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
  ["Blurred"]="magick $wallpaper_current -blur 0x10 $wallpaper_output"
  ["Charcoal"]="magick $wallpaper_current -charcoal 0x5 $wallpaper_output"
  ["Edge Detect"]="magick $wallpaper_current -edge 1 $wallpaper_output"
  ["Emboss"]="magick $wallpaper_current -emboss 0x5 $wallpaper_output"
  ["Frame Raised"]="magick $wallpaper_current +raise 150 $wallpaper_output"
  ["Frame Sunk"]="magick $wallpaper_current -raise 150 $wallpaper_output"
  ["Negate"]="magick $wallpaper_current -negate $wallpaper_output"
  ["Oil Paint"]="magick $wallpaper_current -paint 4 $wallpaper_output"
  ["Posterize"]="magick $wallpaper_current -posterize 4 $wallpaper_output"
  ["Polaroid"]="magick $wallpaper_current -polaroid 0 $wallpaper_output"
  ["Sepia Tone"]="magick $wallpaper_current -sepia-tone 65% $wallpaper_output"
  ["Solarize"]="magick $wallpaper_current -solarize 80% $wallpaper_output"
  ["Sharpen"]="magick $wallpaper_current -sharpen 0x5 $wallpaper_output"
  ["Vignette"]="magick $wallpaper_current -vignette 0x3 $wallpaper_output"
  ["Vignette-black"]="magick $wallpaper_current -background black -vignette 0x3 $wallpaper_output"
  ["Zoomed"]="magick $wallpaper_current -gravity Center -extent 1:1 $wallpaper_output"
)

# Function to apply no effects
no-effects() {
  awww img -o "$focused_monitor" "$wallpaper_current" $SWWW_PARAMS &&
    wait $!
  "$COLOR_GEN" run "$wallpaper_current" -s &&
    wait $!
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
      awww img -o "$focused_monitor" "$wallpaper_output" $SWWW_PARAMS &

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

sleep 1

if [[ -n "$choice" ]]; then
  # Resolve SDDM themes directory (standard and NixOS path)
  sddm_themes_dir=""
  if [ -d "/usr/share/sddm/themes" ]; then
    sddm_themes_dir="/usr/share/sddm/themes"
  elif [ -d "/run/current-system/sw/share/sddm/themes" ]; then
    sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
  fi

  if [ -n "$sddm_themes_dir" ]; then
    sddm_simple="$sddm_themes_dir/simple_sddm_2"

    # Only prompt if theme exists and its Backgrounds directory is writable
    if [ -d "$sddm_simple" ] && [ -w "$sddm_simple/Backgrounds" ]; then
      # Check if yad is running to avoid multiple yad notification
      if pidof yad >/dev/null; then
        killall yad
      fi

      if yad --info --text="Set current wallpaper as SDDM background?\n\nNOTE: This only applies to SIMPLE SDDM v2 Theme" \
        --text-align=left \
        --title="SDDM Background" \
        --timeout=5 \
        --timeout-indicator=right \
        --button="yad-yes:0" \
        --button="yad-no:1" \
        ; then

        # Check if terminal exists
        if ! command -v "$terminal" &>/dev/null; then
          "$NOTIFY" -i "$iDIR/ja.png" "Missing $terminal" "Install $terminal to enable setting of wallpaper background"
          exit 1
        fi

        bash "$SCRIPTSDIR/sddm_wallpaper.sh" --effects
      fi
    fi
  fi
fi
