#!/usr/bin/env bash
# Copied from Discord post. Thanks to @Zorg

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

# Get id of an active window

active_pid=$("$HYPRCTL" activewindow | grep -o 'pid: [0-9]*' | cut -d' ' -f2)

# Close active window
kill $active_pid

