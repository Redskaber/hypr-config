#!/usr/bin/env bash
# sys/scripts/Refresh.sh — Restart bar, notification daemon, and optional user scripts.
# Called after theme changes (wallust), layout switches, or GameMode exit.
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


SCRIPTSDIR="$HOME/.config/hypr/sys/scripts"
UserScripts="$HOME/.config/hypr/user/scripts"

# ── Stop running services ────────────────────────────────────
for proc in "$BAR" "$ROFI" "$NOTIFICATION"; do
    pkill "$proc" 2>/dev/null || true
done

# ── Restart waybar ───────────────────────────────────────────
sleep 0.1
"$BAR" &

# ── Restart swaync ───────────────────────────────────────────
sleep 0.3
"$NOTIFICATION" >/dev/null 2>&1 &
"$NOTIFICATION"-client --reload-config

# ── Optional user scripts ────────────────────────────────────
sleep 1
if [ -x "${UserScripts}/RainbowBorders.sh" ]; then
    "${UserScripts}/RainbowBorders.sh" &
fi

exit 0
