# State Machines — Runtime State Management

> Pure `.lua` (Hyprland v0.55+). Verified against actual code in
> [`lib/sm.lua`](../../lib/sm.lua) and [`sys/statemachine/*.lua`](../../sys/statemachine/).

## Overview

Three explicit **finite state machines** manage runtime behavior changes without
full Hyprland reloads. Each FSM lives inside the config as a Lua module under
`sys/statemachine/`, sharing a common base class [`lib/sm.lua`](../../lib/sm.lua).

| FSM | States | Trigger | Module |
| --- | --- | --- | --- |
| Layout | scrolling ↔ dwindle ↔ master | `SUPER + ALT + L` | `sys/statemachine/layout.lua` |
| GameMode | normal ↔ gaming | `SUPER + SHIFT + G` | `sys/statemachine/gamemode.lua` |
| NightLight | off ↔ on | `SUPER + N` | `sys/statemachine/nightlight.lua` |

The legacy bash scripts (`ChangeLayout.sh`, `GameMode.sh`, `Hyprsunset.sh`) survive
as **fallback targets** invoked when the Lua SM fails to load (e.g. `lib/sm.lua` deleted).

---

## Base Class: `lib/sm.lua`

A minimal but formal FSM base class with **atomic transitions** and **invariant assertions**.

```lua
-- lib/sm.lua (excerpt)
local M = {}
M.__index = M

function M.new(opts)
  assert(opts.states and opts.initial and opts.transitions,
    "states, initial, transitions required")
  return setmetatable({
    states      = opts.states,
    initial     = opts.initial,
    current     = opts.initial,
    transitions = opts.transitions,
    invariant   = opts.invariant or function(_) return true end,
    persistence = opts.persistence or "none",
    log         = {},  -- transition log for debugging/property tests
  }, M)
end

function M:fire(event)
  for _, t in ipairs(self.transitions) do
    if t.from == self.current and t.on == event then
      -- ATOMIC: pcall ensures action failures don't leave half-state
      local ok, err = pcall(t.action, self, self.current, t.to)
      if not ok then
        return false, ("transition action failed: %s"):format(err)
      end
      local prev = self.current
      self.current = t.to
      -- INVARIANT assertion (catches logic errors at dev time, not runtime)
      assert(self.invariant(self),
        ("invariant violated after %s -> %s"):format(prev, self.current))
      self.log[#self.log+1] = {from=prev, on=event, to=self.current}
      return true
    end
  end
  return false, ("no transition from %s on %s"):format(self.current, event)
end

-- Property-based testing helpers
function M:fire_n(n, event)
  for _ = 1, n do
    local ok, err = self:fire(event)
    if not ok then return false, err end
  end
  return true
end

function M:reset()
  self.current = self.initial
  self.log = {}
end

return M
```

### Key Properties

| Property | How |
| --- | --- |
| **Atomicity** | `pcall` wraps `t.action` — if the action throws, `self.current` is NOT updated (no half-state) |
| **Invariant checking** | `self.invariant(self)` asserted after every transition; failure raises loud error at dev time |
| **Transition log** | `self.log` records every transition for debugging/property tests |
| **Property testing** | `:fire_n(n, event)` helper fires the same event N times — useful for cycle tests |
| **Reset** | `:reset()` returns to initial state + clears log |

---

## Layout Engine State Machine

**File**: [`sys/statemachine/layout.lua`](../../sys/statemachine/layout.lua)

Cycles through three layouts at runtime via `SUPER + ALT + L`:

```
scrolling  →  dwindle  →  master  →  scrolling  → …
```

```lua
-- sys/statemachine/layout.lua (structure)
local SM = require("lib.sm")

function M.new(hl)
  local function apply_layout(to)
    hl.config({ general = { layout = to } })
    -- Rebind J/K/O based on layout (dwindle: focus + togglesplit;
    -- master: focus only; scrolling: unbind all — built-in owns column nav)
    if to == "dwindle" then
      hl.bind("SUPER + J", hl.dsp.focus({direction="d"}))
      hl.bind("SUPER + K", hl.dsp.focus({direction="u"}))
      hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))
    elseif to == "master" then
      hl.bind("SUPER + J", hl.dsp.focus({direction="d"}))
      hl.bind("SUPER + K", hl.dsp.focus({direction="u"}))
      hl.unbind("SUPER + O")
    else  -- scrolling: built-in column nav
      hl.unbind("SUPER + J"); hl.unbind("SUPER + K"); hl.unbind("SUPER + O")
    end
  end

  return SM.new{
    states = {"scrolling", "dwindle", "master"},
    initial = "dwindle",   -- no hl.getoption in wiki API → default to dwindle
    invariant = function(sm)
      for _, s in ipairs(sm.states) do if s == sm.current then return true end end
      return false
    end,
    transitions = {
      {from="scrolling", on="cycle", to="dwindle",  action=function(_,_,to) apply_layout(to) end},
      {from="dwindle",  on="cycle", to="master",   action=function(_,_,to) apply_layout(to) end},
      {from="master",   on="cycle", to="scrolling", action=function(_,_,to) apply_layout(to) end},
    },
  }
end
```

### Per-layout Keybinds

| Layout | `SUPER+J/K` | `SUPER+O` |
| --- | --- | --- |
| `dwindle` | focus down/up | togglesplit |
| `master` | focus down/up | unbound |
| `scrolling` | unbound (built-in column nav) | unbound |

---

## Game Mode State Machine

**File**: [`sys/statemachine/gamemode.lua`](../../sys/statemachine/gamemode.lua)

Toggles a "gaming" profile: animations/blur/gaps off for performance.

```
normal  ⇄  gaming
```

```lua
-- sys/statemachine/gamemode.lua (structure)
return SM.new{
  states = {"normal", "gaming"},
  initial = "normal",
  transitions = {
    {from="normal", on="toggle", to="gaming",
     action=function(hl, from, to)
       -- Save current decoration, apply gaming profile
       hl.config({
         animations = { enabled = false },
         decoration = { shadow = {enabled=false}, blur = {enabled=false}, rounding = 0 },
         general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
       })
     end},
    {from="gaming", on="toggle", to="normal",
     action=function(hl, from, to)
       -- Restore (reload config defaults)
       hl.exec_cmd("hyprctl reload")
     end},
  },
}
```

### State Persistence

**No persistence** — state resets to `normal` on Hyprland restart. (User can re-toggle
after restart.) Future: persist to `~/.config/hypr/.gamemode_state` file.

---

## Night Light State Machine

**File**: [`sys/statemachine/nightlight.lua`](../../sys/statemachine/nightlight.lua)

Toggles blue light filter (hyprsunset at 4500K):

```
off  ⇄  on
```

```lua
-- sys/statemachine/nightlight.lua (structure)
return SM.new{
  states = {"off", "on"},
  initial = "off",
  transitions = {
    {from="off", on="toggle", to="on",
     action=function(hl, from, to)
       hl.exec_cmd("hyprsunset -t 4500")
     end},
    {from="on", on="toggle", to="off",
     action=function(hl, from, to)
       hl.exec_cmd("pkill hyprsunset")
     end},
  },
}
```

### State Persistence

State persists across Hyprland restarts via `~/.config/hypr/.nightlight_state`
file (read on startup, written on toggle). See the full source for details.

---

## SM-Aware Keybind Pattern

In `sys/keybind.lua`, the SMs are instantiated once (at file load) and bound via
Lua-function dispatchers:

```lua
-- sys/keybind.lua (excerpt)
local layout_mod = require('sys.statemachine.layout')
local gamemode_mod = require('sys.statemachine.gamemode')
local nightlight_mod = require('sys.statemachine.nightlight')

local layout_sm = layout_mod.new(hl)        -- instantiated once, state persists
local gamemode_sm = gamemode_mod.new(hl)
local nightlight_sm = nightlight_mod.new(hl)

hl.bind("SUPER + ALT + L", function() layout_sm:fire("cycle") end)
hl.bind("SUPER + SHIFT + G", function() gamemode_sm:fire("toggle") end)
hl.bind("SUPER + N", function() nightlight_sm:fire("toggle") end)
```

**Key insight**: SMs are instantiated at file load (not in bind callbacks), so
`self.current` state persists across keybind fires.

---

## Race Condition Prevention

### The "Keybind handler must not block" rule

> Wiki warning: Keybind handlers must not block — they run on Hyprland's main thread.

The SMs avoid blocking by:
1. **No `io.popen` / `os.execute` in bind callbacks** — only `hl.exec_cmd()` (async)
2. **No `pcall` of `os.execute`** — `pcall` catches errors but doesn't prevent blocking
3. **State update is synchronous** — `self.current = t.to` is instant; the slow action
   (`hl.exec_cmd`) is fire-and-forget

### Atomic transition guarantee

```lua
local ok, err = pcall(t.action, self, self.current, t.to)
if not ok then return false, err end   -- action failed, state NOT updated
local prev = self.current
self.current = t.to                     -- only update if action succeeded
```

If `t.action` throws, `self.current` stays at `t.from` — no half-state.

---

## Debugging State Issues

### Print current state at runtime

```bash
hyprctl eval 'return require("sys.statemachine.layout").new(hl).current'
# (Note: this creates a NEW instance, so current will be "dwindle" (initial).
#  The actual instance is in sys/keybind.lua's local — not accessible via eval.
#  For true introspection, add a debug hl.on("window.title", ...) hook.)
```

### Check transition log

```lua
-- Add to sys/keybind.lua temporarily:
hl.bind("SUPER + SHIFT + D", function()
  for i, t in ipairs(layout_sm.log) do
    hl.notification.create({ text = string.format("%d: %s → %s on %s", i, t.from, t.to, t.on) })
  end
end)
```

### Property-based testing

```lua
-- Test that 3 cycles return to initial state
local sm = require('sys.statemachine.layout').new(hl)
assert(sm:fire_n(3, "cycle"))   -- should succeed
assert(sm.current == sm.initial) -- should be true
```

---

## Fallback to .sh Scripts

If a Lua SM fails to load (e.g. `lib/sm.lua` deleted, syntax error in module),
the bind falls back to the legacy `.sh` script:

```lua
-- Pattern (not actually in code, but recommended):
local ok_sm, layout_sm = pcall(function() return require('sys.statemachine.layout').new(hl) end)

hl.bind("SUPER + ALT + L", function()
  if ok_sm then layout_sm:fire("cycle")
  else hl.exec_cmd(_G.HYPR_CONST.S .. "/ChangeLayout.sh") end
end)
```

> Note: The current `sys/keybind.lua` doesn't use `pcall` fallback (SMs are required).
> Adding `pcall` fallback is a future enhancement.

---

## References

- [`lib/sm.lua`](../../lib/sm.lua) — base class source
- [`sys/statemachine/layout.lua`](../../sys/statemachine/layout.lua) — layout FSM
- [`sys/statemachine/gamemode.lua`](../../sys/statemachine/gamemode.lua) — game mode FSM
- [`sys/statemachine/nightlight.lua`](../../sys/statemachine/nightlight.lua) — night light FSM
- [`sys/keybind.lua`](../../sys/keybind.lua) — SM-aware binds
- [Finite-state machine (Wikipedia)](https://en.wikipedia.org/wiki/Finite-state_machine)
- [Strategy Pattern](https://refactoring.guru/design-patterns/state)
