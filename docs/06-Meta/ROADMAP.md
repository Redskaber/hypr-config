# Project Roadmap

> Pure `.lua` (Hyprland v0.55+). Verified with real `hyprland --verify-config`.

## Current State (2026-08-21)

### Architecture
- **SSOT const**: `sys/const.lua` → `require("const")` (Lua) + `.deps_cache.sh` (shell)
- **Three-layer**: bootstrap (paths) → sys (defaults) → user (overrides)
- **12/12 sys/user pairs**: hardware/env/misc/input/layout/decoration/render/startup/keybind/tags/rules/policy
- **DI**: `lib/deps.lua` (26 tools) + `common.sh` (shell DI via `.deps_cache.sh`)
- **SM**: 3 FSMs (layout/gamemode/nightlight) on `lib/sm.lua` + pcall fallback + state persistence
- **Events**: `hl.on("window.title")` + `hl.on("window.open")` compound conditions
- **Types**: 18 class annotations in `lib/types.lua` (LuaLS)

### Verified
- ✅ Real `hyprland --verify-config`: **config ok**
- ✅ 54 `.lua` files, 62 `.sh` scripts, 26 deps, 21 docs
- ✅ 0 hardcoded paths in `.lua` (all via `const.*`)
- ✅ 0 Chinese comments
- ✅ 0 `_G.HYPR_CONST` legacy
- ✅ `sys/hardware/laptop.lua`: vendor-agnostic (ASUS keys moved to `user/hardware/`)
- ✅ `sys/decoration.lua`: reads merged colors (user/policy/wallust → sys defaults + overrides)

### Pipeline
```
hyprland.lua → bootstrap/default.lua
  Stage 0: const merge (bootstrap + sys + user) → require("const")
           + export_to_shell() → .deps_cache.sh
  Stage 1: sys/default.lua
    sys.hardware.default → user.hardware.default
    sys.policy.default  → user.policy.default
    sys.env  → user.env
    sys.misc → user.misc
    sys.input → user.input
    sys.layout → user.layout
    sys.decoration → user.decoration  (reads merged wallust colors)
    sys.render → user.render
    sys.startup → user.startup
    sys.keybind → user.keybind  (SM with pcall fallback)
    sys.tags → user.tags
    sys.rules → user.rules  (event-driven compound conditions)
```

### Const Architecture (SSOT)
```
sys/const.lua (Lua SSOT)
  ├─ const.apps (terminal, file_manager, editor)
  ├─ const.modifier (SUPER)
  ├─ const.dirs (scripts, hardware, policy, animations, ...)
  ├─ const.external (swaync_dir, rofi_dir, waybar_dir, wallust_dir, kitty_dir, qt_dir)
  ├─ const.helpers (cheat, settings)
  ├─ const.search_engine
  ├─ const.wallpaper_dir
  └─ M.export_to_shell() → .deps_cache.sh (auto-generated)

user/const.lua (overrides)
  └─ M.apps, M.external, M.search_engine, ... (delta only)

common.sh (shell entry)
  └─ source .deps_cache.sh + helper functions
```

### Naming Rules
- **Lua**: `const.apps.terminal`, `const.dirs.scripts`, `const.external.rofi_dir`
- **Shell**: `TERMINAL`, `HYPR_SCRIPTS_DIR`, `ROFI_DIR` (UPPER_SNAKE_CASE)
- **External paths**: all end in `_dir` (swaync_dir, rofi_dir, ...) — no exceptions

## Validation

```bash
# Real Hyprland verify (gold standard)
hyprland --verify-config

# Static analysis
luacheck ~/.config/hypr --codes
```

## Key Lessons (from 104+ audit rounds)

1. Wiki API must be verified — but `--verify-config` is the real gold standard (not wiki)
2. `load()` only checks syntax; real execution catches runtime bugs
3. `_G` globals are anti-pattern; namespaced modules are the solution
4. SSOT: Lua is the single source, auto-generates shell cache
5. Batch operations introduce regressions — always re-verify after
6. `bezier` not `curve` (wiki signature is misleading; runtime is authoritative)
7. `non_consumed` not `non_consuming` (past participle, not present)
8. Naming rules must have zero exceptions
9. sys/ = vendor-agnostic; user/ = vendor-specific + overrides
10. Every `sys/X.lua` must have a paired `user/X.lua` (12/12 complete)
