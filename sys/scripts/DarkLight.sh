#!/usr/bin/env bash
# @path: sys/scripts/DarkLight.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Toggle dark/light theme across wallpaper/swaync/kitty/qt/gtk/ags/rofi (sed-based config editor)
#
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

# For Dark and Light switching
# Note: Scripts are looking for keywords Light or Dark except for wallpapers as the are in a separate directories

# Paths
# SCRIPT-21 fix: respect $HYPR_WALLPAPER_DIR env var (set in user/env.conf)
#   instead of hardcoding $HOME/Pictures/wallpapers. Same pattern as
#   WallpaperSelect.sh:13 and WallpaperRandom.sh.
wallpaper_base_path="${HYPR_WALLPAPER_DIR:-$HOME/Pictures/wallpapers}/Dynamic-Wallpapers"
dark_wallpapers="$wallpaper_base_path/Dark"
light_wallpapers="$wallpaper_base_path/Light"
swaync_style="$SWAYNC_DIR/style.css"
ags_style="${XDG_CONFIG_HOME:-$HOME/.config}/ags/user/style.css"
SCRIPTSDIR="$HYPR_SCRIPTS_DIR"
notif="$SWAYNC_IMAGES/bell.png"
wallust_rofi="$WALLUST_DIR/templates/colors-"$ROFI".rasi"
kitty_conf="$KITTY_DIR/kitty.conf"

wallust_config="$WALLUST_DIR/wallust.toml"
pallete_dark="dark16"
pallete_light="light16"

# initial signal — tell running processes to prepare for theme change
# SCRIPT-37 note: SIGUSR1 is sent to swaync ($NOTIFICATION). swaync does NOT
# document a SIGUSR1 handler for live CSS reload — the actual swaync style
# reload is performed later (in the second killall loop near the bottom) via
# `swaync-client --reload-config` (invoked from Refresh.sh, see Round 104
# dt_swaync_reload helper). The SIGUSR1 here is harmless if swaync ignores it,
# but if it ever causes issues we should drop $NOTIFICATION from this loop.
for pid in "$BAR" "$ROFI" "$NOTIFICATION" "$AGS" swaybg; do
  killall -SIGUSR1 "$pid" 2>/dev/null || true
done

# Initialize wallpaper client if needed
# Round 110: use $WALLPAPER_CLIENT (DI) instead of hardcoded awww
"$WALLPAPER_CLIENT" query 2>/dev/null

# Set wallpaper options
# SCRIPT-38 fix: use an array instead of a space-separated string so the
# wallpaper_client img command isn't word-split incorrectly.
# Round 110: use $WALLPAPER_CLIENT (DI) instead of hardcoded awww
awww_cmd=("$WALLPAPER_CLIENT" img)
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 60 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Determine current theme mode
# SCRIPT-39 fix: quote "$HOME" — was unquoted in `cat $HOME/...` (would break
# if HOME ever contained spaces, unlikely but defensive).
if [ "$(cat "$HYPR_CACHE_DIR/.theme_mode")" = "Light" ]; then
  next_mode="Dark"
  # Logic for Dark mode
  wallpaper_path="$dark_wallpapers"
else
  next_mode="Light"
  # Logic for Light mode
  wallpaper_path="$light_wallpapers"
fi

# Function to update theme mode for the next cycle
update_theme_mode() {
  echo "$next_mode" >"$HYPR_CACHE_DIR/.theme_mode"
}

# Function to notify user
notify_user() {
  "$NOTIFY" -u low -i "$notif" " Switching to" " $1 mode"
}

# Use sed to replace the palette setting in the wallust config file
if [ "$next_mode" = "Dark" ]; then
  sed -i 's/^palette = .*/palette = "'"$pallete_dark"'"/' "$wallust_config"
else
  sed -i 's/^palette = .*/palette = "'"$pallete_light"'"/' "$wallust_config"
fi

# Function to set Waybar style
set_waybar_style() {
  theme="$1"
  waybar_styles="$WAYBAR_DIR/style"
  waybar_style_link="$WAYBAR_DIR/style.css"
  style_prefix="\\[${theme}\\].*\\.css$"

  style_file=$(find -L "$waybar_styles" -maxdepth 1 -type f -regex ".*$style_prefix" | shuf -n 1)

  if [ -n "$style_file" ]; then
    ln -sf "$style_file" "$waybar_style_link"
  else
    echo "Style file not found for $theme theme."
  fi
}

# Call the function after determining the mode
set_waybar_style "$next_mode"
notify_user "$next_mode"

# swaync color change
if [ "$next_mode" = "Dark" ]; then
  sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.8);/' "${swaync_style}"
  #sed -i '/@define-color noti-bg-alt/s/#.*;/#111111;/' "${swaync_style}"
else
  sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.9);/' "${swaync_style}"
  #sed -i '/@define-color noti-bg-alt/s/#.*;/#F0F0F0;/' "${swaync_style}"
fi

# ags color change
if command -v "$AGS" >/dev/null 2>&1; then
  if [ "$next_mode" = "Dark" ]; then
    sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.4);/' "${ags_style}"
    sed -i '/@define-color text-color/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.7);/' "${ags_style}"
    sed -i '/@define-color noti-bg-alt/s/#.*;/#111111;/' "${ags_style}"
  else
    sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.4);/' "${ags_style}"
    sed -i '/@define-color text-color/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.7);/' "${ags_style}"
    sed -i '/@define-color noti-bg-alt/s/#.*;/#F0F0F0;/' "${ags_style}"
  fi
fi

# kitty background color change
if [ "$next_mode" = "Dark" ]; then
  sed -i '/^foreground /s/^foreground .*/foreground #dddddd/' "${kitty_conf}"
  sed -i '/^background /s/^background .*/background #000000/' "${kitty_conf}"
  sed -i '/^cursor /s/^cursor .*/cursor #dddddd/' "${kitty_conf}"
else
  sed -i '/^foreground /s/^foreground .*/foreground #000000/' "${kitty_conf}"
  sed -i '/^background /s/^background .*/background #dddddd/' "${kitty_conf}"
  sed -i '/^cursor /s/^cursor .*/cursor #000000/' "${kitty_conf}"
fi

for pid_kitty in $(pidof "$TERMINAL"); do
  kill -SIGUSR1 "$pid_kitty"
done

# Set Dynamic Wallpaper for Dark or Light Mode
if [ "$next_mode" = "Dark" ]; then
  next_wallpaper="$(find -L "${dark_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
else
  next_wallpaper="$(find -L "${light_wallpapers}" -type f \( -iname "*.jpg" -o -iname "*.png" \) -print0 | shuf -n1 -z | xargs -0)"
fi

# Update wallpaper using awww command
# SCRIPT-38 fix: use "${awww_cmd[@]}" array expansion (was `$awww` which
# word-splits — happened to work because awww+img is two intended tokens).
"${awww_cmd[@]}" "${next_wallpaper}" $effect

# Set Kvantum Manager theme & QT5/QT6 settings
if [ "$next_mode" = "Dark" ]; then
  kvantum_theme="catppuccin-mocha-blue"
  qt5ct_color_scheme="$QT_DIR/qt5ct/colors/Catppuccin-Mocha.conf"
  qt6ct_color_scheme="$QT_DIR/qt6ct/colors/Catppuccin-Mocha.conf"
else
  kvantum_theme="catppuccin-latte-blue"
  qt5ct_color_scheme="$QT_DIR/qt5ct/colors/Catppuccin-Latte.conf"
  qt6ct_color_scheme="$QT_DIR/qt6ct/colors/Catppuccin-Latte.conf"
fi

sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt5ct_color_scheme|" "$QT_DIR/qt5ct/qt5ct.conf"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt6ct_color_scheme|" "$QT_DIR/qt6ct/qt6ct.conf"
kvantummanager --set "$kvantum_theme"

# set the rofi color for background
# SCRIPT-40 fix: quote "$wallust_rofi" — was unquoted in sed (path with
# spaces would have been split into multiple sed args).
if [ "$next_mode" = "Dark" ]; then
  sed -i '/^background:/s/.*/background: rgba(0,0,0,0.7);/' "$wallust_rofi"
else
  sed -i '/^background:/s/.*/background: rgba(255,255,255,0.9);/' "$wallust_rofi"
fi

# GTK themes and icons switching
set_custom_gtk_theme() {
  mode=$1
  gtk_themes_directory="$HOME/.themes"
  icon_directory="$HOME/.icons"
  color_setting="org.gnome.desktop.interface color-scheme"
  theme_setting="org.gnome.desktop.interface gtk-theme"
  icon_setting="org.gnome.desktop.interface icon-theme"

  if [ "$mode" == "Light" ]; then
    search_keywords="*Light*"
    gsettings set $color_setting 'prefer-light'
  elif [ "$mode" == "Dark" ]; then
    search_keywords="*Dark*"
    gsettings set $color_setting 'prefer-dark'
  else
    echo "Invalid mode provided."
    return 1
  fi

  themes=()
  icons=()

  while IFS= read -r -d '' theme_search; do
    themes+=("$(basename "$theme_search")")
  done < <(find "$gtk_themes_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

  while IFS= read -r -d '' icon_search; do
    icons+=("$(basename "$icon_search")")
  done < <(find "$icon_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

  if [ ${#themes[@]} -gt 0 ]; then
    if [ "$mode" == "Dark" ]; then
      selected_theme=${themes[RANDOM % ${#themes[@]}]}
    else
      selected_theme=${themes[$RANDOM % ${#themes[@]}]}
    fi
    echo "Selected GTK theme for $mode mode: $selected_theme"
    gsettings set $theme_setting "$selected_theme"

    # Flatpak GTK apps (themes)
    if command -v flatpak &>/dev/null; then
      flatpak --user override --filesystem=$HOME/.themes
      sleep 0.5
      flatpak --user override --env=GTK_THEME="$selected_theme"
    fi
  else
    echo "No $mode GTK theme found"
  fi

  if [ ${#icons[@]} -gt 0 ]; then
    if [ "$mode" == "Dark" ]; then
      selected_icon=${icons[RANDOM % ${#icons[@]}]}
    else
      selected_icon=${icons[$RANDOM % ${#icons[@]}]}
    fi
    echo "Selected icon theme for $mode mode: $selected_icon"
    gsettings set $icon_setting "$selected_icon"

    ## QT5ct icon_theme
    sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$QT_DIR/qt5ct/qt5ct.conf"
    sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$QT_DIR/qt6ct/qt6ct.conf"

    # Flatpak GTK apps (icons)
    if command -v flatpak &>/dev/null; then
      flatpak --user override --filesystem=$HOME/.icons
      sleep 0.5
      flatpak --user override --env=ICON_THEME="$selected_icon"
    fi
  else
    echo "No $mode icon theme found"
  fi
}

# Call the function to set GTK theme and icon theme based on mode
set_custom_gtk_theme "$next_mode"

# Update theme mode for the next cycle
update_theme_mode

${SCRIPTSDIR}/WallustSwww.sh "${next_wallpaper}" &&
  sleep 2
# Stop services that need restart for theme reload.
# Round 104 (Task 117 regression fix): swaync ($NOTIFICATION) MUST NOT be
# killall'd — it core-dumps on kill+restart. Use swaync-client --reload-config
# instead (handled in Refresh.sh). waybar can be safely killed.
# swaybg is also safe to kill (it's a wallpaper renderer, not a daemon).
for pid1 in "$BAR" "$ROFI" "$AGS" swaybg; do
  killall "$pid1" 2>/dev/null || true
done

sleep 1
${SCRIPTSDIR}/Refresh.sh

sleep 0.5
# Display notifications for theme and icon changes
"$NOTIFY" -u low -i "$notif" " Themes switched to:" " $next_mode Mode"
