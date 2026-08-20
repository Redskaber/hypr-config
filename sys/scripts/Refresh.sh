#!/usr/bin/env bash
# sys/scripts/Refresh.sh — Restart bar, notification daemon, and optional user scripts.
# Called after theme changes (wallust), layout switches, or GameMode exit.

SCRIPTSDIR="$HOME/.config/hypr/sys/scripts"
UserScripts="$HOME/.config/hypr/user/scripts"

# ── Stop running services ────────────────────────────────────
for proc in waybar rofi swaync; do
    pkill "$proc" 2>/dev/null || true
done

# ── Restart waybar ───────────────────────────────────────────
sleep 0.1
waybar &

# ── Restart swaync ───────────────────────────────────────────
sleep 0.3
swaync >/dev/null 2>&1 &
swaync-client --reload-config

# ── Optional user scripts ────────────────────────────────────
sleep 1
if [ -x "${UserScripts}/RainbowBorders.sh" ]; then
    "${UserScripts}/RainbowBorders.sh" &
fi

exit 0
