#!/usr/bin/env bash
# Source shared library — SSOT paths + DI variables
source "$(dirname "$0")/lib/common.sh"

# @path: sys/scripts/UptimeNixOS.sh
# @author: redskaber
# @date: 2026-08-20

if [[ -r /proc/uptime ]]; then

# Script parses /proc/uptime to get the system uptime
# and prints it in a human-readable format
# This is a workaround for system where `uptime` command is taken from coreutils
# where `uptime -p` is not supported

  s=$(</proc/uptime)
  s=${s/.*/}
else
  echo "Error UptimeNixOS.sh: Uptime could not be determined." >&2
  exit 1  # error path — /proc/uptime not readable
fi

d="$((s / 60 / 60 / 24)) days"
h="$((s / 60 / 60 % 24)) hours"
m="$((s / 60 % 60)) minutes"

# Remove plural if < 2.
((${d/ */} == 1)) && d=${d/s/}
((${h/ */} == 1)) && h=${h/s/}
((${m/ */} == 1)) && m=${m/s/}

# Hide empty fields.
((${d/ */} == 0)) && unset d
((${h/ */} == 0)) && unset h
((${m/ */} == 0)) && unset m

uptime=${d:+$d, }${h:+$h, }$m
uptime=${uptime%', '}
uptime=${uptime:-$s seconds}

echo "up $uptime"
