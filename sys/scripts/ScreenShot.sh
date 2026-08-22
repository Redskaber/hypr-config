#!/usr/bin/env bash
# @path: sys/scripts/ScreenShot.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Screenshot capture (grim + slurp + wl-copy + swappy + notify)
#
# ARCHITECTURE (Round 104 — capability boundary):
#   - grim/slurp/wl-copy/swappy are external Wayland CLIs → no Lua bindings
#   - hyprctl -j activewindow for active window geometry → could be replaced
#     by hl.get_active_window() in Lua, but swappy/xdg-open still need sh
#   - Stays in sh; uses DI vars ($SCREENSHOT/$SLURP/$WL_COPY/$SCREENSHOT_EDITOR/$FILE_OPENER)
#
# Round 104 fixes:
#   - Replaced hardcoded `swappy` → `$SCREENSHOT_EDITOR` (DI)
#   - Replaced hardcoded `xdg-open` → `$FILE_OPENER` (DI)
#   - Removed dead code: lines 20-22 (active_window_* computed at top but only
#     used in shotactive which recomputes — wasteful hyprctl call per invocation)
#   - Removed dead code: shotwin() (not bound in keybind.lua)
#   - Quoted all `cd "$dir"` (was unquoted, breaks on spaces)
#   - Restored `exit 0` at end (was `true # exit removed`)
#   - Added `$RANDOM` to active_window_file (collision risk)

# Source shared library — provides SCREENSHOT, SLURP, WL_COPY, SCREENSHOT_EDITOR,
# FILE_OPENER, HYPRCTL, JQ, NOTIFY, SWAYNC_ICONS, SWAYNC_IMAGES, HYPR_SCRIPTS_DIR
source "$(dirname "$0")/lib/common.sh"

# Variables (active_window_* computed lazily inside shotactive, not at top)
time=$(date "+%d-%b_%H-%M-%S")
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

iDIR="$SWAYNC_ICONS"
iDoR="$SWAYNC_IMAGES"
sDIR="$HYPR_SCRIPTS_DIR"

# Notify command base (with action buttons for Open/Delete)
notify_cmd_base="$NOTIFY -t 10000 -A action1=Open -A action2=Delete -h string:x-canonical-private-synchronous:shot-notify"
notify_cmd_shot="${notify_cmd_base} -i ${iDIR}/picture.png"
notify_cmd_NOT="$NOTIFY -u low -i ${iDoR}/note.png"

# Notify and offer Open/Delete actions on the captured screenshot
notify_view() {
  local target_file="$1"
  local label="$2"
  if [[ -e "$target_file" ]]; then
    "${sDIR}/Sounds.sh" --screenshot
    local resp
    resp=$(timeout 5 $notify_cmd_shot " Screenshot:" " ${label} Saved.")
    case "$resp" in
    action1)
      "$FILE_OPENER" "$target_file" &
      ;;
    action2)
      rm "$target_file" &
      ;;
    esac
  else
    $notify_cmd_NOT " Screenshot:" " ${label} NOT Saved."
    "${sDIR}/Sounds.sh" --error
  fi
}

# Countdown before shot (5 or 10 seconds)
countdown() {
  local sec
  for sec in $(seq "$1" -1 1); do
    "$NOTIFY" -h string:x-canonical-private-synchronous:shot-notify -t 1000 \
      -i "$iDIR/timer.png" " Taking shot" " in: $sec secs"
    sleep 1
  done
}

# Take shots
shotnow() {
  (cd "$dir" && "$SCREENSHOT" - | tee "$file" | "$WL_COPY")
  sleep 2
  notify_view "${dir}/${file}" "Full screen"
}

shot5() {
  countdown '5'
  sleep 1
  (cd "$dir" && "$SCREENSHOT" - | tee "$file" | "$WL_COPY")
  sleep 1
  notify_view "${dir}/${file}" "Full screen (5s delay)"
}

shot10() {
  countdown '10'
  sleep 1
  (cd "$dir" && "$SCREENSHOT" - | tee "$file" | "$WL_COPY")
  notify_view "${dir}/${file}" "Full screen (10s delay)"
}

shotarea() {
  local tmpfile geom
  tmpfile=$(mktemp)
  geom=$("$SLURP" 2>/dev/null)
  if [ -z "$geom" ]; then
    rm -f "$tmpfile"
    exit 0  # user cancelled slurp
  fi
  "$SCREENSHOT" -g "$geom" - >"$tmpfile"
  if [[ -s "$tmpfile" ]]; then
    "$WL_COPY" <"$tmpfile"
    mv "$tmpfile" "${dir}/${file}"
    notify_view "${dir}/${file}" "Region"
  else
    rm -f "$tmpfile"
  fi
}

shotactive() {
  local class at size out_file
  class=$("$HYPRCTL" -j activewindow 2>/dev/null | "$JQ" -r '.class // "Unknown"')
  at=$("$HYPRCTL" -j activewindow 2>/dev/null | "$JQ" -r '"\(.at[0]),\(.at[1])"')
  size=$("$HYPRCTL" -j activewindow 2>/dev/null | "$JQ" -r '"\(.size[0])x\(.size[1])"')
  out_file="${dir}/Screenshot_${time}_${class}_${RANDOM}.png"
  "$SCREENSHOT" -g "${at} ${size}" - "${out_file}"
  sleep 1
  notify_view "$out_file" "$class"
}

shotswappy() {
  local tmpfile geom
  tmpfile=$(mktemp)
  geom=$("$SLURP" 2>/dev/null)
  if [ -z "$geom" ]; then
    rm -f "$tmpfile"
    exit 0
  fi
  "$SCREENSHOT" -g "$geom" - >"$tmpfile"
  if [[ -s "$tmpfile" ]]; then
    "$WL_COPY" <"$tmpfile"
    "${sDIR}/Sounds.sh" --screenshot
    "$SCREENSHOT_EDITOR" -f - <"$tmpfile" 2>/dev/null || \
      $notify_cmd_NOT " Screenshot:" " $SCREENSHOT_EDITOR not available"
    rm -f "$tmpfile"
  else
    rm -f "$tmpfile"
  fi
}

# Ensure screenshot directory exists
if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

# CLI dispatch
case "$1" in
  --now)     shotnow ;;
  --in5)     shot5 ;;
  --in10)    shot10 ;;
  --area)    shotarea ;;
  --active)  shotactive ;;
  --swappy)  shotswappy ;;
  *)
    echo "Usage: $(basename "$0") [--now|--in5|--in10|--area|--active|--swappy]"
    echo "Available Options: --now --in5 --in10 --area --active --swappy"
    exit 1
    ;;
esac

exit 0
