#!/usr/bin/env bash
# @path: sys/scripts/Battery.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Print battery status + capacity for BAT0–BAT3 (reads /sys/class/power_supply)

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

for i in {0..3}; do
  if [ -f /sys/class/power_supply/BAT$i/capacity ]; then
    battery_level=$(cat /sys/class/power_supply/BAT$i/status)
    battery_capacity=$(cat /sys/class/power_supply/BAT$i/capacity)
    echo "Battery: $battery_capacity% ($battery_level)"
  fi
done
