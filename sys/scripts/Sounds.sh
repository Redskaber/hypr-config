#!/usr/bin/env bash
# @path: sys/scripts/Sounds.sh
# @author: redskaber
# @date: 2026-08-22
# @description: Play system sound effects (screenshot/volume/error).
#
# ARCHITECTURE (Round 111):
#   - find + paplay (audio playback — no Lua API)
#   - Reads system sound theme index (freedesktop)
#   Stays in sh.
#
# Round 111 fixes:
#   - Unquoted $sDIR in find (word-splitting on paths with spaces)
#   - Missing error handling on cat "$sDIR/index.theme"
#   - Hardcoded pw-play/pa-play → added AUDIO_PLAYER DI var with fallback
#   - $HOME/.local/share → XDG_DATA_HOME (XDG-aware)

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"

theme="freedesktop" # Set the theme for the system sounds.
mute=false          # Set to true to mute the system sounds.

# Mute individual sounds here.
muteScreenshots=false
muteVolume=false

# Round 111: audio player (pipewire preferred, pulseaudio fallback)
# Can be overridden via $AUDIO_PLAYER env var
AUDIO_PLAYER="${AUDIO_PLAYER:-pw-play}"
AUDIO_PLAYER_FALLBACK="${AUDIO_PLAYER_FALLBACK:-paplay}"

# Exit if the system sounds are muted.
if [[ "$mute" = true ]]; then
  exit 0 # muted — nothing to play (not an error)
fi

# Choose the sound to play.
if [[ "$1" == "--screenshot" ]]; then
  if [[ "$muteScreenshots" = true ]]; then
    exit 0 # screenshot sound muted — nothing to play
  fi
  soundoption="screen-capture.*"
elif [[ "$1" == "--volume" ]]; then
  if [[ "$muteVolume" = true ]]; then
    exit 0 # volume sound muted — nothing to play
  fi
  soundoption="audio-volume-change.*"
elif [[ "$1" == "--error" ]]; then
  if [[ "$muteScreenshots" = true ]]; then
    exit 0 # error sound muted — nothing to play
  fi
  soundoption="dialog-error.*"
else
  echo -e "Available sounds: --screenshot, --volume, --error"
  exit 1 # usage error — invalid sound selector
fi

# Set the directory defaults for system sounds.
if [ -d "/run/current-system/sw/share/sounds" ]; then
  systemDIR="/run/current-system/sw/share/sounds" # NixOS
else
  systemDIR="/usr/share/sounds"
fi
# Round 111: use XDG_DATA_HOME (XDG-aware) instead of hardcoded $HOME/.local/share
userDIR="${XDG_DATA_HOME:-$HOME/.local/share}/sounds"
defaultTheme="freedesktop"

# Prefer the user's theme, but use the system's if it doesn't exist.
sDIR="$systemDIR/$defaultTheme"
if [ -d "$userDIR/$theme" ]; then
  sDIR="$userDIR/$theme"
elif [ -d "$systemDIR/$theme" ]; then
  sDIR="$systemDIR/$theme"
fi

# Get the theme that it inherits (Round 111: error handling for missing index.theme)
if [ ! -f "$sDIR/index.theme" ]; then
  echo "Error: Sound theme index not found at $sDIR/index.theme" >&2
  exit 1
fi
iTheme=$(grep -i "inherits" "$sDIR/index.theme" | cut -d "=" -f 2 | tr -d '[:space:]')
iDIR="$sDIR/../$iTheme"

# Find the sound file and play it.
# Round 111: quoted $sDIR (was unquoted — word-splitting on paths with spaces)
sound_file=$(find -L "$sDIR/stereo" -name "$soundoption" -print -quit 2>/dev/null)
if ! test -f "$sound_file"; then
  sound_file=$(find -L "$iDIR/stereo" -name "$soundoption" -print -quit 2>/dev/null)
  if ! test -f "$sound_file"; then
    sound_file=$(find -L "$userDIR/$defaultTheme/stereo" -name "$soundoption" -print -quit 2>/dev/null)
    if ! test -f "$sound_file"; then
      sound_file=$(find -L "$systemDIR/$defaultTheme/stereo" -name "$soundoption" -print -quit 2>/dev/null)
      if ! test -f "$sound_file"; then
        echo "Error: Sound file not found."
        exit 1 # sound file missing in all searched dirs
      fi
    fi
  fi
fi

# Round 111: use $AUDIO_PLAYER with fallback (was hardcoded pw-play/pa-play)
"$AUDIO_PLAYER" "$sound_file" 2>/dev/null || "$AUDIO_PLAYER_FALLBACK" "$sound_file"
