#!/usr/bin/env bash

# @path: sys/scripts/RefreshNoWaybar.sh
# @author: redskaber
# @date: 2026-08-20

SCRIPTSDIR="$HYPR_SCRIPTS_DIR"

# sys/scripts/RefreshNoWaybar.sh — Refresh theme without restarting "$BAR".
# Used after wallpaper changes (WallpaperAutoChange, Animations) where "$BAR"
# does not need a full restart.

UserScripts="$HYPR_CONFIG_DIR/user/scripts"

# ── Kill rofi if open ────────────────────────────────────────
pkill "$ROFI" 2>/dev/null || true

# ── Regenerate wallust color templates ───────────────────────
"${SCRIPTSDIR}/WallustSwww.sh"
sleep 0.2

# ── Reload swaync ────────────────────────────────────────────
"${NOTIFICATION}-client" --reload-config 2>/dev/null || true

# ── Optional user scripts ────────────────────────────────────
sleep 1
if [ -x "${UserScripts}/RainbowBorders.sh" ]; then
    "${UserScripts}/RainbowBorders.sh" &
fi

true  # exit removed: script exits naturally

