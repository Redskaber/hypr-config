# Architecture Overview — Quick Reference

> Pure `.lua` (Hyprland v0.55+). This is a quick reference — for deep dives,
> follow the links below.

## At a Glance

A **layered, pipeline-driven Hyprland configuration** applying software
engineering principles from compiler design, state machine theory, and
policy-based management.

- **Config form**: Lua (native, Hyprland v0.55+)
- **Tested on**: Hyprland 0.56.2
- **Entry point**: [`hyprland.lua`](../../hyprland.lua) (6 lines)
- **Pipeline orchestrator**: [`bootstrap/default.lua`](../../bootstrap/default.lua)
- **Files**: 49 `.lua` + 60 `.sh` + 4 `lib/` modules

## Pipeline (Quick View)

```
hyprland.lua
  └── bootstrap/default.lua
        ├── Stage 0: 3-layer const (bootstrap/sys/user)
        └── Stage 1+: sys/default.lua
              ├── sys/hardware/   ← monitors, laptop, workspaces
              ├── sys/policy/      ← wallust colors + animations preset
              ├── sys/env          ← user/env
              ├── sys/misc         ← user/misc
              ├── sys/input        ← user/input
              ├── sys/layout       ← user/layout
              ├── sys/decoration   ← user/decoration
              ├── sys/render       ← user/render
              ├── sys/startup      ← user/startup
              ├── sys/keybind      ← user/keybind
              ├── sys/tags         ← user/tags
              └── sys/rules        ← user/rules
```

**require order = override priority** (later wins on `_G.HYPR_CONST` and `hl.config()` keys).

## Key Concepts (1-liners)

| Concept | One-liner | Deep dive |
| --- | --- | --- |
| **3-layer constants** | `_G.HYPR_CONST` populated by bootstrap/sys/user; last-write-wins | [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) |
| **Pipeline** | `require()` chain = compilation phases | [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) |
| **Tags** | 26 tags classify windows; rules apply effects by tag | [../03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) |
| **State machines** | 3 FSMs (layout/gamemode/nightlight) on `lib/sm.lua` base | [../03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) |
| **Strategy pattern** | Swappable animation presets + wallust colors | [DESIGN_PRINCIPLES.md § Strategy](DESIGN_PRINCIPLES.md) |
| **Dependency injection** | 25 external tools declared in `lib/deps.lua`, 0 hard-coded | [DESIGN_PRINCIPLES.md § DI](DESIGN_PRINCIPLES.md) |
| **Incremental override** | `user/X.lua` runs after `sys/X.lua`, contains only deltas | [DESIGN_PRINCIPLES.md § Incremental](DESIGN_PRINCIPLES.md) |

## Project Structure (top-level)

```
~/.config/hypr/
├── hyprland.lua              ← entry point: require("bootstrap.default")
├── bootstrap/                ← Layer 1: paths (immutable)
├── sys/                      ← Layer 2: vendor defaults (read-only)
│   ├── const.lua            ← M, M_terminal, S/H/P path prefixes
│   ├── default.lua          ← sys pipeline
│   ├── hardware/            ← monitors + laptop + workspaces
│   ├── policy/              ← animations + wallust (Strategy)
│   ├── statemachine/        ← layout/gamemode/nightlight FSMs
│   ├── scripts/             ← 60 .sh + 3 .lua helpers
│   └── *.lua                ← env/input/decoration/render/keybind/tags/rules
├── user/                     ← Layer 3: YOUR overrides (edit here)
├── lib/                      ← Shared: sm.lua, deps.lua, types.lua, script_utils.lua
└── docs/                     ← This documentation
```

## Key Statistics

| Metric | Value |
| --- | --- |
| Lua config files | 49 |
| Shell scripts | 60 (+ 3 lua helpers in `sys/scripts/lua/`) |
| Shared libraries | 4 (`lib/`) |
| Keybinds | 132 (`hl.bind` calls in `sys/keybind.lua`) |
| Window tags | 26 (20 category + 6 behavior/helper) |
| State machines | 3 |
| External deps declared | 25 (in `lib/deps.lua`) |
| Documentation files | 18 (across 6 categories) |

## Where to Go Next

| If you want to… | Read |
| --- | --- |
| Install & configure | [../01-Getting-Started/QUICK_START.md](../01-Getting-Started/QUICK_START.md) |
| Do common tasks | [../01-Getting-Started/COMMON_TASKS.md](../01-Getting-Started/COMMON_TASKS.md) |
| Understand constants | [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) |
| Understand the pipeline | [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) |
| Design principles catalog | [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md) |
| Tag system | [../03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) |
| State machines | [../03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) |
| Troubleshoot | [../05-Reference/TROUBLESHOOTING.md](../05-Reference/TROUBLESHOOTING.md) |

## Validation

```bash
# Static analysis
luacheck ~/.config/hypr --codes

# Runtime simulator (executes full pipeline)
python3 hypr-sim.py

# Real Hyprland (needs nix store access)
hyprland --verify-config
```

## References

- [Hyprland Wiki](https://wiki.hypr.land/) — official API reference
- [Hyprland Window Rules](https://wiki.hypr.land/Configuring/Basics/Window-Rules/) — `hl.window_rule` spec
- [Hyprland Dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/) — `hl.dsp.*` spec
