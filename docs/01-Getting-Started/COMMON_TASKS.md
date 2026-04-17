# Common Tasks Cheat Sheet

> Quick reference for frequent operations — copy, paste, done!

---

## 📋 Table of Contents

- [Application Management](#application-management)
- [Window Management](#window-management)
- [Workspace Operations](#workspace-operations)
- [System Controls](#system-controls)
- [Configuration Changes](#configuration-changes)
- [Troubleshooting](#troubleshooting)

---

## Application Management

### Open Terminal

```bash
# Keyboard shortcut
Press: SUPER + Return

# Or via command
hyprctl dispatch exec kitty  # Replace with your terminal
```

### Open Application Launcher

```bash
# Keyboard shortcut
Press: SUPER + Space

# Or via command
rofi -show drun
```

### Launch Specific Application

```bash
# Add to user/keybind.conf
bind = $M, F, exec, firefox        # Browser
bind = $M, E, exec, $M_file_manager # File manager
bind = $M, C, exec, code           # VS Code

# Reload after editing
hyprctl reload
```

### Kill Active Window

```bash
# Keyboard shortcut
Press: SUPER + Q

# Or via command
hyprctl dispatch killactive
```

---

## Window Management

### Focus Windows (Vim-style)

```bash
Press: SUPER + H  ← Focus left
Press: SUPER + J  ↓ Focus down
Press: SUPER + K  ↑ Focus up
Press: SUPER + L  → Focus right
```

### Move Windows

```bash
Press: SUPER + Shift + H  ← Move left
Press: SUPER + Shift + J  ↓ Move down
Press: SUPER + Shift + K  ↑ Move up
Press: SUPER + Shift + L  → Move right
```

### Toggle Fullscreen

```bash
# Keyboard shortcut
Press: SUPER + F

# Or via command
hyprctl dispatch fullscreen 1
```

### Toggle Pseudo Mode (Tiling ↔ Floating)

```bash
# Keyboard shortcut
Press: SUPER + P

# Or via command
hyprctl dispatch pseudo
```

### Resize Windows

```bash
Press: SUPER + Ctrl + H/J/K/L  # Resize in directions
Or: Drag window borders with mouse
```

### Change Layout

```bash
# Cycle layouts
Press: SUPER + L

# Or specific layout
hyprctl dispatch layoutmsg cyclingdwindle  # Dwindle
hyprctl dispatch layoutmsg cyclingmaster   # Master
```

### Make Window Float

```bash
# Add rule in user/rules.conf
windowrule = float, match:title ^(MyApp)$

# Or toggle current window
hyprctl dispatch togglefloating
```

### Pin Window to All Workspaces

```bash
# Add rule in user/rules.conf
windowrule = pin, match:class ^(StickyApp)$

# Or toggle current window
hyprctl dispatch pinactive
```

---

## Workspace Operations

### Switch Workspace

```bash
Press: SUPER + 1    # Go to workspace 1
Press: SUPER + 2    # Go to workspace 2
...
Press: SUPER + 9    # Go to workspace 9
Press: SUPER + 0    # Go to workspace 10
```

### Move Window to Workspace

```bash
Press: SUPER + Shift + 1    # Move to workspace 1
Press: SUPER + Shift + 2    # Move to workspace 2
...
Press: SUPER + Shift + 9    # Move to workspace 9
```

### Move to Next/Previous Workspace

```bash
Press: SUPER + Tab          # Next workspace
Press: SUPER + Shift + Tab  # Previous workspace
```

### Create Empty Workspace

```bash
# Hyprland auto-creates workspaces when you switch to them
Press: SUPER + 11  # Creates workspace 11 if it doesn't exist
```

### Rename Workspace

```bash
# Not directly supported in Hyprland
# Use workspace rules instead:
# In user/rules.conf
workspace = 1, monitor:HDMI-A-1  # Workspace 1 on specific monitor
```

---

## System Controls

### Volume Control

```bash
# Increase volume
Press: XF86AudioRaiseVolume
# Or: pactl set-sink-volume @DEFAULT_SINK@ +5%

# Decrease volume
Press: XF86AudioLowerVolume
# Or: pactl set-sink-volume @DEFAULT_SINK@ -5%

# Toggle mute
Press: XF86AudioMute
# Or: pactl set-sink-mute @DEFAULT_SINK@ toggle
```

### Brightness Control (Laptop)

```bash
# Increase brightness
Press: XF86MonBrightnessUp
# Or: brightnessctl set +5%

# Decrease brightness
Press: XF86MonBrightnessDown
# Or: brightnessctl set 5%-
```

### Media Controls

```bash
# Play/Pause
Press: XF86AudioPlay
# Or: playerctl play-pause

# Next track
Press: XF86AudioNext
# Or: playerctl next

# Previous track
Press: XF86AudioPrev
# Or: playerctl previous
```

### Screenshot

```bash
# Full screen
Press: Print
# Saves to: ~/Pictures/Screenshots/

# Select area
Press: SUPER + Print
# Drag to select region

# Current window
Press: SUPER + Shift + Print
# Captures active window
```

### Lock Screen

```bash
# Keyboard shortcut
Press: SUPER + Shift + L

# Or via command
hyprlock
```

### Power Menu

```bash
# Keyboard shortcut
Press: SUPER + Shift + E

# Or via command
wlogout
```

---

## Configuration Changes

### Change Terminal Emulator

```bash
# Edit user/const.conf
nano ~/.config/hypr/user/const.conf

# Add/modify:
$M_terminal = ghostty  # Options: kitty, alacritty, foot, wezterm

# Save and reload
hyprctl reload
```

### Change Keyboard Layout

```bash
# Edit user/input.conf
nano ~/.config/hypr/user/input.conf

# Add:
input {
    kb_layout = us,cn
    kb_options = caps:escape  # Caps Lock as Escape
}

# Reload
hyprctl reload
```

### Change Wallpaper

```bash
# Interactive selection
~/.config/hypr/sys/scripts/WallpaperSelect.sh

# Or set specific wallpaper
swww img ~/Pictures/my-wallpaper.jpg --transition-type fade

# Random wallpaper
~/.config/hypr/sys/scripts/WallpaperRandom.sh
```

### Modify Colors (Wallust)

```bash
# Regenerate colors from current wallpaper
~/.config/hypr/sys/scripts/WallustSwww.sh

# Or switch color scheme manually
# Edit sys/policy/wallust/wallust-hyprland.conf
```

### Add Custom Keybinding

```bash
# Edit user/keybind.conf
nano ~/.config/hypr/user/keybind.conf

# Add your binding:
bind = $M, X, exec, my-command

# Reload
hyprctl reload
```

### Enable/Disable Blur

```bash
# Toggle blur
~/.config/hypr/sys/scripts/ChangeBlur.sh

# Or edit user/decoration.conf
decoration {
    blur {
        enabled = false  # Disable blur
    }
}

# Reload
hyprctl reload
```

### Toggle Night Light

```bash
# Toggle night light
~/.config/hypr/sys/scripts/Hyprsunset.sh

# Or add keybinding
bind = $M SHIFT, S, exec, $S/Hyprsunset.sh
```

### Enable Game Mode

```bash
# Toggle game mode (disables animations, blur)
~/.config/hypr/sys/scripts/GameMode.sh

# Or add keybinding
bind = $M SHIFT, G, exec, $S/GameMode.sh
```

---

## Troubleshooting

### Config Not Reloading

```bash
# Check for syntax errors
hyprctl config 2>&1 | grep -i error

# Fix errors then reload
hyprctl reload

# If still broken, restart Hyprland
killall Hyprland && Hyprland &
```

### Waybar Not Showing

```bash
# Restart waybar
killall waybar && waybar &

# Check waybar status
ps aux | grep waybar

# View waybar logs
journalctl --user -u waybar -f
```

### Wallpaper Not Loading

```bash
# Check if swww is running
ps aux | grep swww

# Initialize swww
swww init

# Set wallpaper manually
swww img ~/.config/hypr/wallpaper_effects/.wallpaper_current
```

### Audio Not Working

```bash
# Check audio devices
pactl list sinks short

# Set default sink
pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo

# Test audio
speaker-test -t wav
```

### Touchpad Not Working

```bash
# List input devices
hyprctl devices

# Enable touchpad (edit user/input.conf)
device {
    name = your-touchpad-name
    enabled = true
}

# Reload
hyprctl reload
```

### Performance Issues (Slow/Laggy)

```bash
# Disable animations temporarily
~/.config/hypr/sys/scripts/Animations.sh

# Or disable blur
~/.config/hypr/sys/scripts/ChangeBlur.sh

# Check resource usage
htop

# Reduce shadow/rendering
# Edit user/render.conf
render {
    direct_scanout = true
}
```

### Keybindings Not Responding

```bash
# Re-initialize layout binds
~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh

# Check active binds
hyprctl binds

# Reload config
hyprctl reload
```

### Monitor Not Detected

```bash
# List monitors
hyprctl monitors

# Force detect
hyprctl reload

# Edit monitor config
nano ~/.config/hypr/sys/hardware/monitors.conf

# Example:
monitor = HDMI-A-1, 1920x1080@60, 0x0, 1
```

---

## Advanced Tasks

### Add Window Rule for Specific App

```bash
# Edit user/rules.conf
nano ~/.config/hypr/user/rules.conf

# Example: Make Discord float and set opacity
windowrule = float, match:class ^(discord)$
windowrule = opacity 0.95 0.90, match:class ^(discord)$
windowrule = move 50% 50%, match:class ^(discord)$

# Reload
hyprctl reload
```

### Create Custom Workspace Assignment

```bash
# Edit user/tags.conf
nano ~/.config/hypr/user/tags.conf

# Assign apps to specific workspaces
windowrule = workspace 1, match:class ^(Firefox)$
windowrule = workspace 2, match:class ^(Code)$
windowrule = workspace 3, match:class ^(Discord)$

# Reload
hyprctl reload
```

### Backup Configuration

```bash
# Create timestamped backup
cp -r ~/.config/hypr ~/.config/hypr.backup.$(date +%Y%m%d_%H%M%S)

# List backups
ls -lh ~/.config/hypr.backup.*
```

### Restore Configuration

```bash
# Remove current config
rm -rf ~/.config/hypr

# Restore from backup
cp -r ~/.config/hypr.backup.20260417_120000 ~/.config/hypr

# Restart Hyprland
killall Hyprland && Hyprland &
```

### Export Current Configuration

```bash
# Export active configuration
hyprctl config > ~/hyprland-config-export.txt

# View exported config
cat ~/hyprland-config-export.txt
```

---

## Quick Reference: Modifier Keys

| Symbol     | Key                 | Example                       |
| ---------- | ------------------- | ----------------------------- |
| `$M`       | SUPER (Windows key) | `$M, Return` = SUPER+Return   |
| `$M SHIFT` | SUPER + Shift       | `$M SHIFT, Q` = SUPER+Shift+Q |
| `$M CTRL`  | SUPER + Ctrl        | `$M CTRL, R` = SUPER+Ctrl+R   |
| `$M ALT`   | SUPER + Alt         | `$M ALT, F4` = SUPER+Alt+F4   |

---

## Quick Reference: Special Keys

| Key Name             | Description     |
| -------------------- | --------------- |
| `Return`             | Enter key       |
| `Space`              | Spacebar        |
| `Tab`                | Tab key         |
| `Escape`             | Esc key         |
| `Print`              | PrintScreen     |
| `F1-F12`             | Function keys   |
| `XF86Audio*`         | Media keys      |
| `XF86MonBrightness*` | Brightness keys |

---

## Need More Help?

- **[Quick Start Guide](QUICK_START.md)** — First-time setup
- **[Troubleshooting Guide](../05-Reference/TROUBLESHOOTING.md)** _(coming soon)_ — Detailed problem solving
- **[Configuration Guide](../04-Implementation/CONFIGURATION_GUIDE.md)** _(coming soon)_ — Complete config reference
- **[Documentation Index](../06-Meta/DOCUMENTATION_INDEX.md)** — Full documentation navigation

---

**Last Updated**: 2026-04-17  
**Read Time**: 15 minutes (reference)  
**Difficulty**: ⭐⭐ Intermediate

