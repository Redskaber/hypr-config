#!/usr/bin/env bash
# RofiBeats - unified, dynamic UI (add, remove, manage, play)
# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"





# @path: sys/scripts/RofiBeats.sh
# @author: redskaber
# @date: 2026-08-20

mDIR="$HOME/Music/"
iDIR="$SWAYNC_ICONS"
rofi_theme="$ROFI_DIR/config-"$ROFI"-Beats.rasi"
rofi_theme_menu="$ROFI_DIR/config-"$ROFI"-Beats-menu.rasi"
music_list="$ROFI_DIR/online_music.list"

mkdir -p "$(dirname "$music_list")"
[[ -f "$music_list" ]] || touch "$music_list"

# Send notification
notification() {
  "$NOTIFY" -u normal -i "$iDIR/music.png" "$@"
}

# Check if mpv is currently playing
music_playing() { pgrep -x "mpv" >/dev/null; }

# Stop all mpv processes except mpvpaper
# Round 104 fix: was `ps aux | grep 'unique-wallpaper-process'` which matches
# nothing (no process is named that). Use pgrep -x mpvpaper to find video
# wallpaper mpv instances (mpvpaper spawns mpv with --mpv-profile=mpvpaper).
stop_music() {
  mpv_pids=$(pgrep -x mpv 2>/dev/null)
  if [ -n "$mpv_pids" ]; then
    # mpvpaper runs mpv as a child; its pids are discoverable via pgrep -x mpvpaper
    # then we walk each mpvpaper pid's children via pgrep -P
    mpvpaper_pids=$(pgrep -x mpvpaper 2>/dev/null)
    mpvpaper_children=""
    for mpp in $mpvpaper_pids; do
      mpvpaper_children="$mpvpaper_children $(pgrep -P "$mpp" 2>/dev/null)"
    done
    for pid in $mpv_pids; do
      # Skip mpv processes that are children of mpvpaper (don't kill video wallpaper)
      skip=false
      for child in $mpvpaper_children; do
        if [ "$pid" = "$child" ]; then skip=true; break; fi
      done
      if [ "$skip" = "false" ]; then
        kill -9 "$pid" 2>/dev/null || true
      fi
    done
    notification "Music stopped"
  fi
}

# Populate local music file list
populate_local_music() {
  local_music=()
  filenames=()
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find -L "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
}

# Play selected local music file
play_local_music() {
  populate_local_music
  choice=$(printf "%s\n" "${filenames[@]}" | "$ROFI" -i -dmenu -config "$rofi_theme" \
    -theme-str 'entry { placeholder: "🎵 Choose Local Music"; }')
  [[ -z "$choice" ]] && exit 1
  for ((i = 0; i < "${#filenames[@]}"; ++i)); do
    if [ "${filenames[$i]}" = "$choice" ]; then
      music_playing && stop_music
      notification "Now Playing:" "$choice"
      mpv --no-video --playlist-start="$i" --loop-playlist "${local_music[@]}"
      break
    fi
  done
}

# Shuffle and play all local music
shuffle_local_music() {
  music_playing && stop_music
  notification "Shuffle Play local music"
  mpv --no-video --shuffle --loop-playlist "$mDIR"
}

# Play selected online music
play_online_music() {
  if [ ! -s "$music_list" ]; then
    "$NOTIFY" -u low -i "$iDIR/music.png" "No online music found" "Add some with Manage Music"
return 0
  fi
  choice=$(awk -F'|' '{print $1}' "$music_list" | sort | "$ROFI" -i -dmenu -config "$rofi_theme" \
    -theme-str 'entry { placeholder: "🌐 Choose Online Station"; }')
  [[ -z "$choice" ]] && exit 1
  link=$(awk -F'|' -v name="$choice" '$1 == name {print $2; exit}' "$music_list")
  [[ -z "$link" ]] && {
    "$NOTIFY" -u low -i "$iDIR/music.png" "URL not found for" "$choice"
return 1
  }
  music_playing && stop_music
  notification "Now Playing:" "$choice"
  mpv --no-video --shuffle "$link"
}

# Manage online music list (add, remove, view)
manage_music() {
  sub_choice=$(printf "Add Music\nRemove Music\nView List" | "$ROFI" -dmenu \
    -config "$rofi_theme_menu" \
    -theme-str 'entry { placeholder: "🛠️ Manage Music List"; }')

  case "$sub_choice" in
  "Add Music")
    name=$("$ROFI" -dmenu -lines 0 -config "$rofi_theme_menu" \
      -theme-str 'entry { placeholder: "🎼 Enter Music Title"; }')
    [[ -z "$name" ]] && return
    url=$("$ROFI" -dmenu -lines 0 -config "$rofi_theme_menu" \
      -theme-str 'entry { placeholder: "🔗 Enter Music URL"; }')
    [[ -z "$url" ]] && return
    echo "$name|$url" >>"$music_list"
    notification "Added" "$name"
    ;;
  "Remove Music")
    entry=$(awk -F'|' '{print $1}' "$music_list" | "$ROFI" -dmenu -config "$rofi_theme_menu" \
      -theme-str 'entry { placeholder: "🗑️ Select Music to Remove"; }')
    [[ -z "$entry" ]] && return
    grep -vF "$entry" "$music_list" >"$music_list.tmp" && mv "$music_list.tmp" "$music_list"
    notification "Removed" "$entry"
    ;;
  "View List")
    # Show only titles, not URLs
    awk -F'|' '{print $1}' "$music_list" | "$ROFI" -dmenu -config "$rofi_theme_menu" \
      -theme-str 'entry { placeholder: "📜 Online Music List"; }' >/dev/null
    ;;
  esac
}

# Main menu
user_choice=$(printf "%s\n" \
  "Play from Online Stations" \
  "Play from Music directory" \
  "Shuffle Play from Music directory" \
  "Stop RofiBeats" \
  "Manage Music List" |
  "$ROFI" -dmenu -config "$rofi_theme_menu" \
    -theme-str 'entry { placeholder: "🎧 RofiBeats Menu"; }')

case "$user_choice" in
"Play from Online Stations") play_online_music ;;
"Play from Music directory") play_local_music ;;
"Shuffle Play from Music directory") shuffle_local_music ;;
"Stop RofiBeats") music_playing && stop_music ;;
"Manage Music List") manage_music ;;
esac
