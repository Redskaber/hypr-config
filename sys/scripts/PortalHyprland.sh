#!/usr/bin/env bash
# @path: sys/scripts/PortalHyprland.sh
# @author: redskaber
# @date: 2026-08-22
# @description: Restart xdg-desktop-portal-hyprland (manual portal restart).
#
# ARCHITECTURE (Round 113):
#   - killall + background exec (process management — no Lua API)
#   - System binary paths (/usr/lib, /usr/libexec) — standard FHS locations
#   Stays in sh.
#
# Round 113 fixes:
#   - killall without || true (errors when process not running) → added || true
#   - Hardcoded /usr/lib + /usr/libexec paths → command -v check with fallback
#   - Background processes without disown → added disown
#   - Missing error handling → graceful degradation

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

sleep 1
# Kill existing portal processes (|| true: OK if not running)
killall xdg-desktop-portal-hyprland 2>/dev/null || true
killall xdg-desktop-portal-wlr 2>/dev/null || true
killall xdg-desktop-portal-gnome 2>/dev/null || true
killall xdg-desktop-portal 2>/dev/null || true
sleep 1

# Start xdg-desktop-portal-hyprland (try common paths, fall back to PATH)
# Round 113: use command -v instead of hardcoded /usr/lib + /usr/libexec
portal_hyprland=""
for candidate in \
  "/usr/libexec/xdg-desktop-portal-hyprland" \
  "/usr/lib/xdg-desktop-portal-hyprland" \
  "$(command -v xdg-desktop-portal-hyprland 2>/dev/null)"; do
  if [ -x "$candidate" ]; then
    portal_hyprland="$candidate"
    break
  fi
done
if [ -n "$portal_hyprland" ]; then
  "$portal_hyprland" &
  disown 2>/dev/null || true
else
  dt_notify "Portal" "xdg-desktop-portal-hyprland not found" critical
fi

sleep 2

# Start xdg-desktop-portal (try common paths, fall back to PATH)
portal=""
for candidate in \
  "/usr/libexec/xdg-desktop-portal" \
  "/usr/lib/xdg-desktop-portal" \
  "$(command -v xdg-desktop-portal 2>/dev/null)"; do
  if [ -x "$candidate" ]; then
    portal="$candidate"
    break
  fi
done
if [ -n "$portal" ]; then
  "$portal" &
  disown 2>/dev/null || true
else
  dt_notify "Portal" "xdg-desktop-portal not found" critical
fi

exit 0
