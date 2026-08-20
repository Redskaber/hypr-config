# Common Tasks Cheat Sheet

> **⚠️ 本文档以 .lua（Hyprland v0.55+ 原生）为准**。历史 .conf 形式见 git history。
> 语法对照见 [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md)。

> Quick reference for frequent operations — copy, paste, done!

All examples below use the **`.lua` config form** (Hyprland v0.55+ native). The repo no longer ships `.conf` files; for the historical `.conf` syntax, see [git history](https://github.com/Redskaber/hypr-config).

---

## 📋 Table of Contents

- [Application Management](#application-management)
- [Window Management](#window-management)
- [Workspace Operations](#workspace-operations)
- [System Controls](#system-controls)
- [Configuration Changes](#configuration-changes)
- [Add HiDPI / Multi-monitor](#add-hidpi--multi-monitor)
- [Enable NVIDIA](#enable-nvidia)
- [Add Custom Keybind](#add-custom-keybind)
- [Add Window Rule](#add-window-rule)
- [Troubleshooting](#troubleshooting)
- [Historical .conf form](#historical-conf-form)

---

## Application Management

### Open Terminal

```bash
# Keyboard shortcut (uses $M_terminal from user/const.lua)
Press: SUPER + Return

# Or via command
hyprctl dispatch exec ghostty  # Replace with your terminal
```

### Open Application Launcher

```bash
# Keyboard shortcut
Press: SUPER + D

# Or via command
rofi -show drun
```

### Launch Specific Application

Add a bind in `user/keybind.lua` (Lua form):

```lua
-- user/keybind.lua
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))        -- Browser
hl.bind("SUPER + E", hl.dsp.exec_cmd("nemo"))           -- File manager
hl.bind("SUPER + C", hl.dsp.exec_cmd("code"))            -- VS Code
```

**No `hyprctl reload` needed** — Hyprland auto-reloads `.lua` files on save.

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

(Actual binds in `sys/keybind.lua` use `movefocus` dispatcher.)

### Move Windows

```bash
Press: SUPER + Ctrl + left   ← Move left
Press: SUPER + Ctrl + right  → Move right
Press: SUPER + Ctrl + up     ↑ Move up
Press: SUPER + Ctrl + down   ↓ Move down
```

### Toggle Fullscreen

```bash
# Keyboard shortcut
Press: SUPER + Shift + F

# Or via command
hyprctl dispatch fullscreen
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
Press: SUPER + Shift + arrow  # Resize in directions (repeating)
Or: Drag window borders with mouse
```

### Change Layout

```bash
# Cycle layouts (3-state Lua SM in sys/statemachine/layout.lua)
Press: SUPER + ALT + L
# scrolling  →  dwindle  →  master  →  scrolling → ...

# Or set a specific layout via Lua
hyprctl keyword general:layout dwindle   # or: master, scrolling
```

### Make Window Float

Add a rule in `user/rules.lua`:

```lua
-- user/rules.lua
hl.window_rule({
  float = true,
  match = { class = "^([Mm]yapp)$" },
})

-- Or toggle floating for the current window
-- Press: SUPER + Space
```

### Pin Window to All Workspaces

```lua
-- user/rules.lua
hl.window_rule({
  pin = true,
  match = { class = "^([Ss]tickyapp)$" },
})
```

```bash
# Or toggle pin for current window
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

### Rename Workspace

Hyprland doesn't have a native rename, but you can assign a workspace to a monitor via the `workspace` rule keyword. This is set in `user/rules.lua`:

```lua
-- user/rules.lua — bind a workspace to a monitor
hl.config({ workspace = { ["1"] = { monitor = "HDMI-A-1" } } })
```

---

## System Controls

### Volume Control

```bash
# Increase volume (bind is locked + repeating, so works on lock screen)
Press: XF86AudioRaiseVolume
# Or: pactl set-sink-volume @DEFAULT_SINK@ +5%

# Decrease volume
Press: XF86AudioLowerVolume
# Or: pactl set-sink-volume @DEFAULT_SINK@ -5%

# Toggle mute
Press: XF86AudioMute
# Or: pactl set-sink-mute @DEFAULT_SINK@ toggle
```

These are bound in `sys/keybind.lua`:

```lua
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/Volume.sh --inc"),
       { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/Volume.sh --toggle"),
       { locked = true })
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
```

### Screenshot

```bash
# Full screen
Press: SUPER + Print
# Saves to: ~/Pictures/Screenshots/

# Select area
Press: SUPER + Shift + Print
# Drag to select region

# Current window
Press: ALT + Print
```

### Lock Screen

```bash
# Keyboard shortcut
Press: CTRL + ALT + L

# Or via command
hyprlock
```

### Power Menu

```bash
# Keyboard shortcut
Press: CTRL + ALT + P

# Or via command
wlogout
```

---

## Configuration Changes

### Change Terminal Emulator

```bash
nano ~/.config/hypr/user/const.lua
```

Edit the **return-table** to override the `$M_terminal` constant:

```lua
-- user/const.lua
return {
  ['M_terminal = "ghostty",  -- options: kitty, alacritty, foot, wezterm, ghostty
}
```

**No reload needed** — Hyprland auto-reloads `.lua` files. The next `SUPER + Return` press will use your new terminal.

### Change Keyboard Layout

```bash
nano ~/.config/hypr/user/input.lua
```

```lua
-- user/input.lua
hl.config({ input = { kb_layout = "us,cn" } })
hl.config({ input = { kb_options = "caps:escape" } })  -- Caps Lock as Escape
```

### Change Wallpaper

```bash
# Interactive selection (also regenerates wallust colors)
~/.config/hypr/sys/scripts/WallpaperSelect.sh

# Or set specific wallpaper
awww img ~/Pictures/my-wallpaper.jpg --transition-type fade

# Random wallpaper
~/.config/hypr/sys/scripts/WallpaperRandom.sh
```

### Modify Colors (Wallust)

```bash
# Regenerate colors from current wallpaper
~/.config/hypr/sys/scripts/WallustSwww.sh

# Or manually edit wallust-generated color variables
nano ~/.config/hypr/sys/policy/wallust/wallust-hyprland.lua
```

### Add Custom Keybinding

```bash
nano ~/.config/hypr/user/keybind.lua
```

```lua
-- user/keybind.lua
hl.bind("SUPER + X", hl.dsp.exec_cmd("my-command"))

-- With locked flag (active on lock screen)
hl.bind("CTRL + ALT + X", hl.dsp.exec_cmd("my-command"), { locked = true })

-- With repeating flag (auto-repeat on hold)
hl.bind("SUPER + SHIFT + X", function() hl.dispatch("resizeactive", "50 0") end,
       { repeating = true })

-- With description (optional, for keybind hint tools)
hl.bind("SUPER + Y", hl.dsp.exec_cmd("my-y-command"))
```

### Enable/Disable Blur

```bash
# Toggle blur (script)
~/.config/hypr/sys/scripts/ChangeBlur.sh
```

Or edit `user/decoration.lua` directly:

```lua
-- user/decoration.lua
hl.config({ decoration = { blur = { enabled = false } } })  -- disable
hl.config({ decoration = { blur = { enabled = true  } } })  -- enable
```

### Toggle Night Light

The night light is a Lua state machine (`sys/statemachine/nightlight.lua`):

```bash
# Toggle night light (state persists across sessions)
Press: SUPER + N
```

Or add your own keybinding that fires the SM directly:

```lua
-- user/keybind.lua
hl.bind("SUPER + SHIFT + S", function()
  require('sys.statemachine.nightlight').new(hl):fire("toggle")
end)
```

### Enable Game Mode

The game mode is a Lua state machine (`sys/statemachine/gamemode.lua`):

```bash
# Toggle game mode (disables animations, blur, gaps)
Press: SUPER + Shift + G
```

Or trigger it from a script / window rule:

```lua
-- user/keybind.lua — alternate bind
hl.bind("SUPER + ALT + G", function()
  require('sys.statemachine.gamemode').new(hl):fire("toggle")
end)
```

---

## Add HiDPI / Multi-monitor

For HiDPI displays or multi-monitor setups, override `user/hardware/monitors.lua` (create the file if missing):

```lua
-- user/hardware/monitors.lua — overrides sys/hardware/monitors.lua

-- HiDPI laptop screen (2x scaling)
hl.monitor({
  output = "eDP-1",
  mode = "2880x1800@120",
  position = "0x0",
  scale = "2",
})

-- External 1080p monitor (1x scaling, right of laptop)
hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "2880x0",
  scale = "1",
})
```

**Environment variables for HiDPI** (Qt/GTK scaling):

```lua
-- user/env.lua
hl.env("GDK_SCALE", "1")       -- GTK (1 = auto; use GDK_DPI_SCALE for fractional)
hl.env("QT_SCALE_FACTOR", "1.5")
```

---

## Enable NVIDIA

For NVIDIA GPUs, set environment variables in `user/env.lua`:

```lua
-- user/env.lua — NVIDIA driver setup
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "1")
hl.env("WLR_DRM_NO_ATOMIC", "1")
```

**Required**: NVIDIA driver 545+ and `nvidia_drm.modeset=1` kernel parameter (set in `/etc/default/grub` or your bootloader config).

**Verify**:

```bash
# Modeset should be enabled
cat /sys/module/nvidia_drm/parameters/modeset
# Expected: Y
```

If you still see flicker, try adding `WLR_NO_HARDWARE_CURSORS=1`:

```lua
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
```

---

## Add Custom Keybind

The `.lua` form uses `hl.bind(keystring, dispatcher, flags?)`. The keystring uses ` + ` between mods and key:

```lua
-- user/keybind.lua

-- Simple: open an app
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))

-- With SHIFT modifier
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("firefox --private-window"))

-- With CTRL modifier
hl.bind("SUPER + CTRL + R", hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/Refresh.sh"))

-- Media keys (CamelCase keysym required!)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Mouse bind (move window)
hl.bind("SUPER + mouse:272", function() hl.dispatch("movewindow") end, { mouse = true })

-- Resize window (repeating on hold)
hl.bind("SUPER + SHIFT + left", function() hl.dispatch("resizeactive", "-50 0") end,
       { repeating = true })

-- Lua function dispatcher (impossible in .conf era!)
hl.bind("SUPER + SHIFT + G", function()
  require('sys.statemachine.gamemode').new(hl):fire("toggle")
end)
```

### Flag reference

| Flag                | Meaning                                | .conf equivalent |
| ------------------- | --------------------------------------- | ---------------- |
| `{ locked = true }` | Active on lock screen                   | `bindl` / `bindld` |
| `{ repeating = true }` | Auto-repeat on hold                  | `binde` / `binded` |
| `{ mouse = true }`  | Mouse bind                              | `bindm` / `bindmd` |
| `{ non_consuming = true }` | Don't consume key press         | `bindn` / `bindlnd` |

**Note**: The `.conf` `bindd` (description) variant has no `.lua` equivalent — `hl.bind` has only 3 args.

---

## Add Window Rule

The `.lua` form uses `hl.window_rule({ ... })` with structured fields. Tag-driven rules live in `user/tags.lua` (classify) and `user/rules.lua` (behavior):

### Step 1: Register the app to a tag

```lua
-- user/tags.lua
hl.window_rule({
  match = { class = "^([Dd]iscord)$" },
  tag = "discord",
})
```

### Step 2: Define behavior for that tag

```lua
-- user/rules.lua
hl.window_rule({
  float = true,
  match = { tag = "discord" },
})
hl.window_rule({
  opacity = "0.95 0.90",
  match = { tag = "discord" },
})
hl.window_rule({
  size = "1200 800",
  match = { tag = "discord" },
})
```

### Direct class rule (no tag — for one-off apps)

```lua
-- user/rules.lua
hl.window_rule({
  float = true,
  match = { class = "^([Mm]yapp)$" },
})
hl.window_rule({
  size = "1200 800",
  match = { class = "^([Mm]yapp)$" },
})
```

### Rule keyword → Lua field mapping

| .conf rule                         | .lua field                                  | Type    |
| ---------------------------------- | ------------------------------------------- | ------- |
| `opacity X Y`                      | `opacity = "X Y"`                           | string  |
| `float on` / `float off`           | `float = true` / `false`                    | boolean |
| `center on` / `center off`         | `center = true` / `false`                   | boolean |
| `size W H`                         | `size = "W H"`                              | string  |
| `pin on` / `pin off`               | `pin = true` / `false`                      | boolean |
| `idle_inhibit fullscreen`          | `idle_inhibit = "fullscreen"`               | string  |
| `match:class ^X$`                  | `match = { class = "^X$" }`                 | table   |
| `match:title ^X$`                  | `match = { title = "^X$" }`                 | table   |
| `match:tag X`                      | `match = { tag = "X" }`                     | table   |

### Compound conditions (class + negative title)

```lua
-- Compound: class matches AND title does NOT match
hl.window_rule({
  float = true,
  match = {
    class = "^([Tt]hunar)$",
    title_negative = "^(.*[Tt]hunar.*)$",
  },
})
```

### Workspace assignment

```lua
-- user/rules.lua — assign Firefox to workspace 1
hl.window_rule({
  workspace = "1",
  match = { class = "^([Ff]irefox)$" },
})
```

---

## Troubleshooting

### Config Not Auto-Reloading

```bash
# Hyprland watches the config directory; if not reloading, check:
# 1. Are you editing files in ~/.config/hypr/? (not /etc/...)
# 2. Is the file saved? (most editors need explicit save)
# 3. Force reload:
hyprctl reload

# Check for Lua errors
luacheck ~/.config/hypr --codes
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
# Check if awww is running
ps aux | grep awww

# Initialize awww
awww init

# Set wallpaper manually
awww img ~/.config/hypr/wallpaper_effects/.wallpaper_current
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

# Enable touchpad in user/input.lua
```

```lua
-- user/input.lua
hl.config({
  input = {
    touchdevice = { enabled = true },
    touchpad = { natural_scroll = true, ["tap-to-click"] = true },
  },
})
```

### Performance Issues (Slow/Laggy)

```bash
# Disable animations temporarily
~/.config/hypr/sys/scripts/Animations.sh

# Or disable blur
~/.config/hypr/sys/scripts/ChangeBlur.sh

# Check resource usage
htop
```

```lua
-- user/render.lua — reduce rendering quality
hl.config({ render = { direct_scanout = true } })
```

### Keybindings Not Responding

```bash
# Re-initialize layout binds
~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh

# Check active binds
hyprctl binds

# Force config reload
hyprctl reload

# Look for Lua errors (typo in require path / wrong keysym)
luacheck ~/.config/hypr --codes
journalctl -u hyprland-session -f
```

### Monitor Not Detected

```bash
# List monitors
hyprctl monitors

# Force detect (disconnect/reconnect cable, then)
hyprctl reload

# Edit monitor config
nano ~/.config/hypr/user/hardware/monitors.lua
```

```lua
-- user/hardware/monitors.lua
hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "0x0",
  scale = "1",
})
```

---

## Advanced Tasks

### Add Window Rule for Specific App

```bash
nano ~/.config/hypr/user/rules.lua
```

```lua
-- Example: Make Discord float with opacity
hl.window_rule({
  float = true,
  match = { class = "^([Dd]iscord)$" },
})
hl.window_rule({
  opacity = "0.95 0.90",
  match = { class = "^([Dd]iscord)$" },
})
hl.window_rule({
  size = "1200 800",
  match = { class = "^([Dd]iscord)$" },
})
```

### Create Custom Workspace Assignment

```bash
nano ~/.config/hypr/user/rules.lua
```

```lua
-- Assign apps to specific workspaces
hl.window_rule({
  workspace = "1",
  match = { class = "^([Ff]irefox)$" },
})
hl.window_rule({
  workspace = "2",
  match = { class = "^(VSCode|code)$" },
})
hl.window_rule({
  workspace = "3",
  match = { class = "^([Dd]iscord)$" },
})
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
# Export active configuration (Lua form)
hyprctl config > ~/hyprland-config-export.txt

# View exported config
cat ~/hyprland-config-export.txt
```

---

## Quick Reference: Modifier Keys

| Symbol         | Key                  | Example                         |
| -------------- | -------------------- | ------------------------------- |
| `SUPER`        | SUPER (Windows key)  | `"SUPER + Return"`              |
| `SUPER + SHIFT`| SUPER + Shift        | `"SUPER + SHIFT + Q"`           |
| `SUPER + CTRL` | SUPER + Ctrl         | `"SUPER + CTRL + R"`            |
| `SUPER + ALT`  | SUPER + Alt          | `"SUPER + ALT + L"`             |

**Note**: In `.lua`, modifiers and the key are joined by ` + ` inside a single string. No more `,` separator (that was `.conf` syntax).

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
| `XF86Audio*`         | Media keys (CamelCase!) |
| `XF86MonBrightness*` | Brightness keys (CamelCase!) |
| `XF86Sleep`          | Sleep key       |
| `XF86WLAN`           | Airplane mode key |
| `mouse:272`          | Left mouse button |
| `mouse:273`          | Right mouse button |

**Critical**: `.lua` requires CamelCase keysym (`XF86AudioMute`, not `xf86audiomute`). Lowercase variants are silently rejected by Hyprland's keysym parser.

---

## Historical .conf form

> The following examples show the **legacy `.conf` syntax** preserved here for historical context only. The current repo no longer contains `.conf` files — see git history for the migration.

### Example 1: const file + bind (LEGACY `.conf`)

```conf
# user/const.conf  (LEGACY — not in current repo)
$M_terminal = ghostty

# user/keybind.conf  (LEGACY)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("$M_terminal"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))
bindl = , XF86AudioMute, exec, $S/Volume.sh --toggle
```

**Equivalence**: In `.lua`, `$M_terminal = "ghostty"` becomes a table key `['M_terminal = "ghostty"` in `user/const.lua`. `bind = MOD, KEY, exec, CMD` becomes `hl.bind("MOD + KEY", hl.dsp.exec_cmd("CMD"))`. The `.conf` `bindl` (locked) variant becomes the third-arg flag `{ locked = true }` in `.lua`. The keysym `XF86AudioMute` must be CamelCase in `.lua` (lowercase was silently accepted in `.conf`).

### Example 2: windowrule + env (LEGACY `.conf`)

```conf
# user/rules.conf  (LEGACY)
hl.window_rule({ float = true, match = { class = "^(discord)$" } })$
hl.window_rule({ opacity = "0.95 0.90", match = { class = "^(discord)$" } })
hl.window_rule({ workspace = "1", match = { class = "^(firefox)$" } })

# user/env.conf  (LEGACY)
env = GDK_SCALE, 1.5
env = LIBVA_DRIVER_NAME, nvidia
```

**Equivalence**: In `.lua`, `windowrule = float, class:^(discord)$` becomes `hl.window_rule({ float = true, match = { class = "^([Dd]iscord)$" } })` — the rule keyword becomes a table field name and the `class:regex` argument becomes the `match` table. `env = VAR, VALUE` becomes `hl.env("VAR", "VALUE")`.

---

## Need More Help?

- **[Quick Start Guide](QUICK_START.md)** — First-time setup
- **[Troubleshooting Guide](../05-Reference/TROUBLESHOOTING.md)** — Detailed problem solving
- **[Lua Reference](../07-Lua-Reference/README.md)** — Full `.lua` API and patterns
- **[Documentation Index](../06-Meta/DOCUMENTATION_INDEX.md)** — Full documentation navigation

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
