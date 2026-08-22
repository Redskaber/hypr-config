#!/usr/bin/env bash
# @path: sys/scripts/KillActiveProcess.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Force-kill the active window's process (SIGKILL)

# Source shared library — SSOT paths + DI variables
source "$(dirname "$0")/lib/common.sh"

# Get active window PID via JSON (cleaner than grep/cut)
active_pid=$("$HYPRCTL" activewindow -j 2>/dev/null | "$JQ" -r '.pid // empty')

if [ -n "$active_pid" ] && [ "$active_pid" -gt 0 ]; then
  kill -9 "$active_pid" 2>/dev/null || true
fi
