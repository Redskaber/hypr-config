# Three-Layer Constant System

> Pure `.lua` (Hyprland v0.55+). Verified against actual code in
> [`bootstrap/const.lua`](../../bootstrap/const.lua),
> [`bootstrap/default.lua`](../../bootstrap/default.lua),
> [`sys/const.lua`](../../sys/const.lua),
> [`user/const.lua`](../../user/const.lua).
>
> **Round 105**: This doc was completely rewritten — the previous version
> described a `_G.HYPR_CONST` global mutation pattern that was removed in
> Task 85. The actual code uses `package.loaded["const"] = const` injection.

## Overview

Constants are a **module-injected singleton** (`const`), populated by three
layered files and merged via `deep_merge()`. Each layer has a clear role:

| Layer | File | Role | Mutability |
|---|---|---|---|
| 1 | `bootstrap/const.lua` | Path infrastructure (immutable base) | Never edit |
| 2 | `sys/const.lua` | System defaults + SSOT export to shell | Read-only |
| 3 | `user/const.lua` | User deltas (incremental overrides) | **EDIT HERE** |

The merged `const` table is the **Single Source of Truth (SSOT)** for:
- Application commands (`const.apps.terminal`, `const.apps.file_manager`, ...)
- Main modifier key (`const.modifier`)
- Internal directory paths (`const.dirs.scripts`, `const.dirs.hardware`, ...)
- External tool config paths (`const.external.swaync_dir`, `const.external.rofi_dir`, ...)
- Helper tag names (`const.helpers.cheat`, `const.helpers.settings`)
- Search engine URL (`const.search_engine`)
- Wallpaper directory (`const.wallpaper_dir`)

## Architecture

```
hyprland.lua
  └── bootstrap/default.lua
        ├── require("bootstrap.const")    ← Layer 1: paths (immutable)
        ├── require("sys.const")          ← Layer 2: system defaults
        ├── require("user.const")         ← Layer 3: user deltas (EDIT HERE)
        │
        ├── deep_merge(sys_const.apps, user_const.apps)
        ├── deep_merge(sys_const.external, user_const.external)
        │
        ├── package.loaded["const"] = merged_const   ← INJECT module
        │
        └── sys_const.export_to_shell()              ← Generate .deps_cache.sh
              │
              ▼
        All later modules use require("const")
        Shell scripts source .deps_cache.sh
```

## The Three Layers

### Layer 1: `bootstrap/const.lua` — Path Infrastructure (immutable)

Defines absolute path constants derived from `XDG_CONFIG_HOME` (or `~/.config`)
and `XDG_CACHE_HOME` (or `~/.cache`). **Never edit** — these are the foundation
that other layers depend on.

```lua
-- bootstrap/const.lua (actual code, Round 109)
local M = {}
M.config_hypr = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config") .. "/hypr"
M.bootstrap = M.config_hypr .. "/bootstrap"
M.sys = M.config_hypr .. "/sys"
M.user = M.config_hypr .. "/user"
M.wallust_effects = M.config_hypr .. "/wallust_effects"
M.lock_background = M.config_hypr .. "/wallpaper_effects/.wallpaper_current"
M.icon = M.config_hypr .. "/icon.png"
-- Round 109: cache dir (XDG_CACHE_HOME or ~/.cache) for state persistence files
M.cache_dir = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
return M
```

### Layer 2: `sys/const.lua` — System Defaults (read-only)

Defines default values for all SSOT keys + the `M.export_to_shell()` function
that generates `.deps_cache.sh` for shell-script DI.

```lua
-- sys/const.lua (actual code, abbreviated)
local M = {}
M.apps = { terminal = "kitty", file_manager = "nemo", editor = os.getenv("EDITOR") or "nano" }
M.modifier = "SUPER"
M.dirs = { scripts = paths.sys .. "/scripts", hardware = paths.sys .. "/hardware", ... }
M.external = { swaync_dir = HOME .. "/.config/swaync", rofi_dir = HOME .. "/.config/rofi", ... }
M.helpers = { cheat = "Help_Cheat", settings = "Help_Settings" }
M.search_engine = "https://www.google.com/search?q={}"
M.wallpaper_dir = HOME .. "/Pictures/wallpapers"
M.notify_icon = paths.icon
M.config_hypr = paths.config_hypr

function M.export_to_shell() ... end  -- generates .deps_cache.sh
return M
```

### Layer 3: `user/const.lua` — User Deltas (EDIT HERE)

Contains **only the deltas** — keys you want to override. The `deep_merge()`
in `bootstrap/default.lua` overlays these on top of sys defaults.

```lua
-- user/const.lua (example override)
local M = {}
M.apps = { terminal = "ghostty" }       -- overrides sys.apps.terminal
M.modifier = "SUPER"                     -- overrides sys.modifier
M.external = { rofi_dir = HOME .. "/.config/rofi-custom" }
M.wallpaper_dir = HOME .. "/Pictures/wallpapers-custom"
return M
```

## Module Injection (not global mutation)

The merged const is registered as the `"const"` module via Lua's
`package.loaded` mechanism:

```lua
-- bootstrap/default.lua (actual code)
package.loaded["const"] = const  -- inject merged const as "const" module
```

This allows all downstream modules to access the SSOT via standard `require`:

```lua
-- any module (sys/keybind.lua, sys/startup.lua, etc.)
local const = require("const")
print(const.apps.terminal)          -- "kitty" (or "ghostty" if user overrode)
print(const.dirs.scripts)           -- "/home/user/.config/hypr/sys/scripts"
print(const.external.swaync_dir)    -- "/home/user/.config/swaync"
```

## Shell Export (SSOT → shell scripts)

`sys/const.lua:M.export_to_shell()` generates `.deps_cache.sh`, a
shell-sourceable file containing all paths + DI variables as `export` statements:

```bash
# .deps_cache.sh (auto-generated)
export HYPR_CONFIG_DIR="/home/user/.config/hypr"
export HYPR_SCRIPTS_DIR="/home/user/.config/hypr/sys/scripts"
export HYPR_WALLPAPER_DIR="/home/user/Pictures/wallpapers"
export SWAYNC_DIR="/home/user/.config/swaync"
export ROFI_DIR="/home/user/.config/rofi"
export TERMINAL="kitty"
export NOTIFY="notify-send"
# ... (all 26 deps + all paths)
```

Shell scripts source this file via `lib/common.sh`:

```bash
# sys/scripts/lib/common.sh
_DEPS_CACHE="${HYPR_DEPS_CACHE:-${XDG_CONFIG_HOME:-$HOME/.config}/hypr/.deps_cache.sh}"
[ -f "$_DEPS_CACHE" ] && . "$_DEPS_CACHE" || {
  # Fallback defaults if cache missing (e.g. script run before Hyprland starts)
  : "${HYPRCTL:=hyprctl}"
  : "${NOTIFY:=notify-send}"
  # ... (26 fallback defaults)
}
```

## Validation

```bash
# Verify the merged const is correctly injected
lua -e '
  package.path = "./?.lua;./lib/?.lua"
  require("bootstrap.default")
  local const = require("const")
  print("terminal:", const.apps.terminal)
  print("scripts:", const.dirs.scripts)
  print("swaync_dir:", const.external.swaync_dir)
'

# Verify .deps_cache.sh is generated
cat ~/.config/hypr/.deps_cache.sh | head -5
```

## Key Design Principles

1. **Single Source of Truth (SSOT)**: `sys/const.lua` is the ONLY place paths
   and DI variables are defined. Shell scripts never hardcode paths.

2. **Incremental Override**: `user/const.lua` contains only deltas, not full
   copies. Easier to maintain, less drift.

3. **Deep Merge**: Tables are merged recursively (sys + user), so users can
   override a single key without redefining the whole table.

4. **Module Injection**: `package.loaded["const"] = const` is cleaner than
   `_G.HYPR_CONST` global mutation (no global namespace pollution).

5. **Shell Bridge**: `export_to_shell()` auto-generates `.deps_cache.sh` so
   shell scripts get the same SSOT values (no manual sync).

6. **Resilience**: `lib/common.sh` has fallback defaults if `.deps_cache.sh`
   is missing (e.g. script run before Hyprland starts).

## References

- [`bootstrap/default.lua`](../../bootstrap/default.lua) — merge + injection
- [`sys/const.lua`](../../sys/const.lua) — SSOT + shell export
- [`user/const.lua`](../../user/const.lua) — user deltas
- [`sys/scripts/lib/common.sh`](../../sys/scripts/lib/common.sh) — shell DI
- [`lib/deps.lua`](../../lib/deps.lua) — 26-tool DI manifest
