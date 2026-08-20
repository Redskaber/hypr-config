# Quick Start Guide

> **⚠️ 本文档以 .lua（Hyprland v0.55+ 原生）为准**。历史 .conf 形式见 git history。
> 语法对照见 [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md)。

> Get your Hyprland configuration up and running in **5 minutes**

This guide assumes you have a fresh Wayland session and want to install this `.lua`-first Hyprland config. The config uses Hyprland's native `hl.*` Lua API — no `hyprlang`, no `hyprctl reload` for most edits (Hyprland auto-reloads `.lua` files on save).

---

## 🎯 Prerequisites

Before starting, ensure you have:

- ✅ **Hyprland** >= 0.55.0 installed (tested on 0.56.2; Lua config native)
- ✅ **Wayland session** running
- ✅ **Basic packages**: `awww`, `waybar`, `rofi`, `swaync`, `cliphist`, `hypridle`, `wallust`

### Check Installation

```bash
# Verify Hyprland is installed (must be >= 0.55.0 for .lua config)
hyprctl version

# Check required packages
which awww waybar rofi swaync cliphist hypridle wallust
```

**Missing packages?** Install them:

```bash
# Arch Linux
sudo pacman -S awww waybar rofi swaync cliphist hypridle wallust

# Fedora
sudo dnf install awww waybar rofi swaync cliphist hypridle wallust

# NixOS (add to configuration.nix)
environment.systemPackages = with pkgs; [ awww waybar rofi swaync cliphist hypridle wallust ];
```

---

## 📦 Installation

### Step 1: Backup Existing Config (If Any)

```bash
# Backup current Hyprland config
mv ~/.config/hypr ~/.config/hypr.backup 2>/dev/null || true
```

### Step 2: Clone the .lua Config

```bash
# Clone or copy this configuration (now ships as .lua, not .conf)
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr

# Or copy from USB/backup
cp -r /path/to/hypr-config ~/.config/hypr
```

### Step 3: Verify Structure

```bash
# Check key .lua files exist
ls ~/.config/hypr/hyprland.lua
ls ~/.config/hypr/bootstrap/default.lua
ls ~/.config/hypr/sys/const.lua
ls ~/.config/hypr/user/const.lua
```

Expected output: All four `.lua` files should exist. The repo no longer ships any `.conf` files — see [git history](https://github.com/Redskaber/hypr-config) for the migration commits if you remember the old form.

### Step 4: Static Syntax Check (Optional but Recommended)

```bash
# Install luacheck if missing
sudo pacman -S luarocks        # Arch
sudo luarocks install luacheck # or: cargo install luacheck

# Run static check — should be 0 warnings/errors
luacheck ~/.config/hypr --codes
```

If `luacheck` reports errors, fix them before launching Hyprland — they will also surface at runtime.

---

## ⚙️ Initial Configuration

### Step 5: Customize User Constants

Edit `user/const.lua` to match your preferences. This file is a **Lua table** — return-style:

```bash
nano ~/.config/hypr/user/const.lua
```

The default file looks like this:

```lua
-- user/const.lua — return a table of constant overrides
return {
  ['Search_Engine = "\"https://www.bing.com/search?q={}\"",
}
```

**Common customizations** (add/modify keys in the `return { ... }` table):

```lua
-- user/const.lua
return {
  -- Change terminal emulator (default: kitty)
  ['M_terminal     = "ghostty",        -- options: kitty, alacritty, foot, wezterm, ghostty

  -- Change file manager (default: nemo)
  ['M_file_manager = "thunar",         -- options: nemo, nautilus, dolphin, thunar

  -- Change wallpaper directory (default: /home/z/Pictures/wallpapers)
  ['W              = "~/Pictures/wallpapers",

  -- Change web search engine used by RofiSearch.sh
  ['Search_Engine  = "\"https://duckduckgo.com/?q={}\"",
}
```

**Note**: The `['var = "value"` syntax is the literal table key (with the `$` as part of the string). It mirrors the historical `.conf` `$var = value` for migration clarity; the bootstrap pipeline substitutes these into shell scripts that still expect `$M_terminal` etc.

**Save** (`Ctrl+O`, `Enter`) and **exit** (`Ctrl+X`).

### Step 6: Review Hardware Configuration

Check monitor setup:

```bash
# List connected monitors
hyprctl monitors

# Edit hardware config if needed (advanced — defaults auto-detect)
nano ~/.config/hypr/sys/hardware/monitors.lua
```

The default `sys/hardware/monitors.lua` auto-configures any monitor:

```lua
-- sys/hardware/monitors.lua
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })
hl.monitor({ output = "", mode = "highrr",   position = "auto", scale = "1" })
hl.monitor({ output = "", mode = "highres",  position = "auto", scale = "1" })
```

For a specific dual-monitor setup, override in `user/` (create `user/hardware/monitors.lua` if missing) — see [Common Tasks: Add HiDPI / Multi-monitor](COMMON_TASKS.md#add-hidpi--multi-monitor).

---

## 🚀 First Launch

### Step 7: Start Hyprland

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

### Step 8: Verify Installation

Once Hyprland starts, you should see:

- ✅ Desktop background (wallpaper)
- ✅ Waybar at top/bottom
- ✅ Default terminal window

**Test basic functionality**:

```bash
# Open terminal (uses $M_terminal from user/const.lua)
Press: SUPER + Return

# Open application launcher
Press: SUPER + D

# Check Hyprland status
hyprctl version
```

**No `hyprctl reload` needed after editing `.lua` files** — Hyprland watches the config directory and auto-reloads on save. The only changes that require a full Hyprland restart are: monitor configuration and environment variables (those set via `hl.env`).

---

## 🎨 First Customization

### Change Wallpaper

```bash
# Select wallpaper interactively (also runs wallust to regenerate colors)
~/.config/hypr/sys/scripts/WallpaperSelect.sh

# Or set specific wallpaper
awww img ~/Pictures/my-wallpaper.jpg --transition-type fade
```

### Modify Keybindings

Edit `user/keybind.lua` (a **Lua** file using `hl.bind`):

```bash
nano ~/.config/hypr/user/keybind.lua
```

**Example** (add custom keybinding):

```lua
-- user/keybind.lua — append your custom binds here

-- Open browser with SUPER+B
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))

-- Take a screenshot with PrintScreen
hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/ScreenShot.sh --now"))
```

**No reload command** — Hyprland detects the file change and reloads within ~1s.

### Switch Layout

The config supports 3 layouts, cycled by `SUPER + ALT + L`:

```lua
-- In-process state machine (sys/statemachine/layout.lua)
scrolling  →  dwindle  →  master  →  scrolling → ...
```

Press `SUPER + ALT + L` to cycle, or set initial layout in `user/layout.lua`:

```lua
-- user/layout.lua
hl.config({ general = { layout = "dwindle" } })  -- "scrolling" | "dwindle" | "master"
```

---

## 🔧 Common First Tasks

### Task 1: Add Your Favorite Applications

Edit `user/tags.lua` and `user/rules.lua` (both are **Lua** files using `hl.window_rule`):

```bash
nano ~/.config/hypr/user/tags.lua
nano ~/.config/hypr/user/rules.lua
```

**Example** (make Firefox float, terminal-classify a custom app):

```lua
-- user/tags.lua — register a new app to a tag
hl.window_rule({
  match = { class = "^([Mm]yapp)$" },
  tag = "myapp",
})

-- user/rules.lua — define behavior for that tag
hl.window_rule({
  float = true,
  match = { tag = "myapp" },
})
hl.window_rule({
  size = "1200 800",
  match = { tag = "myapp" },
})
```

### Task 2: Configure Input Devices

Edit `user/input.lua`:

```lua
-- user/input.lua
hl.config({ input = { kb_layout = "us,cn" } })
hl.config({ input = { kb_options = "caps:escape" } })
hl.config({ input = { touchpad = { natural_scroll = true } } })
hl.config({ input = { touchpad = { ["tap-to-click"] = true } } })
```

### Task 3: Enable Night Light

The config ships a Lua state machine for night light (`sys/statemachine/nightlight.lua`):

```bash
# Toggle night light at 4500K (state persists across sessions)
Press: SUPER + N
```

Or add your own keybinding in `user/keybind.lua` (the sys bind already does this; this is an example of adding a second bind):

```lua
-- user/keybind.lua
hl.bind("SUPER + SHIFT + S", function()
  -- Calls the in-config SM directly
  require('sys.statemachine.nightlight').new(hl):fire("toggle")
end)
```

---

## 🐛 Troubleshooting First Launch

### Problem 1: Black Screen

**Symptoms**: Hyprland starts but screen is black

**Solutions**:

```bash
# Check if Hyprland is running
ps aux | grep Hyprland

# Check logs — look for Lua errors specifically
journalctl -u hyprland-session -f

# Common .lua error: "module not found" — check require paths
# Common .lua error: "syntax error" — run luacheck
luacheck ~/.config/hypr --codes

# Try restarting
killall Hyprland && Hyprland
```

### Problem 2: No Waybar

**Symptoms**: Desktop loads but no status bar

**Solutions**:

```bash
# Check if waybar is installed
which waybar

# Start waybar manually (sys/startup.lua launches it via hl.on("hyprland.start", fn))
waybar &

# Restart waybar
killall waybar && waybar &
```

### Problem 3: Wrong Keyboard Layout

**Symptoms**: Keyboard types wrong characters

**Solution**:

```lua
-- user/input.lua — edit and save; Hyprland auto-reloads
hl.config({ input = { kb_layout = "us,cn" } })
```

### Problem 4: "Unknown keysym" Error

**Symptoms**: Hyprland log shows `[ERROR] unknown keysym xf86audioraisevolume`

**Cause**: `.lua` requires CamelCase keysym names; `.conf` accepted lowercase.

```lua
-- BAD: lowercase (would error at runtime)
hl.bind("xf86audioraisevolume", ...)

-- GOOD: CamelCase
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/Volume.sh --inc"),
       { locked = true, repeating = true })
```

See [COMPATIBILITY.md § XF86 keysym](../07-Lua-Reference/COMPATIBILITY.md#35-xf86-keysym-规范) for the full table.

### Problem 5: Wallpaper Not Loading

```bash
# Check if awww is running
ps aux | grep awww

# Initialize awww
awww init

# Set wallpaper manually
awww img ~/.config/hypr/wallpaper_effects/.wallpaper_current
```

The startup hook lives in `sys/startup.lua`:

```lua
-- sys/startup.lua
hl.on("hyprland.start", function()
  hl.exec_cmd("awww-daemon --format xrgb")
  -- ...
end)
```

---

## 📚 Next Steps

Congratulations! Your Hyprland configuration is running. Now explore:

### Learn the Basics (15 min)

- **[Common Tasks](COMMON_TASKS.md)** — Cheat sheet for frequent operations

### Understand Architecture (90 min)

- **[Three-Layer Constants](../02-Architecture/THREE_LAYER_CONSTANTS.md)** — How customization works
- **[Architecture Overview](../02-Architecture/ARCHITECTURE_OVERVIEW.md)** — High-level design

### Advanced Customization (3+ hours)

- **[Tag System](../03-Core-Systems/TAG_SYSTEM.md)** — Window management
- **[State Machines](../03-Core-Systems/STATE_MACHINES.md)** — Runtime behavior (Lua SM modules)
- **[Lua Reference](../07-Lua-Reference/README.md)** — Full `hl.*` API and patterns

---

## 🎓 Essential Keyboard Shortcuts

| Shortcut                  | Action                              |
| ------------------------- | ----------------------------------- |
| `SUPER + Return`          | Open terminal                       |
| `SUPER + D`               | Application launcher (Rofi)         |
| `SUPER + Q`               | Close active window                 |
| `SUPER + ALT + L`         | Cycle layouts (scrolling → dwindle → master) |
| `SUPER + J / K`           | Cycle windows (layout-aware)        |
| `SUPER + H`               | Cheat sheet                         |
| `SUPER + F`               | Toggle fullscreen                   |
| `SUPER + P`               | Toggle pseudo mode                  |
| `SUPER + Tab`             | Switch workspaces                   |
| `SUPER + 1-9`             | Go to workspace 1-9                 |
| `SUPER + Shift + 1-9`     | Move window to workspace 1-9        |
| `SUPER + Shift + G`       | Toggle game mode                    |
| `SUPER + N`               | Toggle night light                  |
| `SUPER + Shift + E`       | Quick Settings menu                 |

**Full keybinding reference**: See  _(coming soon)_

---

## 💡 Pro Tips

### Tip 1: Use Incremental Overrides

Never edit `sys/` files directly. Always create corresponding `user/` files with only your changes.

```lua
-- GOOD: user/input.lua (only your changes)
hl.config({ input = { kb_layout = "us,cn" } })

-- BAD: Editing sys/input.lua directly (will be overwritten on git pull)
```

### Tip 2: Test Changes Safely (No GPU Required)

```bash
# Headless validation — runs Lua + Hyprland without GPU
WLR_BACKENDS=headless hyprland \
  --config ~/.config/hypr/hyprland.lua \
  --i-am-really-stupid 2>&1 | grep -iE "lua|error"
# Expected: "Welcome to Hyprland!" with 0 Lua errors

# Static check before launching
luacheck ~/.config/hypr --codes
```

### Tip 3: Backup Working Config

```bash
# Create backup of working configuration
cp -r ~/.config/hypr ~/.config/hypr.working.$(date +%Y%m%d)
```

### Tip 4: Read Logs for Debugging

```bash
# View Hyprland logs (Lua errors print to stderr)
journalctl -u hyprland-session -f

# Or check runtime logs
tail -f /tmp/hypr/hyprland.log
```

---

## 🆘 Getting Help

### Documentation

- **[Documentation Index](../06-Meta/DOCUMENTATION_INDEX.md)** — Complete navigation
- **[Troubleshooting Guide](../05-Reference/TROUBLESHOOTING.md)** — Detailed problem solving
- **[Design Principles](../02-Architecture/DESIGN_PRINCIPLES.md)** — Why things work this way
- **[Lua Reference](../07-Lua-Reference/README.md)** — Full `.lua` API

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

# Lua-specific diagnostic
luacheck ~/.config/hypr --codes
```

---

## ✅ Verification Checklist

Before considering setup complete, verify:

- [ ] Hyprland starts without errors (check `journalctl -u hyprland-session`)
- [ ] `luacheck ~/.config/hypr --codes` reports 0 errors
- [ ] Wallpaper displays correctly
- [ ] Waybar shows system information
- [ ] Terminal opens with `SUPER + Return` (uses `$M_terminal`)
- [ ] Application launcher works with `SUPER + D`
- [ ] Keyboard layout is correct
- [ ] Touchpad/mouse works as expected
- [ ] Can switch workspaces
- [ ] Can close windows
- [ ] Layout cycle works (`SUPER + ALT + L`)
- [ ] Night light toggle works (`SUPER + N`)
- [ ] Game mode toggle works (`SUPER + Shift + G`)

**All checked?** 🎉 You're ready to customize!

---

## Historical .conf form

> The following example shows the **legacy `.conf` syntax** preserved here for historical context only. The current repo no longer contains `.conf` files — see git history for the migration.

### Example 1: const + bind + exec-once (LEGACY `.conf`)

```conf
# user/const.conf  (LEGACY — not in current repo)
$M_terminal = ghostty

# user/keybind.conf  (LEGACY)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("$M_terminal"))

# sys/startup.conf  (LEGACY)
exec-once = awww-daemon --format xrgb
exec-once = waybar
```

**Equivalence**: In `.lua`, `$M_terminal = "ghostty"` becomes a table key `['M_terminal = "ghostty"` inside `return { ... }` in `user/const.lua`. `bind = SUPER, Return, exec, $M_terminal` becomes `hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))` (no `$var` substitution — the value is baked in at merge time). `exec-once = cmd` becomes `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` — event-driven, with the bonus of `hl.on("hyprland.shutdown", fn)` cleanup hooks that were impossible in the `.conf` era.

---

**Next**: [Common Tasks Cheat Sheet](COMMON_TASKS.md)
**Questions?**: See [Troubleshooting Guide](../05-Reference/TROUBLESHOOTING.md)

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
