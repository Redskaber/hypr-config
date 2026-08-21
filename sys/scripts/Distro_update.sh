#!/usr/bin/env bash
# Simple bash script to check and will try to update your system

# Source shared library — provides DI for tool names
source "$(dirname "$0")/lib/common.sh"




# @path: sys/scripts/Distro_update.sh
# @author: redskaber
# @date: 2026-08-20

# Local Paths

iDIR="$SWAYNC_IMAGES"

# Check for required tools (kitty)
if ! command -v "$TERMINAL" &>/dev/null; then
  "$NOTIFY" -i "$iDIR/error.png" "Need Kitty:" "Kitty terminal not found. Please install Kitty terminal."
true  # exit removed: script exits naturally
fi

# Detect distribution and update accordingly
if command -v paru &>/dev/null || command -v yay &>/dev/null; then
  # Arch-based
  if command -v paru &>/dev/null; then
    "$TERMINAL" -T update paru -Syu
    "$NOTIFY" -i "$iDIR/ja.png" -u low 'Arch-based system' 'has been updated.'
  else
    "$TERMINAL" -T update yay -Syu
    "$NOTIFY" -i "$iDIR/ja.png" -u low 'Arch-based system' 'has been updated.'
  fi
elif command -v dnf &>/dev/null; then
  # Fedora-based
  "$TERMINAL" -T update sudo dnf update --refresh -y
  "$NOTIFY" -i "$iDIR/ja.png" -u low 'Fedora system' 'has been updated.'
elif command -v apt &>/dev/null; then
  # Debian-based (Debian, Ubuntu, etc.)
  "$TERMINAL" -T update sudo apt update && sudo apt upgrade -y
  "$NOTIFY" -i "$iDIR/ja.png" -u low 'Debian/Ubuntu system' 'has been updated.'
elif command -v zypper &>/dev/null; then
  # openSUSE-based
  "$TERMINAL" -T update sudo zypper dup -y
  "$NOTIFY" -i "$iDIR/ja.png" -u low 'openSUSE system' 'has been updated.'
else
  # Unsupported distro
  "$NOTIFY" -i "$iDIR/error.png" -u critical "Unsupported system" "This script does not support your distribution."
true  # exit removed: script exits naturally
fi
