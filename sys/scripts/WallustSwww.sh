#!/usr/bin/env bash
# @path: sys/scripts/WallustSwww.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Resolve current wallpaper path + run wallust to regenerate color templates
#
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

set -uo pipefail # No set -e: prevent script from killing session on command failure

# Inputs and paths
passed_path="${1:-}"
cache_dir="$HYPR_CACHE_DIR/awww/"
rofi_link="$ROFI_DIR/.current_wallpaper"
wallpaper_current="$HYPR_CONFIG_DIR/wallust_effects/.wallpaper_current"

# (SCRIPT-19 fix: removed local get_focused_monitor() — it reimplemented
#  dt_get_focused_monitor() from lib/common.sh. Now uses the shared helper
#  which has an awk fallback for systems without jq.)

# Determine wallpaper_path
wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  # Try to read from awww cache for the focused monitor, with a short retry loop
  current_monitor="$(dt_get_focused_monitor)"
  cache_file="$cache_dir$current_monitor"

  # Wait briefly for awww to write its cache after an image change
  for i in {1..10}; do
    if [[ -f "$cache_file" ]]; then
      break
    fi
    sleep 0.1
  done

  if [[ -f "$cache_file" ]]; then
    # The first non-filter line is the original wallpaper path
    # wallpaper_path="$(grep -v 'Lanczos3' "$cache_file" | head -n 1)"
    # SCRIPT-20 fix: quote $current_monitor in grep (was unquoted — a monitor
    # name with regex metacharacters or spaces could match the wrong line).
    # Prefer jq if "$WALLPAPER_CLIENT" query returns JSON; fall back to awk positional parse.
    if wallpaper_path=$("$WALLPAPER_CLIENT" query 2>/dev/null | "$JQ" -r --arg mon "$current_monitor" \
      '.[] | select(.monitor == $mon or .output == $mon or .name == $mon) | (.wallpaper // .image // .path) // empty' 2>/dev/null) &&
      [ -n "$wallpaper_path" ]; then
      : # jq succeeded
    else
      wallpaper_path=$("$WALLPAPER_CLIENT" query 2>/dev/null | grep "\"$current_monitor\"" | awk '{print $9}')
    fi
  fi
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  # Nothing to do; avoid failing loudly so callers can continue
  exit 1
fi

# Update helpers that depend on the path
ln -sf "$wallpaper_path" "$rofi_link" || true
mkdir -p "$(dirname "$wallpaper_current")"
cp -f "$wallpaper_path" "$wallpaper_current" || true

# Run wallust (silent) to regenerate templates defined in ~/.config/wallust/wallust.toml
# -s is used in this repo to keep things quiet and avoid extra prompts
"$COLOR_GEN" run -s "$wallpaper_path" || true
