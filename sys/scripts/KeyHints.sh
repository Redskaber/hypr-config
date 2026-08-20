#!/usr/bin/env bash

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

# Check if rofi or yad is running and kill them if they are
if pidof "$ROFI" >/dev/null; then
  pkill "$ROFI"
fi
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"


if pidof yad >/dev/null; then
  pkill yad
fi

# Launch yad with calculated width and height
GDK_BACKEND=$BACKEND yad \
  --center \
  --title="Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column=Key: \
  --column=Description: \
  --column=Command: \
  --timeout-indicator=bottom \
  "ESC" "close this app" "" " = " "SUPER KEY (Windows Key Button)" "(SUPER KEY)" \
  " SHIFT K" "Searchable Keybinds" "(Search all Keybinds via "$ROFI")" \
  " SHIFT E" "Hyprland Settings Menu" "" \
  "" "" "" \
  " enter" "Terminal" "("$TERMINAL")" \
  " SHIFT enter" "DropDown Terminal" " Q to close" \
  " B" "Launch Browser" "(Default browser)" \
  " A" "Desktop Overview" "(AGS - if opted to install)" \
  " D" "Application Launcher" "("$ROFI"-wayland)" \
  " E" "Open File Manager" "(Thunar)" \
  " S" "Google Search using "$ROFI"" "("$ROFI")" \
  " Q" "close active window" "(not kill)" \
  " Shift Q " "kills an active window" "(kill)" \
  " ALT mouse scroll up/down   " "Desktop Zoom" "Desktop Magnifier" \
  " Alt V" "Clipboard Manager" "("$CLIPBOARD")" \
  " W" "Choose wallpaper" "(Wallpaper Menu)" \
  " Shift W" "Choose wallpaper effects" "(imagemagick + awww)" \
  "CTRL ALT W" "Random wallpaper" "(via awww)" \
  " CTRL ALT B" "Hide/UnHide Waybar" "waybar" \
  " CTRL B" "Choose "$BAR" styles" "("$BAR" styles)" \
  " ALT B" "Choose "$BAR" layout" "("$BAR" layout)" \
  " ALT R" "Reload Waybar "$NOTIFICATION" Rofi" "CHECK NOTIFICATION FIRST!!!" \
  " SHIFT N" "Launch Notification Panel" "swaync Notification Center" \
  " Print" "screenshot" "("$SCREENSHOT")" \
  " Shift Print" "screenshot region" "("$SCREENSHOT" + "$SLURP")" \
  " Shift S" "screenshot region" "(swappy)" \
  " CTRL Print" "screenshot timer 5 secs " "("$SCREENSHOT")" \
  " CTRL SHIFT Print" "screenshot timer 10 secs " "("$SCREENSHOT")" \
  "ALT Print" "Screenshot active window" "active window only" \
  "CTRL ALT P" "power-menu" "("$LOGOUT_MENU")" \
  "CTRL ALT L" "screen lock" "("$LOCK")" \
  "CTRL ALT Del" "Hyprland Exit" "(NOTE: Hyprland Will exit immediately)" \
  " SHIFT F" "Fullscreen" "Toggles to full screen" \
  " CTL F" "Fake Fullscreen" "Toggles to fake full screen" \
  " ALT L" "Toggle Dwindle | Master Layout" "Hyprland Layout" \
  " SPACEBAR" "Toggle float" "single window" \
  " ALT SPACEBAR" "Toggle all windows to float" "all windows" \
  " ALT O" "Toggle Blur" "normal or less blur" \
  " CTRL O" "Toggle Opaque ON or OFF" "on active window only" \
  " Shift A" "Animations Menu" "Choose Animations via "$ROFI"" \
  " CTRL R" "Rofi Themes Menu" "Choose Rofi Themes via "$ROFI"" \
  " CTRL Shift R" "Rofi Themes Menu v2" "Choose Rofi Themes via Theme Selector (modified)" \
  " SHIFT G" "Gamemode! All animations OFF or ON" "toggle" \
  " ALT E" "Rofi Emoticons" "Emoticon" \
  " H" "Launch this Quick Cheat Sheet" "" \
  "" "" "" \
  "More tips: ~/.config/hypr/user/ (user overrides) and ~/.config/hypr/sys/ (system defaults)"
