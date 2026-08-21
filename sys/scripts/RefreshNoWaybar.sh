SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
#!/usr/bin/env bash
# sys/scripts/RefreshNoWaybar.sh — Refresh theme without restarting "$BAR".
# Used after wallpaper changes (WallpaperAutoChange, Animations) where "$BAR"
# does not need a full restart.
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


UserScripts="$HYPR_CONFIG_DIR/user/scripts"

# ── Kill rofi if open ────────────────────────────────────────
pkill "$ROFI" 2>/dev/null || true

# ── Regenerate wallust color templates ───────────────────────
"${SCRIPTSDIR}/WallustSwww.sh"
sleep 0.2

# ── Reload swaync ────────────────────────────────────────────
"$NOTIFICATION"-client --reload-config

# ── Optional user scripts ────────────────────────────────────
sleep 1
if [ -x "${UserScripts}/RainbowBorders.sh" ]; then
    "${UserScripts}/RainbowBorders.sh" &
fi

exit 0

