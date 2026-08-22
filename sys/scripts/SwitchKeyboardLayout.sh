#!/usr/bin/env bash
# This is for changing kb_layouts. Set kb_layouts in $settings_file
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"





# @path: sys/scripts/SwitchKeyboardLayout.sh
# @author: redskaber
# @date: 2026-08-20

layout_file="$HOME/.cache/kb_layout"
# NOTE: Task 6 migration renamed sys/input.conf → sys/input.lua (Lua API).
# This script still needs the comma-separated kb_layout list as plain text,
# so prefer the .lua file if present, else fall back to .conf for older installs.
if [ -f "$HYPR_CONFIG_DIR/sys/input.lua" ]; then
  settings_file="$HYPR_CONFIG_DIR/sys/input.lua"
else
  settings_file="$HYPR_CONFIG_DIR/sys/input.conf"
fi
notif_icon="$SWAYNC_IMAGES/ja.png"

# Refined ignore list with patterns or specific device names
ignore_patterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
  "Other Device 
  Name"
)

# Create layout file with default layout if it does not exist
if [ ! -f "$layout_file" ]; then
  echo "Creating layout file..."
  # Extract kb_layout value: works for both `kb_layout = us,de` (conf)
  # and `kb_layout = "us,de",` (lua) — pull chars after `=`, strip quotes/spaces.
  default_layout=$(grep 'kb_layout[[:space:]]*=' "$settings_file" | head -n1 \
    | sed -E 's/^[^=]*=//; s/["'\''[:space:]]//g' | cut -d ',' -f 1 2>/dev/null)
  default_layout=${default_layout:-"us"} # Default to 'us' layout
  echo "$default_layout" >"$layout_file"
  echo "Default layout set to $default_layout"
fi

current_layout=$(cat "$layout_file")
echo "Current layout: $current_layout"

# Read available layouts from settings file (works for both .conf and .lua formats).
if [ -f "$settings_file" ]; then
  kb_layout_line=$(grep 'kb_layout[[:space:]]*=' "$settings_file" | head -n1 \
    | sed -E 's/^[^=]*=//; s/["'\''[:space:]]//g')
  # Remove leading and trailing spaces around each layout (already stripped above).
  IFS=',' read -r -a layout_mapping <<<"$kb_layout_line"
else
  echo "Settings file not found!"
  exit 1  # error path — cannot read layout config
fi

layout_count=${#layout_mapping[@]}
echo "Number of layouts: $layout_count"

# Guard against div-by-zero when no layouts are configured.
[ "$layout_count" -gt 0 ] || {
  echo "Error: no kb_layout entries found in $settings_file" >&2
  exit 1
}

# Find current layout index and calculate next layout
for ((i = 0; i < layout_count; i++)); do
  if [ "$current_layout" == "${layout_mapping[i]}" ]; then
    current_index=$i
    break
  fi
done

# Defensive: if current_layout didn't match any entry, start at 0.
current_index=${current_index:-0}

next_index=$(((current_index + 1) % layout_count))
new_layout="${layout_mapping[next_index]}"
echo "Next layout: $new_layout"

# Function to get keyboard names
get_keyboard_names() {
  "$HYPRCTL" devices -j | "$JQ" -r '.keyboards[].name'
}

# Function to check if a device matches any ignore pattern
is_ignored() {
  local device_name=$1
  for pattern in "${ignore_patterns[@]}"; do
    if [[ "$device_name" == *"$pattern"* ]]; then
      return 0 # Device matches ignore pattern
    fi
  done
  return 1 # Device does not match any ignore pattern
}

# Function to change keyboard layout
change_layout() {
  local error_found=false

  while read -r name; do
    if is_ignored "$name"; then
      echo "Skipping ignored device: $name"
      continue
    fi

    echo "Switching layout for $name to $new_layout..."
    "$HYPRCTL" switchxkblayout "$name" "$next_index"
    if [ $? -ne 0 ]; then
      echo "Error while switching layout for $name." >&2
      error_found=true
    fi
  done <<<"$(get_keyboard_names)"

  $error_found && return 1
  return 0
}

# Execute layout change and notify
if ! change_layout; then
  "$NOTIFY" -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
  echo "Layout change failed." >&2
  exit 1  # error path — change_layout returned non-zero
else
  "$NOTIFY" -u low -i "$notif_icon" " kb_layout: $new_layout"
  echo "Layout change notification sent."
fi

echo "$new_layout" >"$layout_file"

exit 0  # end of script — layout switched + state persisted
