#!/usr/bin/env bash
# For Hyprlock

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


# Ensure weather cache is up-to-date before locking (Waybar/lockscreen readers)
# WeatherWrap.sh moved to sys/scripts in new arch
weather_script="$HYPR_SCRIPTS_DIR/WeatherWrap.sh"
[[ -x "$weather_script" ]] && bash "$weather_script" >/dev/null 2>&1
loginctl lock-session
