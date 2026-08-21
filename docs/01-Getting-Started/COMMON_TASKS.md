# Common Tasks Cheat Sheet

> Quick reference for frequent operations — copy, paste, done!
> Pure `.lua` (Hyprland v0.55+). Verified against actual code.

---

## 📋 Application Management

### Open Terminal

```lua
-- sys/keybind.lua (already bound by default)
local const = _G.HYPR_CONST
hl.bind(const.M .. " + Return", hl.dsp.exec_cmd(const.M_terminal))
```

To change the terminal, edit `user/const.lua`:
```lua
_G.HYPR_CONST.M_terminal = "alacritty"
```

### Open App Launcher

`SUPER + D` → rofi drun (already bound).

### Open File Manager

`SUPER + E` → `M_file_manager` (default: nemo).

---

## 🪟 Window Management

### Float a Window

```lua
-- user/rules.lua
hl.window_rule({ float = true, match = { class = "^([Mm]yapp)$" } })
```

### Center a Floating Window

```lua
-- user/rules.lua
hl.window_rule({ center = true, match = { tag = "myapp" } })
```

### Set Window Size (relative to monitor)

```lua
-- user/rules.lua
hl.window_rule({
  size = { "monitor_w * 0.60", "monitor_h * 0.70" },
  match = { tag = "myapp" },
})
```

> ⚠️ `size` uses Lua table form for expressions: `{ "expr1", "expr2" }`,
> NOT `"(expr1) (expr2)"` (string with parens).

### Set Window Size (absolute pixels)

```lua
hl.window_rule({ size = "480 640", match = { tag = "calculator" } })
```

### Set Opacity

```lua
-- Format: "active inactive" or "active inactive fullscreen"
hl.window_rule({ opacity = "0.90 0.80", match = { tag = "terminal" } })
```

---

## 🏷️ Workspace Operations

### Switch Workspace

`SUPER + 1` through `SUPER + 0` (bound in `sys/keybind.lua`).

### Move Window to Workspace

```lua
-- user/keybind.lua
local const = _G.HYPR_CONST
hl.bind(const.M .. " + SHIFT + 1", hl.dsp.window.move({ workspace = "1" }))
```

### Toggle Special Workspace (scratchpad)

```lua
hl.bind(const.M .. " + S", hl.dsp.workspace.toggle_special("scratchpad"))
```

---

## ⚙️ System Controls

### Lock Screen

`CTRL + ALT + L` → `sys/scripts/LockScreen.sh` (hyprlock).

### Logout Menu

`CTRL + ALT + P` → `sys/scripts/Wlogout.sh`.

### Exit Hyprland

`CTRL + ALT + Delete` → `hl.dsp.exit()`.

### Refresh Bar/Notifications

`SUPER + ALT + R` → `sys/scripts/Refresh.sh` (restarts waybar + swaync).

---

## 🔧 Configuration Changes

### Change Modifier Key

```lua
-- user/const.lua
_G.HYPR_CONST.M = "ALT"   -- was "SUPER" (default)
```

### Change Keyboard Layout

```lua
-- user/input.lua
hl.config({ input = { kb_layout = "us,cn" } })   -- multiple layouts
```

### Enable Variable Frame Rate (power saving)

```lua
-- user/misc.lua
hl.config({ misc = { vfr = true } })
```

### Set Environment Variables

```lua
-- user/env.lua
hl.env("EDITOR", "nvim")
hl.env("HYPR_TERMINAL", "ghostty")
hl.env("GDK_SCALE", "1.5")          -- HiDPI
hl.env("QT_SCALE_FACTOR", "1.5")
```

---

## 🖥️ Add HiDPI / Multi-monitor

### Set Monitor Scale

```lua
-- sys/hardware/monitors.lua (edit, or override in user/)
hl.monitor({
  name = "eDP-1",
  resolution = "1920x1080@60",
  position = "0x0",
  scale = 1.5,    -- HiDPI scale (1.0 = no scaling)
})
```

### Multi-monitor Layout

```lua
-- sys/hardware/monitors.lua
hl.monitor({ output = "eDP-1", resolution = "1920x1080", position = "0x0",   scale = 1.0 })
hl.monitor({ output = "DP-1",  resolution = "2560x1440", position = "1920x0", scale = 1.0 })
```

---

## 🎮 Enable NVIDIA

```lua
-- user/env.lua
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_GSYNC_ALLOWED", "1")
```

```lua
-- user/render.lua
hl.config({ opengl = { nvidia_anti_flicker = true } })
```

See [../05-Reference/GPU_VERIFICATION_CHECKLIST.md](../05-Reference/GPU_VERIFICATION_CHECKLIST.md) for full NVIDIA setup.

---

## ⌨️ Add Custom Keybind

```lua
-- user/keybind.lua
local const = _G.HYPR_CONST

-- Simple bind (exec command)
hl.bind(const.M .. " + T", hl.dsp.exec_cmd("thunderbird"))

-- With flags (locked = fires on lock screen)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Repeat on hold
hl.bind("XF86Monbrightnessup", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })

-- Lua function (impossible in .conf era)
hl.bind(const.M .. " + ALT + G", function()
  require('sys.statemachine.gamemode').new(hl):fire("toggle")
end)
```

---

## 🏷️ Add Window Rule (Tag-based)

### Step 1: Classify the app

```lua
-- user/tags.lua
hl.window_rule({
  match = { class = "^([Mm]yapp)$" },
  tag = "myapp",
})
```

### Step 2: Define behavior

```lua
-- user/rules.lua
hl.window_rule({ float = true,   match = { tag = "myapp" } })
hl.window_rule({ center = true,  match = { tag = "myapp" } })
hl.window_rule({ size = { "monitor_w * 0.50", "monitor_h * 0.60" }, match = { tag = "myapp" } })
hl.window_rule({ opacity = "0.90 0.80", match = { tag = "myapp" } })
```

Or use the `floating_panel()` helper (DRY):
```lua
-- In user/rules.lua, you can't access sys helper; replicate the pattern
-- Or add your own helper at top of user/rules.lua
```

See [../03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) for full tag system docs.

---

## 🎨 Change Theme / Animations

### Switch Animation Preset

Edit `sys/policy/default.lua`:
```lua
-- was: require("sys.policy.animations.default")
require("sys.policy.animations.ml4w-fast")   -- options: default/disable/end4/hyde-optimized/hyde-vertical/ml4w-fast
```

### Apply Wallust Colors

Press `SUPER + W` → wallpaper selector → wallust auto-generates colors into
`sys/policy/wallust/wallust-hyprland.lua`.

### Toggle Dark/Light

`Quick Settings` menu (`SUPER + SHIFT + E`) → `DarkLight.sh`.

---

## 🐛 Troubleshooting

### Config won't load

```bash
# 1. Static check
luacheck ~/.config/hypr --codes

# 2. Runtime simulator (catches errors luacheck misses)
cd ~/.config/hypr && hyprland --verify-config

# 3. Real Hyprland verify
hyprland --verify-config
```

### App not following rules

```bash
# Check the window's tag
hyprctl activewindow -j | jq '{class, tags}'

# Check exact class string (regex must match)
hyprctl clients -j | jq '.[] | select(.class | test("myapp")) | .class'
```

### Keybind not responding

```bash
# Check if the bind is registered
hyprctl binds -j | jq '.[] | select(.key | test("SUPER + T"))'
```

See [../05-Reference/TROUBLESHOOTING.md](../05-Reference/TROUBLESHOOTING.md) for full guide.

---

## 📚 References

- [Quick Start](QUICK_START.md) — 5-minute install
- [Architecture Overview](../02-Architecture/ARCHITECTURE_OVERVIEW.md) — design principles
- [Tag System](../03-Core-Systems/TAG_SYSTEM.md) — window classification
- [State Machines](../03-Core-Systems/STATE_MACHINES.md) — layout/gamemode/nightlight
- [Troubleshooting](../05-Reference/TROUBLESHOOTING.md) — diagnose issues
- [Hyprland Wiki](https://wiki.hypr.land/) — official API reference
