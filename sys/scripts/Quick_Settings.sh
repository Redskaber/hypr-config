#!/usr/bin/env bash
# Rofi menu for Hyprland Quick Settings (SUPER SHIFT E)

HYPR_DIR="$HOME/.config/hypr"

# terminal and editor: prefer env vars set via user/env.conf, fall back to defaults
term="${HYPR_TERMINAL:-kitty}"
edit="${EDITOR:-nano}"

# variables
sys_conf="$HYPR_DIR/sys"
user_conf="$HYPR_DIR/user"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
msg=' ⁉️ Choose what to do ⁉️'
iDIR="$HOME/.config/swaync/images"
scriptsDir="$HYPR_DIR/sys/scripts"

# Function to show info notification
show_info() {
  notify-send -i "$iDIR/info.png" "Info" "$1"
}

# Function to display the menu options
menu() {
  cat <<EOF
--- USER CUSTOMIZATIONS ---
Edit User Constants
Edit User ENV variables
Edit User Keybinds
Edit User Layout
Edit User Decorations
Edit User Startup Apps (overlay)
Edit User Window Rules (overlay)
Edit User Input Settings
Edit User Misc Settings
Edit User Animations
Edit User Laptop Settings
--- SYSTEM DEFAULTS  ---
Edit System Default Keybinds
Edit System Default Startup Apps
Edit System Default Window Rules
Edit System Default Settings
--- UTILITIES ---
Choose Kitty Terminal Theme
Configure Monitors (nwg-displays)
Configure Workspace Rules (nwg-displays)
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Toggle Game Mode
Switch Dark-Light Theme
EOF
}

# Main function to handle menu selection
main() {
  choice=$(menu | rofi -i -dmenu -config $rofi_theme -mesg "$msg")

  case "$choice" in
  "Edit User Constants")              file="$user_conf/const.conf" ;;
  "Edit User ENV variables")          file="$user_conf/env.conf" ;;
  "Edit User Keybinds")               file="$user_conf/keybind.conf" ;;
  "Edit User Layout")                 file="$user_conf/layout.conf" ;;
  "Edit User Decorations")            file="$user_conf/decoration.conf" ;;
  "Edit User Startup Apps (overlay)") file="$user_conf/startup.conf" ;;
  "Edit User Window Rules (overlay)") file="$user_conf/rules.conf" ;;
  "Edit User Input Settings")         file="$user_conf/input.conf" ;;
  "Edit User Misc Settings")          file="$user_conf/misc.conf" ;;
  "Edit User Animations")             file="$sys_conf/policy/animations/default.conf" ;;
  "Edit User Laptop Settings")        file="$sys_conf/hardware/laptop.conf" ;;
  "Edit System Default Keybinds")     file="$sys_conf/keybind.conf" ;;
  "Edit System Default Startup Apps") file="$sys_conf/startup.conf" ;;
  "Edit System Default Window Rules") file="$sys_conf/rules.conf" ;;
  "Edit System Default Settings")     file="$sys_conf/misc.conf" ;;
  "Choose Kitty Terminal Theme") $scriptsDir/Kitty_themes.sh ;;
  "Configure Monitors (nwg-displays)")
    if ! command -v nwg-displays &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-displays first"
      exit 1
    fi
    nwg-displays
    ;;
  "Configure Workspace Rules (nwg-displays)")
    if ! command -v nwg-displays &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-displays first"
      exit 1
    fi
    nwg-displays
    ;;
  "GTK Settings (nwg-look)")
    if ! command -v nwg-look &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install nwg-look first"
      exit 1
    fi
    nwg-look
    ;;
  "QT Apps Settings (qt6ct)")
    if ! command -v qt6ct &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt6ct first"
      exit 1
    fi
    qt6ct
    ;;
  "QT Apps Settings (qt5ct)")
    if ! command -v qt5ct &>/dev/null; then
      notify-send -i "$iDIR/error.png" "E-R-R-O-R" "Install qt5ct first"
      exit 1
    fi
    qt5ct
    ;;
  "Choose Hyprland Animations") $scriptsDir/Animations.sh ;;
  "Choose Monitor Profiles")    $scriptsDir/MonitorProfiles.sh ;;
  "Choose Rofi Themes")         $scriptsDir/RofiThemeSelector.sh ;;
  "Search for Keybinds")        $scriptsDir/KeyBinds.sh ;;
  "Toggle Game Mode")           $scriptsDir/GameMode.sh ;;
  "Switch Dark-Light Theme")    $scriptsDir/DarkLight.sh ;;
  *) return ;;
  esac

  if [ -n "$file" ]; then
    $term -e $edit "$file"
  fi
}

# Check if rofi is already running
if pidof rofi >/dev/null; then
  pkill rofi
fi

main
