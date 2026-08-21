#!/usr/bin/env bash
# @path: sys/scripts/RofiSearch.sh
# @author: redskaber
# @date: 2026-08-20
#
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

search_engine="$HYPR_SEARCH_ENGINE"
# RofiSearch.sh — Web search via rofi prompt
#
# Search engine resolution (dependency-inversion / incremental-override pattern):
#   1. user/const.conf  — user override (checked first)
#   2. sys/const.conf   — system default (fallback)
#   3. hard-coded default — last resort
#
# $Search_Engine must contain a URL with '{}' as the query placeholder,
# e.g. "https://www.google.com/search?q={}"

# ── Rofi prompt ───────────────────────────────────────────────
rofi_theme="$ROFI_DIR/config-search.rasi"

# Kill any existing rofi instance before opening a new one
pkill -x "$ROFI" 2>/dev/null

# msg='‼️ **note** ‼️ search via default web browser'
# query=$(echo "" | "$ROFI" -dmenu -config "$rofi_theme" -mesg "$msg")
query=$(echo "" | "$ROFI" -dmenu -config "$rofi_theme")

[[ -z "$query" ]] && exit 0

url="${search_engine/\{\}/${query}}"
xdg-open "$url"
