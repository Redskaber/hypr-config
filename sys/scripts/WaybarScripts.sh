#!/usr/bin/env bash
# Waybar module launcher — opens terminal apps or file manager.
# terminal and file manager: prefer env vars set via user/env.conf, fall back to defaults.
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


term="${HYPR_TERMINAL:-"$TERMINAL"}"
files="${HYPR_FILE_MANAGER:-"$FILE_MANAGER"}"

# Execute accordingly based on the passed argument
if [[ "$1" == "--btop" ]]; then
    $term --title btop sh -c 'btop'
elif [[ "$1" == "--nvtop" ]]; then
    $term --title nvtop sh -c 'nvtop'
elif [[ "$1" == "--nmtui" ]]; then
    $term nmtui
elif [[ "$1" == "--term" ]]; then
    $term &
elif [[ "$1" == "--files" ]]; then
    $files &
else
    echo "Usage: $0 [--btop | --nvtop | --nmtui | --term | --files]"
fi
