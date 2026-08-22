#!/usr/bin/env bash
# @path: sys/scripts/Polkit.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Start first available polkit agent from common FHS paths (background exec + disown)
#
# This script starts the first available Polkit agent from a list of possible locations

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

# List of potential Polkit agent file paths

polkit=(
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
  "/usr/libexec/hyprpolkitagent"
  "/usr/lib/hyprpolkitagent"
  "/usr/lib/hyprpolkitagent/hyprpolkitagent"
  "/usr/lib/polkit-kde-authentication-agent-1"
  "/usr/lib/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-mate-authentication-agent-1"
  "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1"
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
)
# Round 113: removed `executed=false` (dead variable — exit 0 on success, exit 1 below)

# Loop through the list of paths
for file in "${polkit[@]}"; do
  if [ -x "$file" ] && [ ! -d "$file" ]; then
    echo "Found: $file — executing..."
    "$file" &
    disown 2>/dev/null || true
    exit 0 # success — polkit agent started
  fi
done

# Fallback message if nothing executed
echo "No valid Polkit agent found. Please install one."
exit 1 # error — no polkit agent available
