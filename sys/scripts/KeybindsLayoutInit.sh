#!/usr/bin/env bash
# DEPRECATED: This script is replaced by the Lua state machine module (sys/statemachine/).
# Kept for reference only. Do not use — the SM module is called directly via hl.bind().
# sys/scripts/KeybindsLayoutInit.sh — Initialize layout-aware keybinds on startup.
#
# Called once at startup (exec-once in sys/startup.conf).
# Reads the current layout and sets J/K + O binds accordingly,
# matching the same logic used by ChangeLayout.sh.
#
# J/K ownership:
#   scrolling — unbound; hyprscrolling plugin handles column navigation
#   dwindle   — cyclenext/prev + SUPER+O togglesplit
#   master    — cyclenext/prev (no SUPER+O)
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


set -euo pipefail

LAYOUT=$("$HYPRCTL" -j getoption general:layout | "$JQ" -r '.str')

# Clear all layout-managed binds first
"$HYPRCTL" keyword unbind SUPER,J || true
"$HYPRCTL" keyword unbind SUPER,K || true
"$HYPRCTL" keyword unbind SUPER,O || true

case "$LAYOUT" in
"scrolling")
    # hyprscrolling owns J/K — leave unbound
    ;;
"dwindle")
    "$HYPRCTL" keyword bind SUPER,J,cyclenext
    "$HYPRCTL" keyword bind SUPER,K,cyclenext,prev
    "$HYPRCTL" keyword bind SUPER,O,togglesplit
    ;;
"master"|*)
    "$HYPRCTL" keyword bind SUPER,J,cyclenext
    "$HYPRCTL" keyword bind SUPER,K,cyclenext,prev
    ;;
esac
