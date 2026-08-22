#!/usr/bin/env bash
# @path: sys/scripts/Tak0-Per-Window-Switch.sh
# @author: redskaber
# @date: 2026-08-22
# @description: Per-window keyboard layout switcher (Tak0's design).
#
# ARCHITECTURE (Round 105 — capability boundary):
#   - Reads kb_layout list from sys/input.lua via lib/input_config.lua (Lua parser)
#   - hyprctl activewindow -j (JSON query — no Lua API for active window in sh)
#   - hyprctl devices -j (JSON query — no Lua API for device listing)
#   - hyprctl switchxkblayout (CLI — no Lua dispatcher)
#   - socat (socket listener for Hyprland events — no Lua bridge from sh)
#   - notify-send (notification — no Lua API)
#   Stays in sh; Lua only used for parsing the SSOT config file.
#
# Round 105 fixes:
#   - Replaced broken sed/grep parser with lib/input_config.lua (Lua-aware)
#   - Fixed listener leak: pgrep -f "$SCRIPT_NAME.*--listener" never matched
#     bash subshell → spawned new listener every keybind press. Now uses
#     pidfile-based singleton lock.
#   - Added `disown` + `setsid` for listener to survive parent exit.
#   - Added cleanup trap on listener exit.

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

MAP_FILE="$HYPR_CACHE_DIR/kb_layout_per_window"
settings_file="$HYPR_CONFIG_DIR/sys/input.lua"
[ -f "$settings_file" ] || settings_file="$HYPR_CONFIG_DIR/sys/input.conf"
ICON="$SWAYNC_IMAGES/ja.png"
SCRIPT_NAME="$(basename "$0")"
LUA_BIN="${LUA:-lua}"
PIDFILE="$HYPR_CACHE_DIR/tak0-pws-listener.pid"

# Ensure map file exists
touch "$MAP_FILE"

# Read layouts from sys/input.lua via lib/input_config.lua (proper Lua parser).
read_layouts() {
  local layouts_file="$HYPR_CONFIG_DIR/lib/input_config.lua"
  if [ -f "$layouts_file" ] && command -v "$LUA_BIN" >/dev/null 2>&1; then
    "$LUA_BIN" "$layouts_file" layouts "$settings_file" 2>/dev/null
  else
    # Fallback: legacy sed parser (handles simple cases, may break on trailing comma)
    grep 'kb_layout[[:space:]]*=' "$settings_file" 2>/dev/null | head -n1 |
      sed -E 's/^[^=]*=//; s/["'\''[:space:]]//g; s/,$//' | tr ',' ' '
  fi
}

read -r -a kb_layouts <<<"$(read_layouts)"
count=${#kb_layouts[@]}
[ "$count" -gt 0 ] || {
  echo "Error: no kb_layout entries found in $settings_file" >&2
  exit 1
}

# Get current active window address (stable across title changes)
get_win() {
  "$HYPRCTL" activewindow -j 2>/dev/null | "$JQ" -r '.address // empty'
}

# Get available keyboards
get_keyboards() {
  "$HYPRCTL" devices -j 2>/dev/null | "$JQ" -r '.keyboards[].name'
}

# Save window-specific layout
# SCRIPT-15 fix: wrapped read-modify-write in flock for atomic update (was
#   TOCTOU race: grep>.tmp; echo>>.tmp; mv — concurrent toggles could lose
#   updates or interleave entries).
save_map() {
  local W=$1 L=$2
  (
    flock 9
    grep -v "^${W}:" "$MAP_FILE" >"$MAP_FILE.tmp" 2>/dev/null
    echo "${W}:${L}" >>"$MAP_FILE.tmp"
    mv "$MAP_FILE.tmp" "$MAP_FILE"
  ) 9>"$MAP_FILE.lock"
}

# Load layout for window (fallback to default = kb_layouts[0])
load_map() {
  local W=$1 E
  E=$(grep "^${W}:" "$MAP_FILE" 2>/dev/null)
  if [ -n "$E" ]; then
    echo "${E#*:}"
  else
    echo "${kb_layouts[0]}"
  fi
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
  local W CUR i NEXT
  W=$(get_win)
  [ -z "$W" ] && return
  CUR=$(load_map "$W")
  i=0
  for idx in "${!kb_layouts[@]}"; do
    if [ "${kb_layouts[idx]}" = "$CUR" ]; then
      i=$idx
      break
    fi
  done
  NEXT=$(((i + 1) % count))
  do_switch "$NEXT"
  save_map "$W" "${kb_layouts[NEXT]}"
  dt_notify "kb_layout: ${kb_layouts[NEXT]}" "" low
}

# Restore layout on focus
cmd_restore() {
  local W LAY
  W=$(get_win)
  [ -z "$W" ] && return
  LAY=$(load_map "$W")
  for idx in "${!kb_layouts[@]}"; do
    if [ "${kb_layouts[idx]}" = "$LAY" ]; then
      do_switch "$idx"
      break
    fi
  done
}

# Listen to focus events and restore window-specific layouts.
# Singleton guard: pidfile-based lock prevents multiple listeners.
subscribe() {
  local SOCKET2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  [ -S "$SOCKET2" ] || {
    echo "Error: Hyprland socket not found." >&2
    return 1
  }
  # Cleanup pidfile on exit
  trap 'rm -f "$PIDFILE"' EXIT INT TERM
  echo $$ >"$PIDFILE"
  socat -u UNIX-CONNECT:"$SOCKET2" - 2>/dev/null | while read -r line; do
    [[ "$line" =~ ^activewindow ]] && cmd_restore
  done
}

# Start listener as singleton (pidfile-based lock — Round 105 fix)
start_listener() {
  # Check if listener already running (verify pid is alive)
  if [ -f "$PIDFILE" ]; then
    local old_pid
    old_pid=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
      return # listener already running
    fi
    rm -f "$PIDFILE" # stale pidfile
  fi
  # Start listener in background, detached from parent
  setsid subscribe >/dev/null 2>&1 &
  disown 2>/dev/null || true
}

# CLI
case "$1" in
--listener)
  subscribe
  ;;
toggle | "")
  start_listener
  cmd_toggle
  ;;
*)
  echo "Usage: $SCRIPT_NAME [toggle]" >&2
  exit 1
  ;;
esac

exit 0
