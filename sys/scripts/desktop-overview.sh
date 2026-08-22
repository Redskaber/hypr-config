#!/usr/bin/env bash
# @path: sys/scripts/desktop-overview.sh
# @author: redskaber
# @date: 2026-08-22
# @description: Toggle desktop overview — try Quickshell IPC, fall back to AGS (no Lua API)
#
# ARCHITECTURE (Round 120):
#   - qs/ags CLI (widget tools — no Lua API for overview toggle)
#   - pgrep/pkill (process management — no Lua API)
#   - notify-send (notification — no Lua API)
#   Stays in sh; uses $QUICKSHELL + $AGS DI vars.
#
# Round 120: replaced hardcoded `qs`/`ags` → $QUICKSHELL/$AGS (DI)

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

# 1) Try Quickshell via IPC (works if QS is running and listening)
if pgrep -x quickshell >/dev/null 2>&1; then
  if "$QUICKSHELL" ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# If QS isn't running, but the CLI exists, try starting it and retry once
if command -v "$QUICKSHELL" >/dev/null 2>&1; then
  "$QUICKSHELL" -c overview >/dev/null 2>&1 &
  sleep 0.6
  if "$QUICKSHELL" ipc -c overview call overview toggle >/dev/null 2>&1; then
    exit 0
  fi
fi

# 2) Fall back to AGS template
if command -v "$AGS" >/dev/null 2>&1; then
  pkill "$ROFI" || true
  if "$AGS" -t 'overview' >/dev/null 2>&1; then
    exit 0
  fi
  # If it failed, try starting AGS daemon then call the template
  "$AGS" >/dev/null 2>&1 &
  sleep 0.6
  if "$AGS" -t 'overview' >/dev/null 2>&1; then
    exit 0
  fi
fi

# If we get here, neither worked
"$NOTIFY" "Overview" "Neither Quickshell nor AGS is available" -u low 2>/dev/null || true
exit 1
