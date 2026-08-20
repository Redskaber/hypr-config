#!/usr/bin/env bash
# KeyBinds.sh — Searchable keybind display using rofi
# 通解: use hyprctl binds -j (runtime query) instead of parsing .lua files
# This works because Hyprland knows all registered binds at runtime

pkill yad 2>/dev/null || true
if pidof rofi >/dev/null; then pkill rofi; fi

rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='Clicking or ENTER will have NO function (display only)'

# Query registered binds from Hyprland runtime (JSON format)
# hyprctl binds -j returns array of bind objects with:
#   key: key string, modcode: modifier bitmask, desc: description (if bindd)
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required for KeyBinds.sh" >&2
  exit 1
fi

binds_json=$(hyprctl binds -j 2>/dev/null)
if [ -z "$binds_json" ] || [ "$binds_json" = "[]" ]; then
  echo "No keybinds found or Hyprland not running." >&2
  exit 1
fi

# Parse JSON into readable format: "MODS + KEY — DESCRIPTION"
display_keybinds=$(echo "$binds_json" | jq -r '
  .[] | 
  # Convert modcode to modifier names
  (.has_mod? 
    | if . then 
        (if (. & 64) > 0 then "SUPER + " else "" end) +
        (if (. & 8) > 0 then "ALT + " else "" end) +
        (if (. & 4) > 0 then "CTRL + " else "" end) +
        (if (. & 1) > 0 then "SHIFT + " else "" end)
      else "" end
    // ""
  ) as $mods |
  (.key // "unknown") as $key |
  (.desc // .dispatcher // "no description") as $desc |
  ($mods + $key + " — " + $desc)
' 2>/dev/null)

if [ -z "$display_keybinds" ]; then
  echo "Failed to parse keybinds." >&2
  exit 1
fi

# Display with rofi
printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
