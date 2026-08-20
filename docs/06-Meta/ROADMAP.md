# Project Roadmap & Task Planning

> Complete task planning with dependency analysis.
> Based on Task 68-72 audit findings + worklog history.
> Pure `.lua` (Hyprland v0.55+).

## Executive Summary

This roadmap consolidates all findings from Task 68-72 (deep audit rounds) and
defines the remaining work to reach production-grade quality. Tasks are ordered
by dependency and priority.

## Current State (verified 2026-08-20, Task 77)

### Completed
- ✅ 11 bug classes fixed (BUG-1~11)
- ✅ DRY refactor: rules.lua (−108 lines) + tags.lua (−80 lines) = −188 lines
- ✅ DI 通解: `common.sh` shared shell library + `deps.export_to_shell()` + `batch_migrate.py`
- ✅ 91% hard-coded tools eliminated (412/451 → 39 remaining, all path refs or POSIX tools)
- ✅ SM resilience: pcall fallback for all 3 state machines + state persistence
- ✅ Event-driven: `hl.on("window.title")` + `hl.on("window.open")` compound conditions
- ✅ Type-driven: 18 class annotations in `lib/types.lua`
- ✅ Test-driven: 16 SM property tests in `tests/sm_test.lua`
- ✅ CI: `scripts/pre-commit.sh` (3-layer: lupa + hypr-sim + validate_tags)
- ✅ 17 docs rewritten (8287 → 1877 lines, −77%) + ROADMAP + CONTRIBUTING
- ✅ hypr-sim: full pipeline + 48 .lua file scan + animation/curve/config-section validation

### Verified Metrics
| Metric | Value |
| --- | --- |
| Lua config files | 49 (all load OK via hypr-sim) |
| Shell scripts | 60 (54 migrated to common.sh, 91% hard-codes eliminated) |
| Window rules | 134 (0 errors, 0 orphaned tags) |
| Keybinds | 145 |
| External deps | 26 (in `lib/deps.lua`, +wl_copy added) |
| Documentation | 19 files (all .conf leftovers removed) |
| hypr-sim scan | 48/48 .lua files load successfully |
| SM property tests | 16/16 pass |
| Config section validation | 8/8 hl.config calls valid |

---

## Task Priority Matrix

### P0 — Critical (blocks core functionality)
_None remaining_ — all P0 bugs fixed in Task 68-72.

### P1 — High (improves robustness/maintainability)

| Task ID | Description | Dependencies | Effort | Status |
| --- | --- | --- | --- | --- |
| T73 | Migrate remaining 57 .sh scripts to `common.sh` | T72 (common.sh exists) | 4h | Pending |
| T74 | Implement event-driven compound conditions (`hl.on("window.title", fn)`) | None | 2h | Pending |
| T75 | Add type annotations to `lib/types.lua` for all `hl.*` API | T72 | 3h | Pending |
| T76 | Create `validate_tags.sh` script (orphan tag detector) | None | 1h | Pending |

### P2 — Medium (polish/optimization)

| Task ID | Description | Dependencies | Effort | Status |
| --- | --- | --- | --- | --- |
| T77 | Extend hypr-sim to validate `hl.animation`/`hl.curve` params | T72 | 2h | Pending |
| T78 | Add property-based tests for state machines (`lib/sm.lua` `:fire_n`) | None | 2h | Pending |
| T79 | Persist nightlight/gamemode state across Hyprland restarts | None | 1h | Pending |
| T80 | Add `user/` template files with examples | None | 1h | Pending |

### P3 — Low (nice-to-have)

| Task ID | Description | Dependencies | Effort | Status |
| --- | --- | --- | --- | --- |
| T81 | Create CONTRIBUTING.md (contributing guidelines) | None | 1h | Pending |
| T82 | Add CI hook: run `hypr-sim` + `luacheck` on commit | T72 | 2h | Pending |
| T83 | Generate API docs from `lib/types.lua` | T75 | 3h | Pending |
| T84 | Migrate `.luacheckrc` to `luarc.json` (LSP integration) | None | 1h | Pending |

---

## Dependency Graph

```
T72 (common.sh) ──────┬──→ T73 (migrate 57 scripts)
                     │
                     ├──→ T75 (type annotations)
                     │       │
                     │       └──→ T83 (generate API docs)
                     │
                     └──→ T77 (extend hypr-sim)
                              │
                              └──→ T82 (CI hook)

T74 (event-driven) ←─── independent

T76 (validate_tags.sh) ←─── independent

T78 (SM property tests) ←─── independent

T79 (state persistence) ←─── independent

T80 (user templates) ←─── independent

T81 (CONTRIBUTING) ←─── independent

T84 (luarc.json) ←─── independent
```

**Critical path**: T72 → T73 (4h) — unblocks the 57-script migration.
**Parallel track**: T74, T76, T78, T79, T80 can all run independently.

---

## Detailed Task Specs

### T73: Migrate remaining 57 .sh scripts to common.sh

**Goal**: Eliminate all 451 hard-coded tool names by using `common.sh`.

**Approach** (batch by tool usage frequency):
1. **Batch 1 (high frequency, 10 scripts)**: scripts using `notify-send` + `rofi` + `swaync` (most common combo)
   - `Animations.sh`, `ChangeBlur.sh`, `ChangeLayout.sh`, `Kitty_themes.sh`
   - `Quick_Settings.sh`, `sddm_wallpaper.sh`, `SwitchKeyboardLayout.sh`
   - `Tak0-Per-Window-Switch.sh`, `WallpaperEffects.sh`, `WallpaperSelect.sh`
2. **Batch 2 (medium, 15 scripts)**: scripts using `hyprctl` + `jq`
3. **Batch 3 (low, 32 scripts)**: remaining scripts

**Pattern** (per script):
```bash
# Add at top (after shebang):
source "$(dirname "$0")/lib/common.sh"

# Replace hard-coded tool names:
#   notify-send → "$NOTIFY"
#   hyprctl     → "$HYPRCTL"
#   jq          → "$JQ"
#   rofi        → "$ROFI"
#   swaync      → "$NOTIFICATION"
#   grim        → "$SCREENSHOT"
#   slurp       → "$SLURP"
#   playerctl   → "$MEDIA_CONTROL"
#   brightnessctl → "$BRIGHTNESS_CONTROL"
#   pamixer     → "$VOLUME_CONTROL"
```

**Verification**: `bash -n` each script + manual smoke test.

**Effort**: ~4h (60 scripts × ~4 min each).

### T74: Event-driven compound conditions

**Goal**: Use `hl.on("window.title", fn)` for sub-window detection (Thunar dialogs, Steam popups, etc.) that can't be expressed via static `match` table.

**Approach** (per wiki "Static effects cannot match on dynamically-changing titles"):
```lua
-- sys/rules.lua (new section)
hl.on("window.title", function(w)
  if w == nil then return end
  -- Float Firefox dialogs (title != "Mozilla Firefox")
  if w.class and w.class:match("^([Ff]irefox)$") then
    if w.title and not w.title:match("^Mozilla Firefox") then
      hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))
    end
  end
  -- Float Thunar dialogs (title != "Thunar" / "Files")
  if w.class and w.class:match("^([Tt]hunar)$") then
    if w.title and w.title ~= "Thunar" then
      hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))
    end
  end
end)
```

**Effort**: ~2h (5-10 compound conditions).

### T75: Type annotations for `lib/types.lua`

**Goal**: Make `lib/types.lua` a comprehensive type definition file for LuaLS / lua-language-server.

**Approach**: Add `---@class` / `---@field` annotations for all `hl.*` API:
```lua
--- @class HL
--- @field config fun(opts: table)
--- @field bind fun(key: string, action: any, flags?: table)
--- @field window_rule fun(opts: table)
--- @field layer_rule fun(opts: table)
--- @field on fun(event: string, fn: function)
--- @field env fun(key: string, value: string)
--- @field exec_cmd fun(cmd: string)
--- @field monitor fun(opts: table)
--- @field device fun(opts: table)
--- @field notification HLNotification
--- @field dsp HLDispatcher
--- ...
```

**Effort**: ~3h.

### T76: `validate_tags.sh` script

**Goal**: CI script that detects orphaned tags (defined in `tags.lua` but no rule in `rules.lua`).

```bash
#!/usr/bin/env bash
# sys/scripts/validate_tags.sh — detect orphaned tags
source "$(dirname "$0")/lib/common.sh"

defined=$("$JQ" -r '.[]' <(grep -oE 'tag = "[^"]+"' "$HYPR_CONFIG_DIR/sys/tags.lua" | sort -u) 2>/dev/null || \
  grep -oE 'tag = "[^"]+"' "$HYPR_CONFIG_DIR/sys/tags.lua" | sed 's/tag = //; s/"//g' | sort -u)
used=$(grep -oE 'tag = "[^"]+"' "$HYPR_CONFIG_DIR/sys/rules.lua" | sed 's/tag = //; s/"//g' | sort -u)

orphans=$(comm -23 <(echo "$defined") <(echo "$used"))
if [ -n "$orphans" ]; then
  echo "❌ Orphaned tags (defined but no rule):"
  echo "$orphans"
  exit 1
fi
echo "✅ All tags have rules"
```

**Effort**: ~1h.

---

## Retrospective: Lessons Learned (Task 68-72)

### Lesson 10: API consistency must use wiki whitelist
`keep_aspect_ratio` looks like an effect but is a dispatcher param; `fullscreen` is bool not string; `ignore_alpha` is number not string. These can only be verified by checking wiki, not by memory.

### Lesson 11: `load()` only checks syntax; runtime execution catches more
`require("const")` is syntactically valid but crashes at runtime. `hl.device(nil)` is syntactically valid but raises "attempt to call nil value". Only building an API simulator that actually executes the pipeline catches these "syntax-correct but logic-wrong" bugs.

### Lesson 12: docs must be based on code reality, not impressions
Old docs had `return { ['M = "SUPER" }` (invalid Lua), `deep_merge` (doesn't exist), `tag +X` (old syntax), `.strip()` (Python). Rewrite by measuring every stat with `grep`/`wc`, validating every code block with `lupa load()`, checking every link with `[ -e file ]`.

### Lesson 13: Audit must find systemic root causes, not surface fixes
Task 68-70 fixed 7 bugs + refactored tags/rules, but missed 52 .sh scripts hard-coding 451 tool names. This is a systemic DI violation: `lib/deps.lua` declares 25 tools but .sh layer doesn't use them. `deps.export_to_shell()` is the 通解 — lets .sh read deps too.

### Lesson 14: Audit must cover ALL files, not just main pipeline
Task 71's hypr-sim only ran `require("bootstrap.default")` main pipeline; `sys/scripts/lua/*.lua` are on-demand modules not in the pipeline, so `require("sys.deps")` bug wasn't caught. Fixed in Task 72 by extending hypr-sim to scan all 48 .lua files.

### Lesson 15 (REVISED): `bezier` is correct, `curve` is WRONG — wiki is misleading
Wiki signature says `curve = STRING` but actual `hyprland --verify-config` rejects it with "bezier or spring is required". The wiki examples use `bezier = "name"` and `spring = "name"` — those are correct. **The gold standard is `--verify-config`, not wiki docs** (wiki has internal inconsistency). BUG-13 was my mistake in Task 73: I changed `bezier=` → `curve=` based on wiki signature, but real Hyprland requires `bezier=`/`spring=`. Fixed in Task 80 by reverting to `bezier=`.

---

## Validation Strategy (ongoing)

### Three-layer verification (all must pass)

1. **Static analysis** (`luacheck`):
   ```bash
   luacheck ~/.config/hypr --codes
   ```

2. **Runtime simulator** (`hypr-sim`, catches what luacheck misses):
   ```bash
   python3 hypr-sim.py
   # Scans: main pipeline + all 48 .lua files
   # Validates: rule effects against wiki whitelist, orphaned tags, type mismatches
   ```

3. **Real Hyprland** (gold standard, needs nix store):
   ```bash
   hyprland --verify-config
   ```

### Pre-commit hook (proposed T82)
```bash
# .git/hooks/pre-commit
#!/bin/bash
cd ~/.config/hypr
luacheck --codes . || exit 1
python3 hypr-sim.py || exit 1
bash sys/scripts/validate_tags.sh || exit 1  # (after T76)
```

---

## Long-term Vision

### Architectural Goals (achieved)
- ✅ Layered pipeline (bootstrap → sys → user)
- ✅ Three-layer constants (`_G.HYPR_CONST`, last-write-wins)
- ✅ Tag-driven window management (26 tags, 134 rules)
- ✅ State machines (3 FSMs on `lib/sm.lua` base)
- ✅ Strategy pattern (animations/wallust policies)
- ✅ Dependency injection (`lib/deps.lua` + `common.sh`)
- ✅ DRY (helpers: `floating_panel()`, `common.sh`)

### Architectural Goals (in progress)
- 🔄 Event-driven (compound conditions via `hl.on`)
- 🔄 Type-driven (`lib/types.lua` annotations)
- 🔄 Data-driven (tag metadata → auto-derive rules)
- 🔄 State machine integration (game mode auto-dims non-games tags)

### Quality Goals
- 🔄 100% .sh scripts use `common.sh` (3/60 done)
- 🔄 100% `hl.*` API type-annotated
- 🔄 CI hook (pre-commit: luacheck + hypr-sim + validate_tags)
- 🔄 Property-based tests for state machines

---

## References

- [AUDIT_REPORT.md](../../AUDIT_REPORT.md) — Task 68 audit
- [REVIEW_DEEP_AUDIT.md](REVIEW_DEEP_AUDIT.md) — Task 69 deep audit
- [CHANGELOG.md](CHANGELOG.md) — version history
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) — doc navigation
- [Hyprland Wiki](https://wiki.hypr.land/) — official API
- `hypr-sim.py` — runtime simulator
- `worklog.md` — full task history (Task 60-72)
