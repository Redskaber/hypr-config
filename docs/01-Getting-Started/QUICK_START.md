# Quick Start Guide

> Get your Hyprland configuration up and running in **5 minutes**

---

## 🎯 Prerequisites

Before starting, ensure you have:

- ✅ **Hyprland** >= 0.52.0 installed
- ✅ **Wayland session** running
- ✅ **Basic packages**: `swww`, `waybar`, `rofi`, `swaync`, `cliphist`

### Check Installation

```bash
# Verify Hyprland is installed
hyprctl version

# Check required packages
which swww waybar rofi swaync cliphist
```

**Missing packages?** Install them:

```bash
# Arch Linux
sudo pacman -S swww waybar rofi swaync cliphist hypridle wallust

# Fedora
sudo dnf install swww waybar rofi swaync cliphist hypridle wallust

# NixOS (add to configuration.nix)
environment.systemPackages = with pkgs; [ swww waybar rofi swaync cliphist hypridle wallust ];
```

---

## 📦 Installation

### Step 1: Backup Existing Config (If Any)

```bash
# Backup current Hyprland config
mv ~/.config/hypr ~/.config/hypr.backup 2>/dev/null || true
```

### Step 2: Install Configuration

```bash
# Clone or copy this configuration
git clone <repository-url> ~/.config/hypr

# Or copy from USB/backup
cp -r /path/to/hypr-config ~/.config/hypr
```

### Step 3: Verify Structure

```bash
# Check key files exist
ls ~/.config/hypr/hyprland.conf
ls ~/.config/hypr/bootstrap/default.conf
ls ~/.config/hypr/sys/const.conf
ls ~/.config/hypr/user/const.conf
```

Expected output: All files should exist.

---

## ⚙️ Initial Configuration

### Step 4: Customize User Constants

Edit `user/const.conf` to match your preferences:

```bash
nano ~/.config/hypr/user/const.conf
```

**Common customizations**:

```bash
# Change terminal emulator
$M_terminal = ghostty    # Options: kitty, alacritty, foot, wezterm

# Change file manager
$M_file_manager = thunar  # Options: nemo, nautilus, dolphin

# Change wallpaper directory
$W = $HOME/Pictures/wallpapers

# Change search engine
$Search_Engine = "https://duckduckgo.com/?q={}"
```

**Save** (`Ctrl+O`, `Enter`) and **exit** (`Ctrl+X`).

### Step 5: Review Hardware Configuration

Check monitor setup:

```bash
# List connected monitors
hyprctl monitors

# Edit hardware config if needed
nano ~/.config/hypr/sys/hardware/monitors.conf
```

**Example** (dual monitor setup):

```bash
monitor = HDMI-A-1, 1920x1080@60, 0x0, 1
monitor = eDP-1, 1920x1080@60, 1920x0, 1
```

---

## 🚀 First Launch

### Step 6: Start Hyprland

**Option A: From TTY**

```bash
# Logout from current session
# Press Ctrl+Alt+F2 to switch to TTY
# Login and run:
Hyprland
```

**Option B: From Display Manager (SDDM/GDM)**

```bash
# Select "Hyprland" session
# Enter password and login
```

### Step 7: Verify Installation

Once Hyprland starts, you should see:

- ✅ Desktop background (wallpaper)
- ✅ Waybar at top/bottom
- ✅ Default terminal window

**Test basic functionality**:

```bash
# Open terminal
Press: SUPER + Return

# Open application launcher
Press: SUPER + Space

# Check Hyprland status
hyprctl version
```

---

## 🎨 First Customization

### Change Wallpaper

```bash
# Select wallpaper interactively
~/.config/hypr/sys/scripts/WallpaperSelect.sh

# Or set specific wallpaper
swww img ~/Pictures/my-wallpaper.jpg --transition-type fade
```

### Modify Keybindings

Edit `user/keybind.conf`:

```bash
nano ~/.config/hypr/user/keybind.conf
```

**Example** (add custom keybinding):

```bash
# Open browser with SUPER+B
bind = $M, B, exec, $M_browser

# Screenshot with PrintScreen
bind = , Print, exec, $S/ScreenShot.sh
```

**Reload config**:

```bash
hyprctl reload
```

### Adjust Layout

```bash
# Switch to dwindle layout
hyprctl dispatch layoutmsg cyclingdwindle

# Switch to master layout
hyprctl dispatch layoutmsg cyclingmaster

# Or use keyboard shortcut
Press: SUPER + L (cycles layouts)
```

---

## 🔧 Common First Tasks

### Task 1: Add Your Favorite Applications

Edit `user/rules.conf` to set window rules:

```bash
nano ~/.config/hypr/user/rules.conf
```

**Example** (make Firefox float):

```bash
windowrule = float, match:class ^(firefox)$
windowrule = size 1200 800, match:class ^(firefox)$
```

### Task 2: Configure Input Devices

Edit `user/input.conf`:

```bash
nano ~/.config/hypr/user/input.conf
```

**Example** (keyboard layout and touchpad):

```bash
input {
    kb_layout = us,cn
    kb_options = caps:escape
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}
```

### Task 3: Enable Night Light

```bash
# Toggle night light
~/.config/hypr/sys/scripts/Hyprsunset.sh

# Or add keybinding in user/keybind.conf
bind = $M SHIFT, S, exec, $S/Hyprsunset.sh
```

---

## 🐛 Troubleshooting First Launch

### Problem 1: Black Screen

**Symptoms**: Hyprland starts but screen is black

**Solutions**:

```bash
# Check if Hyprland is running
ps aux | grep Hyprland

# Check logs
journalctl -u hyprland-session -f

# Try restarting
killall Hyprland && Hyprland
```

### Problem 2: No Waybar

**Symptoms**: Desktop loads but no status bar

**Solutions**:

```bash
# Check if waybar is installed
which waybar

# Start waybar manually
waybar &

# Check waybar config
ls ~/.config/waybar/

# Restart waybar
killall waybar && waybar &
```

### Problem 3: Wrong Keyboard Layout

**Symptoms**: Keyboard types wrong characters

**Solution**:

```bash
# Set layout temporarily
hyprctl keyword input:kb_layout us,cn

# Make permanent (edit user/input.conf)
nano ~/.config/hypr/user/input.conf
# Add: input { kb_layout = us,cn }

# Reload
hyprctl reload
```

### Problem 4: Wallpaper Not Loading

**Symptoms**: Black or default background

**Solutions**:

```bash
# Check if swww is running
ps aux | grep swww

# Initialize swww
swww init

# Set wallpaper manually
swww img ~/.config/hypr/wallpaper_effects/.wallpaper_current

# Auto-start on next boot (already configured in startup.conf)
```

---

## 📚 Next Steps

Congratulations! Your Hyprland configuration is running. Now explore:

### Learn the Basics (15 min)

→ **[Common Tasks](COMMON_TASKS.md)** — Cheat sheet for frequent operations

### Understand Architecture (90 min)

→ **[Three-Layer Constants](../02-Architecture/THREE_LAYER_CONSTANTS.md)** — How customization works  
→ **[Architecture Overview](../02-Architecture/ARCHITECTURE_OVERVIEW.md)** — High-level design

### Advanced Customization (3+ hours)

→ **[Configuration Guide](../04-Implementation/CONFIGURATION_GUIDE.md)** _(coming soon)_  
→ **[Tag System](../03-Core-Systems/TAG_SYSTEM.md)** — Window management  
→ **[State Machines](../03-Core-Systems/STATE_MACHINES.md)** — Runtime behavior

---

## 🎓 Essential Keyboard Shortcuts

| Shortcut                  | Action                              |
| ------------------------- | ----------------------------------- |
| `SUPER + Return`          | Open terminal                       |
| `SUPER + Space`           | Application launcher (Rofi)         |
| `SUPER + Q`               | Close active window                 |
| `SUPER + L`               | Cycle layouts (dwindle/master)      |
| `SUPER + H/J/K/L`         | Navigate windows (vim-style)        |
| `SUPER + Shift + H/J/K/L` | Move windows                        |
| `SUPER + F`               | Toggle fullscreen                   |
| `SUPER + P`               | Toggle pseudo mode                  |
| `SUPER + Tab`             | Switch workspaces                   |
| `SUPER + 1-9`             | Go to workspace 1-9                 |
| `SUPER + Shift + 1-9`     | Move window to workspace 1-9        |
| `SUPER + Shift + E`       | Power menu (logout/reboot/shutdown) |

**Full keybinding reference**: See [CONFIGURATION_GUIDE.md](../04-Implementation/CONFIGURATION_GUIDE.md) _(coming soon)_

---

## 💡 Pro Tips

### Tip 1: Use Incremental Overrides

Never edit `sys/` files directly. Always create corresponding `user/` files with only your changes.

```bash
# GOOD: user/input.conf (only your changes)
input {
    kb_layout = us,cn
}

# BAD: Editing sys/input.conf directly (will be overwritten on update)
```

### Tip 2: Test Changes Safely

```bash
# Test config syntax before reloading
hyprctl config 2>&1 | grep -i error

# If errors found, fix them before:
hyprctl reload
```

### Tip 3: Backup Working Config

```bash
# Create backup of working configuration
cp -r ~/.config/hypr ~/.config/hypr.working.$(date +%Y%m%d)
```

### Tip 4: Read Logs for Debugging

```bash
# View Hyprland logs
journalctl -u hyprland-session -f

# Or check runtime logs
tail -f /tmp/hypr/hyprland.log
```

---

## 🆘 Getting Help

### Documentation

- **[Documentation Index](../06-Meta/DOCUMENTATION_INDEX.md)** — Complete navigation
- **[Troubleshooting Guide](../05-Reference/TROUBLESHOOTING.md)** _(coming soon)_
- **[Design Principles](../02-Architecture/DESIGN_PRINCIPLES.md)** — Why things work this way

### Community

- **GitHub Issues**: Report bugs or ask questions
- **Hyprland Discord**: Real-time support
- **Hyprland Wiki**: General Hyprland documentation

### Quick Diagnostics

```bash
# Generate system info for bug reports
hyprctl version
hyprctl monitors
hyprctl devices
neofetch  # or fastfetch
```

---

## ✅ Verification Checklist

Before considering setup complete, verify:

- [ ] Hyprland starts without errors
- [ ] Wallpaper displays correctly
- [ ] Waybar shows system information
- [ ] Terminal opens with `SUPER + Return`
- [ ] Application launcher works with `SUPER + Space`
- [ ] Keyboard layout is correct
- [ ] Touchpad/mouse works as expected
- [ ] Can switch workspaces
- [ ] Can close windows
- [ ] Can reload config without restart

**All checked?** 🎉 You're ready to customize!

---

**Next**: [Common Tasks Cheat Sheet](COMMON_TASKS.md)  
**Questions?**: See [Troubleshooting Guide](../05-Reference/TROUBLESHOOTING.md) _(coming soon)_

---

**Last Updated**: 2026-04-17  
**Read Time**: 5 minutes  
**Difficulty**: ⭐ Beginner

