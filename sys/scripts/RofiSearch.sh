#!/usr/bin/env bash
# RofiSearch.sh — Web search via rofi prompt
#
# Search engine resolution (dependency-inversion / incremental-override pattern):
#   1. user/const.conf  — user override (checked first)
#   2. sys/const.conf   — system default (fallback)
#   3. hard-coded default — last resort
#
# $Search_Engine must contain a URL with '{}' as the query placeholder,
# e.g. "https://www.google.com/search?q={}"

HYPR_DIR="${HOME}/.config/hypr"
USER_CONST="${HYPR_DIR}/user/const.conf"
SYS_CONST="${HYPR_DIR}/sys/const.conf"
FALLBACK_ENGINE="https://www.google.com/search?q={}"

# Extract $Search_Engine from a Hyprland-style conf file.
# Returns empty string if not found.
_read_engine() {
    local file="$1"
    [[ -f "$file" ]] || return
    grep -E '^\$Search_Engine\s*=' "$file" \
        | tail -n1 \
        | sed -E 's/^\$Search_Engine\s*=\s*//' \
        | tr -d '"' \
        | xargs
}

# Stage 1 — user override
Search_Engine=$(_read_engine "$USER_CONST")

# Stage 2 — system default
if [[ -z "$Search_Engine" ]]; then
    Search_Engine=$(_read_engine "$SYS_CONST")
fi

# Stage 3 — hard-coded fallback (should never be reached in a correct install)
if [[ -z "$Search_Engine" ]]; then
    Search_Engine="$FALLBACK_ENGINE"
fi

# ── Rofi prompt ───────────────────────────────────────────────
rofi_theme="${HOME}/.config/rofi/config-search.rasi"
msg='‼️ **note** ‼️ search via default web browser'

# Kill any existing rofi instance before opening a new one
pkill -x rofi 2>/dev/null

query=$(echo "" | rofi -dmenu -config "$rofi_theme" -mesg "$msg")

[[ -z "$query" ]] && exit 0

url="${Search_Engine/\{\}/${query}}"
xdg-open "$url"
