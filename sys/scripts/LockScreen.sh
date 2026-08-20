#!/usr/bin/env bash
# For Hyprlock

# Ensure weather cache is up-to-date before locking (Waybar/lockscreen readers)
# WeatherWrap.sh moved to sys/scripts in new arch
weather_script="$HOME/.config/hypr/sys/scripts/WeatherWrap.sh"
[[ -x "$weather_script" ]] && bash "$weather_script" >/dev/null 2>&1

loginctl lock-session
