#!/usr/bin/env bash
# @path: sys/scripts/SwitchKeyboardLayout.sh
# @author: redskaber
# @date: 2026-08-22
# @description: Cycle keyboard layouts globally (all keyboards).
#
# ARCHITECTURE (Round 105 — capability boundary):
#   - Reads kb_layout list from sys/input.lua (SSOT) via lib/input_config.lua
#     (Lua parser — handles both quoted "us,cn" and unquoted us,de forms)
#   - hyprctl devices -j (JSON query — no Lua API for device listing)
#   - hyprctl switchxkblayout (CLI — no Lua dispatcher for this)
#   - notify-send (notification — no Lua API)
#   Stays in sh; Lua only used for parsing the SSOT config file.
#
# Round 105 fix: replaced broken sed/grep parser (left trailing comma →
# div-by-zero / empty array elements) with proper Lua-aware parser.

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

layout_file="$HYPR_CACHE_DIR/kb_layout"
settings_file="$HYPR_CONFIG_DIR/sys/input.lua"
[ -f "$settings_file" ] || settings_file="$HYPR_CONFIG_DIR/sys/input.conf"
notif_icon="$SWAYNC_IMAGES/ja.png"

# Lua binary path (for input_config.lua parser).
LUA_BIN="${LUA:-lua}"

# Refined ignore list with patterns or specific device names
ignore_patterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
  "Other Device Name"
)

# Read layouts from sys/input.lua via lib/input_config.lua (proper Lua parser).
# Output: space-separated layout names, e.g. "us cn"
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

# Create layout file with default layout if it does not exist
if [ ! -f "$layout_file" ]; then
  default_layout=$(read_layouts | awk '{print $1}')
  default_layout=${default_layout:-"us"}
  echo "$default_layout" >"$layout_file"
fi

current_layout=$(cat "$layout_file")

# Read available layouts into array
read -r -a layout_mapping <<<"$(read_layouts)"

layout_count=${#layout_mapping[@]}
[ "$layout_count" -gt 0 ] || {
  echo "Error: no kb_layout entries found in $settings_file" >&2
  exit 1
}

# Find current layout index and calculate next layout
current_index=0
for ((i = 0; i < layout_count; i++)); do
  if [ "$current_layout" == "${layout_mapping[i]}" ]; then
    current_index=$i
    break
  fi
done

next_index=$(((current_index + 1) % layout_count))
new_layout="${layout_mapping[next_index]}"

# Function to get keyboard names
# SCRIPT-30 fix: propagate hyprctl/jq failure instead of returning empty.
# Callers (change_layout) loop over the output; an empty output used to
# silently succeed (loop body never executed, error_found stayed false).
# Now we return non-zero if hyprctl or jq fails so change_layout can react.
get_keyboard_names() {
  local out
  out=$("$HYPRCTL" devices -j 2>/dev/null | "$JQ" -r '.keyboards[].name' 2>/dev/null)
  if [ -z "$out" ]; then
    return 1
  fi
  printf '%s\n' "$out"
}

# Function to check if a device matches any ignore pattern
is_ignored() {
  local device_name=$1
  for pattern in "${ignore_patterns[@]}"; do
    [[ "$device_name" == *"$pattern"* ]] && return 0
  done
  return 1
}

# Function to change keyboard layout
change_layout() {
  local error_found=false names
  # Capture names up-front so get_keyboard_names failure can be detected
  # (was piped into the while loop, which masked the failure as empty input).
  if ! names=$(get_keyboard_names); then
    echo "Error: failed to enumerate keyboards via hyprctl" >&2
    return 1
  fi
  while read -r name; do
    [ -z "$name" ] && continue
    if is_ignored "$name"; then continue; fi
    "$HYPRCTL" switchxkblayout "$name" "$next_index" 2>/dev/null || error_found=true
  done <<<"$names"
  # SCRIPT-31 fix: replaced `$error_found && return 1` ternary with explicit
  # if/else for clarity (the && short-circuit is fragile if the LHS ever
  # produces output that could fail).
  if $error_found; then
    return 1
  fi
  return 0
}

# Execute layout change and notify
if ! change_layout; then
  dt_notify "kb_layout" "Layout change failed" critical
  exit 1
else
  dt_notify "kb_layout: $new_layout" "" low
fi

echo "$new_layout" >"$layout_file"
exit 0
