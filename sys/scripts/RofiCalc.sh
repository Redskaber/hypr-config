#!/usr/bin/env bash
# @path: sys/scripts/RofiCalc.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Interactive rofi calculator using qalc + wl-copy.
#
# ARCHITECTURE (Round 104 — capability boundary):
#   - rofi -dmenu (interactive prompt) → cannot be done in Lua
#   - qalc (calculator engine) → external CLI, no Lua binding
#   - wl-copy (clipboard) → external CLI
#   Stays in sh. State is local to this script (no shared state).
#
# DESIGN: Loop so user can chain calculations. Exit on Escape (rofi returns
#   non-zero) or empty input. Calculation result is copied to clipboard.

# Source shared library — provides DI for tool names (ROFI, WL_COPY, ROFI_DIR, CALCULATOR)
source "$(dirname "$0")/lib/common.sh"

rofi_theme="$ROFI_DIR/config-calc.rasi"
calc_result=""

# Kill rofi if already running (avoid stacking instances)
if pgrep -x "$ROFI" >/dev/null; then
  pkill "$ROFI" 2>/dev/null || true
fi

# Main loop: user enters expression → qalc evaluates → result shown + copied.
# Exit conditions:
#   - rofi returns non-zero (Escape pressed) → break
#   - empty input → break (user done)
while true; do
  result=$(
    "$ROFI" -i -dmenu \
      -config "$rofi_theme" \
      -mesg "Result: $calc_result" \
      -format f 2>/dev/null
  )
  # Exit on Escape (rofi exit code != 0) or empty input
  [ $? -ne 0 ] && break
  [ -z "$result" ] && break

  # Evaluate and copy to clipboard
  if calc_result=$("$CALCULATOR" -t "$result" 2>/dev/null); then
    printf '%s' "$calc_result" | "$WL_COPY"
  else
    calc_result="(error)"
  fi
done

exit 0
