#!/usr/bin/env bash
# @path: sys/scripts/Kitty_themes.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Interactive kitty theme picker via rofi with live preview + SIGUSR1 reload
#
# Kitty Themes Source https://github.com/dexpota/kitty-themes #

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

# Define directories and variables

kitty_themes_DiR="$KITTY_DIR/kitty-themes" # Kitty Themes Directory
kitty_config="$KITTY_DIR/kitty.conf"
iDIR="$SWAYNC_IMAGES" # For notifications
# SCRIPT-49 fix: rofi theme filename used to embed $TERMINAL
# (config-"$TERMINAL"-theme.rasi), which made the script brittle — if the
# user changed const.apps.terminal, the rofi theme would silently break
# (file not found → script exits). Use a fixed, terminal-agnostic name.
# Users upgrading from the old name should rename/symlink their existing
# config-kitty-theme.rasi to config-kitty-themes.rasi.
rofi_theme_for_this_script="$ROFI_DIR/config-kitty-themes.rasi"

# --- Helper Functions ---
notify_user() {
  "$NOTIFY" -u low -i "$1" "$2" "$3"
}

# Function to apply the selected kitty theme
apply_kitty_theme_to_config() {
  local theme_name_to_apply="$1"
  if [ -z "$theme_name_to_apply" ]; then
    echo "Error: No theme name provided to apply_kitty_theme_to_config." >&2
    return 1
  fi
  local theme_file_path_to_apply="$kitty_themes_DiR/$theme_name_to_apply.conf"
  if [ ! -f "$theme_file_path_to_apply" ]; then
    notify_user "$iDIR/error.png" "Error" "Theme file not found: $theme_name_to_apply.conf"
    return 1
  fi

  local temp_kitty_config_file
  temp_kitty_config_file=$(mktemp)
  cp "$kitty_config" "$temp_kitty_config_file"

  if grep -q -E '^[#[:space:]]*include\s+\./kitty-themes/.*\.conf' "$temp_kitty_config_file"; then
    sed -i -E "s|^([#[:space:]]*include\s+\./kitty-themes/).*\.conf|include ./kitty-themes/$theme_name_to_apply.conf|g" "$temp_kitty_config_file"
  else
    if [ -s "$temp_kitty_config_file" ] && [ "$(tail -c1 "$temp_kitty_config_file")" != "" ]; then
      echo >>"$temp_kitty_config_file"
    fi
    echo "include ./kitty-themes/$theme_name_to_apply.conf" >>"$temp_kitty_config_file"
  fi

  cp "$temp_kitty_config_file" "$kitty_config"
  rm "$temp_kitty_config_file"

  for pid_kitty in $(pidof "$TERMINAL"); do
    if [ -n "$pid_kitty" ]; then
      kill -SIGUSR1 "$pid_kitty"
    fi
  done
  return 0
}

# --- Main Script Execution ---

if [ ! -d "$kitty_themes_DiR" ]; then
  notify_user "$iDIR/error.png" "E-R-R-O-R" "Kitty Themes directory not found: $kitty_themes_DiR"
  exit 1
fi

if [ ! -f "$rofi_theme_for_this_script" ]; then
  notify_user "$iDIR/error.png" "Rofi Config Missing" "Rofi theme for Kitty selector not found at: $rofi_theme_for_this_script."
  exit 1
fi

original_kitty_config_content_backup=$(cat "$kitty_config")
# SCRIPT-47 note: command substitution `$(cat ...)` strips trailing newlines,
# so the backup may not byte-exactly match the original. Restores below use
# `printf '%s'` (no added newline) to avoid introducing a spurious extra
# newline that wasn't in the source.

mapfile -t available_theme_names < <(find "$kitty_themes_DiR" -maxdepth 1 -name "*.conf" -type f -printf "%f\n" | sed 's/\.conf$//' | sort)

if [ ${#available_theme_names[@]} -eq 0 ]; then
  notify_user "$iDIR/error.png" "No Kitty Themes" "No .conf files found in $kitty_themes_DiR."
  exit 1
fi

current_selection_index=0
# SCRIPT-48 fix: replaced fragile awk -F regex (which relied on the FS being
# `include ./kitty-themes/` or `.conf` and could break on odd spacing) with
# a more robust grep -E + sed pipeline. Anchors on `include` keyword with
# explicit `[[:space:]]+` separator, allows arbitrary whitespace at line
# start, and extracts the theme name between the path prefix and `.conf`.
current_active_theme_name=$(grep -E '^[[:space:]]*include[[:space:]]+\./kitty-themes/[^[:space:]]+\.conf' "$kitty_config" 2>/dev/null |
  head -n1 |
  sed -E 's|^[[:space:]]*include[[:space:]]+\./kitty-themes/||; s|\.conf[[:space:]]*$||')

if [ -n "$current_active_theme_name" ]; then
  for i in "${!available_theme_names[@]}"; do
    if [[ "${available_theme_names[$i]}" == "$current_active_theme_name" ]]; then
      current_selection_index=$i
      break
    fi
  done
fi

while true; do
  theme_to_preview_now="${available_theme_names[$current_selection_index]}"

  if ! apply_kitty_theme_to_config "$theme_to_preview_now"; then
    printf '%s' "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof "$TERMINAL"); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    notify_user "$iDIR/error.png" "Preview Error" "Failed to apply $theme_to_preview_now. Reverted."
    exit 1
  fi

  rofi_input_list=""
  for theme_name_in_list in "${available_theme_names[@]}"; do
    rofi_input_list+="$theme_name_in_list\n"
  done
  rofi_input_list_trimmed="${rofi_input_list%\\n}"

  chosen_index_from_rofi=$(echo -e "$rofi_input_list_trimmed" |
    "$ROFI" -dmenu -i \
      -format 'i' \
      -p "Kitty Theme" \
      -mesg "Preview: ${theme_to_preview_now} | Enter: Preview | Ctrl+S: Apply & Exit | Esc: Cancel" \
      -config "$rofi_theme_for_this_script" \
      -selected-row "$current_selection_index" \
      -kb-custom-1 "Control+s") # MODIFIED HERE: Changed to Control+s for custom action 1

  rofi_exit_code=$?

  if [ $rofi_exit_code -eq 0 ]; then
    if [[ "$chosen_index_from_rofi" =~ ^[0-9]+$ ]] && [ "$chosen_index_from_rofi" -lt "${#available_theme_names[@]}" ]; then
      current_selection_index="$chosen_index_from_rofi"
    fi
    # SCRIPT-46 fix: removed empty `else :` no-op branch — no action needed
    # when the chosen index is invalid/out-of-range; current_selection_index
    # stays unchanged and the next loop iteration previews the same theme.
  elif [ $rofi_exit_code -eq 1 ]; then
    notify_user "$iDIR/note.png" "Kitty Theme" "Selection cancelled. Reverting to original theme."
    printf '%s' "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof "$TERMINAL"); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  elif [ $rofi_exit_code -eq 10 ]; then # This is the exit code for -kb-custom-1
    notify_user "$iDIR/ja.png" "Kitty Theme Applied" "$theme_to_preview_now"
    break
  else
    notify_user "$iDIR/error.png" "Rofi Error" "Unexpected Rofi exit ($rofi_exit_code). Reverting."
    printf '%s' "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof "$TERMINAL"); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  fi
done

exit 0
