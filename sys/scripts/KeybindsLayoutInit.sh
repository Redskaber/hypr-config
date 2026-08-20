#!/usr/bin/env bash
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

set -euo pipefail

LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str')

# Clear all layout-managed binds first
hyprctl keyword unbind SUPER,J || true
hyprctl keyword unbind SUPER,K || true
hyprctl keyword unbind SUPER,O || true

case "$LAYOUT" in
"scrolling")
    # hyprscrolling owns J/K — leave unbound
    ;;
"dwindle")
    hyprctl keyword bind SUPER,J,cyclenext
    hyprctl keyword bind SUPER,K,cyclenext,prev
    hyprctl keyword bind SUPER,O,togglesplit
    ;;
"master"|*)
    hyprctl keyword bind SUPER,J,cyclenext
    hyprctl keyword bind SUPER,K,cyclenext,prev
    ;;
esac
