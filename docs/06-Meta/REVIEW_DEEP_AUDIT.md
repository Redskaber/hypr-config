# Deep Audit Report — Round 2 (Task 69)

> Continuation of Task 68. Addresses "是否只是浮于表面" + "通解 > 特解" + "nix 真实测试必须".

## Summary

| Metric | Task 68 (surface) | Task 69 (deep) | Delta |
| --- | --- | --- | --- |
| Bugs found | 6 (P0) | +1 (BUG-7, runtime crash) | +1 |
| DRY violations fixed | 0 | 8 groups → `floating_panel()` helper | -108 lines |
| Runtime test method | `load()` only | **hypr-sim full pipeline simulator** | qualitative leap |
| Docs audited | 1 (TAG_SYSTEM.md) | 15 files scanned for .conf leftovers | +14 |

## BUG-7: `require("const")` runtime crash (found by hypr-sim, missed by `load()`)

**File**: `sys/hardware/laptop.lua:6`
**Problem**: `local const = require("const")` — standard Lua `require` cannot resolve `"const"` to any file (there is no `const.lua` or `const/init.lua` in package.path). The actual constants live in `_G.HYPR_CONST` (populated by `bootstrap/const.lua` + `sys/const.lua` + `user/const.lua`).
**Root cause**: All other files (keybind, startup, script_utils) correctly use `local const = _G.HYPR_CONST`. `laptop.lua` was the only outlier — a migration artifact.
**Fix**: `local const = _G.HYPR_CONST`
**Why `load()` missed it**: `load()` only checks syntax (can the code compile?). `require("const")` is syntactically valid Lua. Only at RUNTIME does it fail (module not found). The hypr-sim actually executes the `require` chain, catching this class of error.

## hypr-sim: Hyprland API Simulator

### What it does
Instead of running the real nix Hyprland binary (whose `/nix/store` deps are unreachable in this sandbox), the simulator:
1. Stubs all `hl.*` API functions (window_rule, layer_rule, bind, config, env, on, exec_cmd, device, gesture, etc.)
2. Sets up `package.path` to find config modules
3. **Actually executes the full pipeline** (`require("bootstrap.default")` → all sys/ + user/ modules)
4. Collects all 155 registered window rules + 5 layer rules + 145 binds
5. Validates against the wiki API whitelist (effects, props, types)

### Why it's better than `load()`
| Check | `load()` | hypr-sim |
| --- | --- | --- |
| Syntax errors | ✅ | ✅ |
| Runtime errors (nil indexing, missing modules) | ❌ | ✅ |
| Rule registration count | ❌ | ✅ (155 rules) |
| Empty class detection | ❌ | ✅ |
| Orphaned tag detection | ❌ | ✅ |
| Unknown effect detection | ❌ | ✅ (wiki whitelist) |
| Effect type validation | ❌ | ✅ (bool/int/number/string) |
| Pipeline ordering (require chain) | ❌ | ✅ |

### Results
```
Window rules registered: 155
Layer rules registered:   5
Binds registered:        145
Config calls:              8
Event hooks (hl.on):       2
✅ No errors found
✅ No warnings
```

## DRY Refactor: `floating_panel()` helper

### Problem (ISSUE-2 from Task 68)
8 tags (im, notes, file-manager, viewer, text-editor, utils, settings, wallpaper) each had 4 identical-structure rules:
```lua
hl.window_rule({ float = true,  match = { tag = "im" } })
hl.window_rule({ center = true, match = { tag = "im" } })
hl.window_rule({ size = { "monitor_w * 0.60", "monitor_h * 0.70" }, match = { tag = "im" } })
hl.window_rule({ opacity = "0.94 0.86", match = { tag = "im" } })
```
= 32 rules, ~96 lines of repetition.

### Solution (通解 — helper function)
```lua
local function floating_panel(tag, size_expr, opacity_str)
  hl.window_rule({ float = true,   match = { tag = tag } })
  hl.window_rule({ center = true,  match = { tag = tag } })
  hl.window_rule({ size = size_expr, match = { tag = tag } })
  if opacity_str then
    hl.window_rule({ opacity = opacity_str, match = { tag = tag } })
  end
end

floating_panel("im", { "monitor_w * 0.60", "monitor_h * 0.70" }, "0.94 0.86")
```

### Result
- 8 groups replaced → 8 single-line calls
- rules.lua: 379 → 271 lines (−108 lines, −28.5%)
- hypr-sim confirms: still 155 rules registered (same count, same behavior)

## Design Principles Deep Analysis (extended)

### Principles verified as correctly implemented
✅ **SSOT**: tags in `sys/tags.lua` only; rules reference by tag
✅ **Single Responsibility**: tags classify, rules apply effects
✅ **Open/Closed**: user extends via `user/*.lua` without modifying `sys/`
✅ **Strategy Pattern**: each tag = a behavior strategy
✅ **Three-layer constants**: `_G.HYPR_CONST` with last-write-wins
✅ **Dependency Injection**: `lib/deps.lua` resolves 25 tools, 0 hard-coded
✅ **DRY** (now): `floating_panel()` eliminates 4-tuple repetition

### Principles partially implemented (remaining work)
⚠️ **Event-driven**: wiki recommends `hl.on("window.title", fn)` for dynamic title matching (compound conditions). Currently only 2 `hl.on` hooks exist (both in startup). Thunar/Nautilus/Steam sub-window detection still needs this.
⚠️ **Type-driven**: `lib/types.lua` exists but not consumed by rules.lua (no type annotations on the `floating_panel` helper or rule tables).

### Principles not yet implemented
❌ **Data-driven**: tags have no metadata (default opacity/size); rules can't be auto-derived from tag definitions.
❌ **State machine integration**: tags don't interact with SMs (e.g., game mode could auto-dim non-games tags).

## Remaining docs work (15 files with .conf-era leftovers)

| File | .conf leftovers | Priority |
| --- | --- | --- |
| docs/01-Getting-Started/COMMON_TASKS.md | 19 | P1 |
| docs/01-Getting-Started/QUICK_START.md | 12 | P1 |
| docs/02-Architecture/THREE_LAYER_CONSTANTS.md | 18 | P1 |
| docs/02-Architecture/DESIGN_PRINCIPLES.md | 14 | P1 |
| docs/02-Architecture/PIPELINE_ARCHITECTURE.md | 13 | P1 |
| docs/02-Architecture/ARCHITECTURE_OVERVIEW.md | 11 | P1 |
| docs/05-Reference/TROUBLESHOOTING.md | 20 | P1 |
| docs/03-Core-Systems/STATE_MACHINES.md | 10 | P2 |
| docs/07-Lua-Reference/COMPATIBILITY.md | 11 | P2 |
| docs/07-Lua-Reference/README.md | 9 | P2 |
| docs/01-Getting-Started/README.md | 7 | P2 |
| docs/06-Meta/DOCUMENTATION_INDEX.md | 3 | P3 |
| docs/06-Meta/CHANGELOG.md | 1 | P3 |
| docs/06-Meta/DOC_RESTRUCTURING_NOTICE.md | 2 | P3 |
| docs/03-Core-Systems/TAG_SYSTEM.md | 1 (fixed) | ✅ |

**Next round priority**: Rewrite the 7 P1 docs files (Getting Started + Architecture + Troubleshooting) to remove .conf-era syntax and align with actual code.
