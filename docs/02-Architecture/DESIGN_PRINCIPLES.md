# Design Principles & Implementation

> Pure `.lua` (Hyprland v0.55+). All claims verified against actual code.

## Executive Summary

This is a **production-grade, layered pipeline architecture** for Hyprland ≥ 0.55
that applies software engineering principles from compiler design, state machine
theory, dependency injection, and policy-based management. The configuration
treats the desktop environment as a **compiled system** rather than a collection
of scripts.

Every Hyprland directive is a function call on the `hl.*` API:
`hl.config()`, `hl.bind()`, `hl.window_rule()`, `hl.on()`, `hl.env()`,
`hl.monitor()`, `hl.device()`, `hl.gesture()`, `hl.curve()`, `hl.animation()`.

## Core Design Principles

### 1. Single Source of Truth (SSOT)

**Each concept defined once, referenced everywhere.**

| SSOT | Location | Referenced by |
| --- | --- | --- |
| Constants | `_G.HYPR_CONST` (3-layer merged) | All sys/ + user/ modules |
| Tags | `sys/tags.lua` (26 tags) | `sys/rules.lua` via `match = { tag = "X" }` |
| External deps | `lib/deps.lua` (25 specs) | `sys/keybind.lua`, `sys/startup.lua` |
| State machines | `lib/sm.lua` (base class) | `sys/statemachine/*.lua` (3 instances) |

### 2. Single Responsibility Principle (SRP)

Each file has one clear purpose:

| File | Responsibility |
| --- | --- |
| `sys/tags.lua` | Classify windows (assign tags) |
| `sys/rules.lua` | Apply effects by tag |
| `sys/keybind.lua` | Register keybinds (132 binds) |
| `sys/startup.lua` | Launch daemons on `hyprland.start` event |
| `sys/decoration.lua` | Visual decoration (blur, shadows) |
| `lib/deps.lua` | Declare external tool dependencies |
| `lib/sm.lua` | State machine base class |

### 3. Open/Closed Principle (OCP)

**sys/ is closed** (vendor, read-only). **user/ is open** (extension point).

```
sys/X.lua   ← vendor defaults (don't edit)
user/X.lua  ← your deltas (edit here, runs AFTER sys, last-write-wins)
```

User can add tags, override rules, add keybinds, change decoration — all without
modifying sys/.

### 4. Dependency Inversion Principle (DIP)

**High-level modules depend on abstractions, not concrete values.**

```lua
-- BAD: hard-coded tool name (violates DIP)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))

-- GOOD: depends on const abstraction (DIP compliant)
local const = _G.HYPR_CONST
hl.bind(const.M .. " + Return", hl.dsp.exec_cmd(const.M_terminal))
--                                          ↑ abstraction, not concrete "kitty"
```

Same for external tools — `lib/deps.lua` declares 25 tools (hyprctl, terminal,
launcher, bar, ...), and `sys/keybind.lua` resolves them via `deps.get("name").cmd`:

```lua
-- sys/keybind.lua
local deps = require("lib.deps")
local launcher_cmd = deps.get("launcher").cmd or "rofi"   -- DI: resolved at load
hl.bind(const.M .. " + D", hl.dsp.exec_cmd(launcher_cmd))
```

### 5. Dependency Injection (DI)

External tools are injected via `lib/deps.lua`:

```lua
-- lib/deps.lua declares the spec
M.specs.terminal = { cmd = "kitty", fallback = "alacritty", env_var = "HYPR_TERMINAL" }

-- sys/keybind.lua injects the resolved tool
local terminal_cmd = deps.get("terminal").cmd   -- "kitty" or $HYPR_TERMINAL
```

**Zero hard-coded tool names** in keybind/startup — all 25 tools come from deps.

### 6. Incremental Override Pattern

User files contain **only deltas**, not full redeclarations:

```lua
-- sys/input.lua (system default — read-only)
hl.config({ input = { kb_layout = "us" } })

-- user/input.lua (your delta — only what differs)
hl.config({ input = { kb_layout = "us,cn" } })   -- last-write-wins on top-level key
```

> ⚠️ `hl.config()` does top-level key merge, not deep merge of every nested field.
> Pass the full sub-table you want to override.

### 7. Strategy Pattern (Policy Layer)

Swappable algorithms at runtime:

```
sys/policy/animations/
  ├── default.lua         ← default preset
  ├── disable.lua         ← no animations
  ├── end4.lua            ← end-4 style
  ├── hyde-optimized.lua  ← HyDE style
  ├── hyde-vertical.lua
  └── ml4w-fast.lua       ← ML4W fast
```

Switch by editing one line in `sys/policy/default.lua`:
```lua
require("sys.policy.animations.end4")   -- was: require("sys.policy.animations.default")
```

Same for wallust colors — `sys/policy/wallust/wallust-hyprland.lua` is
**generated** by wallust on wallpaper change (Strategy: algorithm = current wallpaper).

### 8. State Machine Pattern

Three formal FSMs in `sys/statemachine/`, sharing `lib/sm.lua` base class:

| FSM | States | Trigger | Module |
| --- | --- | --- | --- |
| Layout | scrolling ↔ dwindle ↔ master | `SUPER + ALT + L` | `sys/statemachine/layout.lua` |
| GameMode | normal ↔ gaming | `SUPER + SHIFT + G` | `sys/statemachine/gamemode.lua` |
| NightLight | off ↔ on | `SUPER + N` | `sys/statemachine/nightlight.lua` |

`lib/sm.lua` provides:
- **pcall-wrapped transitions** (atomicity — action failure doesn't leave half-state)
- **invariant assertions** (catches logic errors at dev time)
- **transition log** (for debugging/property tests)

```lua
-- lib/sm.lua (excerpt)
function M:fire(event)
  for _, t in ipairs(self.transitions) do
    if t.from == self.current and t.on == event then
      local ok, err = pcall(t.action, self, self.current, t.to)  -- atomic
      if not ok then return false, err end
      local prev = self.current
      self.current = t.to
      assert(self.invariant(self), "invariant violated")  -- dev-time check
      self.log[#self.log+1] = {from=prev, on=event, to=self.current}
      return true
    end
  end
end
```

### 9. Tag-Driven Window Management

Decouples classification from behavior:

```lua
-- sys/tags.lua — WHAT (classify)
hl.window_rule({ match = { class = "^([Ff]irefox|...)$" }, tag = "browser" })

-- sys/rules.lua — HOW (behavior)
hl.window_rule({ opacity = "1.00 0.85", match = { tag = "browser" } })
```

See [TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) for full spec.

### 10. Event-Driven Pattern

`hl.on(event, fn)` hooks for reactive behavior:

```lua
-- sys/startup.lua
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  -- ... (14 daemons launched on start event)
end)
```

Currently 2 event hooks (both in startup). Future: `hl.on("window.title", fn)`
for dynamic title matching (per wiki recommendation for compound conditions).

## Software Design Patterns Catalog

| Pattern | Where | Example |
| --- | --- | --- |
| **Strategy** | Policy layer (animations, colors) | `sys/policy/animations/*.lua` |
| **State Machine** | Layout/GameMode/NightLight | `sys/statemachine/*.lua` + `lib/sm.lua` |
| **Registry** | Tag registry | `sys/tags.lua` (26 tags) |
| **Template Method** | All apps with same tag follow same rule template | `floating_panel()` helper in rules.lua |
| **Dependency Injection** | External tools | `lib/deps.lua` + `deps.get("name").cmd` |
| **Observer** | Event hooks | `hl.on("hyprland.start", fn)` |
| **Factory** | State machine instantiation | `require('sys.statemachine.layout').new(hl)` |
| **Facade** | Pipeline orchestrator | `bootstrap/default.lua` (single entry) |
| **Pipeline** | Config loading | `require()` chain = compilation phases |

## Layered Architecture

```
┌─────────────────────────────────────────────────┐
│  Layer 3: user/                                 │
│  User overrides (EDIT HERE)                     │
│  const / env / input / keybind / tags / rules  │
├─────────────────────────────────────────────────┤
│  Layer 2: sys/                                  │
│  System defaults (vendor, read-only)            │
│  const / env / input / keybind / tags / rules  │
│  + hardware/ + policy/ + statemachine/          │
├─────────────────────────────────────────────────┤
│  Layer 1: bootstrap/                            │
│  Path infrastructure (immutable)               │
│  const / default                                │
├─────────────────────────────────────────────────┤
│  Layer 0: lib/                                   │
│  Shared libraries (sm, deps, types, utils)      │
└─────────────────────────────────────────────────┘
```

**Boundary rules**:
- Layer N can only depend on layers below (N-1, N-2, ...)
- user/ can read sys/ but not modify it
- sys/ cannot read user/ (one-way dependency)
- lib/ is shared by all layers

## Process Lifecycle Management

Daemons launched via `hl.on("hyprland.start", fn)` in `sys/startup.lua`:

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd(deps.cmd("wallpaper_daemon"))   -- DI: tool from deps
  hl.exec_cmd(deps.get("bar").cmd)             -- DI: waybar
  hl.exec_cmd(deps.get("notification").cmd)    -- DI: swaync
  -- ... 14 total, all resolved via deps
end)
```

**Key**: absolute paths via `_G.HYPR_CONST.S` for scripts, `deps.cmd()` for
external tools. Zero hard-coded `"waybar"` or `"/usr/bin/..."` strings.

## Validation Strategy

### Static (offline)
```bash
luacheck ~/.config/hypr --codes    # see .luacheckrc; hl is a known global
```

### Runtime (sandbox)
```bash
hyprland --verify-config    # executes full require chain + validates all rules
```
hypr-sim catches runtime errors that `load()` and `luacheck` miss (e.g.,
`require("nonexistent")`, `nil` indexing).

### Real Hyprland
```bash
hyprland --verify-config    # gold standard (needs nix store access)
```

## References

- [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) — const system
- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) — pipeline spec
- [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md) — quick reference
- [../03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) — tag system
- [../03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) — FSMs
- [Design Patterns (refactoring.guru)](https://refactoring.guru/design-patterns)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
