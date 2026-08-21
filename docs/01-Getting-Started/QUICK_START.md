# Quick Start Guide

> Get your Hyprland configuration up and running in **5 minutes**.
> Pure `.lua` (Hyprland v0.55+). Verified against actual code.

This guide assumes a fresh Wayland session and this `.lua`-first config. The
config uses Hyprland's native `hl.*` Lua API — auto-reloads on `.lua` file save
(no `hyprctl reload` for most edits).

---

## 🎯 Prerequisites

- **Hyprland** ≥ 0.55.0 (tested on 0.56.2; Lua config native)
- **Wayland session** running
- **Required packages** (25 declared in [`lib/deps.lua`](../../lib/deps.lua), top ones):
  `hyprland` `hyprlock` `hypridle` `awww` `waybar` `swaync` `rofi` `wallust` `cliphist` `wl-clipboard` `grim` `slurp` `jq`

### Check Installation

```bash
# Verify Hyprland version (must be >= 0.55.0 for .lua config)
hyprctl version

# Check required packages
which awww waybar rofi swaync cliphist hypridle wallust
```

**Install missing packages** (choose your distro):

```bash
# Arch Linux
sudo pacman -S awww waybar rofi swaync cliphist hypridle wallust \
                 wl-clipboard grim slurp jq

# Fedora
sudo dnf install awww waybar rofi swaync cliphist hypridle wallust \
                  wl-clipboard grim slurp jq

# NixOS (in configuration.nix)
environment.systemPackages = with pkgs; [
  awww waybar rofi swaync cliphist hypridle wallust
  wl-clipboard grim slurp jq
];
```

> ℹ️ `awww` is the renamed `swww` (wallpaper daemon). If your distro only has
> `swww`, install that and override in `user/const.lua` (see below).

---

## 📥 Installation

### Step 1: Clone the config

```bash
# Backup existing config (if any)
[ -d ~/.config/hypr ] && mv ~/.config/hypr ~/.config/hypr.bak

# Clone
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr
```

### Step 2: Edit user constants

```bash
$EDITOR ~/.config/hypr/user/const.lua
```

Minimal edit — override only what differs from sys defaults:

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}

_G.HYPR_CONST.M_terminal = "kitty"        -- your terminal (default: kitty)
_G.HYPR_CONST.M_file_manager = "thunar"  -- your file manager (default: nemo)
_G.HYPR_CONST.W = "~/Pictures/wallpapers" -- your wallpaper dir
```

### Step 3: Verify the config

```bash
# Static analysis
luacheck ~/.config/hypr --codes

# Runtime simulator (executes the full pipeline)
cd ~/.config/hypr && hyprland --verify-config

# Real Hyprland (gold standard, needs nix store access)
hyprland --verify-config
```

Expected: `✅ Pipeline loaded successfully` + `0 errors`.

### Step 4: Launch Hyprland

```bash
# From a TTY
Hyprland

# Or via display manager (add Hyprland to your DM's session list)
```

---

## 🎨 First Run

On first launch, Hyprland loads `hyprland.lua` → `bootstrap.default` → full
pipeline. You should see:

- Waybar at the bottom (or top — configurable)
- Swaync notification daemon running
- Wallpaper daemon (awww) running
- Default `dwindle` layout active

### Try the keybinds

| Key | Action |
| --- | --- |
| `SUPER + D` | App launcher (rofi) |
| `SUPER + Return` | Terminal |
| `SUPER + E` | File manager |
| `SUPER + W` | Wallpaper selector |
| `SUPER + H` | Cheat sheet (all keybinds) |
| `SUPER + SHIFT + K` | Searchable keybind list |
| `SUPER + ALT + L` | Cycle layout (dwindle → master → scrolling) |
| `SUPER + Q` | Close window |
| `CTRL + ALT + L` | Lock screen |

Press `SUPER + H` for the full cheat sheet at any time.

---

## 🔧 Common First-Time Customizations

### Change the terminal

```lua
-- user/const.lua
_G.HYPR_CONST.M_terminal = "alacritty"   -- or "foot", "wezterm", "ghostty"
```

Hyprland auto-reloads on save — no reload command needed.

### Change the wallpaper directory

```lua
-- user/const.lua
_G.HYPR_CONST.W = "~/Pictures/my-wallpapers"
```

Then press `SUPER + W` to pick a wallpaper (wallust auto-generates colors).

### Add a custom keybind

```lua
-- user/keybind.lua
local const = _G.HYPR_CONST
hl.bind(const.M .. " + T", hl.dsp.exec_cmd("thunderbird"))
```

### Switch animation preset

Edit `sys/policy/default.lua`:
```lua
-- was: require("sys.policy.animations.default")
require("sys.policy.animations.ml4w-fast")   -- faster animations
```

---

## 🐛 Troubleshooting First Run

### Config doesn't load

```bash
# 1. Static check
luacheck ~/.config/hypr --codes

# 2. Runtime check (catches errors luacheck misses)
cd ~/.config/hypr && hyprland --verify-config

# 3. Real Hyprland verify
hyprland --verify-config

# 4. Check session log
journalctl -u hyprland-session -f
# or: cat ~/.cache/hyprland/$(cat /tmp/hypr/.env | grep HYPRLAND_INSTANCE_SIGNATURE | cut -d= -f2)/hyprland.log
```

### Waybar / swaync not starting

Check `sys/startup.lua` — daemons are launched via `deps.get("name").cmd`:

```lua
-- sys/startup.lua (excerpt)
local bar = deps.get("bar")
if bar and bar.found then hl.exec_cmd(bar.cmd) end
```

If `deps.get("bar").found` is false, install `waybar` (or override via `HYPR_BAR` env var).

### Wallpaper daemon errors

`awww` is the renamed `swww`. If you only have `swww`:

```lua
-- user/const.lua override (extend lib/deps.lua spec)
-- Or set env var: export HYPR_WALLPAPER_DAEMON=swww-daemon
```

See [../05-Reference/TROUBLESHOOTING.md](../05-Reference/TROUBLESHOOTING.md) for full guide.

---

## 📚 Next Steps

- [Common Tasks](COMMON_TASKS.md) — cheat sheet for frequent operations
- [Architecture Overview](../02-Architecture/ARCHITECTURE_OVERVIEW.md) — understand the design
- [Tag System](../03-Core-Systems/TAG_SYSTEM.md) — how windows get classified
- [State Machines](../03-Core-Systems/STATE_MACHINES.md) — layout/gamemode/nightlight FSMs
- [Troubleshooting](../05-Reference/TROUBLESHOOTING.md) — diagnose issues

---

**⏱️ Time to complete**: ~5 minutes (clone + edit const.lua + launch).
