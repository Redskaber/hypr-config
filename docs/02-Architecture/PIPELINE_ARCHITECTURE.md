# Pipeline Architecture - Layered Configuration Flow

> **本文档以 .lua（Hyprland v0.55+ 原生）为准**。历史 .conf 形式见文末 [Historical .conf form](#historical-conf-form) 节，亦见 git history。
> 语法对照见 [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md)。

## Overview

This document describes the **pipeline-based configuration loading architecture** that treats Hyprland configuration as a **compiled system** with distinct compilation phases, dependency management, and incremental override patterns.

In the `.lua` era, Hyprland's `hl.*` API replaces the `.conf` DSL. The "compilation" metaphor is preserved but the stages are reinterpreted:

| Compiler phase | .lua interpretation |
| -------------- | ------------------- |
| Lexical        | `require()` const tables (`return { ['M = "SUPER" }`) |
| Syntax         | `require()` DAG (`bootstrap.default` → `sys.default` → `sys.X` + `user.X`) |
| Semantic       | `hl.window_rule({ match = { tag = ... } })` validation against `sys/tags.lua` |
| Codegen        | `hl.config({ ... })` calls mutate Hyprland internal state |
| JIT            | `hl.bind(key, fn)` runtime dispatch + `hl.on(event, fn)` reactive hooks |

---

## Layered Pipeline Data Flow

### Complete Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────┐
│                     hyprland.lua (Entry Point)                     │
│                  require("bootstrap.default")                       │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 0: CONSTANT DEFINITION (Lexical Analysis / Tokenization)    │
│  Each const file returns a table; deep_merge(last-write-wins).     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  bootstrap/const.lua                                          │  │
│  │  return {                                                     │  │
│  │    ['Hypr = "~/.config/hypr",                              │  │
│  │    ['sys  = "~/.config/hypr/sys",                           │  │
│  │    ['user = "~/.config/hypr/user",                         │  │
│  │  }                                                            │  │
│  │                                                               │  │
│  │  sys/const.lua                                                │  │
│  │  return {                                                     │  │
│  │    ['M          = "SUPER",                                 │  │
│  │    ['S          = "~/.config/hypr/sys/scripts",            │  │
│  │    ['H          = "~/.config/hypr/sys/hardware",           │  │
│  │    ['P          = "~/.config/hypr/sys/policy",             │  │
│  │    ['M_terminal = "kitty",                                 │  │
│  │  }                                                            │  │
│  │                                                               │  │
│  │  user/const.lua (OVERRIDES — only deltas)                    │  │
│  │  return {                                                     │  │
│  │    ['M_terminal = "ghostty",   -- overrides sys/const.lua  │  │
│  │    ['Search_Engine = "https://www.bing.com/search?q={}",   │  │
│  │  }                                                            │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Output: One merged const table (deep_merge bootstrap→sys→user)     │
│  Invariant: All constants defined before use in later stages        │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Merged const table available to all later requires
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 1: HARDWARE ABSTRACTION (Physical Layer / Device Config)     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/hardware/default.lua                                    │  │
│  │  ├── laptop.lua     (laptop function keys, touchpad)           │  │
│  │  │   ├── hl.bind(XF86Kbdbrightnessup, ...)                    │  │
│  │  │   └── hl.config({ device = { name = "$Touchpad_Device" }})│  │
│  │  ├── monitors.lua   (hl.monitor({...}) calls)                │  │
│  │  │   └── Monitor definitions (resolution, refresh, position)  │  │
│  │  └── workspaces.lua (workspace→monitor assignments)           │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: merged const table from Stage 0                     │
│  Output: Physical device state (monitors, input devices)            │
│  Invariant: Hardware configured before visual policies              │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Devices ready
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 2: POLICY APPLICATION (Strategy Pattern / Visual Policies)   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/policy/default.lua                                       │  │
│  │  require("sys.policy.wallust.wallust-hyprland")              │  │
│  │  require("sys.policy.animations.default")                    │  │
│  │                                                               │  │
│  │  wallust-hyprland.lua (generated, returns table)            │  │
│  │  return {                                                     │  │
│  │    ['background = "rgb(1E1F1F)",                           │  │
│  │    ['foreground = "rgb(EBEBEB)",                           │  │
│  │    ['color0 = "rgb(444545)", ... ['color15 = "rgb(...)" │  │
│  │  }                                                            │  │
│  │                                                               │  │
│  │  animations/default.lua (hl.curve + hl.animation calls)      │  │
│  │  ├── bezier curves (wind, winIn, winOut, etc.)                │  │
│  │  └── animation definitions (windows, fade, workspaces)       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: const table + wallust color sub-table                │
│  CRITICAL CONSTRAINT: Colors MUST merge before decoration.lua loads │
│  Output: Visual policy active ($colorN values resolvable)           │
│  Invariant: Policy layer complete before core rendering config      │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Policies loaded ($color0-$color15 resolvable)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 3: CORE CONFIGURATION (Semantic Analysis / Behavior Setup)   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  For each domain X (incremental override pattern):            │  │
│  │    require("sys.X")   -- vendor defaults                      │  │
│  │    require("user.X")  -- user deltas  (LATER WINS via merge)  │  │
│  │                                                               │  │
│  │  Domain Load Order (critical dependencies):                   │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ 1. env.lua       → hl.env(...) calls                  │  │  │
│  │  │    ├── Wayland display vars                             │  │  │
│  │  │    ├── Qt/GTK theme engines                             │  │  │
│  │  │    └── App defaults (EDITOR, BROWSER, etc.)            │  │  │
│  │  │                                                         │  │  │
│  │  │ 2. misc.lua      → hl.config({ misc = {...} })        │  │  │
│  │  │    ├── disable_hyprland_logo                            │  │  │
│  │  │    ├── vrr (variable refresh rate)                      │  │  │
│  │  │    └── swallow_regex (uses $M_terminal)                │  │  │
│  │  │                                                         │  │  │
│  │  │ 3. input.lua     → hl.config({ input = {...} })       │  │  │
│  │  │    ├── Keyboard layout (kb_layout)                      │  │  │
│  │  │    ├── Touchpad settings                                │  │  │
│  │  │    └── Mouse sensitivity                                 │  │  │
│  │  │                                                         │  │  │
│  │  │ 4. layout.lua    → Tiling engines                       │  │  │
│  │  │    ├── hl.config({ general = { layout = "dwindle" }})  │  │  │
│  │  │    ├── hl.config({ dwindle  = { preserve_split = true }}) │  │
│  │  │    ├── hl.config({ master   = { mfact = 0.5 }})        │  │  │
│  │  │    └── hl.config({ plugin = { scrolling layout = {...} }})│  │  │
│  │  │                                                         │  │  │
│  │  │ 5. decoration.lua → Visual effects ⚠️ DEPENDS ON STAGE2│  │  │
│  │  │    ├── hl.config({ decoration = { rounding = 10 }})     │  │  │
│  │  │    ├── hl.config({ decoration = { blur = {...} }})      │  │  │
│  │  │    └── shadow { color = "rgb(70717F)" } ← resolved      │  │  │
│  │  │                                                         │  │  │
│  │  │ 6. render.lua    → Render pipeline                      │  │  │
│  │  │    ├── col.active_border = "rgb(70717F)" ← resolved    │  │  │
│  │  │    ├── direct_scanout                                    │  │  │
│  │  │    └── hl.config({ cursor = { no_warps = true }})       │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: const table + wallust color sub-table                │
│  Output: Core behavior configured (input, layout, visuals)          │
│  Invariant: Each domain's user/ override immediately follows sys/   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Core behavior ready
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 4: SERVICE LIFECYCLE (Process Initialization / Daemon Mgmt)  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/startup.lua                                             │  │
│  │  hl.on("hyprland.start", function()                          │  │
│  │    hl.exec_cmd("dbus-update-activation-environment ...")      │  │
│  │    hl.exec_cmd("systemctl --user import-environment ...")     │  │
│  │    hl.exec_cmd("awww-daemon --format xrgb")                   │  │
│  │    hl.exec_cmd("~/.config/hypr/sys/scripts/Polkit-NixOS.sh")  │  │
│  │    hl.exec_cmd("nm-applet --indicator")                       │  │
│  │    hl.exec_cmd("swaync")                                      │  │
│  │    hl.exec_cmd("waybar")                                      │  │
│  │    hl.exec_cmd("wl-paste --type text  --watch cliphist store")│  │
│  │    hl.exec_cmd("hypridle -c ~/.config/hypr/sys/hypridle.lua")│  │
│  │    hl.exec_cmd("~/.config/hypr/sys/scripts/Hyprsunset.sh init")│  │
│  │  end)                                                         │  │
│  │                                                               │  │
│  │  user/startup.lua (ADDITIONAL SERVICES — appended to handler)│  │
│  │  ├── hl.on("hyprland.start", function() ... end)            │  │
│  │  └── fcitx5 -d -r (input method)                              │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: const table (for script paths)                       │
│  CRITICAL: Services start AFTER core config is complete             │
│  Output: Background processes running (daemons initialized)         │
│  Invariant: Process lifecycle managed (absolute paths for daemons)  │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Services started
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 5: WINDOW MANAGEMENT (Rule Compilation / Tag System)         │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/tags.lua          → Window tag registry (WHAT apps ARE) │  │
│  │  ├── hl.window_rule({ match = { class = "...", tag = "browser" }})│  │
│  │  ├── Category tags (28): browser, terminal, im, projects...   │  │
│  │  ├── Behavior tags (5): pip, auth-dialog, file-dialog...      │  │
│  │  └── Helper tags (3): Help_Cheat, Help_Settings, keybindings  │  │
│  │                                                               │  │
│  │  user/tags.lua         → User tag additions                  │  │
│  │  └── hl.window_rule({ match = { class = "^signal$", tag = "im" }})│  │
│  │                                                               │  │
│  │  sys/rules.lua         → Tag-driven rules (HOW windows act)  │  │
│  │  ├── Browser rules: opacity, idle_inhibit                     │  │
│  │  ├── IM rules: float, center, size, opacity                   │  │
│  │  ├── Game rules: fullscreen, no_blur, idle_inhibit            │  │
│  │  └── ... (rules for all 28 category tags)                     │  │
│  │                                                               │  │
│  │  user/rules.lua        → User rule additions/overrides       │  │
│  │  └── hl.window_rule({ float = true, match = { tag = "signal" }})│  │
│  │                                                               │  │
│  │  POST-PROCESSING: KeybindsLayoutInit.sh (external script)     │  │
│  │  └── Applies layout-specific binds based on current layout    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: Tags from bootstrap (Help_Cheat, Help_Settings)      │
│  INVARIANT: Every tag in tags.lua has ≥1 rule in rules.lua          │
│  Output: Window classification + behavior rules compiled            │
│  Final State: Fully configured Hyprland instance ready              │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow Characteristics

**Direction**: Strictly unidirectional (Stage 0 → Stage 5)

**Dependencies**:

- Stage 0 provides: Merged const table (paths, modifiers, tag names)
- Stage 1 provides: Hardware state (monitors, input devices)
- Stage 2 provides: Visual policies (`$color0`-`$color15` values, animation curves)
- Stage 3 provides: Core behavior (layout, decoration, rendering)
- Stage 4 provides: Running services (daemons)
- Stage 5 provides: Window management rules

**Critical Constraints**:

1. Stage 2 (policy) MUST complete before Stage 3 decoration.lua (needs `$colorN` resolved)
2. Stage 0 constants MUST be available to all subsequent stages (deep_merge at bootstrap)
3. Stage 4 services start AFTER Stage 3 core config is complete
4. Stage 5 tag registry MUST be complete before rules are applied

**Incremental Override Points**:

- Stage 0: `user/const.lua` overrides constants (deep_merge with sys/)
- Stage 3: Each domain has `user/X.lua` overriding `sys/X.lua` (later `require()` wins via merge)
- Stage 4: `user/startup.lua` adds additional `hl.on("hyprland.start", ...)` handlers
- Stage 5: `user/tags.lua` and `user/rules.lua` extend window rules

---

## Pipeline Stages

The configuration loading process follows a strict **5-stage pipeline**:

```
┌──────────────────────────────────────────────────────────────┐
│  STAGE 0: Constant Definition (Lexical Analysis)             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ bootstrap/const.lua  → return { ['$Hypr'], ['$sys'] }│  │
│  │ sys/const.lua        → return { ['$M'], ['$S'], ... }│  │
│  │ user/const.lua       → return { ['M_terminal="ghostty" }│  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: Merged const table (deep_merge bootstrap→sys→user)  │
└──────────────────────┬───────────────────────────────────────┘
                       │ All constants available
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 1: Hardware Abstraction (Physical Layer)              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ require("sys.hardware.default")                       │  │
│  │   ├── laptop.lua     → hl.bind(XF86*) + touchpad cfg  │  │
│  │   ├── monitors.lua   → hl.monitor({...}) calls         │  │
│  │   └── workspaces.lua → workspace→monitor mapping       │  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: Physical device state configured                    │
└──────────────────────┬───────────────────────────────────────┘
                       │ Hardware ready
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 2: Policy Application (Strategy Pattern)              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ require("sys.policy.default")                         │  │
│  │   ├── wallust/wallust-hyprland.lua → returns $colorN  │  │
│  │   └── animations/default.lua        → hl.curve/anim    │  │
│  └────────────────────────────────────────────────────────┘  │
│  Critical: Colors MUST be defined before decoration.lua      │
│  Output: Visual policy active ($color0-$color15 resolvable)  │
└──────────────────────┬───────────────────────────────────────┘
                       │ Policy loaded
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 3: Core Configuration (Semantic Analysis)             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ For each config domain X:                              │  │
│  │   require("sys.X")   -- vendor defaults (read-only)    │  │
│  │   require("user.X")  -- user deltas (later wins)        │  │
│  │                                                        │  │
│  │ Domains (in order):                                    │  │
│  │   env → misc → input → layout → decoration → render    │  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: Core behavior configured                            │
└──────────────────────┬───────────────────────────────────────┘
                       │ Core ready
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 4: Service Lifecycle (Process Initialization)         │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ sys/startup.lua  → hl.on("hyprland.start", fn)        │  │
│  │ user/startup.lua → user services (appended handlers)   │  │
│  └────────────────────────────────────────────────────────┘  │
│  Services: awww-daemon, waybar, swaync, cliphist, hypridle   │
│  Output: Background processes running                         │
└──────────────────────┬───────────────────────────────────────┘
                       │ Services started
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 5: Window Management (Rule Compilation)                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ require("sys.tags")   → Window tag registry            │  │
│  │ require("user.tags")  → User tag additions             │  │
│  │ require("sys.rules")  → Tag-driven rules               │  │
│  │ require("user.rules") → User rule additions            │  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: Window classification + behavior rules active      │
└──────────────────────────────────────────────────────────────┘
```

---

## Stage Dependency Matrix

This matrix shows which stages depend on outputs from previous stages:

| Stage       | Depends On                                                  | Provides To                                               | Critical Variables                                                     |
| ----------- | ----------------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------- |
| **Stage 0** | None (root)                                                 | All stages                                                | `$Hypr`, `$sys`, `$user`, `$M`, `$S`, `$H`, `$P`, `$colorN` (indirect) |
| **Stage 1** | Stage 0 (const table)                                       | Stage 3 (input devices affect layout)                     | Monitor config, touchpad state                                         |
| **Stage 2** | Stage 0 (const table)                                       | Stage 3 (decoration needs `$colorN`)                      | `$color0`-`$color15`, animation presets                                |
| **Stage 3** | Stage 0 (const table), Stage 2 (`$colorN`)                  | Stage 4 (services use config), Stage 5 (rules use layout) | Layout engine, decoration settings, render options                     |
| **Stage 4** | Stage 0 (const table), Stage 3 (core config)                | Stage 5 (services provide runtime context)                | Running daemons (awww, waybar, swaync, hypridle)                       |
| **Stage 5** | Stage 0 (`Help_Cheat`, `Help_Settings`), Stage 3 (layout state) | Runtime (window management active)                        | Tag registry, window rules, keybinds                                   |

### Dependency Violation Examples

**❌ VIOLATION: Using `$color12` before Stage 2**

```lua
-- BAD: sys/decoration.lua required before sys/policy/default.lua
require("sys.decoration")   -- tries to use $color12 → unresolved
require("sys.policy.default")  -- defines $color12 → too late!
```

**✅ CORRECT: Policy before decoration**

```lua
-- GOOD: Policy defines colors first (in sys/default.lua)
require("sys.policy.default")  -- merges $color0-$color15 into const table
require("sys.decoration")      -- uses $color12 → resolved correctly
```

**❌ VIOLATION: User constants in Stage 3**

```lua
-- BAD: user/const.lua required too late
require("sys.default")      -- uses $M_terminal = "kitty" (sys default)
require("user.const")       -- sets $M_terminal = "ghostty" → already used!
```

**✅ CORRECT: User constants in Stage 0**

```lua
-- GOOD: User constants available throughout pipeline (bootstrap/default.lua)
require("bootstrap.const")  -- Layer 1: paths
require("sys.const")        -- Layer 2: sys defaults
require("user.const")       -- Layer 3: user overrides (LAST = WINS)
require("sys.default")      -- uses $M_terminal = "ghostty" → correct!
```

---

## Pipeline Execution Timeline

### Millisecond-by-Millisecond Startup Sequence

```
Time    Stage   Action                                          State Change
────    ─────   ──────────────────────────────────────────      ────────────
0ms     S0      hyprland.lua require("bootstrap.default")     Pipeline start
1ms     S0      require("bootstrap.const")                    const table init
2ms     S0      require("sys.const")                          $M, $S, $H, $P merged
3ms     S0      require("user.const")                         $M_terminal="ghostty" override
        │
4ms     S1      require("sys.hardware.default")               Hardware stage start
5ms     S1      ├─ laptop.lua                                  Touchpad configured
6ms     S1      ├─ monitors.lua                                eDP-1: 2560x1440@165
7ms     S1      └─ workspaces.lua                              Workspace assignments set
        │
8ms     S2      require("sys.policy.default")                 Policy stage start
9ms     S2      ├─ wallust-hyprland.lua                       $color0-$color15 merged
10ms    S2      └─ animations/default.lua                     Animation preset loaded
        │
11ms    S3      Core configuration begins                      Semantic analysis start
12ms    S3      ├─ sys.env → user.env                          EDITOR=nvim, GDK_SCALE=1.5
13ms    S3      ├─ sys.misc → user.misc                        vfr=true, vrr=2
14ms    S3      ├─ sys.input → user.input                      kb_layout=us,cn
15ms    S3      ├─ sys.layout → user.layout                    layout=scrolling
16ms    S3      ├─ sys.decoration → user.decoration           Uses $color12 ✓, rounding=16
17ms    S3      └─ sys.render → user.render                    Uses $color12 ✓, cursor config
        │
18ms    S4      Service lifecycle begins                       Process initialization
19ms    S4      ├─ dbus-update-activation-environment          Env propagated
20ms    S4      ├─ awww-daemon --format xrgb                   Wallpaper daemon started
21ms    S4      ├─ Polkit-NixOS.sh                              Auth agent running
22ms    S4      ├─ nm-applet, swaync, waybar                    System services up
23ms    S4      ├─ cliphist store (text + image)               Clipboard managers ready
24ms    S4      ├─ hypridle                                     Idle daemon running
25ms    S4      └─ Hyprsunset.sh init                           Night light restored
        │
26ms    S5      Window management begins                        Rule compilation start
27ms    S5      ├─ sys/tags.lua                                28 category tags registered
28ms    S5      ├─ user/tags.lua                               User tags added
29ms    S5      ├─ sys/rules.lua                               200+ rules compiled
30ms    S5      ├─ user/rules.lua                              User rules added
31ms    S5      └─ KeybindsLayoutInit.sh                        Layout-specific binds applied
        │
32ms    -       Configuration load complete                     Hyprland ready for use
```

**Total Load Time**: ~32ms (excluding service startup overhead)

**Key Observations**:

- Stage 0 (constants): 3ms — Fast `require()` of three small const tables
- Stage 1 (hardware): 4ms — Device configuration
- Stage 2 (policy): 2ms — Color/animation policy
- Stage 3 (core): 7ms — Behavior configuration (largest stage)
- Stage 4 (services): 8ms — Process initialization
- Stage 5 (rules): 6ms — Window rule compilation

**Bottleneck**: Stage 4 (service startup) — dominated by external process launch times

---

## Incremental Override Mechanism - Detailed Flow

### How `sys/X.lua` → `user/X.lua` Works

For each configuration domain in Stage 3, the incremental override pattern applies:

```lua
-- Example: input domain

-- Step 1: sys/input.lua (vendor default)
hl.config({ input = { kb_layout = "us" } })
hl.config({ input = { sensitivity = 0 } })
hl.config({ input = { touchpad = { natural_scroll = true } } })
-- → Hyprland state: input.kb_layout = "us"

-- Step 2: user/input.lua (user delta — ONLY differences)
hl.config({ input = { kb_layout = "us,cn" } })
-- → Hyprland state: input.kb_layout = "us,cn" (overwritten)

-- Final state: kb_layout = "us,cn", sensitivity = 0 (inherited), natural_scroll = true (inherited)
```

**Mechanism**: Each `hl.config({...})` call mutates Hyprland's internal key→value store with **last-write-wins** semantics. Requiring `user/X` after `sys/X` ensures user deltas overwrite vendor defaults for the same key.

**Benefits**:

1. **Minimal Diffs**: User files only contain changes, not full config
2. **Vendor Updates Safe**: Updating `sys/` doesn't affect `user/` overrides
3. **Clear Intent**: Easy to see what's customized vs default
4. **Git-Friendly**: `user/` can be tracked separately or ignored

### Override Chain Example

```lua
-- Configuration Domain: decoration

-- sys/decoration.lua (vendor defaults)
hl.config({ decoration = { rounding = 10 } })
hl.config({ decoration = { blur = { enabled = true, size = 6, passes = 2 } } })
hl.config({ decoration = { shadow = { enabled = true, color = "rgb(70717F)" } } })
-- ↑ $color12 resolved by Stage 2 deep_merge before this file runs

-- user/decoration.lua (user deltas)
hl.config({ decoration = { rounding = 16 } })              -- override: larger rounding
hl.config({ decoration = { blur = { size = 8 } } })        -- override: stronger blur

-- Resolution Process:
--   1. require("sys.decoration")  → rounding=10, blur.size=6, blur.passes=2, shadow.color="rgb(70717F)"
--   2. require("user.decoration") → rounding=16 (override), blur.size=8 (override)
--   3. Final state: rounding=16, blur.size=8, blur.passes=2 (inherited), shadow.color="rgb(70717F)" (inherited)
```

**Important**: Unspecified keys in `user/X.lua` files inherit from `sys/X.lua`. Only explicit `hl.config({...})` calls with matching paths change values.

---

## Stage 0: Constant Definition (Lexical Analysis)

### Purpose

Define all symbolic constants (tokens) used throughout the configuration. This is equivalent to a compiler's **lexical analysis phase**, where raw source is converted into a symbol table.

In `.lua`, constants live in three files that each `return` a table. The orchestrator `deep_merge`s them in order (bootstrap → sys → user); the final merged table is queried by every later `require()`.

### Files & Responsibilities

#### `bootstrap/const.lua` — Path Constants

```lua
-- bootstrap/const.lua
return {
  ['Hypr            = "~/.config/hypr",
  ['bootstrap       = "~/.config/hypr/bootstrap",
  ['sys             = "~/.config/hypr/sys",
  ['user            = "~/.config/hypr/user",
  ['lock_background = "~/.config/hypr/wallpaper_effects/.wallpaper_current",
}
```

**Design Principle**: **Single Source of Truth** for paths. Changing `$sys` updates all references automatically.

#### `sys/const.lua` — System Defaults

```lua
-- sys/const.lua
return {
  -- Modifier keys
  ['M              = "SUPER",
  ['M_terminal     = "kitty",
  ['M_file_manager = "nemo",
  ['M_editor       = "${EDITOR:-nano}",

  -- Path shortcuts (depend on Layer 1)
  ['S              = "~/.config/hypr/sys/scripts",
  ['H              = "~/.config/hypr/sys/hardware",
  ['P              = "~/.config/hypr/sys/policy",
  ['P_w            = "~/.config/hypr/sys/policy/wallust",
  ['P_a            = "~/.config/hypr/sys/policy/animations",

  -- User layer shortcuts
  ['U              = "~/.config/hypr/user",
  ['U_s            = "~/.config/hypr/user/scripts",

  -- Semantic tags
  ['H_Cheat        = "Help_Cheat",
  ['H_Settings     = "Help_Settings",

  -- Resources
  ['W              = os.getenv("HOME") .. "/Pictures/wallpapers",
  ['Search_Engine = "https://www.google.com/search?q={}",
}
```

**Design Principle**: **Default Values**. All constants have sensible defaults that work out-of-the-box.

#### `user/const.lua` — User Overrides

```lua
-- user/const.lua — only deltas, deep_merge over sys/const.lua
return {
  ['M_terminal     = "ghostty",
  ['M_file_manager = "thunar",
  ['W              = os.getenv("HOME") .. "/Pictures/my-wallpapers",
  ['Search_Engine = "https://www.bing.com/search?q={}",
}
```

**Design Principle**: **Incremental Override**. Only specify differences from defaults.

### Three-Layer Constant System

**📚 Complete Documentation**: See [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) for full specification with dependency graphs, resolution examples, debugging guides, and best practices.

The configuration implements a **three-layer constant resolution system** that applies the Dependency Inversion Principle at multiple levels:

```
Layer 1: bootstrap/const.lua  — Path infrastructure (return { ['Hypr = ..., ['sys = ... })
Layer 2: sys/const.lua        — System defaults  (return { ['M = "SUPER", ... })
Layer 3: user/const.lua       — User overrides    (return { ['M_terminal = "ghostty" })
```

**Resolution Order** (deep_merge, last-write-wins):

```lua
-- bootstrap/default.lua (orchestrator)
local C = {}
deep_merge(C, require("bootstrap.const"))  -- Layer 1
deep_merge(C, require("sys.const"))        -- Layer 2
deep_merge(C, require("user.const"))       -- Layer 3 (LAST = WINS)
-- C['$M_terminal'] is now "ghostty" if user overrode it
```

**Critical Design Decision**: All three layers load in **Stage 0**, ensuring constants are available to ALL subsequent stages.

For complete details including:

- Full constant listings for all three layers
- Dependency graph visualization
- Resolution examples with step-by-step expansion
- Debugging guides for common issues
- Best practices for users and developers
- Performance characteristics
- Advanced techniques (profiles, environment integration)

➡️ Read [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md)

### Compiler Analogy

| Compiler Phase   | Config Equivalent                | Example                                    |
| ---------------- | -------------------------------- | ------------------------------------------ |
| Character Stream | Raw `.lua` source                | Text content                               |
| Tokenization     | `require("X.const")` returns table | `return { ['M = "SUPER" }`            |
| Symbol Table     | Merged const table               | `C['$M']` → `"SUPER"`                       |
| Error Detection  | `nil` lookup at use site         | `C['$UNDEFINED']` → `nil` → visible error  |

---

## Stage 1: Hardware Abstraction (Physical Layer)

### Purpose

Configure physical devices (monitors, keyboards, touchpads) before applying higher-level policies. This mirrors the **hardware abstraction layer (HAL)** in operating systems.

### Pipeline

```lua
-- sys/hardware/default.lua
require("sys.hardware.laptop")     -- laptop-specific binds + touchpad
require("sys.hardware.monitors")    -- display configuration
require("sys.hardware.workspaces")  -- workspace→monitor assignments
```

### Key Design Patterns

#### 1. Device-Specific Configuration

```lua
-- sys/hardware/laptop.lua
local Touchpad_Device = "asue1209:00-04f3:319f-touchpad"  -- parameterized

hl.config({ device = { name    = Touchpad_Device } })
hl.config({ device = { enabled = true } })

-- Laptop function keys
hl.bind("XF86Kbdbrightnessup",
  hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/BrightnessKbd.sh --inc"),
  { repeating = true })
hl.bind("XF86Monbrightnessup",
  hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/Brightness.sh --inc"),
  { repeating = true })
```

**Principle**: **Parameterization**. Device names are local Lua variables, easy to swap.

#### 2. Conditional Behavior via Lid Switch

```lua
-- OPTION B — File-based state management
hl.bind(", switch:off:Lid Switch",
  hl.dsp.exec_cmd('echo "monitor = eDP-1, preferred, auto, 1" > ' ..
                  '~/.config/hypr/sys/hardware/laptop-display.lua'),
  { locked = true })

hl.bind(", switch:on:Lid Switch",
  hl.dsp.exec_cmd('echo "monitor = eDP-1, disable" > ' ..
                  '~/.config/hypr/sys/hardware/laptop-display.lua'),
  { locked = true })

require("sys.hardware.laptop-display")  -- apply current state
```

**Principle**: **State Persistence**. Lid switch state persists across reloads via file I/O.

#### 3. Monitor Profile Swapping

```lua
-- sys/hardware/monitors.lua
-- Managed by nwg-displays; manual edits may be overwritten
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })
hl.monitor({ output = "", mode = "highrr",    position = "auto", scale = "1" })
hl.monitor({ output = "", mode = "highres",  position = "auto", scale = "1" })

-- Switch at runtime: scripts/MonitorProfiles.sh
```

**Principle**: **External Management**. Complex monitor configs delegated to GUI tool (nwg-displays).

### Boundary Contract

**Provides**:

- Monitor resolution/refresh rate
- Keyboard layout/touchpad settings
- Laptop function key bindings

**Consumes**:

- Const table (paths from Stage 0)

**Must Not**:

- Reference user-specific paths directly
- Define visual policies (colors, animations)
- Modify window rules

---

## Stage 2: Policy Application (Strategy Pattern)

### Purpose

Apply swappable visual policies (colors, animations) that can be changed at runtime without full config reload. Implements the **Strategy design pattern**.

### Pipeline

```lua
-- sys/policy/default.lua
require("sys.policy.wallust.wallust-hyprland")  -- returns $colorN table
require("sys.policy.animations.default")        -- hl.curve + hl.animation calls
```

### Color Policy (Wallust Integration)

#### Generation Process

```bash
# Triggered by WallpaperSelect.sh or WallpaperAutoChange.sh
wallust run -s "$wallpaper_path"
# Outputs: sys/policy/wallust/wallust-hyprland.lua (returns a color table)
```

#### Generated Output

```lua
-- sys/policy/wallust/wallust-hyprland.lua (generated by wallust template)
return {
  ['background = "rgb(191B1C)",
  ['foreground = "rgb(E5E7EE)",
  ['color0     = "rgb(404143)",
  ['color1     = "rgb(161C23)",
  -- ... $color2-$color15
  ['color12    = "rgb(70717F)",
  ['color15    = "rgb(D1D4DE)",
}
```

**Design Principle**: **Code Generation**. Colors are programmatically generated, not manually specified.

#### Dependency Constraint

```lua
-- sys/default.lua — CRITICAL ORDER
require("sys.policy.default")  -- defines $colorN (deep_merge into const table)
require("sys.decoration")     -- uses $colorN (now resolvable)
```

**Violation Consequence**: If `sys.decoration` is required before `sys.policy.default`, all `$colorN` references resolve to `nil` → invisible borders / fallback colors.

### Animation Policy (Preset Swapping)

#### Available Presets

| Preset                | Style                  | Performance | Use Case           |
| --------------------- | ---------------------- | ----------- | ------------------ |
| `default.lua`         | Smooth slide           | Medium      | General use        |
| `disable.lua`         | None                   | Maximum     | Gaming, low-power  |
| `end4.lua`            | Material Design pop-in | High        | Modern aesthetic   |
| `hyde-optimized.lua`  | Fast deceleration      | Low-Medium  | Productivity       |
| `ml4w-fast.lua`       | Minimal pop-in         | Low         | Quick interactions |

#### Runtime Switching

```bash
# sys/scripts/Animations.sh
chosen_file="end4"
full_path="$animations_dir/$chosen_file.lua"

# .lua era: reload is via hyprctl dispatch, since .lua doesn't have a
# single-file "source" verb. The script triggers a partial reload of the
# animation module by re-requiring it in a fresh Hyprland Lua state, or
# via hyprctl keyword for individual options.
hyprctl reload
```

**Mechanism**: Runtime animation swap is achieved via `hyprctl reload` (full Lua re-require) or via targeted `hyprctl keyword` calls for individual options.

**State Management**: No state file needed — current animation state readable via:

```bash
hyprctl getoption animations:enabled
```

### Strategy Pattern Implementation

```
┌─────────────────────────────────────┐
│  Context: sys/policy/default.lua   │
│  ┌───────────────────────────────┐  │
│  │ Strategy: wallust colors     │  │
│  │ Strategy: animation preset   │  │
│  └───────────────────────────────┘  │
│  Interface: $colorN, bezier curves  │
└─────────────────────────────────────┘
           │
           │ Runtime swap via:
           │ hyprctl reload (re-requires .lua)
           ▼
┌─────────────────────────────────────┐
│  Concrete Strategies:               │
│  ├── default.lua                    │
│  ├── end4.lua                       │
│  ├── hyde-optimized.lua             │
│  └── ml4w-fast.lua                  │
└─────────────────────────────────────┘
```

**Benefits**:

- **Open/Closed Principle**: Add new presets without modifying existing code
- **Runtime Flexibility**: Swap strategies without restart
- **Testability**: Each preset is independently testable

---

## Stage 3: Core Configuration (Semantic Analysis)

### Purpose

Apply core behavioral settings with incremental override pattern. This is the **semantic analysis phase**, ensuring configuration correctness and applying user customizations.

### Incremental Override Pattern

For each configuration domain `X`:

```lua
-- sys/default.lua (orchestrator)
require("sys.X")   -- vendor defaults (read-only)
require("user.X")  -- user deltas (write here; later wins)
```

### Configuration Domains (Load Order)

#### 1. Environment Variables (`env.lua`)

```lua
-- sys/env.lua
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM",     "wayland;xcb")
hl.env("GDK_BACKEND",         "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- user/env.lua (deltas)
hl.env("GDK_SCALE",           "1.5")          -- HiDPI override
hl.env("LIBVA_DRIVER_NAME",   "nvidia")       -- NVIDIA support
```

**Use Cases**:

- HiDPI scaling
- NVIDIA driver enablement
- Default application selection
- Theme engine configuration

#### 2. Miscellaneous Options (`misc.lua`)

```lua
-- sys/misc.lua
hl.config({ misc = { disable_hyprland_logo = true } })
hl.config({ misc = { vrr = 2 } })                          -- Fullscreen only
hl.config({ misc = { enable_swallow = false } })
hl.config({ misc = { swallow_regex = "^(kitty)$" } })     -- uses $M_terminal

-- user/misc.lua (delta)
hl.config({ debug = { vfr = true } })                     -- Variable frame rate
```

**Key Feature**: `swallow_regex` uses the `$M_terminal` constant → respects user terminal choice.

#### 3. Input Devices (`input.lua`)

```lua
-- sys/input.lua
hl.config({ input = { kb_layout = "us" } })
hl.config({ input = { touchpad = { natural_scroll = true } } })

-- user/input.lua (delta)
hl.config({ input = { kb_layout = "us,cn" } })            -- Add Chinese layout
```

**Per-Window Layout**: Advanced users can enable `Tak0-Per-Window-Switch.sh` for per-application keyboard layouts.

#### 4. Layout Engine (`layout.lua`)

```lua
-- sys/layout.lua
hl.config({ general = { layout = "dwindle" } })           -- Sys default
hl.config({ dwindle  = { preserve_split = true } })
hl.config({ master   = { mfact = 0.5 } })

-- user/layout.lua (delta)
hl.config({ general = { layout = "scrolling" } })         -- requires scrolling layout (built-in since v0.55)

-- plugin-specific options
hl.config({ plugin = { scrolling layout = {
  column_width = 0.5,
  follow_focus = true,
} } })
```

**Layout State Machine**: See [State Machine Documentation](../03-Core-Systems/STATE_MACHINES.md#layout-engine).

#### 5. Visual Decoration (`decoration.lua`)

```lua
-- sys/decoration.lua
hl.config({ decoration = { rounding = 10 } })
hl.config({ decoration = { blur  = { enabled = true, size = 6, passes = 2 } } })
hl.config({ decoration = { shadow = {
  enabled = true,
  color   = "rgb(70717F)",   -- $color12 resolved from Stage 2
} } })

-- user/decoration.lua (delta)
hl.config({ decoration = { rounding = 16 } })             -- larger rounding
hl.config({ decoration = { blur = { size = 8 } } })       -- stronger blur
```

**Dependency**: Requires `$colorN` from Stage 2 (policy layer).

#### 6. Render Pipeline (`render.lua`)

```lua
-- sys/render.lua
hl.config({ general = { col = { active_border   = "rgb(70717F)" } } })  -- $color12
hl.config({ general = { col = { inactive_border = "rgb(1F2A35)" } } })  -- $color10
hl.config({ render = { direct_scanout = 0 } })
hl.config({ cursor = { no_warps = true } })
hl.config({ cursor = { enable_hyprcursor = true } })
```

**Responsibility**: Low-level rendering settings (scanout, cursor warping).

### Load Order Rationale

```
env → misc → input → layout → decoration → render
```

**Reasoning**:

1. **env**: Must be first (affects all subsequent processes)
2. **misc**: Basic behavior before visual settings
3. **input**: Input devices before layout (keyboard affects layout navigation)
4. **layout**: Tiling engine before decoration (layout determines window positions)
5. **decoration**: Visual effects need layout context
6. **render**: Lowest-level settings last (depends on all above)

---

## Stage 4: Service Lifecycle (Process Initialization)

### Purpose

Start background services required for desktop functionality. Implements **process lifecycle management**.

### Pipeline

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

  -- Idle management
  hl.exec_cmd("hypridle -c ~/.config/hypr/sys/hypridle.lua")

  -- Night light (restore previous state)
  hl.exec_cmd("~/.config/hypr/sys/scripts/Hyprsunset.sh init")
end)

-- NEW in .lua era: shutdown hook (cleanup impossible in .conf)
hl.on("hyprland.shutdown", function()
  hl.exec_cmd("pkill swaync 2>/dev/null")
end)
```

### Process Lifecycle Patterns

#### Pattern 1: Stateless Services

```lua
hl.exec_cmd("waybar")
hl.exec_cmd("swaync")
```

**Characteristics**:

- No state persistence
- Can be restarted freely
- Configuration via separate files

#### Pattern 2: Stateful Daemons

```lua
-- sys/startup.lua
hl.exec_cmd("hypridle -c ~/.config/hypr/sys/hypridle.lua")
-- hypridle manages its own state internally
-- Config path must be absolute (process isolation)
```

**Characteristics**:

- Maintains internal state (idle timers)
- Config path must be absolute (process isolation)
- Restart requires state restoration

#### Pattern 3: State-Persisted Services

```lua
-- Hyprsunset — state in ~/.cache/.hyprsunset_state
hl.exec_cmd("~/.config/hypr/sys/scripts/Hyprsunset.sh init")

-- Script reads state file and restores previous state
-- (inside Hyprsunset.sh):
-- cmd_init() {
--     state="$(cat "$STATE_FILE")"
--     if [[ "$state" == "on" ]]; then
--         nohup hyprsunset -t "$TARGET_TEMP" >/dev/null &
--     fi
-- }
```

**Characteristics**:

- State persisted to file
- Startup script restores state
- Toggle script updates state file

#### Pattern 4: Pre-Spawned Terminals

```lua
hl.exec_cmd("~/.config/hypr/sys/scripts/Dropterminal.sh kitty &")
-- Script pre-spawns terminal in special:scratchpad workspace
-- Enables instant drop-down terminal (SUPER+SHIFT+Return)
```

**Characteristics**:

- Pre-initialization for performance
- Hidden until triggered
- Address cached for quick access

### Service Dependencies

```
dbus/systemd environment propagation
  ↓
awww-daemon (wallpaper)
  ↓
waybar (depends on awww for wallpaper info)
  ↓
swaync (notifications)
  ↓
cliphist (clipboard manager)
  ↓
hypridle (idle management)
```

**Design Principle**: **Explicit Ordering**. Services started in dependency order (inside `hyprland.start` handler).

### User Service Addition

```lua
-- user/startup.lua
hl.on("hyprland.start", function()
  hl.exec_cmd("fcitx5 -d -r")                              -- input method
  hl.exec_cmd("blueman-applet")                            -- bluetooth
  hl.exec_cmd("~/.config/hypr/sys/scripts/RainbowBorders.sh")  -- visual effect
end)
```

**Rule**: User services register additional `hyprland.start` handlers; Hyprland invokes all registered handlers (require order = handler order).

---

## Stage 5: Window Management (Rule Compilation)

### Purpose

Compile window classification and behavior rules. This is the most complex stage, implementing a **tag-driven rule system** with clear separation of concerns.

### Pipeline

```lua
require("sys.tags")   -- Define window tags (WHAT an app IS)
require("user.tags")  -- Add user tags
require("sys.rules")  -- Apply rules based on tags (HOW it behaves)
require("user.rules") -- Add user rules
```

### Tag System Architecture

#### Tag Categories

**Category Tags** (What an app IS):

- `browser`, `terminal`, `im`, `email`, `projects`, `notes`
- `file-manager`, `multimedia`, `games`, `settings`, etc.

**Behavior Tags** (How it behaves):

- `pip`, `auth-dialog`, `file-dialog`
- `no-steal-focus`, `suppress-activate`

**Helper Tags**:

- `Help_Cheat`, `Help_Settings`, `keybindings` (registered as window tags so their key hints get float+center treatment)

#### Tag Definition Example

```lua
-- sys/tags.lua
hl.window_rule({
  match = { class = "^([Ff]irefox|[Cc]hromium)$" },
  tag   = "browser",
})

hl.window_rule({
  match = { class = "^(Alacritty|kitty|ghostty)$" },
  tag   = "terminal",
})

hl.window_rule({
  match = { class = "^([Dd]iscord|[Vv]esktop)$" },
  tag   = "im",
})
```

**Principle**: One tag per semantic category. Apps can have multiple tags (multiple rules match the same window).

#### Rule Application Example

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
hl.window_rule({ float   = true, match = { tag = "im" } })
hl.window_rule({ center  = true, match = { tag = "im" } })
hl.window_rule({
  size    = "(monitor_w*0.60) (monitor_h*0.70)",
  match   = { tag = "im" },
})
```

**Principle**: Rules grouped by tag, not by rule type (easier auditing).

### Compound Conditions (Edge Cases)

Some scenarios require conditions beyond simple tags:

```lua
-- Browser sub-windows: float dialogs but not main window
hl.window_rule({
  float = true,
  match = {
    class          = "^([Tt]hunar)$",
    title_negative = "^(.*[Tt]hunar.*)$",
  },
})
```

**Rationale**: Main Thunar window has title containing "Thunar", dialogs don't. Tag alone can't distinguish.

**Rule**: Direct `match.class` only for compound conditions that tags cannot express.

### Tag Completeness Invariant

**Invariant**: Every tag defined in `tags.lua` must have at least one rule in `rules.lua`.

**Audit Method**:

```bash
# Extract all tags from sys/tags.lua
rg -o 'tag\s*=\s*"[^"]+"' sys/tags.lua | sort -u > /tmp/defined_tags

# Extract all tags from sys/rules.lua
rg -o 'tag\s*=\s*"[^"]+"' sys/rules.lua | sort -u > /tmp/used_tags

# Check for orphaned tags
diff /tmp/defined_tags /tmp/used_tags
```

**Violation**: Orphaned tags indicate incomplete configuration (tag defined but never used).

### User Extension Pattern

```lua
-- user/tags.lua
hl.window_rule({
  match = { class = "^(signal)$" },
  tag   = "im",
})

-- user/rules.lua
hl.window_rule({ float  = true,                 match = { tag = "signal" } })
hl.window_rule({ center = true,                  match = { tag = "signal" } })
hl.window_rule({
  size   = "(monitor_w*0.50) (monitor_h*0.60)",
  match  = { tag = "signal" },
})
```

**Pattern**: Add tag in `user/tags.lua`, add rules in `user/rules.lua`.

---

## Pipeline Execution Trace

### Example: Fresh Hyprland Start

```
[00:00.000] hyprland.lua → require("bootstrap.default")
[00:00.001] Stage 0: require("bootstrap.const")
            → C['sys  = "~/.config/hypr/sys"
[00:00.002] Stage 0: require("sys.const")
            → C['M = "SUPER", C['M_terminal = "kitty"
[00:00.003] Stage 0: require("user.const")
            → C['M_terminal = "ghostty" (deep_merge override)
[00:00.004] Stage 1: require("sys.hardware.default")
            → Monitor: eDP-1, 2560x1440@165
            → Touchpad: asue1209 enabled
[00:00.005] Stage 2: require("sys.policy.default")
            → wallust colors deep_merged (C['$color0']-$color15 ready)
            → default animations registered (hl.curve/hl.animation)
[00:00.006] Stage 3: require("sys.env")  → require("user.env")
            → EDITOR=nvim, GDK_SCALE=1.5
[00:00.007] Stage 3: require("sys.misc") → require("user.misc")
            → vfr=true, vrr=2
[00:00.008] Stage 3: require("sys.input") → require("user.input")
            → kb_layout=us,cn
[00:00.009] Stage 3: require("sys.layout") → require("user.layout")
            → layout=scrolling (with scrolling layout (built-in since v0.55))
[00:00.010] Stage 3: require("sys.decoration") → require("user.decoration")
            → rounding=16, blur.size=8
[00:00.011] Stage 3: require("sys.render") → require("user.render")
            → Borders use C['$color12'] resolved to "rgb(70717F)"
[00:00.012] Stage 4: require("sys.startup")
            → hl.on("hyprland.start", fn) registered
[00:00.013] Stage 4: require("user.startup")
            → Additional hl.on("hyprland.start", fn) registered
[00:00.014] Stage 5: require("sys.tags") → require("user.tags")
            → Register 28 category tags + 5 behavior tags
[00:00.015] Stage 5: require("sys.rules") → require("user.rules")
            → 200+ hl.window_rule() calls compiled
[00:00.016] Stage 5: hl.on("hyprland.start") fires
            → KeybindsLayoutInit.sh exec'd → bind J/K per current layout
[00:00.017] Configuration load complete
```

**Total Load Time**: ~17ms (excluding service startup)

---

## Error Handling & Diagnostics

### Common Pipeline Errors

#### 1. Undefined Constant

```
Error: attempt to index nil value (local 'C['$UNDEFINED_VAR']')
```

**Cause**: Constant used before definition, typo, or `require("user.const")` not loaded in Stage 0.

**Fix**: Check Stage 0 const definitions in `bootstrap/const.lua`, `sys/const.lua`, `user/const.lua`. Ensure correct require order in `bootstrap/default.lua`.

#### 2. Missing Color Variables

```
Warning: shadow.color = nil  -- expected "rgb(...)" string
```

**Cause**: `sys.decoration` required before `sys.policy.default`.

**Fix**: Verify Stage 2 (`sys.policy.default`) is required before Stage 3 `sys.decoration` in `sys/default.lua`.

#### 3. Circular Dependency

```
Error: loop or previous error loading module 'sys.X'
```

**Cause**: Module A requires B, B requires A.

**Fix**: Refactor to eliminate circular reference. Use the const table as the shared abstraction.

### Debugging Techniques

#### Trace Constant Resolution

```bash
# Check final value of an option (after .lua config applied)
hyprctl getoption general:border_size

# List all defined Lua-level options
hyprctl options | rg '^\s*\$'
```

#### Inspect Loaded Config

```bash
# View active configuration (resolved form)
hyprctl config

# Check specific option
hyprctl getoption animations:enabled
```

#### Validate Tag Completeness

```bash
# Script to check tag completeness
./scripts/validate_tags.sh
```

---

## Performance Considerations

### Load Time Optimization

1. **Minimize `require()` count**: Fewer, larger modules vs many small files
2. **Avoid Re-requiring**: Lua caches `require()` results, so duplicate calls are cheap; but duplicate `hl.config({...})` calls for the same path waste cycles
3. **Lazy Loading**: Defer non-critical services inside `hl.on("hyprland.start", fn)` (they execute after config load completes)

### Runtime Performance

1. **Batch Commands**: Use `hyprctl --batch` for atomic updates from scripts
2. **Avoid Full Reloads**: Use `hyprctl keyword` for single setting changes
3. **Cache Expensive Operations**: Store computed values in files (e.g., wallpaper state)

### Memory Usage

1. **Disable Unused Features**: `hl.config({ misc = { disable_hyprland_logo = true } })`
2. **Limit Blur Passes**: `hl.config({ decoration = { blur = { passes = 2 } } })` (not 4+)
3. **Reduce Shadow Range**: `hl.config({ decoration = { shadow = { range = 3 } } })` (not 10+)

---

## Best Practices

### For Users

1. **Edit Only `user/` Files**: Never modify `sys/` directly
2. **Minimal Deltas**: Only override what you need (only emit `hl.config({...})` for changes)
3. **Comment Your Changes**: Explain WHY, not WHAT (Lua `--` comments)
4. **Test Incrementally**: Change one thing at a time

### For Developers

1. **Maintain Invariants**: Every tag must have rules
2. **Document Dependencies**: Comment critical require order in `sys/default.lua`
3. **Use the Const Table**: Never hard-code paths in scripts (read from merged const table)
4. **Validate Changes**: Run tag completeness check after modifications

### For Contributors

1. **Follow Naming Conventions**: `$M_*` for apps, `$H_*` for helpers (in const tables)
2. **Preserve Backwards Compatibility**: Don't break existing user const tables
3. **Update Documentation**: Changes require doc updates
4. **Test Edge Cases**: Empty configs, missing files, invalid values

---

## Comparison with Other Approaches

### Traditional Monolithic Config

```lua
-- Single 2000-line hyprland.lua
-- Problems:
-- - Hard to maintain
-- - No separation of concerns
-- - Updates require manual merge
-- - No user/vendor separation
```

### Directory-Based (config.d)

```
/etc/hypr/conf.d/
  ├── 01-monitors.lua
  ├── 02-input.lua
  └── 99-user.lua

# Problems:
# - Numeric prefixes fragile
# - No clear override mechanism
# - Hard to track dependencies
```

### This Pipeline Architecture

```
✅ Clear stage separation
✅ Incremental override pattern (require order = override priority)
✅ Dependency management (deep_merge at Stage 0)
✅ User/vendor separation (sys/ read-only, user/ writable)
✅ Runtime policy swapping (hyprctl reload re-requires)
✅ Tag-driven extensibility (hl.window_rule with match.tag)
```

---

## Future Enhancements

### Potential Improvements

1. **Config Validation Tool**: Static analysis (luacheck + custom rules) for common errors
2. **Dependency Graph Visualization**: Auto-generate pipeline diagram from `require()` calls
3. **Hot Reload for Specific Stages**: Reload only `sys.decoration`, not entire config
4. **Configuration Profiles**: Save/switch between complete config sets
5. **Lua-native State Machines** (Phase C, see `STATE_MACHINES.md`): Move Layout/GameMode/NightLight logic into `.lua` modules using `hl.bind(key, fn)` + `hl.on(event, fn)` instead of external `.sh` scripts

### Research Directions

1. **Formal Verification**: Prove configuration correctness properties (luacheck + Luarocks test framework)
2. **Incremental Compilation**: Only re-`require()` changed modules
3. **Plugin System**: Third-party stage extensions via Lua `package.path` manipulation
4. **Declarative Policies**: YAML/JSON policy definitions compiled to Lua const tables

---

## Historical .conf form

> The following examples show the **legacy `.conf` syntax** preserved here for historical context only. The current repo no longer contains `.conf` files — see git history for the migration.

### Example 1: Stage 0 const file (`.conf` form)

In the legacy `.conf` era, constants were top-level assignments resolved by Hyprland's lexer at parse time:

```conf
# bootstrap/const.conf  (LEGACY — not in current repo)
$Hypr           = ~/.config/hypr
$bootstrap      = $Hypr/bootstrap
$sys            = $Hypr/sys
$user           = $Hypr/user
$lock_background= $Hypr/wallpaper_effects/.wallpaper_current
```

```conf
# sys/const.conf  (LEGACY — not in current repo)
$M              = SUPER
$M_terminal     = kitty
$S              = $sys/scripts
$H_Cheat        = Help_Cheat
```

**Equivalence**: In the `.lua` era these become `return { ['Hypr = "~/.config/hypr", ... }` tables (see [Stage 0](#stage-0-constant-definition-lexical-analysis) above). The `$var` syntax survives only as **table keys** inside the const table — never as bare assignments.

### Example 2: `source =` directive and `exec-once` (`.conf` form)

The `.conf` `source =` directive is the direct ancestor of `.lua`'s `require()`:

```conf
# bootstrap/default.conf  (LEGACY — not in current repo)
require('bootstrap.const')
require('sys.const')
require('user.const')
require('sys.default')
```

```conf
# sys/startup.conf  (LEGACY — not in current repo)
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = awww-daemon --format xrgb
exec-once = waybar
exec-once = $S/Hyprsunset.sh init
```

**Equivalence**: In `.lua`, `source = path` → `require("module.path")` (no `$var` expansion — paths are resolved by Lua's `package.path`). `exec-once = cmd` → `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` (event-driven, with the new bonus of `hl.on("hyprland.shutdown", fn)` cleanup hooks).

---

## References

- [Hyprland Wiki - Configuration](https://wiki.hyprland.org/Configuring/)
- [Compiler Design - Pipeline Architecture](https://en.wikipedia.org/wiki/Compiler)
- [Design Patterns - Strategy Pattern](https://refactoring.guru/design-patterns/strategy)
- [Linux config.d Convention](https://en.wikipedia.org/wiki/Configuration_file)
- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [../../07-Lua-Reference/README.md](../../07-Lua-Reference/README.md) — .lua configuration architecture
- [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md) — .lua syntax reference
- [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) — three-layer const system specification
- [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md) — design principles catalog

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
