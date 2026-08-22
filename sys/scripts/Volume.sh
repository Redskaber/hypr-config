#!/usr/bin/env bash
# Source shared library — provides VOLUME_CONTROL, NOTIFY, dt_notify_bypass_dnd, etc.
source "$(dirname "$0")/lib/common.sh"

# @path: sys/scripts/Volume.sh
# @author: redskaber
# @date: 2026-08-20
# @description: Volume controls for audio and mic (uses common.sh for DI)

iDIR="$SWAYNC_ICONS"
sDIR="$HYPR_SCRIPTS_DIR"

# Get Volume (uses VOLUME_CONTROL from deps, not hard-coded pamixer)
get_volume() {
  volume=$("$VOLUME_CONTROL" --get-volume)
  if [[ "$volume" -eq "0" ]]; then
    echo "Muted"
  else
    echo "$volume %"
  fi
}

# Get icons
get_icon() {
  current=$(get_volume)
  if [[ "$current" == "Muted" ]]; then
    echo "$iDIR/volume-mute.png"
  elif [[ "${current%\%}" -le 30 ]]; then
    echo "$iDIR/volume-low.png"
  elif [[ "${current%\%}" -le 60 ]]; then
    echo "$iDIR/volume-mid.png"
  else
    echo "$iDIR/volume-high.png"
  fi
}

# Notify (uses NOTIFY from deps, not hard-coded notify-send)
notify_user() {
  if [[ "$(get_volume)" == "Muted" ]]; then
    "$NOTIFY" -e -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" " Volume:" " Muted"
  else
    "$NOTIFY" -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$(get_icon)" " Volume Level:" " $(get_volume)" &&
      "$sDIR/Sounds.sh" --volume
  fi
}

# Increase Volume
inc_volume() {
  if [ "$("$VOLUME_CONTROL" --get-mute)" == "true" ]; then
    toggle_mute
  else
    "$VOLUME_CONTROL" -i 5 --allow-boost --set-limit 150 && notify_user
  fi
}

# Decrease Volume
dec_volume() {
  if [ "$("$VOLUME_CONTROL" --get-mute)" == "true" ]; then
    toggle_mute
  else
    "$VOLUME_CONTROL" -d 5 && notify_user
  fi
}

# Toggle Mute
toggle_mute() {
  if [ "$("$VOLUME_CONTROL" --get-mute)" == "false" ]; then
    "$VOLUME_CONTROL" -m && "$NOTIFY" -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/volume-mute.png" " Mute"
  elif [ "$("$VOLUME_CONTROL" --get-mute)" == "true" ]; then
    "$VOLUME_CONTROL" -u && "$NOTIFY" -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$(get_icon)" " Volume:" " Switched ON"
  fi
}

# Toggle Mic
toggle_mic() {
  if [ "$("$VOLUME_CONTROL" --default-source --get-mute)" == "false" ]; then
    "$VOLUME_CONTROL" --default-source -m && "$NOTIFY" -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/microphone-mute.png" " Microphone:" " Switched OFF"
  elif [ "$("$VOLUME_CONTROL" --default-source --get-mute)" == "true" ]; then
    # Round 104: was `-u --default-source u` (stray trailing 'u' typo). Use `--default-source -u`.
    "$VOLUME_CONTROL" --default-source -u && "$NOTIFY" -e -u low -h boolean:SWAYNC_BYPASS_DND:true -i "$iDIR/microphone.png" " Microphone:" " Switched ON"
  fi
}

# Get Mic Icon
get_mic_icon() {
  current=$("$VOLUME_CONTROL" --default-source --get-volume)
  if [[ "$current" -eq "0" ]]; then
    echo "$iDIR/microphone-mute.png"
  else
    echo "$iDIR/microphone.png"
  fi
}

# Get Microphone Volume
get_mic_volume() {
  volume=$("$VOLUME_CONTROL" --default-source --get-volume)
  if [[ "$volume" -eq "0" ]]; then
    echo "Muted"
  else
    echo "$volume %"
  fi
}

# Notify for Microphone
notify_mic_user() {
  volume=$(get_mic_volume)
  icon=$(get_mic_icon)
  "$NOTIFY" -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -h boolean:SWAYNC_BYPASS_DND:true -u low -i "$icon" " Mic Level:" " $volume"
}

# Increase MIC Volume
inc_mic_volume() {
  if [ "$("$VOLUME_CONTROL" --default-source --get-mute)" == "true" ]; then
    toggle_mic
  else
    "$VOLUME_CONTROL" --default-source -i 5 && notify_mic_user
  fi
}

# Decrease MIC Volume
dec_mic_volume() {
  if [ "$("$VOLUME_CONTROL" --default-source --get-mute)" == "true" ]; then
    toggle_mic
  else
    "$VOLUME_CONTROL" --default-source -d 5 && notify_mic_user
  fi
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
  get_volume
elif [[ "$1" == "--inc" ]]; then
  inc_volume
elif [[ "$1" == "--dec" ]]; then
  dec_volume
elif [[ "$1" == "--toggle" ]]; then
  toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
  toggle_mic
elif [[ "$1" == "--get-icon" ]]; then
  get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
  get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
  inc_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
  dec_mic_volume
else
  get_volume
fi

