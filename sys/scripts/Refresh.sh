#!/usr/bin/env bash
# @path: sys/scripts/Refresh.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Restart bar + reload notification daemon config
#
# ARCHITECTURE: Do NOT kill+restart swaync! It's already running (started
# by sys/startup.lua). Killing swaync causes "core dumped" abort.
# Only kill+restart waybar (it handles restart gracefully).
# For swaync, just reload config via swaync-client.

# Source shared library — SSOT paths + DI variables
source "$(dirname "$0")/lib/common.sh"

SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
# Round 104: RainbowBorders.sh lives in $HYPR_SCRIPTS_DIR (sys/scripts/), not
# user/scripts/. The old path silently failed the `[ -x ... ]` test so the
# rainbow borders hook never fired on Refresh.
UserScripts="$HYPR_CONFIG_DIR/user/scripts"

# ── Restart waybar (kill + restart) ───────────────────────────
pkill "$BAR" 2>/dev/null || true
sleep 0.1
"$BAR" &

# ── Reload swaync config (do NOT kill+restart!) ──────────────
# swaync is already running (started by sys/startup.lua).
# Killing it causes abort/core-dump which can crash the session.
"${NOTIFICATION}-client" --reload-config 2>/dev/null || true

# ── Kill rofi if open ────────────────────────────────────────
pkill "$ROFI" 2>/dev/null || true

# ── Optional rainbow borders hook ────────────────────────────
sleep 1
if [ -x "${SCRIPTSDIR}/RainbowBorders.sh" ]; then
    "${SCRIPTSDIR}/RainbowBorders.sh" &
fi
