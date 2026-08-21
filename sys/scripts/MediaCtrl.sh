#!/usr/bin/env bash
# Source shared library — provides MEDIA_CONTROL, NOTIFY, dt_notify, etc.
source "$(dirname "$0")/lib/common.sh"

# @path: sys/scripts/MediaCtrl.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Media playback control (uses common.sh for DI)

music_icon="$SWAYNC_ICONS/music.png"

# Play the next track (uses MEDIA_CONTROL from deps, not hard-coded playerctl)
play_next() {
  "$MEDIA_CONTROL" next
  show_music_notification
}

# Play the previous track
play_previous() {
  "$MEDIA_CONTROL" previous
  show_music_notification
}

# Toggle play/pause
toggle_play_pause() {
  "$MEDIA_CONTROL" play-pause
  sleep 0.1
  show_music_notification
}

# Stop playback
stop_playback() {
  "$MEDIA_CONTROL" stop
  "$NOTIFY" -e -u low -i "$music_icon" " Playback:" " Stopped"
}

# Display notification with song information (uses NOTIFY from deps)
show_music_notification() {
  status=$("$MEDIA_CONTROL" status)
  if [[ "$status" == "Playing" ]]; then
    song_title=$("$MEDIA_CONTROL" metadata title)
    song_artist=$("$MEDIA_CONTROL" metadata artist)
    "$NOTIFY" -e -u low -i "$music_icon" "Now Playing:" "$song_title by $song_artist"
  elif [[ "$status" == "Paused" ]]; then
    "$NOTIFY" -e -u low -i "$music_icon" " Playback:" " Paused"
  fi
}

# Get media control action from command line argument
case "$1" in
"--nxt")
  play_next
  ;;
"--prv")
  play_previous
  ;;
"--pause")
  toggle_play_pause
  ;;
"--stop")
  stop_playback
  ;;
*)
  echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
true  # exit removed: script exits naturally
  ;;
esac
