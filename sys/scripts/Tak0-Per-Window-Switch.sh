#!/usr/bin/env bash
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"




# @path: sys/scripts/Tak0-Per-Window-Switch.sh
# @author: redskaber
# @date: 2026-08-20

##################################################################
#                                                                #
#                                                                #
#                  TAK_0'S Per-Window-Switch                     #
#                                                                #
#                                                                #
#                                                                #
#  Just a little script that I made to switch keyboard layouts   #
#       per-window instead of global switching for the more      #
#                 smooth and comfortable workflow.               #
#                                                                #
##################################################################

# This is for changing kb_layouts. Set kb_layouts in

MAP_FILE="$HOME/.cache/kb_layout_per_window"
# NOTE: Task 6 migration renamed sys/input.conf → sys/input.lua (Lua API).
# Prefer .lua (current), fall back to .conf for older installs.
if [ -f "$HYPR_CONFIG_DIR/sys/input.lua" ]; then
  CFG_FILE="$HYPR_CONFIG_DIR/sys/input.lua"
else
  CFG_FILE="$HYPR_CONFIG_DIR/sys/input.conf"
fi
ICON="$SWAYNC_IMAGES/ja.png"
SCRIPT_NAME="$(basename "$0")"

# Ensure map file exists
touch "$MAP_FILE"

# Read layouts from config (handles both `kb_layout = us,de` and `kb_layout = "us,de",` formats).
if ! grep -q 'kb_layout' "$CFG_FILE"; then
  echo "Error: cannot find kb_layout in $CFG_FILE" >&2
  exit 1  # error path — config missing required kb_layout directive
fi
# Extract value after `=`, strip quotes/whitespace, then split on comma into array.
kb_layouts=($(grep 'kb_layout[[:space:]]*=' "$CFG_FILE" | head -n1 \
  | sed -E 's/^[^=]*=//; s/["'\''[:space:]]//g' | tr ',' ' '))
count=${#kb_layouts[@]}
# Guard against div-by-zero when no layouts are configured.
[ "$count" -gt 0 ] || {
  echo "Error: no kb_layout entries found in $CFG_FILE" >&2
  exit 1
}

# Get current active window ID
get_win() {
  "$HYPRCTL" activewindow -j | "$JQ" -r '.address // .id'
}

# Get available keyboards
get_keyboards() {
  "$HYPRCTL" devices -j | "$JQ" -r '.keyboards[].name'
}

# Save window-specific layout
save_map() {
  local W=$1 L=$2
  grep -v "^${W}:" "$MAP_FILE" >"$MAP_FILE.tmp"
  echo "${W}:${L}" >>"$MAP_FILE.tmp"
  mv "$MAP_FILE.tmp" "$MAP_FILE"
}

# Load layout for window (fallback to default)
load_map() {
  local W=$1
  local E
  E=$(grep "^${W}:" "$MAP_FILE")
  [[ -n "$E" ]] && echo "${E#*:}" || echo "${kb_layouts[0]}"
}

# Switch layout for all keyboards to layout index
do_switch() {
  local IDX=$1
  for kb in $(get_keyboards); do
    "$HYPRCTL" switchxkblayout "$kb" "$IDX" 2>/dev/null
  done
}

# Toggle layout for current window only
cmd_toggle() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local CUR=$(load_map "$W")
  local i NEXT
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$CUR" ]]; then
      i=$idx
      break
    fi
  done
  NEXT=$(((i + 1) % count))
  do_switch "$NEXT"
  save_map "$W" "${kb_layouts[NEXT]}"
  "$NOTIFY" -u low -i "$ICON" "kb_layout: ${kb_layouts[NEXT]}"
}

# Restore layout on focus
cmd_restore() {
  local W=$(get_win)
  [[ -z "$W" ]] && return
  local LAY=$(load_map "$W")
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$LAY" ]]; then
      do_switch "$idx"
      break
    fi
  done
}

# Listen to focus events and restore window-specific layouts
subscribe() {
  local SOCKET2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  [[ -S "$SOCKET2" ]] || {
    echo "Error: Hyprland socket not found." >&2
return 1
  }

  socat -u UNIX-CONNECT:"$SOCKET2" - | while read -r line; do
    [[ "$line" =~ ^activewindow ]] && cmd_restore
  done
}

# Ensure only one listener
if ! pgrep -f "$SCRIPT_NAME.*--listener" >/dev/null; then
  subscribe --listener &
fi

# CLI
case "$1" in
toggle | "") cmd_toggle ;;
*)
  echo "Usage: $SCRIPT_NAME [toggle]" >&2
  exit 1  # usage error — invalid CLI argument
  ;;
esac

exit 0  # end of script — CLI command dispatched
