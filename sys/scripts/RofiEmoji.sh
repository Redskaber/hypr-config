#!/usr/bin/env bash
# @path: sys/scripts/RofiEmoji.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Rofi-driven emoji picker. Reads emoji catalog from
#   lib/emoji-data.txt (separated from code so `bash -n` is clean).
#
# DESIGN (Task 104 — capability boundary): Pure presentation logic.
#   - Rofi interaction (rofi -dmenu) → cannot be done in Lua (no GUI API).
#   - wl-copy clipboard write → cannot be done in Lua (no clipboard API).
#   - Stays in sh; data lives in lib/emoji-data.txt (single responsibility).

# Source shared library — provides DI for tool names (ROFI, WL_COPY, ROFI_DIR)
source "$(dirname "$0")/lib/common.sh"

# Emoji data is now a separate file (was inlined, caused bash -n to fail).
EMOJI_DATA_FILE="$(dirname "$0")/lib/emoji-data.txt"
[ -f "$EMOJI_DATA_FILE" ] || {
  dt_notify "RofiEmoji" "emoji data file missing: $EMOJI_DATA_FILE" critical
  return 1 2>/dev/null || exit 1
}

# Rofi theme path (from DI — $ROFI_DIR is SSOT for rofi config root)
rofi_theme="$ROFI_DIR/config-emoji.rasi"
msg='** note ** 👀 Click or Return to choose || Ctrl V to Paste'

# Toggle rofi if already running (avoids stacking instances)
if pidof "$ROFI" >/dev/null; then
  pkill "$ROFI"
fi

# Pipe emoji catalog → rofi → awk (first field = emoji) → wl-copy
"$ROFI" -i -dmenu -mesg "$msg" -config "$rofi_theme" <"$EMOJI_DATA_FILE" |
  awk '{print $1}' |
  head -n 1 |
  tr -d '\n' |
  "$WL_COPY"

exit 0 # end of script — emoji (if any) copied to clipboard
