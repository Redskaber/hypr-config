#!/usr/bin/env bash
# Script for waybar styles
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"





# @path: sys/scripts/WaybarStyles.sh
# @author: redskaber
# @date: 2026-08-20

IFS=$'\n\t'

# Define directories
waybar_styles="$WAYBAR_DIR/style"
waybar_style="$WAYBAR_DIR/style.css"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
rofi_config="$ROFI_DIR/config-"$BAR"-style.rasi"
msg=' 🎌 NOTE: Some "$BAR" STYLES NOT fully compatible with some LAYOUTS'

# Apply selected style
apply_style() {
  ln -sf "$waybar_styles/$1.css" "$waybar_style"
  "${SCRIPTSDIR}/Refresh.sh" &
}

main() {
  # resolve current symlink and strip .css
  current_target=$(readlink -f "$waybar_style")
  current_name=$(basename "$current_target" .css)

  # gather all style names (without .css) into an array
  mapfile -t options < <(
    find -L "$waybar_styles" -maxdepth 1 -type f -name '*.css' \
      -exec basename {} .css \; |
      sort
  )

  # mark the active style and record its index
  default_row=0
  MARKER="👉"
  for i in "${!options[@]}"; do
    if [[ "${options[i]}" == "$current_name" ]]; then
      options[i]="$MARKER ${options[i]}"
      default_row=$i
      break
    fi
  done

  # launch rofi with the annotated list and pre‑selected row
  choice=$(
    printf '%s\n' "${options[@]}" |
      "$ROFI" -i -dmenu \
        -config "$rofi_config" \
        -mesg "$msg" \
        -selected-row "$default_row"
  )

  [[ -z "$choice" ]] && {
    echo "No option selected. Exiting."
return 0
  }

  # remove annotation and apply
  choice=${choice#"$MARKER "}
  apply_style "$choice"
}

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
  pkill "$ROFI"
  #exit 0
fi

main
