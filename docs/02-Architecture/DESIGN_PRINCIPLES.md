# Hyprland Configuration Architecture - Design Principles & Implementation

> **本文档以 .lua（Hyprland v0.55+ 原生）为准**。历史 .conf 形式见文末 [Historical .conf form](#historical-conf-form) 节，亦见 git history。
> 语法对照见 [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md)。

## Executive Summary

This is a **production-grade, layered pipeline architecture** for Hyprland ≥ 0.55.0 (Lua) that applies software engineering principles from compiler design, state machine theory, dependency injection, and policy-based management. The configuration treats the desktop environment as a **compiled system** rather than a collection of scripts.

In the `.lua` era, every "directive" from the `.conf` DSL becomes a function call on Hyprland's `hl.*` API (`hl.config`, `hl.bind`, `hl.window_rule`, `hl.on`, `hl.env`, `hl.monitor`, `hl.curve`, `hl.animation`). The architectural principles below remain unchanged; only the syntax has been reified.

---

## Table of Contents

1. [Core Design Principles](#core-design-principles)
2. [Compilation Pipeline Architecture](#compilation-pipeline-architecture)
3. [Layered Architecture & Boundary Management](#layered-architecture--boundary-management)
4. [Dependency Inversion & Incremental Override Pattern](#dependency-inversion--incremental-override-pattern)
5. [State Machine Implementation](#state-machine-implementation)
6. [Tag-Driven Window Management System](#tag-driven-window-management-system)
7. [Policy Layer & Runtime Swapping](#policy-layer--runtime-swapping)
8. [Process Lifecycle Management](#process-lifecycle-management)
9. [Single Responsibility Principle Applied](#single-responsibility-principle-applied)
10. [Software Design Patterns Catalog](#software-design-patterns-catalog)

---

## Core Design Principles

### 1. Single Entry Point (Facade Pattern)

```
hyprland.lua → bootstrap/default.lua → entire system
```

**Rationale**:

- Eliminates circular dependencies
- Provides clear initialization sequence
- Enables deterministic config loading order
- Simplifies debugging (single trace path)

**Implementation**:

```lua
-- hyprland.lua — NO LOGIC, ONLY REQUIRES
require("bootstrap.default")
```

The entire system is reachable from a single `require()` call. Adding logic directly to `hyprland.lua` is an anti-pattern; route everything through `bootstrap/default.lua`.

### 2. Incremental Override Pattern (Decorator Pattern)

Every `sys/X.lua` is immediately followed by `user/X.lua`:

```lua
-- sys/default.lua (orchestrator)
require("sys.env")    -- vendor defaults
require("user.env")   -- user overrides (later wins via hl.config)
```

**Mechanism**: `hl.config({ path = value })` mutates Hyprland's internal key→value store with last-write-wins semantics. Requiring `user.X` *after* `sys.X` ensures user deltas overwrite vendor defaults for the same key path.

**Benefits**:

- User files contain only deltas (minimal diff)
- Vendor updates don't overwrite user customizations
- Clear separation of concerns
- Git-friendly (user/ can be .gitignored or tracked separately)

### 3. Dependency Direction Control

Constants flow **downward only** through the pipeline:

```
Stage 0: bootstrap/const.lua   (return { ['Hypr = ..., ['sys = ... })
         ↓  deep_merge into C
Stage 0: sys/const.lua          (return { ['M = "SUPER", ... })
         ↓  deep_merge into C
Stage 0: user/const.lua         (return { ['M_terminal = "ghostty" })
         ↓  C is finalized
Stage 1+: sys/X.lua             (reads C['$M_terminal'] → "ghostty")
```

**Critical Design Decision**: `user/const.lua` is required in **Stage 0** (bootstrap), NOT Stage 1. This ensures all user-overridden constants are available throughout the entire pipeline, including `sys/` files.

### 4. Policy-Based Configuration

Swappable runtime policies without full reload:

- **Colors**: wallust-generated (`sys/policy/wallust/wallust-hyprland.lua` returns a color table)
- **Animations**: preset profiles (`sys/policy/animations/*.lua`)

**Runtime Switching**:

```bash
# .lua era: animation presets swap via hyprctl reload (full re-require)
# Or via targeted hyprctl keyword for individual options
hyprctl reload
```

### 5. Tag-Driven Rule System (Strategy Pattern)

Tags decouple **window classification** from **window behavior**:

```lua
-- sys/tags.lua   → defines WHAT an app IS (browser, terminal, im)
hl.window_rule({ match = { class = "^firefox$", tag = "browser" } })

-- sys/rules.lua  → defines HOW it behaves (float, center, opacity)
hl.window_rule({ opacity = "0.90", match = { tag = "browser" } })
```

**Benefits**:

- Single source of truth for tags
- Easy to audit completeness (every tag has rules)
- Compound conditions isolated to edge cases
- User extensions via `user/tags.lua` + `user/rules.lua`

---

## Compilation Pipeline Architecture

The configuration loading process mirrors a **compiler pipeline**. In `.lua`, each phase maps to a concrete `hl.*` API surface:

### Phase 1: Lexical Analysis (Token Definition)

**Files**: `bootstrap/const.lua`, `sys/const.lua`, `user/const.lua` — each returns a Lua table.

**Purpose**: Define all symbolic constants (tokens) as table keys:

```lua
-- sys/const.lua
return {
  ['M          = "SUPER",            -- modifier token
  ['S          = "~/.config/hypr/sys/scripts",  -- script path token
  ['H_Cheat    = "Help_Cheat",       -- semantic tag token
}
```

**Compiler Analogy**: Lexer converts raw source into tokens. In `.lua` the "lexer" is the `require()` call returning a table.

### Phase 2: Syntax Analysis (Grammar Rules)

**Files**: `bootstrap/default.lua`, `sys/default.lua` (pipeline orchestrators)

**Purpose**: Define valid require order (grammar):

```lua
-- sys/default.lua — grammar: hardware must come before policy
require("sys.hardware.default")    -- grammar rule: hardware before policy
require("sys.policy.default")

-- grammar rule: env before misc, sys before user (per domain)
require("sys.env")   require("user.env")
require("sys.misc")  require("user.misc")
```

**Compiler Analogy**: Parser validates token sequence against grammar. Here the "grammar" is just Lua's `require()` call order; circular dependencies surface as Lua's `loop or previous error loading module`.

### Phase 3: Semantic Analysis (Type Checking)

**Files**: `sys/tags.lua`, `sys/rules.lua`

**Purpose**: Ensure semantic correctness:

- Every tag referenced in `rules.lua` is defined in `tags.lua`
- No orphaned tags (every tag has at least one rule)
- Behavior tags orthogonal to category tags

**Compiler Analogy**: Type checker ensures variables are declared before use. In `.lua`, looking up an undefined const key returns `nil` → immediately visible at use site (concatenation with `nil` is a runtime error).

### Phase 4: Code Generation (Configuration Application)

**Files**: All `*.lua` files emit `hl.config({...})` / `hl.bind(...)` / `hl.window_rule(...)` calls

**Purpose**: Generate final Hyprland configuration state:

```
Input:  ~44 require() calls
Output: Fully resolved Hyprland config in memory
```

**Compiler Analogy**: Backend generates target machine code. Here, `hl.*` calls mutate Hyprland's internal option store — the "code" is the final option state.

### Phase 5: Runtime Optimization (JIT Compilation)

**Surface**: `hl.bind(key, fn)` runtime dispatch + `hl.on(event, fn)` reactive hooks; external scripts (`ChangeLayout.sh`, `GameMode.sh`, `Animations.sh`) still drive most runtime transitions.

**Purpose**: Dynamic reconfiguration without restart:

```lua
-- JIT-style: a bind handler that mutates state at runtime
hl.bind("SUPER + ALT + L", function()
  local cur = -- hl.getoption does not exist in wiki API("general:layout").str
  local next_layout = ({ scrolling = "dwindle",
                         dwindle   = "master",
                         master    = "scrolling" })[cur]
  hl.dispatch("keyword", "general:layout " .. next_layout)
end)
```

```bash
# Equivalent .sh script (currently the dominant form)
~/.config/hypr/sys/scripts/ChangeLayout.sh
```

**Compiler Analogy**: Just-In-Time compilation for runtime performance. The `.lua` API supports JIT natively (closures capture state); `.sh` scripts do it via `hyprctl` calls.

---

## Layered Architecture & Boundary Management

### Layer Hierarchy (Dependency Graph)

```
┌─────────────────────────────────────────┐
│  hyprland.lua (Entry Point / Facade)    │
│   require("bootstrap.default")          │
└──────────────┬──────────────────────────┘
               │ require
               ▼
┌─────────────────────────────────────────┐
│  bootstrap/ (Constant Definitions)       │
│  ├── const.lua   (return { path table })│
│  └── default.lua (Pipeline entry)        │
└──────────────┬──────────────────────────┘
               │ Stage 0 complete (merged const table C)
               ▼
┌─────────────────────────────────────────┐
│  sys/ (System Defaults - Read Only)     │
│  ├── hardware/    (Physical layer)      │
│  ├── policy/      (Swappable policies)  │
│  ├── env.lua      (hl.env calls)        │
│  ├── misc.lua     (hl.config misc)      │
│  ├── input.lua    (hl.config input)     │
│  ├── layout.lua   (hl.config general)   │
│  ├── decoration.lua (hl.config decoration)│
│  ├── render.lua   (hl.config render)    │
│  ├── startup.lua  (hl.on hyprland.start)│
│  ├── keybind.lua   (hl.bind calls)       │
│  ├── tags.lua      (hl.window_rule tag=)│
│  └── rules.lua    (hl.window_rule match=)│
└──────────────┬──────────────────────────┘
               │ Each sys/X.lua paired with:
               ▼
┌─────────────────────────────────────────┐
│  user/ (User Overrides - Write Here)     │
│  ├── const.lua    (Override $M_*, $W)    │
│  ├── env.lua      (HiDPI, NVIDIA, etc)  │
│  ├── input.lua    (kb_layout, etc)       │
│  ├── layout.lua   (startup layout)       │
│  ├── decoration.lua (colors, blur)      │
│  ├── keybind.lua  (custom binds)        │
│  ├── tags.lua     (app classifications) │
│  └── rules.lua    (behavior overrides)  │
└─────────────────────────────────────────┘
```

### Boundary Contracts

Each layer has explicit contracts:

| Layer                | Provides                                  | Consumes                  | Must Not                                      |
| -------------------- | ----------------------------------------- | ------------------------- | --------------------------------------------- |
| `bootstrap/`         | Path constants, merged const table `C`    | Nothing                   | Contain logic beyond `require`/`deep_merge`   |
| `sys/hardware/`      | Monitor/laptop device config              | `C['$H']` constant        | Reference user paths                          |
| `sys/policy/`        | Color vars (`$colorN`), animation presets | `C['$P']` constant        | Modify non-policy settings                    |
| `sys/decoration.lua` | Visual rendering config                   | `$colorN` from policy     | Define colors directly                        |
| `sys/tags.lua`       | Window tag registry                       | `C['$H_Cheat']`, `C['$H_Settings']` | Contain behavior rules                 |
| `sys/rules.lua`      | Tag-driven window rules                   | Tags from `tags.lua`      | Use `match.class` directly (except compounds) |
| `user/*`             | User-specific overrides                   | All sys constants         | Edit sys/ files                               |

### Violation Detection

The architecture enforces boundaries through:

1. **Require Order**: Later `require()`s override earlier ones via `hl.config({...})` last-write-wins (enforced by Hyprland's option store)
2. **Const Table Lookup**: Constants looked up at use site return `nil` if unset — immediately visible (Lua runtime error on concat)
3. **Tag Completeness**: Every tag in rules must exist in tags (manual audit)
4. **File Naming**: `sys/` vs `user/` prefix makes violations obvious

---

## Dependency Inversion & Incremental Override Pattern

### Three-Layer Constant System

**📚 Complete Specification**: See [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) for full documentation of the bootstrap/sys/user constant system with dependency graphs, resolution examples, and debugging guides.

The configuration implements a sophisticated **three-layer constant system** that applies Dependency Inversion at multiple levels:

```
Layer 1 (bootstrap/const.lua): return { ['Hypr = ..., ['sys = ... }
  ↓ deep_merge into C
Layer 2 (sys/const.lua):       return { ['M = "SUPER", ... }
  ↓ deep_merge into C
Layer 3 (user/const.lua):      return { ['M_terminal = "ghostty" }
  ↓ deep_merge into C — last-write-wins
```

**Key Design Decisions**:

1. All three layers load in **Stage 0** (before any other module)
2. Unidirectional dependencies (Layer 1 → Layer 2 → Layer 3)
3. No circular dependencies allowed (const files are leaf modules — they `require` nothing)
4. User overrides propagate to all subsequent stages automatically (via shared `C` table)

---

### Traditional Approach (Tight Coupling)

```lua
-- BAD: Hard-coded values scattered across files
-- sys/env.lua
hl.env("EDITOR", "nvim")

-- sys/keybind.lua
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))

-- Problem: Changing editor requires editing multiple files
```

### Dependency Inversion (Abstraction Layer)

```lua
-- GOOD: Abstract through the merged const table C

-- sys/const.lua (Layer 2)
return {
  ['M_editor   = os.getenv("EDITOR") or "nano",
  ['M_terminal  = "kitty",
}

-- user/const.lua (Layer 3 — single change point)
return {
  ['M_editor   = "vim",
  ['M_terminal = "ghostty",
}

-- sys/env.lua (uses the abstraction)
hl.env("EDITOR", C['$M_editor'])

-- sys/keybind.lua (uses the abstraction)
hl.bind(C['$M'] .. " + Return", hl.dsp.exec_cmd(C['$M_terminal']))
```

**Benefits**:

- **Open/Closed Principle**: Extend behavior without modifying existing code
- **Single Responsibility**: Each constant has one definition location
- **Testability**: Swap implementations by changing one file (`user/const.lua`)

### Incremental Override Mechanism

The pattern mirrors **CSS specificity** and **Linux config.d directories**:

```lua
-- sys/input.lua (vendor default)
hl.config({ input = { kb_layout = "us" } })
hl.config({ input = { sensitivity = 0 } })

-- user/input.lua (user delta — ONLY differences)
hl.config({ input = { kb_layout = "us,cn" } })
```

**Resolution Algorithm**:

```
1. require("sys.input")  → hl.config({ input = { kb_layout = "us" } })    applied
2. require("user.input")  → hl.config({ input = { kb_layout = "us,cn" } }) overrides
3. Final state: input.kb_layout = "us,cn", input.sensitivity = 0 (inherited)
```

**Key Insight**: Each `hl.config({...})` call mutates Hyprland's internal option store with last-write-wins semantics — enabling clean delta-based customization. This is the `.lua` equivalent of `.conf`'s implicit "later source overrides earlier" rule, but visible in code.

---

## State Machine Implementation

The configuration implements **three explicit state machines** with well-defined transitions. Two are currently driven by external `.sh` scripts (which call `hyprctl`); the long-term plan (Phase C, see `STATE_MACHINES.md`) is to backport them into native `.lua` modules using `hl.bind(key, fn)` + `hl.on(event, fn)`.

### State Machine 1: Layout Engine

**States**: `scrolling` ↔ `dwindle` ↔ `master`

**Transition Function** (currently in `sys/scripts/ChangeLayout.sh`):

```bash
case "$CURRENT_STATE" in
"scrolling") _enter_dwindle   ;;   # scrolling → dwindle
"dwindle")   _enter_master    ;;   # dwindle   → master
"master")    _enter_scrolling ;;   # master    → scrolling
esac
```

**Phase C target — `.lua` native form** (not yet backported):

```lua
-- sys/sm/layout.lua (planned)
local LayoutSM = {
  transitions = {
    scrolling = "dwindle",
    dwindle   = "master",
    master    = "scrolling",
  },
}

function LayoutSM:transition()
  local cur = -- hl.getoption does not exist in wiki API("general:layout").str
  local nxt = self.transitions[cur]
  hl.dispatch("keyword", "general:layout " .. nxt)
  -- rebind J/K/O per new layout
  self:_apply_binds(nxt)
  hl.exec_cmd("notify-send 'Layout → " .. nxt .. "'")
end

hl.bind("SUPER + ALT + L", function() LayoutSM:transition() end)
```

**State Properties**:
| State | SUPER+J/K | SUPER+O | Owner |
|-------|-----------|---------|-------|
| `scrolling` | unbound | unbound | scrolling layout (built-in since v0.55) |
| `dwindle` | cyclenext | togglesplit | Hyprland core |
| `master` | cyclenext | unbound | Hyprland core |

**Atomicity Guarantee**: Each transition atomically updates:

1. Layout engine (`general:layout`)
2. Keybinds (bind/unbind J/K/O)
3. User notification (visual feedback)

**Initialization** (currently `sys/scripts/KeybindsLayoutInit.sh`):

```bash
# Idempotent: reads current state and applies correct binds
LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str')
_apply_layout_binds "$LAYOUT"
```

### State Machine 2: Game Mode

**States**: `normal` ↔ `gaming`

**State Variable**: `animations:enabled` (1 = normal, 0 = gaming)

**Transition Functions** (currently in `sys/scripts/GameMode.sh`):

```bash
_gamemode_on() {
    # Disable visual effects (performance optimization)
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    # Force full opacity (reduce compositor load)
    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    awww kill  # Kill wallpaper daemon (free GPU resources)
}

_gamemode_off() {
    # Restore full visual stack
    awww-daemon --format argb &
    awww img "$HOME/.config/rofi/.current_wallpaper"
    WallustSwww.sh  # Regenerate colors
    hyprctl reload  # Full config reload (restore all settings)
}
```

**Phase C target — `.lua` native form** (not yet backported):

```lua
-- sys/sm/gamemode.lua (planned)
local GameModeSM = { state = "normal" }

function GameModeSM:on()
  self.state = "gaming"
  hl.config({ animations  = { enabled = false } })
  hl.config({ decoration  = { shadow = { enabled = false } } })
  hl.config({ decoration  = { blur   = { enabled = false } } })
  hl.config({ general     = { gaps_in = 0, gaps_out = 0, border_size = 1 } })
  hl.config({ decoration  = { rounding = 0 } })
  hl.window_rule({ opacity = "1 override 1 override 1 override", match = { class = "^(.*)$" } })
  hl.exec_cmd("awww kill")
end

function GameModeSM:off()
  self.state = "normal"
  hl.exec_cmd("awww-daemon --format argb")
  hl.exec_cmd("~/.config/hypr/sys/scripts/WallustSwww.sh")
  hl.dispatch("reload")  -- full re-require of .lua
end

hl.bind("SUPER + SHIFT + G", function()
  if GameModeSM.state == "normal" then GameModeSM:on() else GameModeSM:off() end
end)
```

**Design Rationale**:

- **Asymmetric Transitions**: ON is fast (batch disable), OFF is slow (full reload)
- **State Persistence**: No cache file needed (read from `-- hl.getoption does not exist in wiki API`)
- **Side Effect Management**: Wallpaper daemon lifecycle tied to game mode

### State Machine 3: Night Light (Hyprsunset)

**States**: `off` ↔ `on (@4500K)`

**State Persistence**: `~/.cache/.hyprsunset_state` (file-based)

**Transition Function** (currently in `sys/scripts/Hyprsunset.sh`):

```bash
cmd_toggle() {
    state="$(cat "$STATE_FILE")"

    # Always stop existing instance first (prevent CTM conflicts)
    if pgrep -x hyprsunset >/dev/null; then
        pkill -x hyprsunset
        sleep 0.2  # Race condition prevention
    fi

    if [[ "$state" == "on" ]]; then
        # OFF transition: apply identity matrix, exit
        hyprsunset -i >/dev/null &
        sleep 0.3 && pkill -x hyprsunset
        echo off >"$STATE_FILE"
    else
        # ON transition: start daemon with target temp
        nohup hyprsunset -t "$TARGET_TEMP" >/dev/null &
        echo on >"$STATE_FILE"
    fi
}
```

**Process Lifecycle Management**:

- **Startup** (`Hyprsunset.sh init`): Read state file, restore previous state
- **Status Query** (`Hyprsunset.sh status`): Check process + state file (live detection)
- **Toggle** (`Hyprsunset.sh toggle`): Atomically flip state + update file

**Phase C target — `.lua` native form** (planned, partial): The night-light SM could be reduced to an `hl.bind` handler that writes the state file, since `hyprsunset` is an external daemon that takes its config via CLI args, not Lua.

---

## Tag-Driven Window Management System

### Architecture

```
sys/tags.lua  → defines WHAT an app IS    (hl.window_rule({ match=..., tag="..." }))
sys/rules.lua → defines HOW it behaves   (hl.window_rule({ opacity=..., match={tag="..."} }))
```

**Decoupling**: Tags act as a level of indirection. Adding a new browser class (e.g., `zen-browser`) requires editing **only** `sys/tags.lua` (one line); all browser behavior rules apply automatically.

### Tag Definition

```lua
-- sys/tags.lua
hl.window_rule({
  match = { class = "^([Ff]irefox|[Cc]hromium|[Bb]rave-browser)$" },
  tag   = "browser",
})

hl.window_rule({
  match = { class = "^(Alacritty|kitty|ghostty|wezterm|foot)$" },
  tag   = "terminal",
})

hl.window_rule({
  match = { title = "^(Quick Cheat Sheet)$" },
  tag   = "Help_Cheat",   -- helper tag (const value from sys/const.lua)
})
```

### Rule Application

```lua
-- sys/rules.lua
-- Browser rules
hl.window_rule({
  opacity      = "1.00 0.85",
  match        = { tag = "browser" },
})
hl.window_rule({
  idle_inhibit = "fullscreen",
  match        = { tag = "browser" },
})

-- IM rules
hl.window_rule({ float  = true,                          match = { tag = "im" } })
hl.window_rule({ center = true,                          match = { tag = "im" } })
hl.window_rule({ size   = "(monitor_w*0.60) (monitor_h*0.70)",
                 match  = { tag = "im" } })
```

### Compound Conditions (Edge Cases)

```lua
-- When tags can't express the condition, use match.class directly
hl.window_rule({
  float = true,
  match = {
    class          = "^([Tt]hunar)$",
    title_negative = "^(.*[Tt]hunar.*)$",
  },
})
```

**Rule**: Use `match.class` directly only for compound conditions that tags cannot express.

### User Extension

```lua
-- user/tags.lua
hl.window_rule({
  match = { class = "^(signal)$" },
  tag   = "im",
})

-- user/rules.lua
hl.window_rule({ float  = true,  match = { tag = "signal" } })
hl.window_rule({ center = true,   match = { tag = "signal" } })
hl.window_rule({ size   = "(monitor_w*0.50) (monitor_h*0.60)",
                 match  = { tag = "signal" } })
```

### Tag Completeness Invariant

**Invariant**: Every tag in `tags.lua` has at least one rule in `rules.lua`.

**Audit**:

```bash
rg -o 'tag\s*=\s*"[^"]+"' sys/tags.lua  | sort -u > /tmp/defined_tags
rg -o 'tag\s*=\s*"[^"]+"' sys/rules.lua | sort -u > /tmp/used_tags
diff /tmp/defined_tags /tmp/used_tags
```

---

## Policy Layer & Runtime Swapping

### Architecture

```lua
-- sys/policy/default.lua
require("sys.policy.wallust.wallust-hyprland")  -- returns color table (deep_merged)
require("sys.policy.animations.default")        -- hl.curve + hl.animation calls
```

### Color Policy (Wallust)

```lua
-- sys/policy/wallust/wallust-hyprland.lua (generated by wallust)
return {
  ['background = "rgb(191B1C)",
  ['foreground = "rgb(E5E7EE)",
  ['color0     = "rgb(404143)",
  -- ... $color1-$color15
  ['color12    = "rgb(70717F)",
}
```

**Generation**:

```bash
# Triggered by WallpaperSelect.sh or WallpaperAutoChange.sh
wallust run -s "$wallpaper_path"
# Outputs: sys/policy/wallust/wallust-hyprland.lua
```

### Animation Policy (Strategy Pattern)

| Preset                | Style                  | Performance | Use Case           |
| --------------------- | ---------------------- | ----------- | ------------------ |
| `default.lua`         | Smooth slide           | Medium      | General use        |
| `disable.lua`         | None                   | Maximum     | Gaming, low-power  |
| `end4.lua`            | Material Design pop-in | High        | Modern aesthetic   |
| `hyde-optimized.lua`  | Fast deceleration      | Low-Medium  | Productivity       |
| `ml4w-fast.lua`       | Minimal pop-in         | Low         | Quick interactions |

### Runtime Swapping

```bash
# .lua era: hyprctl reload re-requires all .lua modules
# Or use targeted hyprctl keyword for individual options
hyprctl reload
```

**Mechanism**: `hyprctl reload` triggers a fresh `require()` cycle on the Lua side. State that lives in Hyprland's option store (e.g., monitor config) is preserved; Lua-side module state (e.g., `local` tables) is recreated.

**State Management**: No state file needed — current animation state readable via:

```bash
hyprctl getoption animations:enabled
```

---

## Process Lifecycle Management

### Event-Driven Startup

```lua
-- sys/startup.lua (replaces exec-once with event handler)
hl.on("hyprland.start", function()
  -- Environment propagation
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Wallpaper daemon
  hl.exec_cmd("awww-daemon --format xrgb")

  -- Authentication
  hl.exec_cmd("~/.config/hypr/sys/scripts/Polkit-NixOS.sh")

  -- System services
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("swaync")
  hl.exec_cmd("waybar")

  -- Clipboard
  hl.exec_cmd("wl-paste --type text  --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- Idle management (absolute path — separate daemon)
  hl.exec_cmd("hypridle -c ~/.config/hypr/sys/hypridle.lua")

  -- Night light (restore previous state)
  hl.exec_cmd("~/.config/hypr/sys/scripts/Hyprsunset.sh init")
end)

-- NEW in .lua era: shutdown hook (cleanup impossible in .conf)
hl.on("hyprland.shutdown", function()
  hl.exec_cmd("pkill swaync 2>/dev/null")
end)
```

**Why event-driven?**: `hl.on("hyprland.start", fn)` runs after all `hl.config`/`hl.bind` calls have been processed, guaranteeing services start with a fully-configured compositor.

### Process Lifecycle Patterns

| Pattern | Example | State Persistence | Restart Strategy |
| ------- | ------- | ----------------- | ---------------- |
| Stateless | `waybar`, `swaync` | None | Free restart |
| Stateful daemon | `hypridle` | Internal | Restart requires state restoration |
| File-state | `Hyprsunset.sh init` | `~/.cache/.hyprsunset_state` | Script restores from file |
| Pre-spawned | `Dropterminal.sh kitty &` | Hidden workspace | Cache address |

### User Service Addition

```lua
-- user/startup.lua (additional hyprland.start handlers)
hl.on("hyprland.start", function()
  hl.exec_cmd("fcitx5 -d -r")                              -- input method
  hl.exec_cmd("blueman-applet")                            -- bluetooth
  hl.exec_cmd("~/.config/hypr/sys/scripts/RainbowBorders.sh")  -- visual effect
end)
```

**Rule**: User services register additional `hyprland.start` handlers; Hyprland invokes all registered handlers (require order = handler invocation order).

---

## Single Responsibility Principle Applied

Each `.lua` module has exactly **one reason to change**:

| Module | Single Responsibility |
| ------ | -------------------- |
| `bootstrap/const.lua` | Define path constants (only paths, no logic) |
| `bootstrap/default.lua` | Orchestrate Stage 0 (deep_merge const tables; require sys) |
| `sys/const.lua` | Define system-default constants (no paths, no overrides) |
| `sys/env.lua` | Emit `hl.env` calls (no other side effects) |
| `sys/misc.lua` | Emit `hl.config({ misc = ... })` (no other sections) |
| `sys/input.lua` | Emit `hl.config({ input = ... })` (no other sections) |
| `sys/layout.lua` | Emit `hl.config({ general/dwindle/master/plugin = ... })` |
| `sys/decoration.lua` | Emit `hl.config({ decoration = ... })` (uses policy colors) |
| `sys/render.lua` | Emit `hl.config({ render/cursor = ... })` |
| `sys/startup.lua` | Register `hl.on` event handlers (no config mutations) |
| `sys/keybind.lua` | Emit `hl.bind` calls (no config) |
| `sys/tags.lua` | Emit `hl.window_rule` with `tag=` (no behavior) |
| `sys/rules.lua` | Emit `hl.window_rule` with `match={tag=...}` (no tagging) |
| `user/X.lua` | Override specific keys in the corresponding `sys/X.lua` |

**Violation smell**: A module emitting both `hl.bind` and `hl.window_rule` calls violates SRP (it's mixing input handling with window classification).

---

## Software Design Patterns Catalog

| Pattern | Where Applied | Lua Implementation |
| ------- | ------------- | ----------------- |
| **Facade** | `hyprland.lua` entry | `require("bootstrap.default")` — one-line entry hides entire system |
| **Decorator** | `sys/X` + `user/X` pairs | `require("sys.X"); require("user.X")` — user deltas "wrap" sys defaults |
| **Strategy** | Animation presets | `require("sys.policy.animations.<preset>")` — swappable at runtime via `hyprctl reload` |
| **Template Method** | `bootstrap/default.lua` orchestrator | Defines the require() order; sys/X modules fill in the steps |
| **State Machine** | Layout / GameMode / NightLight | Currently `.sh` scripts; Phase C target is `sys/sm/*.lua` with `hl.bind` + `hl.on` |
| **Observer** | Service lifecycle | `hl.on("hyprland.start", fn)` + `hl.on("hyprland.shutdown", fn)` — pub/sub for events |
| **Dependency Injection** | Three-layer const system | `deep_merge(C, require("user.const"))` — user injects overrides into shared `C` |
| **Registry** | Tag system | `sys/tags.lua` is the single registry; `sys/rules.lua` queries by tag |
| **Adapter** | `hl.dsp.exec_cmd("...")` | Wraps external shell commands as dispatcher functions for `hl.bind` |
| **Composite** | Nested `hl.config` calls | `hl.config({ decoration = { blur = { size = 6 } } })` — compose option paths |
| **Builder** | Fluent API | `hl.config / hl.bind / hl.window_rule` are builder-style call chains on the option store |
| **Null Object** | Empty `user/X.lua` files | Empty Lua file is a valid no-op override (vs `.conf` where empty file caused parse errors) |

---

## Historical .conf form

> The following examples show the **legacy `.conf` syntax** preserved here for historical context only. The current repo no longer contains `.conf` files — see git history for the migration.

### Example 1: Single entry point in `.conf` form

```conf
# hyprland.conf  (LEGACY — not in current repo)
require('bootstrap.default')
```

**Equivalence**: In `.lua`, the entry is `require("bootstrap.default")` (`hyprland.lua` has exactly one line). The `source = path` directive is the direct ancestor of Lua's `require("module.path")` — both load a file and execute it, but `require()` returns the file's value (in `.lua`, that's the const table) and caches the result.

### Example 2: Incremental override and `bindd` directive in `.conf` form

```conf
# sys/input.conf  (LEGACY)
input {
    kb_layout = us
}

# user/input.conf  (LEGACY — only override)
input {
    kb_layout = us,cn
}

# sys/keybind.conf  (LEGACY)
hl.bind(const.M .. " + Return", hl.dsp.exec_cmd("$M_terminal"))  -- open terminal
```

**Equivalence**: In `.lua`, the same logic becomes:

```lua
-- sys/input.lua
hl.config({ input = { kb_layout = "us" } })

-- user/input.lua
hl.config({ input = { kb_layout = "us,cn" } })

-- sys/keybind.lua
hl.bind(C['$M'] .. " + Return", hl.dsp.exec_cmd(C['$M_terminal']))
-- bindd (bind with description) has no separate variant in .lua — description
-- is a docstring/comment, since .lua binds are first-class functions.
```

The `.conf` `bindd` variant (bind+description) collapses in `.lua` to a single `hl.bind(key, dispatcher, flags?)` function — the description becomes a Lua comment, since `.lua` binds are first-class function values (not strings the compositor parses).

---

## References

- [Hyprland Wiki - Configuration](https://wiki.hyprland.org/Configuring/)
- [Facade Pattern](https://refactoring.guru/design-patterns/facade)
- [Decorator Pattern](https://refactoring.guru/design-patterns/decorator)
- [Strategy Pattern](https://refactoring.guru/design-patterns/strategy)
- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single-responsibility_principle)
- [../../07-Lua-Reference/README.md](../../07-Lua-Reference/README.md) — .lua architecture overview
- [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md) — .lua syntax reference
- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) — pipeline architecture
- [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) — three-layer const system
- [../03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) — state machines
- [../03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) — tag system

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
