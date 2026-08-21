#!/usr/bin/env bash
# Clipboard Manager. This script uses cliphist, rofi, and wl-copy.

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


# Variables
rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
msg='👀 **note**  CTRL DEL = "$CLIPBOARD" del (entry)   or   ALT DEL - "$CLIPBOARD" wipe (all)'
# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

# Check if rofi is already running
if pidof "$ROFI" >/dev/null; then
  pkill "$ROFI"
fi
while true; do
  result=$(
    "$ROFI" -i -dmenu \
      -kb-custom-1 "Control-Delete" \
      -kb-custom-2 "Alt-Delete" \
      -config $rofi_theme \
      -mesg "$msg" < <("$CLIPBOARD" list)
  )

  case "$?" in
  1)
    exit
    ;;
  0)
    case "$result" in
    "")
      continue
      ;;
    *)
      "$CLIPBOARD" decode <<<"$result" | "$WL_COPY"
      exit
      ;;
    esac
    ;;
  10)
    "$CLIPBOARD" delete <<<"$result"
    ;;
  11)
    "$CLIPBOARD" wipe
    ;;
  esac
done
