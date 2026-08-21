#!/usr/bin/env bash
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


# @path: sys/scripts/RofiCalc.sh
# @author: redskaber
# @date: 2026-08-20

rofi_theme="$ROFI_DIR/config-calc.rasi"

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
true  # exit removed: script exits naturally
  fi

  if [ -n "$result" ]; then
    calc_result=$(qalc -t "$result")
    echo "$calc_result" | "$WL_COPY"
  fi
done
