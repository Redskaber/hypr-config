#!/usr/bin/env bash
# @path: sys/scripts/validate_tags.sh
# @author: redskaber
# @date: 2026-08-20
# @version: 1.0
# @description: Detect orphaned tags (defined in tags.lua but no rule in rules.lua)
#
# Tag Completeness Invariant: every tag defined in sys/tags.lua MUST have at
# least one rule in sys/rules.lua. Orphaned tags indicate unfinished work or
# migration leftovers.
#
# Usage:
#   ./validate_tags.sh              # check, exit 1 if orphans
#   ./validate_tags.sh --verbose     # show all tags + rules count
#
# Exit codes:
#   0 — all tags have rules (or no tags defined)
#   1 — orphaned tags found (printed to stderr)
#   2 — configuration error (files missing)

# Source shared library for HYPR_CONFIG_DIR + JQ
source "$(dirname "$0")/lib/common.sh"

# If not installed to ~/.config/hypr, derive from script location
if [ ! -d "$HYPR_CONFIG_DIR" ]; then
  HYPR_CONFIG_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
  TAGS_FILE="$HYPR_CONFIG_DIR/sys/tags.lua"
  RULES_FILE="$HYPR_CONFIG_DIR/sys/rules.lua"
fi

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

TAGS_FILE="$HYPR_CONFIG_DIR/sys/tags.lua"
RULES_FILE="$HYPR_CONFIG_DIR/sys/rules.lua"
USER_TAGS_FILE="$HYPR_CONFIG_DIR/user/tags.lua"
USER_RULES_FILE="$HYPR_CONFIG_DIR/user/rules.lua"

# Check files exist
for f in "$TAGS_FILE" "$RULES_FILE"; do
  if [ ! -f "$f" ]; then
    echo "❌ FATAL: $f not found" >&2
true  # exit removed: script exits naturally
  fi
done

# Extract defined tags (tag = "name") from tags.lua files
defined_tags=$({
  grep -oE 'tag = "[a-z_-]+"' "$TAGS_FILE" 2>/dev/null
  [ -f "$USER_TAGS_FILE" ] && grep -oE 'tag = "[a-z_-]+"' "$USER_TAGS_FILE" 2>/dev/null
} | sed 's/tag = //; s/"//g' | sort -u)

# Extract used tags from rules.lua files.
# Tags are referenced in two ways:
#   1. Direct: match = { tag = "name" }
#   2. Via helper: floating_panel("name", ...) — the helper internally uses match = { tag = tag }
used_tags=$({
  # Direct references
  grep -oE 'tag = "[a-z_-]+"' "$RULES_FILE" 2>/dev/null
  [ -f "$USER_RULES_FILE" ] && grep -oE 'tag = "[a-z_-]+"' "$USER_RULES_FILE" 2>/dev/null
  # Helper references (floating_panel("name", ...))
  grep -oE 'floating_panel\("[a-z_-]+"' "$RULES_FILE" 2>/dev/null
  [ -f "$USER_RULES_FILE" ] && grep -oE 'floating_panel\("[a-z_-]+"' "$USER_RULES_FILE" 2>/dev/null
} | sed -e 's/tag = "//' -e 's/floating_panel("//' -e 's/"//g' | sort -u)

# Verbose output
if [ "$VERBOSE" = "1" ]; then
  echo "=== Defined tags (in tags.lua) ==="
  echo "$defined_tags" | sed 's/^/  /'
  echo
  echo "=== Used tags (in rules.lua match) ==="
  echo "$used_tags" | sed 's/^/  /'
  echo
fi

# Find orphaned tags (defined but not used in any rule)
orphans=$(comm -23 <(echo "$defined_tags") <(echo "$used_tags"))

# Find undefined tags (used in rules but not defined in tags — also a bug)
undefined=$(comm -13 <(echo "$defined_tags") <(echo "$used_tags"))

exit_code=0

if [ -n "$orphans" ]; then
  echo "❌ Orphaned tags (defined but no rule):"
  echo "$orphans" | sed 's/^/  - /' >&2
  exit_code=1
fi

if [ -n "$undefined" ]; then
  echo "⚠️  Undefined tags (used in rules but not defined):"
  echo "$undefined" | sed 's/^/  - /' >&2
  exit_code=${exit_code:-1}
fi

if [ -z "$orphans" ] && [ -z "$undefined" ]; then
  defined_count=$(echo "$defined_tags" | grep -c .)
  echo "✅ All $defined_count tags have corresponding rules"
fi

exit $exit_code
