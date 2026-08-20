#!/usr/bin/env bash
# @path: sys/scripts/Dropterminal.sh
# @author: redskaber
# @date: 2026-08-20
# @version: 3.0
# @description: Dropdown Terminal — state machine + strategy pattern + pipeline design.
#
# Design patterns applied:
#   1. State Machine  — 3 states (ABSENT / VISIBLE / HIDDEN) with explicit transitions.
#   2. Strategy       — one strategy function per state (create / show / hide).
#   3. Pipeline       — each strategy is a sequential pipeline of atomic Hyprland actions,
#                       each step verified before proceeding to the next.
#
# State diagram:
#
#     ┌─────────┐  run()   ┌─────────┐  run()   ┌────────┐
#     │ ABSENT  │─────────▶│ VISIBLE │─────────▶│ HIDDEN │
#     │(no term)│ create   │(shown)  │  hide    │(scratch)│
#     └─────────┘          └─────────┘          └────────┘
#          ▲                     │                     │
#          │                     │  run()              │  run()
#          │  process            ▼                     ▼
#          │  killed        ┌─────────┐          ┌─────────┐
#          └────────────────│detected │◀─────────│  show   │
#                           │  ABSENT │          │         │
#                           └─────────┘          └─────────┘
#
# Usage:
#   Dropterminal.sh <terminal_command>
#   Dropterminal.sh -d <terminal_command>   # debug output
#   Dropterminal.sh kitty
#   Dropterminal.sh "kitty -e zsh"
#
# ADDR_FILE format (v3): "<address> <pid> <monitor_name> <terminal_class>"

# ============================================================
# Section 1: Configuration & Constants
# ============================================================
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


DEBUG=false
SPECIAL_WS="special:scratchpad"
ADDR_FILE="/tmp/dropdown_terminal_addr"

# State enum (bash has no enum, use string constants for readability)
STATE_ABSENT="ABSENT"    # no dropdown terminal (ADDR_FILE missing or process dead)
STATE_VISIBLE="VISIBLE"  # dropdown is shown on a normal workspace
STATE_HIDDEN="HIDDEN"    # dropdown is parked in special:scratchpad

# Dropdown geometry (percentages of logical monitor space)
WIDTH_PERCENT=65
HEIGHT_PERCENT=65
Y_PERCENT=10   # X is auto-centered

# Animation
SLIDE_STEPS=5
SLIDE_DOWN_INTERSTEP_SLEEP=0.03   # seconds
SLIDE_UP_INTERSTEP_SLEEP=0.03
SLIDE_PREP_SLEEP=0.05

# Spawn polling
SPAWN_POLL_INTERVAL=0.1   # seconds
SPAWN_POLL_MAX_TRIES=20   # 20 × 0.1s = 2.0s timeout

# ============================================================
# Section 2: Argument Parsing
# ============================================================

if [ "$1" = "-d" ]; then
  DEBUG=true
  shift
fi

TERMINAL_CMD="$1"
TERMINAL_CLASS=$(echo "$TERMINAL_CMD" | awk '{print $1}')

# ============================================================
# Section 3: Utility Functions
# ============================================================

debug_echo() {
  if [ "$DEBUG" = true ]; then
    echo "[DEBUG] $*" >&2
  fi
}

# Validate terminal command argument (called from main, not at top-level —
# this keeps the script sourceable for unit testing).
validate_args() {
  if [ -z "$TERMINAL_CMD" ]; then
    cat >&2 <<EOF
Missing terminal command. Usage: $0 [-d] <terminal_command>
Examples:
  $0 "$TERMINAL"
  $0 -d "$TERMINAL"                      (with debug output)
  $0 '"$TERMINAL" -e zsh'
  $0 '"$TERMINAL" --working-directory /home/user'

State machine:
  ABSENT  + run -> CREATE -> VISIBLE
  VISIBLE + run -> HIDE   -> HIDDEN
  HIDDEN  + run -> SHOW   -> VISIBLE
  (process killed -> detected as ABSENT on next run)

Config knobs (edit in source):
  WIDTH_PERCENT / HEIGHT_PERCENT / Y_PERCENT
EOF
    exit 1
  fi
}

# ============================================================
# Section 4: State File I/O (v3: 4 fields)
# ============================================================

state_read_addr()    { [ -s "$ADDR_FILE" ] && cut -d' ' -f1 "$ADDR_FILE"; }
state_read_pid()     { [ -s "$ADDR_FILE" ] && cut -d' ' -f2 "$ADDR_FILE"; }
state_read_monitor() { [ -s "$ADDR_FILE" ] && cut -d' ' -f3 "$ADDR_FILE"; }
state_read_class()   { [ -s "$ADDR_FILE" ] && cut -d' ' -f4 "$ADDR_FILE"; }

state_clear() {
  rm -f "$ADDR_FILE"
}

state_save() {
  # $1=addr  $2=pid  $3=monitor  $4=class
  echo "$1 $2 $3 $4" >"$ADDR_FILE"
}

# ============================================================
# Section 5: Hyprland Atomic Actions (pipeline primitives)
#
# Each function is ONE atomic step. Returns 0 on success.
# They are the building blocks composed by strategies below.
# ============================================================

# --- window queries ---

# Returns single JSON line of the window matching addr+pid, or empty.
query_window() {
  local addr="$1" pid="$2"
  "$HYPRCTL" clients -j \
    | "$JQ" -c --arg ADDR "$addr" --argjson PID "$pid" \
        '.[] | select(.address == $ADDR and .pid == $PID)' 2>/dev/null
}

# Echoes "x y w h" of the given window (logical coords), or empty.
query_window_geometry() {
  local addr="$1"
  "$HYPRCTL" clients -j \
    | "$JQ" -r --arg ADDR "$addr" \
        '.[] | select(.address == $ADDR) | "\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"' 2>/dev/null
}

# --- window dispatch actions ---

# Move window to a workspace WITHOUT following focus (silent move).
# This is the Lua equivalent of legacy `movetoworkspacesilent`.
# Per wiki: move({workspace, follow?, window?}) — follow=false keeps focus on current ws.
# Critical for hide(): if focus follows the window into special:scratchpad, the
# active workspace visibly switches, defeating the "hide" illusion.
action_move_to_workspace_silent() {
  local addr="$1" ws="$2"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.move({workspace=\"$ws\",follow=false,window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Move window to a workspace AND follow focus (legacy movetoworkspace).
# Used by strategy_show to bring the dropdown onto the active workspace visibly.
action_move_to_workspace_follow() {
  local addr="$1" ws="$2"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.move({workspace=\"$ws\",follow=true,window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Move window to absolute pixel coords
action_move_pixel() {
  local addr="$1" x="$2" y="$3"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.move({x=$x,y=$y,relative=false,window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Resize window to absolute pixel size
action_resize() {
  local addr="$1" w="$2" h="$3"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.resize({x=$w,y=$h,window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Pin a window (show on all workspaces) — uses EXPLICIT action, never toggle
action_pin_enable() {
  local addr="$1"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.pin({action=\"enable\",window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Unpin a window — uses EXPLICIT action, never toggle
action_pin_disable() {
  local addr="$1"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.pin({action=\"disable\",window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Tag a window (per wiki "Minimize windows using special workspaces" pattern).
# Used so we can address the hidden dropdown by tag instead of address,
# which is more robust against address reuse across Hyprland restarts.
DROPDOWN_TAG="dropdown"
action_tag_dropdown() {
  local addr="$1"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.tag({tag=\"$DROPDOWN_TAG\",window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Clear the dropdown tag from a window
action_clear_tag_dropdown() {
  local addr="$1"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.window.clear_tags({window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Focus a window
action_focus() {
  local addr="$1"
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.focus({window=\"address:$addr\"}))" >/dev/null 2>&1
}

# Execute a command with window rules (float + size + workspace)
action_exec_in_special() {
  # $1=cmd  $2=w  $3=h
  "$HYPRCTL" eval "hl.dispatch(hl.dsp.exec_cmd(\"$1\", {float=true, size={$2,$3}, workspace=\"$SPECIAL_WS silent\"}))" >/dev/null 2>&1
}

# ============================================================
# Section 6: Geometry Pipeline
# ============================================================

# Echoes focused monitor: "x y width height scale name"
get_focused_monitor_info() {
  "$HYPRCTL" monitors -j \
    | "$JQ" -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height) \(.scale) \(.name)"' 2>/dev/null
}

# Echoes "x y w h monitor_name" — computed dropdown position for the focused monitor.
calculate_dropdown_geometry() {
  local mon_info
  mon_info=$(get_focused_monitor_info)
  if [ -z "$mon_info" ] || [ "$mon_info" = "null" ]; then
    debug_echo "Failed to get focused monitor; using fallback 100 100 800 600 fallback"
    echo "100 100 800 600 fallback"
    return 1
  fi

  local mon_x mon_y mon_w mon_h mon_scale mon_name
  read -r mon_x mon_y mon_w mon_h mon_scale mon_name <<<"$mon_info"

  # Sanitize scale
  if [ -z "$mon_scale" ] || [ "$mon_scale" = "null" ] || [ "$mon_scale" = "0" ]; then
    mon_scale="1.0"
  fi

  # Logical size = physical / scale
  local logical_w logical_h
  if command -v bc >/dev/null 2>&1; then
    logical_w=$(echo "scale=0; $mon_w / $mon_scale" | bc | cut -d'.' -f1)
    logical_h=$(echo "scale=0; $mon_h / $mon_scale" | bc | cut -d'.' -f1)
  else
    local scale_int
    scale_int=$(echo "$mon_scale" | sed 's/\.//' | sed 's/^0*//')
    [ -z "$scale_int" ] && scale_int=100
    logical_w=$(( (mon_w * 100) / scale_int ))
    logical_h=$(( (mon_h * 100) / scale_int ))
  fi
  [[ "$logical_w" =~ ^-?[0-9]+$ ]] || logical_w=$mon_w
  [[ "$logical_h" =~ ^-?[0-9]+$ ]] || logical_h=$mon_h

  local w=$(( logical_w * WIDTH_PERCENT  / 100 ))
  local h=$(( logical_h * HEIGHT_PERCENT / 100 ))
  local y_off=$(( logical_h * Y_PERCENT / 100 ))
  local x_off=$(( (logical_w - w) / 2 ))

  local final_x=$(( mon_x + x_off ))
  local final_y=$(( mon_y + y_off ))

  debug_echo "monitor=$mon_name logical=${logical_w}x${logical_h} win=${w}x${h} pos=${final_x},${final_y}"
  echo "$final_x $final_y $w $h $mon_name"
}

# Echoes the id of the currently active workspace
get_current_workspace_id() {
  "$HYPRCTL" activeworkspace -j | "$JQ" -r '.id' 2>/dev/null
}

# ============================================================
# Section 7: Animation Pipeline
# ============================================================

# Slide window DOWN into view from above the screen.
# $1=addr  $2=target_x  $3=target_y  $4=w  $5=h
animate_slide_down() {
  local addr="$1" tx="$2" ty="$3" w="$4" h="$5"
  local start_y=$(( ty - h - 50 ))
  local step=$(( (ty - start_y) / SLIDE_STEPS ))
  local i cy

  action_move_pixel "$addr" "$tx" "$start_y"
  sleep "$SLIDE_PREP_SLEEP"
  for i in $(seq 1 $SLIDE_STEPS); do
    cy=$(( start_y + step * i ))
    action_move_pixel "$addr" "$tx" "$cy"
    sleep "$SLIDE_DOWN_INTERSTEP_SLEEP"
  done
  action_move_pixel "$addr" "$tx" "$ty"   # exact final
}

# Slide window UP out of view toward above the screen.
# $1=addr  $2=cur_x  $3=cur_y  $4=w  $5=h
animate_slide_up() {
  local addr="$1" cx="$2" cy_start="$3" w="$4" h="$5"
  local end_y=$(( cy_start - h - 50 ))
  local step=$(( (cy_start - end_y) / SLIDE_STEPS ))
  local i cy

  for i in $(seq 1 $SLIDE_STEPS); do
    cy=$(( cy_start - step * i ))
    action_move_pixel "$addr" "$cx" "$cy"
    sleep "$SLIDE_UP_INTERSTEP_SLEEP"
  done
}

# ============================================================
# Section 8: State Detection Pipeline
#
#   read state file
#      │
#      ▼
#   addr/pid valid? ──no──▶ ABSENT
#      │yes
#      ▼
#   window alive (addr+pid in clients)? ──no──▶ clear state, ABSENT
#      │yes
#      ▼
#   workspace == special:scratchpad? ──yes──▶ HIDDEN
#      │no
#      ▼
#   VISIBLE
# ============================================================

detect_state() {
  local addr pid win_json workspace_name

  addr=$(state_read_addr)
  pid=$(state_read_pid)

  # Step 1: must have both addr and numeric pid
  if [ -z "$addr" ] || [ -z "$pid" ]; then
    echo "$STATE_ABSENT"; return
  fi
  if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
    state_clear
    echo "$STATE_ABSENT"; return
  fi

  # Step 2: window must still be alive (BOTH addr AND pid must match)
  win_json=$(query_window "$addr" "$pid")
  if [ -z "$win_json" ] || [ "$win_json" = "null" ]; then
    debug_echo "Stored dropdown (addr=$addr pid=$pid) no longer alive — clearing stale state"
    state_clear
    echo "$STATE_ABSENT"; return
  fi

  # Step 3: workspace location determines VISIBLE vs HIDDEN
  workspace_name=$(echo "$win_json" | "$JQ" -r '.workspace.name' 2>/dev/null)
  if [ "$workspace_name" = "$SPECIAL_WS" ]; then
    echo "$STATE_HIDDEN"
  else
    echo "$STATE_VISIBLE"
  fi
}

# ============================================================
# Section 9: Strategy — CREATE (ABSENT → VISIBLE)
#
# Pipeline:
#   1. snapshot existing windows (addr+pid sets)
#   2. exec terminal into special:scratchpad silent
#   3. poll for genuinely new window (3 conditions)
#   4. save state
#   5. move to current workspace + pin enable
#   6. animate slide down + focus
# ============================================================

strategy_create() {
  debug_echo "Strategy: CREATE (ABSENT -> VISIBLE)"

  local pos
  pos=$(calculate_dropdown_geometry)
  local tx ty w h mon_name
  read -r tx ty w h mon_name <<<"$pos"
  debug_echo "geometry: pos=${tx},${ty} size=${w}x${h} mon=$mon_name"

  # 1. Snapshot before-set (all existing addr + pid)
  local before_file before_addrs before_pids
  before_file=$(mktemp /tmp/dt_before.XXXXXX)
  "$HYPRCTL" clients -j | "$JQ" -r '.[] | "\(.address) \(.pid)"' | sort >"$before_file"
  before_addrs=$(cut -d' ' -f1 "$before_file" | sort -u)
  before_pids=$(cut -d' ' -f2 "$before_file" | sort -u)

  # 2. Launch terminal into special workspace (silent, no visible spawn)
  action_exec_in_special "$TERMINAL_CMD" "$w" "$h"

  # 3. Poll for genuinely new window (up to SPAWN_POLL_MAX_TRIES)
  local new_addr="" new_pid="" waited=0
  while [ "$waited" -lt "$SPAWN_POLL_MAX_TRIES" ] && [ -z "$new_addr" ]; do
    sleep "$SPAWN_POLL_INTERVAL"
    waited=$((waited + 1))

    # Iterate over windows currently in special:scratchpad
    while IFS=' ' read -r a p; do
      [ -z "$a" ] && continue
      # Cond 1: address genuinely new
      printf '%s\n' "$before_addrs" | grep -qF -- "$a" && continue
      # Cond 2: pid genuinely new
      printf '%s\n' "$before_pids" | grep -qF -- "$p" && continue
      # Cond 3 satisfied by the jq select(.workspace.name == special) above
      new_addr="$a"; new_pid="$p"; break
    done < <("$HYPRCTL" clients -j \
              | "$JQ" -r ".[] | select(.workspace.name == \"$SPECIAL_WS\") | \"\(.address) \(.pid)\"" 2>/dev/null)
  done
  rm -f "$before_file"

  if [ -z "$new_addr" ] || [ -z "$new_pid" ]; then
    debug_echo "ERROR: no genuinely new dropdown window appeared within $((waited * 100))ms — aborting"
    return 1
  fi
  debug_echo "new dropdown: addr=$new_addr pid=$new_pid class=$TERMINAL_CLASS"

  # 4. Save state
  state_save "$new_addr" "$new_pid" "$mon_name" "$TERMINAL_CLASS"

  # 5. Move to current workspace (follow=true so it appears on active ws) +
  #    tag the window for robust later addressing + pin enable.
  #    Pin must come AFTER the move: pinned windows ignore workspace moves
  #    (wiki: "pinning is ignored for non-floating windows" — but also, a
  #    pinned window stays visible across workspaces, so we pin last).
  sleep 0.2
  local current_ws
  current_ws=$(get_current_workspace_id)
  action_move_to_workspace_follow "$new_addr" "$current_ws"
  action_tag_dropdown "$new_addr"
  action_pin_enable "$new_addr"

  # 6. Animate slide down + focus
  animate_slide_down "$new_addr" "$tx" "$ty" "$w" "$h"
  action_focus "$new_addr"
}

# ============================================================
# Section 10: Strategy — SHOW (HIDDEN → VISIBLE)
#
# Pipeline (per wiki "Minimize windows using special workspaces" pattern):
#   1. read stored state (addr, pid, stored monitor)
#   2. calculate geometry for current monitor
#   3. detect monitor change -> update state file
#   4. move to current workspace (follow=true so it visibly appears)
#   5. pin enable (after move, per pin semantics)
#   6. resize (ensure correct size on the possibly new monitor)
#   7. animate slide down + focus
# ============================================================

strategy_show() {
  debug_echo "Strategy: SHOW (HIDDEN -> VISIBLE)"

  local addr pid stored_mon
  addr=$(state_read_addr)
  pid=$(state_read_pid)
  stored_mon=$(state_read_monitor)

  local pos
  pos=$(calculate_dropdown_geometry)
  local tx ty w h cur_mon
  read -r tx ty w h cur_mon <<<"$pos"

  # 3. Monitor change handling — if user switched focus to another monitor,
  #    reposition the dropdown there and persist the new monitor name.
  if [ -n "$stored_mon" ] && [ "$stored_mon" != "$cur_mon" ]; then
    debug_echo "Monitor changed: $stored_mon -> $cur_mon, repositioning"
    state_save "$addr" "$pid" "$cur_mon" "$TERMINAL_CLASS"
  fi

  # 4. Move to current workspace (follow=true so the dropdown visibly appears).
  #    Per wiki minimize pattern, the window is addressed by tag, but since
  #    we have the addr verified in state, we use addr directly.
  local current_ws
  current_ws=$(get_current_workspace_id)
  action_move_to_workspace_follow "$addr" "$current_ws"
  action_pin_enable "$addr"

  # 5. Resize to ensure correct size on the (possibly new) monitor
  action_resize "$addr" "$w" "$h"

  # 6. Animate slide down + focus
  animate_slide_down "$addr" "$tx" "$ty" "$w" "$h"
  action_focus "$addr"
}

# ============================================================
# Section 11: Strategy — HIDE (VISIBLE → HIDDEN)
#
# Pipeline (per wiki "Minimize windows using special workspaces" pattern):
#   1. read stored state (addr, pid)
#   2. query current window geometry (for animation start point)
#   3. animate slide up (window moves above screen)
#   4. pin disable (MUST happen BEFORE the workspace move — a pinned window
#      is shown on ALL workspaces, so moving it to special:scratchpad would
#      have no visible effect while pinned)
#   5. move to special:scratchpad with follow=false (silent — do NOT switch
#      the active workspace; this is the critical difference from the old code)
# ============================================================

strategy_hide() {
  debug_echo "Strategy: HIDE (VISIBLE -> HIDDEN)"

  local addr pid
  addr=$(state_read_addr)
  pid=$(state_read_pid)

  # 2. Query current geometry for the slide-up animation
  local geom cx cy cw ch
  geom=$(query_window_geometry "$addr")
  if [ -n "$geom" ]; then
    read -r cx cy cw ch <<<"$geom"
    debug_echo "current geometry: ${cx},${cy} ${cw}x${ch}"

    # 3. Animate slide up
    animate_slide_up "$addr" "$cx" "$cy" "$cw" "$ch"
  else
    debug_echo "Could not read geometry; hiding without animation"
  fi

  # 4. Pin disable — MUST come BEFORE the workspace move.
  #    A pinned window is shown on all workspaces, so move(workspace=...) would
  #    have no visible effect while pinned. We unpin first so the subsequent
  #    silent move actually parks the window in special:scratchpad.
  sleep 0.05
  action_pin_disable "$addr"

  # 5. Move to special workspace with follow=false (silent).
  #    follow=false means the active workspace does NOT switch — only the
  #    window moves. This is the Lua equivalent of legacy `movetoworkspacesilent`
  #    and is the key fix for the "terminal doesn't hide properly" bug.
  sleep 0.05
  action_move_to_workspace_silent "$addr" "$SPECIAL_WS"
}

# ============================================================
# Section 12: Main — State Machine Dispatcher
# ============================================================

main() {
  validate_args

  local current_state
  current_state=$(detect_state)
  debug_echo "Detected state: $current_state"

  case "$current_state" in
    "$STATE_ABSENT")
      strategy_create
      ;;
    "$STATE_VISIBLE")
      strategy_hide
      ;;
    "$STATE_HIDDEN")
      strategy_show
      ;;
    *)
      debug_echo "FATAL: unknown state '$current_state'"
      exit 1
      ;;
  esac
}

main "$@"
