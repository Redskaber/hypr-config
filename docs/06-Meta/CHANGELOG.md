# Changelog

> Notable changes to the hypr-config project.
> Pure `.lua` (Hyprland v0.55+).

## 2026-08-20 — Deep audit & docs rewrite

### Added
- `- `lib/deps.lua` `M.export_to_shell()` — generates `.deps_cache.sh` for shell DI
- `sys/startup.lua` calls `deps.export_to_shell()` on `hyprland.start`
- `docs/06-Meta/REVIEW_DEEP_AUDIT.md` — Task 69 deep audit report

### Fixed
- **BUG-1**: `sys/tags.lua` 10 places had `class = ""` (empty regex matches all windows) — replaced with title-based matches
- **BUG-2**: `sys/rules.lua` 5 places had trailing comma in class regex — removed
- **BUG-3**: `sys/rules.lua` 15 places had `size = "(expr) (expr)"` string form — converted to `{ "expr1", "expr2" }` table form
- **BUG-4**: `sys/rules.lua` had `fullscreen = "0"` (string, but wiki says bool) — removed
- **BUG-5**: `sys/rules.lua` had `keep_aspect_ratio = true` (not a window_rule effect) — removed
- **BUG-6**: `sys/rules.lua` had `ignore_alpha = "0.5"` (string, but wiki says number) — fixed to `0.5`
- **BUG-7**: `sys/hardware/laptop.lua` used `require("const")` (runtime crash, "const" is not a module) — fixed to `_G.HYPR_CONST`

### Refactored
- `sys/rules.lua`: DRY refactor — extracted `floating_panel()` helper for 8 repeated 4-tuple patterns (379 → 271 lines, −28.5%)
- `sys/tags.lua`: merged 24 redundant tag rules into 3 (browser 9→1, im 7→1, settings 8→1) using `|` alternation (275 → 195 lines, −29%)
- `sys/scripts/Brightness.sh`: source `.deps_cache.sh` for `BRIGHTNESSCTL`/`NOTIFY_SEND` (DI for shell layer)
- `lib/script_utils.lua`: `notify()` now resolves `notify-send` via `deps.cmd("notify")`

### Rewritten (docs)
- `docs/03-Core-Systems/TAG_SYSTEM.md` (762 → 388 lines) — accurate API + 26 tags
- `docs/02-Architecture/THREE_LAYER_CONSTANTS.md` (943 → 168 lines) — `_G.HYPR_CONST` last-write-wins
- `docs/02-Architecture/PIPELINE_ARCHITECTURE.md` (1518 → 169 lines) — accurate require chain
- `docs/02-Architecture/DESIGN_PRINCIPLES.md` (884 → 245 lines) — 10 principles + patterns
- `docs/02-Architecture/ARCHITECTURE_OVERVIEW.md` (455 → 110 lines) — quick reference
- `docs/01-Getting-Started/QUICK_START.md` (580 → 175 lines) — 5-minute install
- `docs/01-Getting-Started/COMMON_TASKS.md` (911 → 232 lines) — cheat sheet
- `docs/05-Reference/TROUBLESHOOTING.md` (rewrite) — 8 issues + real hyprland --verify-config usage
- `docs/03-Core-Systems/STATE_MACHINES.md` (1204 → 245 lines) — 3 FSMs + base class
- `docs/07-Lua-Reference/COMPATIBILITY.md` (311 → 175 lines) — `.conf` ↔ `.lua` translation
- `docs/07-Lua-Reference/README.md` (230 → 130 lines) — Lua API quick card
- `docs/06-Meta/DOCUMENTATION_INDEX.md` (309 → 90 lines) — navigation hub
- `docs/01-Getting-Started/README.md` (root README) — Task 67 rewrite

### Removed
- All `.conf`-era syntax leftovers from docs (107 occurrences across 15 files → 0)
- Historical `.conf form` sections in docs (preserved in git history)

## Earlier 2026-08-20 — Dropterminal state machine

### Added
- `sys/scripts/Dropterminal.sh` v3.0 — state machine + strategy + pipeline design
  - 3 states (ABSENT/VISIBLE/HIDDEN), explicit transitions
  - `floating_panel()`-style atomic actions
  - `follow=false` for silent workspace move (hide)
  - `action_pin_enable`/`action_pin_disable` (explicit, never toggle)
  - Tag-based window addressing (per wiki "Minimize windows using special workspaces" pattern)

### Fixed
- `hl.dsp.X({...})` → `hl.dispatch(hl.dsp.X({...}))` (17 places in Dropterminal.sh — dispatcher must be wrapped)
- `hyprctl dispatch exec "[rule] cmd"` → `hl.dsp.exec_cmd(cmd, rules)` (legacy hyprlang → Lua API)
- `pin` toggle → explicit `action="enable"`/`action="disable"` (toggle is non-deterministic in state machines)

## 2026-08-19 — Initial `.lua` migration

- Migrated entire config from `.conf` (hyprlang) to `.lua` (Hyprland v0.55+ native Lua API)
- 49 `.lua` files + 4 `.conf` (hyprlock/hypridle daemons only) + 60 `.sh` scripts
- Three-layer constant system (`_G.HYPR_CONST` global, last-write-wins)
- 3 state machines (layout/gamemode/nightlight) on `lib/sm.lua` base class
- Tag-driven window management (26 tags in `sys/tags.lua`)
- Dependency injection via `lib/deps.lua` (25 external tools)
