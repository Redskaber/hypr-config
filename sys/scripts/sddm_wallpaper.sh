#!/usr/bin/env bash
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"



# @path: sys/scripts/sddm_wallpaper.sh
# @author: redskaber
# @date: 2026-08-20

# SDDM Wallpaper and Wallust Colors Setter

# Extract colors from rofi wallust config

# for the upcoming changes on the simple_sddm_theme

# variables

terminal="${HYPR_TERMINAL:-"$TERMINAL"}"
wallDIR="${HYPR_WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
wallpaper_current="$HYPR_CONFIG_DIR/wallust_effects/.wallpaper_current"
wallpaper_modified="$HYPR_CONFIG_DIR/wallust_effects/.wallpaper_modified"
# Resolve SDDM themes directory (standard paths and NixOS path)
sddm_themes_dir="/usr/share/sddm/themes"
if [ ! -d "$sddm_themes_dir" ] && [ -d "/run/current-system/sw/share/sddm/themes" ]; then
  sddm_themes_dir="/run/current-system/sw/share/sddm/themes"
fi
sddm_simple="$sddm_themes_dir/simple_sddm_2"

# rofi-wallust-sddm colors path
rofi_wallust="$ROFI_DIR/wallust/colors-"$ROFI".rasi"
sddm_theme_conf="$sddm_simple/theme.conf"

# Directory for swaync
iDIR="$SWAYNC_IMAGES"
iDIRi="$SWAYNC_ICONS"

# Parse arguments
mode="effects" # default
if [[ "$1" == "--normal" ]]; then
  mode="normal"
elif [[ "$1" == "--effects" ]]; then
  mode="effects"
fi

color0=$(grep -oP 'color1:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
color1=$(grep -oP 'color0:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
color7=$(grep -oP 'color14:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
color10=$(grep -oP 'color10:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
color12=$(grep -oP 'color12:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
color13=$(grep -oP 'color13:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
foreground=$(grep -oP 'foreground:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")
#background-color=$(grep -oP 'background:\s*\K#[A-Fa-f0-9]+' "$rofi_wallust")

# wallpaper to use
if [[ "$mode" == "normal" ]]; then
  wallpaper_path="$wallpaper_current"
else
  wallpaper_path="$wallpaper_modified"
fi

# Abort on NixOS where this repo doesn't manage SDDM and themes are typically read-only
if hostnamectl 2>/dev/null | grep -q 'Operating System: NixOS'; then
  "$NOTIFY" -i "$iDIR/error.png" "SDDM" "NixOS detected: skipping SDDM background change."
true  # exit removed: script exits naturally
fi

# Launch terminal and apply changes
$terminal -e bash -c "
echo 'Enter your password to update SDDM wallpapers and colors';

# Update the colors in the SDDM config
sudo sed -i \"s/HeaderTextColor=\\\"#.*\\\"/HeaderTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DateTextColor=\\\"#.*\\\"/DateTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/TimeTextColor=\\\"#.*\\\"/TimeTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/DropdownSelectedBackgroundColor=\\\"#.*\\\"/DropdownSelectedBackgroundColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SystemButtonsIconsColor=\\\"#.*\\\"/SystemButtonsIconsColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/SessionButtonTextColor=\\\"#.*\\\"/SessionButtonTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/VirtualKeyboardButtonTextColor=\\\"#.*\\\"/VirtualKeyboardButtonTextColor=\\\"$color13\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightBackgroundColor=\\\"#.*\\\"/HighlightBackgroundColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/LoginFieldTextColor=\\\"#.*\\\"/LoginFieldTextColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordFieldTextColor=\\\"#.*\\\"/PasswordFieldTextColor=\\\"$color12\\\"/\" \"$sddm_theme_conf\"

sudo sed -i \"s/DropdownBackgroundColor=\\\"#.*\\\"/DropdownBackgroundColor=\\\"$color1\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/HighlightTextColor=\\\"#.*\\\"/HighlightTextColor=\\\"$color10\\\"/\" \"$sddm_theme_conf\"

sudo sed -i \"s/PlaceholderTextColor=\\\"#.*\\\"/PlaceholderTextColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/UserIconColor=\\\"#.*\\\"/UserIconColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"
sudo sed -i \"s/PasswordIconColor=\\\"#.*\\\"/PasswordIconColor=\\\"$color7\\\"/\" \"$sddm_theme_conf\"

# Copy wallpaper to SDDM theme
# Primary: set Backgrounds/default (no extension) for simple_sddm_2
sudo cp -f \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default\" || true
# Fallbacks: if theme ships default.jpg or default.png, update those too
if [ -e \"$sddm_simple/Backgrounds/default.jpg\" ]; then
  sudo cp -f \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default.jpg\"
fi
if [ -e \"$sddm_simple/Backgrounds/default.png\" ]; then
  sudo cp -f \"$wallpaper_path\" \"$sddm_simple/Backgrounds/default.png\"
fi

"$NOTIFY" -i \"$iDIR/ja.png\" \"SDDM\" \"Background SET\"
"
