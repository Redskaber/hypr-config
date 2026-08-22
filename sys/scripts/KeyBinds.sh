#!/usr/bin/env bash
# @path: sys/scripts/KeyBinds.sh
# @author: redskaber
# @date: 2026-08-20
#
# Source shared library — SSOT paths + DI variables
source "$(dirname "$0")/lib/common.sh"

pkill yad 2>/dev/null || true

# KeyBinds.sh — Searchable keybind display using rofi
# 通解: use hyprctl binds -j (runtime query) instead of parsing .lua files
# This works because Hyprland knows all registered binds at runtime

if pidof "$ROFI" >/dev/null; then pkill "$ROFI"; fi

rofi_theme="$ROFI_DIR/config-keybinds.rasi"
msg='Clicking or ENTER will have NO function (display only)'

# Query registered binds from Hyprland runtime (JSON format)
# hyprctl binds -j returns array of bind objects with:
#   key: key string, modcode: modifier bitmask, desc: description (if bindd)
if ! command -v "$JQ" >/dev/null 2>&1; then
  echo "Error: "$JQ" is required for KeyBinds.sh" >&2
  exit 1
fi

binds_json=$("$HYPRCTL" binds -j 2>/dev/null)
if [ -z "$binds_json" ] || [ "$binds_json" = "[]" ]; then
  echo "No keybinds found or Hyprland not running." >&2
  exit 1
fi

# Parse JSON into readable format: "MODS + KEY — DESCRIPTION"
# Round 104 fix: hyprctl binds -j uses `modmask` (not `has_mod`) and
# `description` (not `desc`). See Hyprland 0.55+ wiki:
# https://wiki.hypr.land/Configuring/Binds/#getting-binds
display_keybinds=$(echo "$binds_json" | "$JQ" -r '
  .[] |
  (.modmask // 0
    | if (. & 64) > 0 then "SUPER + " else "" end) as $super |
  (.modmask // 0
    | if (. & 8)  > 0 then "ALT + "  else "" end) as $alt |
  (.modmask // 0
    | if (. & 4)  > 0 then "CTRL + " else "" end) as $ctrl |
  (.modmask // 0
    | if (. & 1)  > 0 then "SHIFT + " else "" end) as $shift |
  ($super + $alt + $ctrl + $shift) as $mods |
  (.key // "unknown") as $key |
  (.description // .dispatcher // "no description") as $desc |
  ($mods + $key + " — " + $desc)
' 2>/dev/null)

if [ -z "$display_keybinds" ]; then
  echo "Failed to parse keybinds." >&2
  exit 0
fi

# Display with rofi
printf '%s\n' "$display_keybinds" | "$ROFI" -dmenu -i -config "$rofi_theme" -mesg "$msg"
