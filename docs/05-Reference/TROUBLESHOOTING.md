# Troubleshooting Guide

> Systematic problem-solving for common and advanced issues

---

## 🔍 Diagnostic Framework

When encountering issues, follow this diagnostic flow:

```
1. Identify symptoms → 2. Check logs → 3. Isolate component → 4. Apply fix → 5. Verify
```

---

## 📊 Quick Problem Solver

| Symptom                 | Likely Cause                 | Quick Fix                   |
| ----------------------- | ---------------------------- | --------------------------- |
| Black screen on startup | Hyprland not starting        | Check TTY, view logs        |
| No waybar               | Waybar crashed/not started   | Restart waybar              |
| Wrong colors            | Wallust not loaded           | Run WallustSwww.sh          |
| Keybinds not working    | Layout binds not initialized | Run KeybindsLayoutInit.sh   |
| Wallpaper not loading   | swww not running             | Initialize swww             |
| Audio not working       | PipeWire/WirePlumber issue   | Restart audio services      |
| Touchpad not working    | Device name mismatch         | Check device name in config |
| Slow performance        | Animations/blur enabled      | Disable via scripts         |

---

## 🚨 Critical Issues

### Issue 1: Hyprland Won't Start

**Symptoms**:

- Black screen after login
- Returns to login manager
- TTY shows errors

**Diagnosis**:

```bash
# Switch to TTY (Ctrl+Alt+F2)
# Check if Hyprland process exists
ps aux | grep Hyprland

# View Hyprland logs
journalctl -u hyprland-session -n 50

# Or check runtime log
cat /tmp/hypr/hyprland.log | tail -50
```

**Common Causes & Fixes**:

#### Cause A: Syntax Error in Config

```bash
# Check for syntax errors
hyprctl config 2>&1 | grep -i error

# Example output:
# [ERROR] Unknown keyword "$M_terrminal" at line 42

# Fix: Edit the file and correct typo
nano ~/.config/hypr/user/const.conf
```

#### Cause B: Missing Dependency

```bash
# Check required packages
which swww waybar rofi swaync

# Install missing packages
sudo pacman -S swww waybar rofi  # Arch
sudo dnf install swww waybar rofi  # Fedora
```

#### Cause C: GPU Driver Issue

```bash
# Check GPU drivers
lspci -k | grep -A 2 -i vga

# For NVIDIA, ensure proper drivers
nvidia-smi

# For Intel/AMD, check kernel modules
lsmod | grep i915  # Intel
lsmod | grep amdgpu  # AMD
```

**Nuclear Option** (last resort):

```bash
# Reset to default config
mv ~/.config/hypr ~/.config/hypr.broken
cp -r /path/to/fresh/config ~/.config/hypr
Hyprland
```

---

### Issue 2: System Freeze/Hang

**Symptoms**:

- Screen frozen
- Mouse/keyboard unresponsive
- Can't switch to TTY

**Immediate Recovery**:

```bash
# Try Magic SysRq key (if enabled)
Alt + SysRq + R  # Take control of keyboard
Alt + SysRq + E  # Terminate all processes
Alt + SysRq + I  # Kill all processes
Alt + SysRq + S  # Sync filesystems
Alt + SysRq + U  # Unmount filesystems
Alt + SysRq + B  # Reboot

# Or try REISUB sequence (safer reboot)
```

**Post-Recovery Diagnosis**:

```bash
# Check system logs
journalctl -b -1 -n 100  # Previous boot

# Check Hyprland crash logs
ls -lh /tmp/hypr/*.log

# Check OOM killer
dmesg | grep -i "out of memory"
```

**Prevention**:

```bash
# Enable earlyoom (kills processes before OOM)
sudo systemctl enable --now earlyoom

# Monitor resources
htop  # or btop
```

---

## 🎨 Visual Issues

### Issue 3: Black Borders/Wrong Colors

**Symptoms**:

- Window borders are black
- Colors don't match wallpaper
- Wallust colors not applied

**Diagnosis**:

```bash
# Check if wallust ran
ls -lh ~/.cache/wallust/

# Check wallust-hyprland.conf exists
cat ~/.config/hypr/sys/policy/wallust/wallust-hyprland.conf

# Verify color variables are defined
hyprctl getoption decoration:col.active_border
```

**Solutions**:

#### Solution 1: Regenerate Colors

```bash
# Run wallust manually
~/.config/hypr/sys/scripts/WallustSwww.sh

# Then reload
hyprctl reload
```

#### Solution 2: Check Load Order

Wallust must load BEFORE decoration.conf:

```bash
# Check bootstrap/default.conf source order
cat ~/.config/hypr/bootstrap/default.conf

# Should see:
# source = $sys/policy/default.conf  (includes wallust)
# source = $sys/decoration.conf      (uses wallust colors)
```

#### Solution 3: Manual Color Test

```bash
# Set border color manually
hyprctl keyword decoration:col.active_border rgba(ff00ffaa)

# If this works, issue is with wallust config
# If this doesn't work, issue is with Hyprland itself
```

---

### Issue 4: Wallpaper Not Loading

**Symptoms**:

- Black background
- Default Hyprland gradient
- Wallpaper flickers then disappears

**Diagnosis**:

```bash
# Check if swww daemon is running
ps aux | grep swww

# Check swww status
swww query

# List available wallpapers
ls -lh ~/Pictures/wallpapers/
```

**Solutions**:

#### Solution 1: Initialize swww

```bash
# Kill existing instances
killall swww-daemon

# Initialize fresh
swww init

# Set wallpaper
swww img ~/.config/hypr/wallpaper_effects/.wallpaper_current
```

#### Solution 2: Check Startup Script

```bash
# Verify startup.conf has swww
grep swww ~/.config/hypr/sys/startup.conf

# Should see:
# exec-once = swww-daemon --format xrgb
```

#### Solution 3: Manual Wallpaper Set

```bash
# Test with known good image
swww img /usr/share/backgrounds/default.jpg

# If this works, issue is with wallpaper file
# Check file exists and is readable
file ~/Pictures/wallpapers/your-wallpaper.jpg
```

---

## ⌨️ Input Issues

### Issue 5: Keyboard Layout Wrong

**Symptoms**:

- Types wrong characters
- Special keys not working
- Layout doesn't switch

**Diagnosis**:

```bash
# Check current layout
hyprctl devices | grep -A 5 "keyboards"

# Test layout switch
hyprctl switchxkblayout your-keyboard-name next
```

**Solutions**:

#### Solution 1: Update Config

```bash
# Edit user/input.conf
nano ~/.config/hypr/user/input.conf

# Add/modify:
input {
    kb_layout = us,cn
    kb_options = caps:escape
}

# Reload
hyprctl reload
```

#### Solution 2: Find Correct Device Name

```bash
# List all keyboards
hyprctl devices | grep -B 2 "keyboard"

# Use exact name in config
# Example: "AT Translated Set 2 keyboard"
```

#### Solution 3: Runtime Layout Change

```bash
# Set layout immediately
hyprctl keyword input:kb_layout us,cn

# Make permanent in config
```

---

### Issue 6: Touchpad Not Working

**Symptoms**:

- Touchpad unresponsive
- Natural scroll not working
- Tap-to-click disabled

**Diagnosis**:

```bash
# List input devices
hyprctl devices

# Check touchpad status
hyprctl devices | grep -A 10 "touchpad"
```

**Solutions**:

#### Solution 1: Enable Touchpad

```bash
# Edit user/input.conf
nano ~/.config/hypr/user/input.conf

# Add:
device {
    name = asue1209:00-04f3:319f-touchpad  # Use your device name
    enabled = true
    natural_scroll = true
    tap-to-click = true
}

# Reload
hyprctl reload
```

#### Solution 2: Laptop Lid Switch Issue

```bash
# Check if lid switch disabled touchpad
cat /proc/acpi/button/lid/*/state

# If closed, open laptop lid
# Or override in config:
bindl = , switch:off:Lid Switch, exec, echo "enabled" > /tmp/touchpad_state
```

---

## 🔊 Audio Issues

### Issue 7: No Sound

**Symptoms**:

- No audio output
- Volume controls don't work
- Audio device not detected

**Diagnosis**:

```bash
# Check audio services
systemctl --user status pipewire
systemctl --user status wireplumber

# List audio devices
pactl list sinks short

# Test audio
speaker-test -t wav -c 2
```

**Solutions**:

#### Solution 1: Restart Audio Services

```bash
# Restart PipeWire
systemctl --user restart pipewire
systemctl --user restart wireplumber

# Wait a moment
sleep 2

# Check status
pactl info | grep "Default Sink"
```

#### Solution 2: Set Default Sink

```bash
# List available sinks
pactl list sinks short

# Set default
pactl set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo

# Test
paplay /usr/share/sounds/alsa/Front_Center.wav
```

#### Solution 3: Check Volume/Mute

```bash
# Check volume
pactl get-sink-volume @DEFAULT_SINK@

# Unmute if needed
pactl set-sink-mute @DEFAULT_SINK@ 0

# Set volume
pactl set-sink-volume @DEFAULT_SINK@ 50%
```

---

## 🖥️ Display Issues

### Issue 8: Monitor Not Detected

**Symptoms**:

- External monitor not showing
- Wrong resolution
- Monitor positioned incorrectly

**Diagnosis**:

```bash
# List monitors
hyprctl monitors

# Check EDID info
ls -lh /sys/class/drm/*/edid
```

**Solutions**:

#### Solution 1: Manual Monitor Config

```bash
# Edit monitors.conf
nano ~/.config/hypr/sys/hardware/monitors.conf

# Add monitor definition:
monitor = HDMI-A-1, 1920x1080@60, 0x0, 1
monitor = eDP-1, 1920x1080@60, 1920x0, 1

# Format: monitor = name, resolution@refresh, position, scale
```

#### Solution 2: Use nwg-displays (GUI)

```bash
# Install nwg-displays
sudo pacman -S nwg-displays  # Arch

# Run GUI tool
nwg-displays

# Save configuration (auto-writes to monitors.conf)
```

#### Solution 3: Force Reload

```bash
# Disconnect and reconnect cable
# Then reload
hyprctl reload

# Or force detect
wlr-randr --output HDMI-A-1 --on
```

---

## ⚡ Performance Issues

### Issue 9: Slow/Laggy Performance

**Symptoms**:

- Animations stutter
- High CPU/GPU usage
- Delayed input response

**Diagnosis**:

```bash
# Monitor resources
htop  # or btop

# Check GPU usage
intel_gpu_top  # Intel
radeontop      # AMD
nvtop          # NVIDIA

# Check Hyprland FPS
hyprctl version  # Should show debug info
```

**Solutions**:

#### Solution 1: Disable Animations

```bash
# Quick toggle
~/.config/hypr/sys/scripts/Animations.sh

# Or edit user/misc.conf
animations {
    enabled = false
}

# Reload
hyprctl reload
```

#### Solution 2: Disable Blur

```bash
# Quick toggle
~/.config/hypr/sys/scripts/ChangeBlur.sh

# Or edit user/decoration.conf
decoration {
    blur {
        enabled = false
    }
}
```

#### Solution 3: Reduce Rendering Quality

```bash
# Edit user/render.conf
render {
    direct_scanout = true
    explicit_sync = 2
}

# Edit user/misc.conf
misc {
    vfr = true  # Variable refresh rate
}
```

#### Solution 4: Game Mode

```bash
# Enable game mode (disables effects)
~/.config/hypr/sys/scripts/GameMode.sh

# Or add keybinding
bind = $M SHIFT, G, exec, $S/GameMode.sh
```

---

## 🔄 Configuration Issues

### Issue 10: Config Changes Not Taking Effect

**Symptoms**:

- Edited config but no change
- Reload doesn't apply changes
- Old settings persist

**Diagnosis**:

```bash
# Check if reload succeeded
hyprctl reload
echo $?  # Should be 0

# Check active config
hyprctl config | grep "your-setting"

# Check for errors
hyprctl config 2>&1 | grep -i error
```

**Solutions**:

#### Solution 1: Verify File Location

```bash
# Ensure editing user/ files, not sys/
ls -la ~/.config/hypr/user/*.conf

# Common mistake: editing sys/ files (overwritten on update)
# Always use user/ for customizations
```

#### Solution 2: Check Source Order

```bash
# Verify user/ files are sourced after sys/
cat ~/.config/hypr/bootstrap/default.conf

# Should see:
# source = $sys/keybind.conf
# source = $user/keybind.conf  # After sys/
```

#### Solution 3: Full Restart

```bash
# Some changes require full restart
killall Hyprland
Hyprland &

# Especially for:
# - Environment variables
# - Monitor configuration
# - Service startups
```

---

### Issue 11: Undefined Variable Errors

**Symptoms**:

```
[ERROR] Unknown keyword "$M_termnal"
[ERROR] Failed to parse config
```

**Diagnosis**:

```bash
# Find all undefined variables
grep -roh '\$[A-Za-z_][A-Za-z0-9_]*' ~/.config/hypr/sys/ ~/.config/hypr/user/ | \
  sort -u > /tmp/used_vars

grep -roh '^\$[A-Za-z_][A-Za-z0-9_]*' \
  ~/.config/hypr/bootstrap/const.conf \
  ~/.config/hypr/sys/const.conf \
  ~/.config/hypr/user/const.conf | \
  sed 's/=.*//' | sort -u > /tmp/defined_vars

comm -23 /tmp/used_vars /tmp/defined_vars
```

**Solution**:

```bash
# Fix typo in variable name
nano ~/.config/hypr/user/keybind.conf

# Change $M_termnal to $M_terminal

# Or define missing variable
nano ~/.config/hypr/user/const.conf
# Add: $M_termnal = kitty
```

---

## 🛠️ Advanced Diagnostics

### Generate Debug Report

```bash
#!/bin/bash
# save as: ~/hypr-debug.sh

echo "=== Hyprland Debug Report ==="
echo "Date: $(date)"
echo ""

echo "--- Version ---"
hyprctl version
echo ""

echo "--- Monitors ---"
hyprctl monitors
echo ""

echo "--- Devices ---"
hyprctl devices
echo ""

echo "--- Active Workspace ---"
hyprctl activeworkspace
echo ""

echo "--- Recent Logs ---"
journalctl -u hyprland-session -n 20 --no-pager
echo ""

echo "--- Config Errors ---"
hyprctl config 2>&1 | grep -i error || echo "No errors found"
echo ""

echo "--- Running Services ---"
ps aux | grep -E "(waybar|swww|swaync|cliphist)" | grep -v grep
echo ""

echo "--- Memory Usage ---"
free -h
echo ""

echo "--- GPU Info ---"
lspci -k | grep -A 2 -i vga
```

**Usage**:

```bash
chmod +x ~/hypr-debug.sh
~/hypr-debug.sh > ~/hypr-debug-report.txt

# Share report when asking for help
```

---

## 📞 Getting Help

### Before Asking for Help

1. ✅ Run diagnostic script above
2. ✅ Check logs for errors
3. ✅ Search existing documentation
4. ✅ Try basic troubleshooting steps
5. ✅ Note what changed recently

### Provide This Information

When reporting issues, include:

```bash
# System info
neofetch  # or fastfetch

# Hyprland version
hyprctl version

# Configuration errors
hyprctl config 2>&1 | grep -i error

# Recent logs
journalctl -u hyprland-session -n 50

# What you tried
# What changed before issue
# Expected vs actual behavior
```

### Where to Ask

- **GitHub Issues**: Bug reports with debug info
- **Hyprland Discord**: Real-time community support
- **Hyprland Wiki**: General documentation
- **This Project's Issues**: Configuration-specific problems

---

## 📚 Related Documentation

- **[Quick Start](../01-Getting-Started/QUICK_START.md)** — First-time setup
- **[Common Tasks](../01-Getting-Started/COMMON_TASKS.md)** — Frequent operations
- **[State Machines](../03-Core-Systems/STATE_MACHINES.md)** — Runtime behavior
- **[Service Lifecycle](../03-Core-Systems/SERVICE_LIFECYCLE.md)** _(coming soon)_ — Process management

---

**Last Updated**: 2026-04-17  
**Read Time**: 30 minutes (reference)  
**Difficulty**: ⭐⭐⭐ Advanced

