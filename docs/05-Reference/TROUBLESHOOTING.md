# Troubleshooting Guide

> **⚠️ 本文档以 .lua（Hyprland v0.55+ 原生）为准**。历史 .conf 形式见文末 [Historical .conf form](#historical-conf-form) 节，亦见 git history。
> 语法对照见 [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md)。

> Systematic problem-solving for common and advanced issues with the `.lua` Hyprland config

This guide focuses on **`.lua`-first** troubleshooting. The repo no longer ships `.conf` files, so most issues are Lua-side (`luacheck`, `require`, keysym casing) or Hyprland-runtime side (`hyprctl`, GPU, services). See the [Historical .conf form](#historical-conf-form) section at the end for issues that only apply to legacy `.conf` setups.

---

## 🔍 Diagnostic Framework

When encountering issues, follow this diagnostic flow:

```
1. Identify symptoms
2. Run luacheck (static)        ← NEW in .lua era
3. Headless test (no GPU)      ← NEW in .lua era
4. Check logs (runtime)
5. Isolate component
6. Apply fix
7. Verify
```

### Quick triage — Lua-specific symptoms

| Symptom                                | Likely Cause                                | Quick Fix                                          |
| -------------------------------------- | ------------------------------------------- | -------------------------------------------------- |
| `Welcome to Hyprland!` then black screen | GPU/CBackend (not config)                | See [Issue 1](#issue-1-hyprland-wont-start)        |
| `module 'X' not found` error           | Wrong `require` path / missing file          | See [Issue 11](#issue-11-require-module-not-found)  |
| `unknown keysym xf86xxx`               | Lowercase XF86 keysym                        | See [Issue 12](#issue-12-unknown-keysym)             |
| `[ERROR] $var not resolved`            | Should be 0 in .lua; means .conf leaked in  | See [Issue 13](#issue-13-var-not-resolved)           |
| `speed exceeds maximum`                | `animation { speed = 150 }` (> 100)         | See [Issue 14](#issue-14-speed-exceeds-maximum)      |
| `attempt to index global 'hl' (nil)`   | Hyprland < 0.55 / not native Lua            | Upgrade Hyprland                                    |
| Layout cycling broken                  | SM pcall failed, fell back to .sh            | See [Issue 15](#issue-15-state-machine-bind-fails)   |

---

## 📊 Quick Problem Solver

| Symptom                 | Likely Cause                 | Quick Fix                                  |
| ----------------------- | ---------------------------- | ------------------------------------------ |
| Black screen on startup | Hyprland not starting / GPU  | Check TTY, view logs, run headless test   |
| No waybar               | Waybar crashed/not started   | Restart waybar                              |
| Wrong colors            | Wallust not loaded           | Run WallustSwww.sh                          |
| Keybinds not working    | Layout binds not initialized | Run KeybindsLayoutInit.sh / luacheck        |
| Wallpaper not loading   | awww not running             | Initialize awww                             |
| Audio not working       | PipeWire/WirePlumber issue   | Restart audio services                      |
| Touchpad not working    | Device name mismatch         | Check device name in config                 |
| Slow performance        | Animations/blur enabled      | Disable via scripts / GameMode               |
| Lua error in log        | Syntax / require path        | `luacheck ~/.config/hypr --codes`           |
| Unknown keysym          | Lowercase XF86 keysym        | Use CamelCase (`XF86AudioMute`)             |

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

# View Hyprland logs (Lua errors print to stderr)
journalctl -u hyprland-session -n 50

# Or check runtime log
cat /tmp/hypr/hyprland.log | tail -50
```

**Common Causes & Fixes**:

#### Cause A: Lua Syntax Error

```bash
# Static check — fastest way to find Lua errors
luacheck ~/.config/hypr --codes

# Example output:
# ~/.config/hypr/user/keybind.lua:42:1: unexpected symbol near '}'
# 1 error
```

Fix the line reported by `luacheck`:

```bash
nano ~/.config/hypr/user/keybind.lua
```

#### Cause B: Headless Test Fails (No GPU Needed)

```bash
# Run Hyprland in headless mode — catches Lua errors without a GPU
WLR_BACKENDS=headless hyprland \
  --config ~/.config/hypr/hyprland.lua \
  --i-am-really-stupid 2>&1 | grep -iE "lua|error|welcome"
# Expected: "Welcome to Hyprland!" with 0 Lua errors
```

If you see `[cfg] Config is lua, loading lua mgr` followed by errors, fix them before retrying.

#### Cause C: Missing Dependency

```bash
# Check required packages
which awww waybar rofi swaync

# Install missing packages
sudo pacman -S awww waybar rofi  # Arch
sudo dnf install awww waybar rofi  # Fedora
```

#### Cause D: GPU Driver Issue

```bash
# Check GPU drivers
lspci -k | grep -A 2 -i vga

# For NVIDIA, ensure proper drivers
nvidia-smi

# For Intel/AMD, check kernel modules
lsmod | grep i915  # Intel
lsmod | grep amdgpu  # AMD
```

**Note**: Hyprland 0.56.2 may emit `CBackend::create() failed` in sandboxed/cloud environments without a real GPU. This is **not a config error** — your `.lua` is fine.

**Nuclear Option** (last resort):

```bash
# Reset to default config
mv ~/.config/hypr ~/.config/hypr.broken
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr
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

# Check wallust-hyprland.lua exists
cat ~/.config/hypr/sys/policy/wallust/wallust-hyprland.lua

# Verify color variables are defined
hyprctl getoption decoration:col.active_border
```

**Solutions**:

#### Solution 1: Regenerate Colors

```bash
# Run wallust manually
~/.config/hypr/sys/scripts/WallustSwww.sh

# Force reload (Lua auto-reloads, but explicit reload works too)
hyprctl reload
```

#### Solution 2: Check require Order

Wallust must be `require`'d BEFORE `sys/decoration.lua`:

```lua
-- bootstrap/default.lua — correct require order
require("bootstrap.const")
require("sys.const")
require("user.const")
require("sys.default")  -- which itself requires policy before decoration
```

```lua
-- sys/default.lua — policy before decoration
require("sys.policy.default")  -- loads wallust colors ($colorN)
require("sys.decoration")      -- uses wallust colors
```

**Equivalence**: This replaces the `.conf` `source =` order check. `require` order = override priority.

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
# Check if awww daemon is running
ps aux | grep awww

# Check awww status
awww query

# List available wallpapers
ls -lh ~/Pictures/wallpapers/
```

**Solutions**:

#### Solution 1: Initialize awww

```bash
# Kill existing instances
killall awww-daemon

# Initialize fresh
awww init

# Set wallpaper
awww img ~/.config/hypr/wallpaper_effects/.wallpaper_current
```

#### Solution 2: Check startup hook

```lua
-- sys/startup.lua — verify awww is in the hyprland.start hook
hl.on("hyprland.start", function()
  hl.exec_cmd("awww-daemon --format xrgb")
  -- ...
end)
```

#### Solution 3: Manual Wallpaper Set

```bash
# Test with known good image
awww img /usr/share/backgrounds/default.jpg

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

```lua
-- user/input.lua
hl.config({ input = { kb_layout = "us,cn" } })
hl.config({ input = { kb_options = "caps:escape" } })  -- Caps Lock as Escape
```

Hyprland auto-reloads `.lua` files — no `hyprctl reload` needed (though it still works).

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

# Make permanent in user/input.lua (auto-reloads on save)
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

```lua
-- user/input.lua
hl.config({
  input = {
    touchdevice = { enabled = true },
    touchpad = {
      natural_scroll = true,
      ["tap-to-click"] = true,
    },
  },
})
```

#### Solution 2: Laptop Lid Switch Issue

```bash
# Check if lid switch disabled touchpad
cat /proc/acpi/button/lid/*/state

# If closed, open laptop lid
# Or override with a locked bind
```

```lua
-- user/keybind.lua — listen for lid switch
hl.bind("switch:off:Lid Switch", function() hl.dispatch("sendkeyboardreset") end,
       { locked = true })
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

```lua
-- user/hardware/monitors.lua (create if missing)
hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "0x0",
  scale = "1",
})
hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = "1",
})

-- Format: output, mode (WxH@refresh), position (XxY), scale
```

#### Solution 2: Use nwg-displays (GUI)

```bash
# Install nwg-displays
sudo pacman -S nwg-displays  # Arch

# Run GUI tool
nwg-displays

# Save configuration (writes to user/hardware/monitors.lua)
```

#### Solution 3: Force Reload

```bash
# Disconnect and reconnect cable
# Hyprland auto-reloads .lua files, but for monitor changes:
hyprctl reload

# Or force detect
wlr-randr --output HDMI-A-1 --on
```

**Note**: Monitor configuration changes require a full Hyprland restart (not just `.lua` reload).

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
# Quick toggle (script)
~/.config/hypr/sys/scripts/Animations.sh
```

```lua
-- user/misc.lua — disable animations
hl.config({ animations = { enabled = false } })
```

#### Solution 2: Disable Blur

```bash
# Quick toggle (script)
~/.config/hypr/sys/scripts/ChangeBlur.sh
```

```lua
-- user/decoration.lua
hl.config({ decoration = { blur = { enabled = false } } })
```

#### Solution 3: Reduce Rendering Quality

```lua
-- user/render.lua
hl.config({ render = { direct_scanout = true } })
hl.config({ render = { explicit_sync = 2 } })

-- user/misc.lua
hl.config({ misc = { vfr = true } })  -- Variable frame rate
```

#### Solution 4: Game Mode (Lua SM)

```bash
# Toggle game mode (disables effects via Lua SM)
~/.config/hypr/sys/scripts/GameMode.sh

# Or use the in-config Lua state machine (no shell overhead)
Press: SUPER + SHIFT + G
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
# Hyprland auto-reloads .lua on save, but force reload works too
hyprctl reload
echo $?  # Should be 0

# Check active config
hyprctl config | grep "your-setting"

# Check for Lua errors
luacheck ~/.config/hypr --codes
```

**Solutions**:

#### Solution 1: Verify File Location

```bash
# Ensure editing user/ files, not sys/
ls -la ~/.config/hypr/user/*.lua

# Common mistake: editing sys/ files (overwritten on git pull)
# Always use user/ for customizations
```

#### Solution 2: Check require Order

```lua
-- bootstrap/default.lua — verify user/ is required AFTER sys/
require("bootstrap.const")
require("sys.const")
require("user.const")    -- AFTER sys.const (last-write-wins)
require("sys.default")
```

```lua
-- sys/default.lua — verify user/ is required after sys/ for each module
require("sys.keybind")
require("user.keybind")  -- AFTER sys/keybind.lua
require("sys.tags")
require("user.tags")     -- AFTER sys/tags.lua
require("sys.rules")
require("user.rules")    -- AFTER sys/rules.lua
```

#### Solution 3: Full Restart

```bash
# Some changes require full restart (not just .lua reload):
killall Hyprland
Hyprland &

# Especially for:
# - Environment variables set via hl.env()
# - Monitor configuration
# - Service startups (hyprland.start hooks)
```

---

### Issue 11: "require module not found"

**Symptoms**:

```
lua: error: module 'sys.statemachine.layout' not found
```

**Cause**: A `require("X")` call references a path that doesn't exist on disk. Common in F3 SM modules if `lib/sm.lua` is missing.

**Diagnosis**:

```bash
# Static check — luacheck catches require errors
luacheck ~/.config/hypr --codes

# Verify the module exists
ls ~/.config/hypr/lib/sm.lua
ls ~/.config/hypr/sys/statemachine/layout.lua
```

**Fix**:

```bash
# If lib/sm.lua was accidentally deleted, restore from git:
cd ~/.config/hypr && git checkout HEAD -- lib/sm.lua sys/statemachine/

# Or check that package.path includes ~/.config/hypr
# (Hyprland's Lua runtime sets this; should not need manual config)
```

**Note**: The `pcall(require, 'sys.statemachine.X')` pattern in `sys/keybind.lua` is **defensive** — if the require fails, the bind silently falls back to the `.sh` script. So a missing SM module degrades to bash behavior rather than crashing the config. To verify the SM is loaded:

```bash
# Test the bind manually — if it errors immediately, the SM is loaded and firing
hyprctl dispatch exec "echo test"
# Then press the key; if behavior differs from .sh, SM is active
```

---

### Issue 12: "Unknown keysym"

**Symptoms**:

```
[ERROR] unknown keysym xf86audioraisevolume
[ERROR] unknown keysym xf86audio_mutemic
```

**Cause**: `.lua` requires **CamelCase** keysym names. The `.conf` lexer silently accepted lowercase, but `.lua` rejects them.

**Diagnosis**:

```bash
# Look in Hyprland log for keysym errors
journalctl -u hyprland-session -f | grep -i keysym

# Find all keysym occurrences in user files
rg "xf86" ~/.config/hypr/user/ --no-ignore -i
```

**Fix** — use CamelCase:

```lua
-- BAD: lowercase (would error at runtime)
hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd("Volume.sh --inc"))

-- GOOD: CamelCase
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/Volume.sh --inc"),
       { locked = true, repeating = true })
```

**Reference table** (see [COMPATIBILITY.md § XF86 keysym](../07-Lua-Reference/COMPATIBILITY.md#35-xf86-keysym-规范)):

| Wrong (lowercase) | Right (CamelCase)   |
| ------------------ | ------------------- |
| `xf86audiomute`       | `XF86AudioMute`         |
| `xf86audioraisevolume` | `XF86AudioRaiseVolume` |
| `xf86audiolowervolume` | `XF86AudioLowerVolume` |
| `xf86audiomicmute`    | `XF86AudioMicMute`     |
| `xf86audioplay`       | `XF86AudioPlay`         |
| `xf86audionext`       | `XF86AudioNext`         |
| `xf86audioprev`       | `XF86AudioPrev`         |
| `xf86sleep`           | `XF86Sleep`             |
| `xf86wlan`            | `XF86WLAN`              |

---

### Issue 13: "$var not resolved"

**Symptoms**:

```
[ERROR] $M_terminal not resolved
```

**Cause**: This should be **0 in the `.lua` config** — `bootstrap/default.lua` `deep_merge`'s all three const tables at load time, so `$var` references are pre-resolved. If you see this error, something has leaked in a `.conf`-style fragment.

**Diagnosis**:

```bash
# Find any remaining $var references (should be 0 outside const tables)
rg '\$[A-Za-z_][A-Za-z0-9_]*\b' ~/.config/hypr/sys/ ~/.config/hypr/user/ \
  --type-add 'lua:*.lua' -tlua \
  | grep -vE "const\.lua|^[^:]+:\d+:\s*--|^\s*\[?['\"]\\\$"
```

If you see `$S`, `$M`, `$W` etc. outside `const.lua` files or `['$var']` table keys, that's the leak.

**Fix**:

```lua
-- BAD: $var as a literal value (would not be resolved by deep_merge)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("$M_terminal"))

-- GOOD: Use the const table directly
local C = require('sys.const')  -- or wherever the merged const is exposed
hl.bind("SUPER + Return", hl.dsp.exec_cmd(C.M_terminal))

-- OR: Hardcode the value (simplest for user overrides)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))
```

**Note**: Shell scripts can still use `$var` — `Volume.sh`, `RofiSearch.sh`, etc. receive the substituted value at runtime via `hl.exec_cmd` after `hl.config` has populated the const table. That's expected and not a problem.

---

### Issue 14: "speed exceeds maximum"

**Symptoms**:

```
[ERROR] speed 150 exceeds maximum (100)
```

**Cause**: `hl.animation({ speed = N })` requires `0 ≤ N ≤ 100`. Higher values are silently truncated or rejected depending on Hyprland version.

**Fix**:

```lua
-- BAD
hl.animation({ leaf = "windows", speed = 150, ... })

-- GOOD (max is 100)
hl.animation({ leaf = "windows", speed = 100, ... })

-- For "very fast" animations, use a faster bezier curve instead
hl.curve("instant", { type = "bezier", points = {{0, 0}, {1, 1}} })
hl.animation({ leaf = "windows", speed = 100, bezier = "instant", style = "popin" })
```

---

### Issue 15: State Machine bind fails (silently falls back to .sh)

**Symptoms**:

- `SUPER + ALT + L` cycles layout, but `SUPER + J`/`SUPER + K` don't rebind correctly
- `SUPER + N` night light toggle works but state doesn't persist
- Game mode toggle is sluggish (2s instead of 50ms)

**Cause**: The `pcall(require, 'sys.statemachine.X')` in `sys/keybind.lua` failed silently and fell back to the `.sh` script.

**Diagnosis**:

```bash
# 1. Verify lib/sm.lua exists
ls ~/.config/hypr/lib/sm.lua

# 2. Verify the SM module loads
luacheck ~/.config/hypr/lib/sm.lua ~/.config/hypr/sys/statemachine/ --codes

# 3. Headless test
WLR_BACKENDS=headless hyprland --config ~/.config/hypr/hyprland.lua --i-am-really-stupid 2>&1 | grep -i lua
```

**Fix**:

```bash
# Restore from git if deleted
cd ~/.config/hypr && git checkout HEAD -- lib/ sys/statemachine/
```

To **forcefully** use the Lua SM (no fallback), temporarily edit `sys/keybind.lua` to remove the `pcall`:

```lua
-- DEBUG: remove pcall to surface the error
local layout_sm = require('sys.statemachine.layout')  -- will throw if missing
hl.bind("SUPER + ALT + L", function() layout_sm.new(hl):fire("cycle") end)
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

echo "--- Lua Static Check ---"
luacheck ~/.config/hypr --codes 2>&1 | head -30 || echo "luacheck not installed"
echo ""

echo "--- Config File Count ---"
echo "Lua files: $(find ~/.config/hypr -name '*.lua' | wc -l)"
echo "Conf files (should be 0): $(find ~/.config/hypr -name '*.conf' | wc -l)"
echo ""

echo "--- Monitors ---"
hyprctl monitors
echo ""

echo "--- Devices ---"
hyprctl devices
echo ""

echo "--- Recent Logs ---"
journalctl -u hyprland-session -n 20 --no-pager
echo ""

echo "--- Config Errors ---"
hyprctl config 2>&1 | grep -i error || echo "No errors found"
echo ""

echo "--- Running Services ---"
ps aux | grep -E "(waybar|awww|swaync|cliphist)" | grep -v grep
echo ""

echo "--- Memory Usage ---"
free -h
echo ""

echo "--- GPU Info ---"
lspci -k | grep -A 2 -i vga
echo ""

echo "--- Headless Test ---"
WLR_BACKENDS=headless hyprland --config ~/.config/hypr/hyprland.lua --i-am-really-stupid 2>&1 | head -5
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

1. ✅ Run `luacheck ~/.config/hypr --codes`
2. ✅ Run headless test (no GPU needed)
3. ✅ Run diagnostic script above
4. ✅ Check logs for Lua errors
5. ✅ Search existing documentation
6. ✅ Note what changed recently

### Provide This Information

When reporting issues, include:

```bash
# System info
neofetch  # or fastfetch

# Hyprland version
hyprctl version

# Lua check
luacheck ~/.config/hypr --codes

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

## Historical .conf form

> The following troubleshooting entries apply to **legacy `.conf`-era setups** only. They are preserved here for users who copied configs from old commits before the `.lua` migration. The current repo no longer ships `.conf` files.

### Legacy Issue A: "Unknown keyword $var"

In the `.conf` era, an undefined `$var` (e.g. typo `$M_terrminal`) would produce:

```
[ERROR] Unknown keyword "$M_terrminal" at line 42
```

**`.conf` diagnosis**:

```bash
# Find all undefined $var references in .conf files
grep -roh '\$[A-Za-z_][A-Za-z0-9_]*' ~/.config/hypr/sys/ ~/.config/hypr/user/ | sort -u
```

**`.lua` equivalent**: This error class is **gone** in the `.lua` era. `bootstrap/default.lua` does explicit `deep_merge(C, require(...))`, so any `$var` not in the merged const table is a Lua **key-lookup error** at runtime, not a parse-time keyword error. The `luacheck` static check catches most of these before launch.

### Legacy Issue B: source = order issue

In `.conf`, `source = ./foo.conf` was order-sensitive. If a user file was sourced before the sys file, the override would be lost:

```conf
# bootstrap/default.conf (LEGACY)
source = $user/keybind.conf   # ← BAD (.conf anti-pattern, don't do this)
source = $sys/keybind.conf    # sys overrides user (wrong direction)
```

**`.lua` equivalent**: The same rule applies to `require()` order — but `bootstrap/default.lua` is now hard-coded with the correct order (`sys.X` then `user.X` for every module), so users cannot accidentally misorder things. The only way to break it is to edit `sys/default.lua` directly, which the README explicitly warns against.

### Legacy Issue C: `bindd` (described bind) missing description

In `.conf`, `bindd = MOD, KEY, exec, CMD, "description"` — forgetting the description string was a common error:

```conf
# user/keybind.conf (LEGACY)
bindd = SUPER, Return, exec, $M_terminal       # ← BAD (.conf anti-pattern)
hl.bind("SUPER + Return", hl.dsp.exec_cmd(const.M_terminal))  # ← GOOD (.lua)
bindl = , XF86AudioMute, exec, $S/Volume.sh --toggle       # ← bindl variant (locked)
```

In `.lua`, there is no `bindd` variant — `hl.bind` takes only 3 args (keystring, dispatcher, flags). Descriptions are attached via separate tooling (e.g. `SUPER + SHIFT + K` opens the cheat sheet from `sys/scripts/KeyHints.sh`). The locked flag moves to the third-arg table: `hl.bind("XF86AudioMute", ..., { locked = true })`.

---

## 📚 Related Documentation

- **[Quick Start](../01-Getting-Started/QUICK_START.md)** — First-time setup
- **[Common Tasks](../01-Getting-Started/COMMON_TASKS.md)** — Frequent operations
- **[State Machines](../03-Core-Systems/STATE_MACHINES.md)** — Runtime behavior (Lua SM modules)
- **[Lua Reference](../07-Lua-Reference/README.md)** — Full `.lua` API
- **[Lua Compatibility](../07-Lua-Reference/COMPATIBILITY.md)** — `.lua` ↔ `.conf` syntax mapping

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
