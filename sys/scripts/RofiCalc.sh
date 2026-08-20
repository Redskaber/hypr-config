#!/usr/bin/env bash
# /* Calculator (using qalculate) and rofi */
# /* Submitted by: https://github.com/JosephArmas */
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


rofi_theme="$HOME/.config/rofi/config-calc.rasi"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
  pkill "$ROFI"
fi

# main function

while true; do
  result=$(
    "$ROFI" -i -dmenu \
      -config $rofi_theme \
      -mesg "$result      =    $calc_result"
  )

  if [ $? -ne 0 ]; then
    exit
  fi

  if [ -n "$result" ]; then
    calc_result=$(qalc -t "$result")
    echo "$calc_result" | "$WL_COPY"
  fi
done
