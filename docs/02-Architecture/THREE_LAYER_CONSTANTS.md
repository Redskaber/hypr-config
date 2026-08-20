# Three-Layer Constant System

> Pure `.lua` (Hyprland v0.55+). Verified against actual code in
> [`bootstrap/const.lua`](../../bootstrap/const.lua),
> [`sys/const.lua`](../../sys/const.lua),
> [`user/const.lua`](../../user/const.lua).

## Overview

Constants live in a single global table `_G.HYPR_CONST`, populated by three
layered files. Each file writes to the same table; **last-write-wins** gives
user overrides priority.

This is **not** a Hyprland DSL feature — it's a plain Lua convention. There is
no `deep_merge()` function and no `return { ... }` table-return form. Each
const file runs `require`d in order and mutates the shared global table.

## Architecture

```
_G.HYPR_CONST = {}                   ← created by bootstrap/default.lua
       │
       ▼
require("bootstrap.const")          ← Layer 1: path infrastructure (immutable)
       │  _G.HYPR_CONST.Hypr  = "~/.config/hypr"
       │  _G.HYPR_CONST.sys   = "~/.config/hypr/sys"
       │  _G.HYPR_CONST.user  = "~/.config/hypr/user"
       ▼
require("sys.const")                ← Layer 2: system defaults (read-only)
       │  _G.HYPR_CONST.M          = "SUPER"
       │  _G.HYPR_CONST.M_terminal = "kitty"
       │  _G.HYPR_CONST.S          = "~/.config/hypr/sys/scripts"
       │  ... (25+ keys)
       ▼
require("user.const")              ← Layer 3: user deltas (EDIT HERE)
       │  _G.HYPR_CONST.M_terminal = "ghostty"   ← wins (loaded last)
       │  _G.HYPR_CONST.Search_Engine = "https://www.bing.com/search?q={}"
       ▼
_G.HYPR_CONST is now the merged SSOT
       │
       ▼
All later modules (sys/keybind, sys/startup, ...) read _G.HYPR_CONST
```

## The Three Layers

### Layer 1: `bootstrap/const.lua` — Path Infrastructure (immutable)

Defines absolute path constants. **Never edit** — these are the foundation
that other layers depend on.

```lua
-- bootstrap/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}

_G.HYPR_CONST.Hypr  = "~/.config/hypr"
_G.HYPR_CONST.sys   = "~/.config/hypr/sys"
_G.HYPR_CONST.user  = "~/.config/hypr/user"
_G.HYPR_CONST.lock_background = "~/.config/hypr/wallpaper_effects/.wallpaper_current"
```

### Layer 2: `sys/const.lua` — System Defaults (vendor, read-only)

Defines default applications, paths to scripts/hardware/policy, and helper
constants. **Treat as read-only** — overrides go in `user/const.lua`.

```lua
-- sys/const.lua (excerpt)
_G.HYPR_CONST = _G.HYPR_CONST or {}

_G.HYPR_CONST.M          = "SUPER"                          -- main modifier
_G.HYPR_CONST.M_terminal = "kitty"
_G.HYPR_CONST.M_file_manager = "nemo"
_G.HYPR_CONST.M_editor   = os.getenv("EDITOR") or "nano"

_G.HYPR_CONST.S = "~/.config/hypr/sys/scripts"             -- scripts dir
_G.HYPR_CONST.H = "~/.config/hypr/sys/hardware"            -- hardware dir
_G.HYPR_CONST.P = "~/.config/hypr/sys/policy"              -- policy dir
_G.HYPR_CONST.P_w = "~/.config/hypr/sys/policy/wallust"
_G.HYPR_CONST.P_a = "~/.config/hypr/sys/policy/animations"

_G.HYPR_CONST.W          = "~/.config/hypr/Pictures/wallpapers"
_G.HYPR_CONST.I_notify   = "~/.config/hypr/icon.png"
_G.HYPR_CONST.Search_Engine = "https://www.google.com/search?q={}"
```

### Layer 3: `user/const.lua` — User Deltas (EDIT HERE)

Override only the keys you want to change. **Last-write-wins** on the shared
`_G.HYPR_CONST` table means user values always win.

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}

_G.HYPR_CONST.M_terminal = "ghostty"                                  -- ← wins
_G.HYPR_CONST.Search_Engine = "https://www.bing.com/search?q={}"      -- ← wins
-- M_editor, M_file_manager, W, I_notify inherit from sys/const.lua
```

## How It Works: last-write-wins

The bootstrap orchestrator ([`bootstrap/default.lua`](../../bootstrap/default.lua))
runs the three `require` calls in order:

```lua
-- bootstrap/default.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
require("bootstrap.const")   -- Layer 1
require("sys.const")          -- Layer 2
require("user.const")         -- Layer 3 (overrides)
require("sys.default")        -- pipeline continues
```

Each `require` executes the file top-to-bottom, mutating `_G.HYPR_CONST` in
place. When `user/const.lua` runs `_G.HYPR_CONST.M_terminal = "ghostty"`, it
overwrites the `"kitty"` set by `sys/const.lua` moments earlier.

After all three layers run, every later module reads the merged table:

```lua
-- sys/keybind.lua
local const = _G.HYPR_CONST
hl.bind(const.M .. " + Return", hl.dsp.exec_cmd(const.M_terminal))
--                                   ↑ resolves to "ghostty" (user override won)
```

## Design Principles Applied

| Principle | How |
| --- | --- |
| **Single Source of Truth (SSOT)** | One table `_G.HYPR_CONST`, one key per concept |
| **Dependency Inversion** | Modules depend on the const abstraction, not specific values |
| **Open/Closed** | `sys/const.lua` closed for modification; `user/const.lua` open for extension |
| **Incremental Override** | User files contain only deltas — no need to redeclare defaults |
| **Layered Architecture** | Clear boundary: bootstrap (infra) → sys (vendor) → user (you) |

## Common Tasks

### Change the terminal emulator

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.M_terminal = "ghostty"   -- kitty, alacritty, foot, wezterm, ghostty
```

### Change the wallpaper directory

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.W = "~/Pictures/my-wallpapers"
```

### Change the search engine (used by RofiSearch.sh)

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.Search_Engine = "https://duckduckgo.com/?q={}"
```

### Add a brand-new constant

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.my_browser = "firefox"   -- then use _G.HYPR_CONST.my_browser in user/keybind.lua
```

## Naming Convention

| Prefix | Meaning | Example |
| --- | --- | --- |
| `M_*` | Application / command | `M_terminal`, `M_file_manager`, `M_editor` |
| `M` | Main modifier key | `M = "SUPER"` |
| `S` | sys/scripts directory | `S = "~/.config/hypr/sys/scripts"` |
| `H` | sys/hardware directory | `H = "~/.config/hypr/sys/hardware"` |
| `P` | sys/policy directory | `P = "~/.config/hypr/sys/policy"` |
| `U*` | User-side equivalents | `U_s`, `U_h`, `U_p` |
| `W` | Wallpaper directory | `W = "~/.config/hypr/Pictures/wallpapers"` |
| `H_*` | Helper tags (window tag names) | `H_Cheat`, `H_Settings` |
| `I_*` | Icons / images | `I_notify` |

## Debugging

### Print all constants at runtime

```bash
hyprctl eval 'for k,v in pairs(_G.HYPR_CONST) do print(k, "=", v) end'
```

### Check a specific value

```bash
hyprctl eval 'return _G.HYPR_CONST.M_terminal'
```

### Common Issues

| Symptom | Cause | Fix |
| --- | --- | --- |
| Override not taking effect | Edited `sys/const.lua` instead of `user/const.lua` | Move edits to `user/const.lua` |
| Lua error "attempt to index nil" | `_G.HYPR_CONST` not yet initialized | Ensure `bootstrap/default.lua` loads const layers first |
| Value still shows old default | Hyprland didn't reload | Save any `.lua` file to trigger auto-reload |

## References

- [`bootstrap/default.lua`](../../bootstrap/default.lua) — pipeline orchestrator
- [`bootstrap/const.lua`](../../bootstrap/const.lua) — Layer 1 source
- [`sys/const.lua`](../../sys/const.lua) — Layer 2 source
- [`user/const.lua`](../../user/const.lua) — Layer 3 source (edit here)
- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
