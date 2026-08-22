#!/usr/bin/env bash
# Source shared library — SSOT paths + DI variables
source "$(dirname "$0")/lib/common.sh"

# @path: sys/scripts/RefreshNoWaybar.sh
# @author: redskaber
# @date: 2026-08-20

SCRIPTSDIR="$HYPR_SCRIPTS_DIR"

# sys/scripts/RefreshNoWaybar.sh — Refresh theme without restarting "$BAR".
# Used after wallpaper changes (WallpaperAutoChange, Animations) where "$BAR"
# does not need a full restart.

# ── Kill rofi if open ────────────────────────────────────────
pkill "$ROFI" 2>/dev/null || true

# ── Regenerate wallust color templates ───────────────────────
"${SCRIPTSDIR}/WallustSwww.sh"
sleep 0.2

# ── Reload swaync ────────────────────────────────────────────
"${NOTIFICATION}-client" --reload-config 2>/dev/null || true

# ── Optional rainbow borders hook ────────────────────────────
# Round 104: was looking at $HYPR_CONFIG_DIR/user/scripts/RainbowBorders.sh
# (non-existent). RainbowBorders.sh lives in $HYPR_SCRIPTS_DIR.
sleep 1
if [ -x "${SCRIPTSDIR}/RainbowBorders.sh" ]; then
    "${SCRIPTSDIR}/RainbowBorders.sh" &
fi

exit 0  # end of script — successful refresh

