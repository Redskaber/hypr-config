# Contributing to hypr-config

> Pure `.lua` (Hyprland v0.55+). All contributions welcome!
> This guide covers the development workflow, coding standards, and validation.

## Quick Start

```bash
# 1. Fork & clone
git clone https://github.com/your-username/hypr-config ~/.config/hypr
cd ~/.config/hypr

# 2. Create feature branch
git checkout -b my-feature

# 3. Make changes (follow coding standards below)

# 4. Verify config
hyprland --verify-config

# 5. Commit & push
git add -A && git commit -m "feat: my feature"
git push origin my-feature

# 6. Open a Pull Request
```

## Development Environment

### Required Tools
- `luacheck` — static analysis (optional)
- `bash` — for running scripts
- `luacheck` (optional, recommended) — static analysis

### Validation Tools (3 layers)

| Tool | Command | Catches |
| --- | --- | --- |
| `lupa` Lua syntax | `python3 -c "..."` | Syntax errors in .lua files |
| `hyprland --verify-config` | Real Hyprland config loader | `hyprland --verify-config` | Runtime errors + API whitelist + orphaned tags |
| 

Run all at once:
```bash
hyprland --verify-config
```

## Coding Standards

### Lua (`.lua` files)

1. **File header** — every file starts with:
   ```lua
   -- @path: sys/path/to/file.lua
   -- @author: redskaber
   -- @date: YYYY-MM-DD
   -- @description: One-line summary
   ```

2. **Dependency Injection** — never hard-code tool names:
   ```lua
   -- BAD
   hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))

   -- GOOD
   local const = require("const")
   hl.bind(const.modifier .. " + Return", hl.dsp.exec_cmd(const.apps.terminal))
   ```

3. **`hl.*` API** — verify every API call against the [Hyprland wiki](https://wiki.hypr.land/):
   - `hl.window_rule` effects: check [Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/)
   - `hl.dsp.*` dispatchers: check [Dispatchers wiki](https://wiki.hypr.land/Configuring/Basics/Dispatchers/)
   - `hl.animation` params: `curve` not `bezier` (see [Animations wiki](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/))

4. **State machines** — use `lib/sm.lua` base class with pcall fallback:
   ```lua
   local ok, sm_mod = pcall(require, 'sys.statemachine.layout')
   local sm = ok and sm_mod.new(hl) or nil
   hl.bind("KEY", function()
     if sm then sm:fire("event") else hl.exec_cmd("fallback.sh") end
   end)
   ```

5. **Never use `class = ""`** — empty regex matches ALL windows (BUG-1).

6. **`size`/`move` expressions** — use Lua table form:
   ```lua
   -- BAD
   hl.window_rule({ size = "(monitor_w*0.5) (monitor_h*0.5)", ... })
   -- GOOD
   hl.window_rule({ size = { "monitor_w * 0.5", "monitor_h * 0.5" }, ... })
   ```

### Shell (`.sh` files)

1. **Source `common.sh`** — every script starts with:
   ```bash
   #!/usr/bin/env bash
   source "$(dirname "$0")/lib/common.sh"
   ```

2. **Use variables, not hard-coded tool names**:
   ```bash
   # BAD
   notify-send "Hello"
   # GOOD
   "$NOTIFY" "Hello"
   ```

3. **File header** — same as Lua, with `@path`, `@author`, `@date`.

### Docs (`.md` files)

1. **Verify all statistics** — use `grep -c` / `wc -l` / `find | wc -l`, don't guess.
2. **Verify all links** — use `[ -e file ]` to check.
3. **Verify all Lua code blocks** — use `lupa load()` to syntax-check.
4. **No `.conf`-era syntax** — the repo is pure `.lua`.

## Architecture Overview

Read [docs/02-Architecture/ARCHITECTURE_OVERVIEW.md](docs/02-Architecture/ARCHITECTURE.md) for:
- Layered pipeline (bootstrap → sys → user)
- Three-layer constants (`const` module, injected via `package.loaded`)
- Tag-driven window management (26 tags)
- State machines (layout/gamemode/nightlight)
- Dependency injection (`lib/deps.lua` + `common.sh`)

## Naming Conventions

| Prefix | Meaning | Example |
| --- | --- | --- |
| `M_*` | Application/command | `M_terminal`, `M_file_manager` |
| `M` | Main modifier key | `M = "SUPER"` |
| `S/H/P` | sys directories | `S` (scripts), `H` (hardware), `P` (policy) |
| `U*` | User-side equivalents | `U_s`, `U_h`, `U_p` |
| `H_*` | Helper tags | `H_Cheat`, `H_Settings` |
| `I_*` | Icons/images | `I_notify` |

## Pull Request Checklist

- [ ] All `.lua` files pass `lupa` syntax check
- [ ] `- [ ] 
- [ ] `bash -n` passes on all modified `.sh` files
- [ ] No hard-coded tool names in `.sh` (use `common.sh` variables)
- [ ] No `class = ""` in `tags.lua` or `rules.lua`
- [ ] All `hl.*` API calls verified against wiki
- [ ] Updated relevant docs (if behavior changed)
- [ ] File headers have `@path`, `@author`, `@date`

## References

- [Hyprland Wiki](https://wiki.hypr.land/) — official API
- [ROADMAP.md](docs/06-Meta/ROADMAP.md) — task planning
- [CHANGELOG.md](docs/06-Meta/CHANGELOG.md) — version history
- [DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md) — design principles
