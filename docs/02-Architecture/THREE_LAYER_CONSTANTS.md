# Three-Layer Constant System - Complete Specification

> **本文档以 .lua（Hyprland v0.55+ 原生）为准**。历史 .conf 形式见文末 [Historical .conf form](#historical-conf-form) 节，亦见 git history。
> 语法对照见 [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md)。

## Overview

This document provides the **complete specification** of the three-layer constant system used throughout the Hyprland configuration. This system implements the **Dependency Inversion Principle** at multiple levels, enabling flexible customization while maintaining architectural integrity.

In the `.lua` era, the "constant system" is not a Hyprland DSL feature — it is a **convention** built on plain Lua:

1. Each const file `return`s a plain Lua table whose keys are the legacy `$var` names (kept as strings for compatibility).
2. The bootstrap orchestrator `deep_merge`s the three tables in order (bootstrap → sys → user); last-write-wins.
3. All later modules see the merged table as a single source of truth and look up keys at use site.

This replaces the `.conf` era's "use-time substitution" (where Hyprland's lexer re-walked the file every time a `$var` was used) with **explicit deep_merge at bootstrap** — one merge, no re-walks.

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: bootstrap/const.lua                           │
│  Purpose: Infrastructure paths ($Hypr, $sys, $user)     │
│  Form:    return { ['Hypr = "...", ['sys = "..." }│
│  Dependencies: None                                     │
│  Overrideable: No                                       │
└──────────────────────┬──────────────────────────────────┘
                       │ deep_merge(C, require("bootstrap.const"))
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 2: sys/const.lua                                │
│  Purpose: System defaults ($M, $S, $H, $P, $W)         │
│  Form:    return { ['M = "SUPER", ['M_terminal=..│
│  Dependencies: Layer 1 (paths already in C)             │
│  Overrideable: Yes (by Layer 3)                         │
└──────────────────────┬──────────────────────────────────┘
                       │ deep_merge(C, require("sys.const"))
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 3: user/const.lua                               │
│  Purpose: User overrides ($M_terminal, $W, etc.)       │
│  Form:    return { ['M_terminal = "ghostty", ... }  │
│  Dependencies: Layers 1 & 2 (already merged into C)    │
│  Overrideable: N/A (final layer, last-write-wins)      │
└─────────────────────────────────────────────────────────┘
```

**Resolution Order**: Layer 1 → Layer 2 → Layer 3 (deep_merge, last-write-wins)  
**Load Time**: Stage 0 (before all other stages)  
**Total Constants**: ~30 (5 + 20 + 5-10)

---

## Layer 1: `bootstrap/const.lua` — Infrastructure Paths

### File Content

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

### Characteristics

| Property            | Value                                    |
| ------------------- | ---------------------------------------- |
| **Dependencies**    | None (except `$Hypr`)                    |
| **Overrideable**    | No (infrastructure is fixed)             |
| **Constants Count** | 5                                        |
| **Edit Frequency**  | Rarely (only if moving config directory) |
| **Analogy**         | Compiler's include path configuration    |

### Design Principles

1. **Single Source of Truth**: All path infrastructure defined in one place
2. **No Circular Dependencies**: Cannot reference `$sys` or `$user` before they're defined
3. **Absolute Paths**: Use `~` expansion for home directory portability

### Usage Examples

```lua
-- Anywhere in the config, look up the merged const table:
local C = require("bootstrap._const")  -- exported merged table

require("sys.decoration")              -- expands internally to ~/.config/hypr/sys/decoration.lua
hl.exec_cmd(C['$S'] .. "/WallpaperAutoChange.sh " .. C['$W'])
-- resolves to: hl.exec_cmd("~/.config/hypr/sys/scripts/WallpaperAutoChange.sh ~/Pictures/wallpapers")
```

---

## Layer 2: `sys/const.lua` — System Default Constants

### File Content

```lua
-- sys/const.lua
return {
  -- Modifier keys
  ['M              = "SUPER",
  ['M_terminal     = "kitty",
  ['M_file_manager = "nemo",
  ['M_editor       = os.getenv("EDITOR") or "nano",

  -- Path shortcuts (depend on Layer 1 values)
  ['S   = "~/.config/hypr/sys/scripts",
  ['H   = "~/.config/hypr/sys/hardware",
  ['P   = "~/.config/hypr/sys/policy",
  ['P_w = "~/.config/hypr/sys/policy/wallust",
  ['P_a = "~/.config/hypr/sys/policy/animations",

  -- User layer shortcuts
  ['U    = "~/.config/hypr/user",
  ['U_s  = "~/.config/hypr/user/scripts",
  ['U_h  = "~/.config/hypr/user/hardware",
  ['U_p  = "~/.config/hypr/user/policy",
  ['U_pw = "~/.config/hypr/user/policy/wallust",
  ['U_pa = "~/.config/hypr/user/policy/animations",

  -- Helper window tags
  ['H_Cheat    = "Help_Cheat",
  ['H_Settings = "Help_Settings",

  -- Resources
  ['W            = os.getenv("HOME") .. "/Pictures/wallpapers",
  ['W_l          = "",
  ['Search_Engine = "https://www.google.com/search?q={}",
}
```

### Constant Categories

| Category           | Variables                                           | Count  | Purpose                          |
| ------------------ | --------------------------------------------------- | ------ | -------------------------------- |
| **Modifiers**      | `$M`, `$M_terminal`, `$M_file_manager`, `$M_editor` | 4      | Application defaults             |
| **Path Shortcuts** | `$S`, `$H`, `$P`, `$P_w`, `$P_a`                    | 5      | Quick access to sys directories  |
| **User Layer**     | `$U`, `$U_s`, `$U_h`, `$U_p`, `$U_pw`, `$U_pa`      | 6      | Quick access to user directories |
| **Semantic Tags**  | `$H_Cheat`, `$H_Settings`                           | 2      | Window tag constants             |
| **Resources**      | `$W`, `$W_l`, `$Search_Engine`                     | 3      | Wallpaper, search engine         |
| **Total**          |                                                     | **20** |                                  |

### Characteristics

| Property            | Value                                         |
| ------------------- | --------------------------------------------- |
| **Dependencies**    | Layer 1 (`$sys`, `$user`, `$Hypr`)            |
| **Overrideable**    | Yes (by Layer 3)                              |
| **Constants Count** | 20                                            |
| **Edit Frequency**  | Never (vendor defaults)                       |
| **Analogy**         | Compiler's standard library and default flags |

### Design Principles

1. **Default Values with Override Points**: All constants have working defaults but are designed to be overridden
2. **Semantic Abstraction**: Tag names (`$H_Cheat`) abstract implementation details
3. **Path Composition**: Build complex paths from simple primitives (`$P_w` derived from `$P`/wallust)
4. **Environment Integration**: `os.getenv("EDITOR") or "nano"` respects system environment variables

### Dependency Chain

```lua
-- All resolved at deep_merge time (Stage 0):
--   Layer 1 provides ['$sys']  → "~/.config/hypr/sys"
--   Layer 1 provides ['$user'] → "~/.config/hypr/user"
-- Then Layer 2 builds on top:

C['S   = C['$sys']  .. "/scripts"      -- ~/.config/hypr/sys/scripts
C['H   = C['$sys']  .. "/hardware"     -- ~/.config/hypr/sys/hardware
C['P   = C['$sys']  .. "/policy"       -- ~/.config/hypr/sys/policy
C['P_w = C['$P']    .. "/wallust"
C['P_a = C['$P']    .. "/animations"

C['U   = C['$user']                    -- ~/.config/hypr/user
C['U_s = C['$U']    .. "/scripts"
C['U_h = C['$U']    .. "/hardware"
C['U_p = C['$U']    .. "/policy"
```

**Invariant**: No forward references allowed (cannot use `$P` before it's defined).

> **Note on the actual repo**: The current `sys/const.lua` in hypr-config uses the resolved literal strings directly (`"~/.config/hypr/sys/scripts"`) rather than computing from `$sys`. This is a Phase A mechanical-translation artifact. The intent (and the proper Phase B refactor) is composition from the merged const table as shown above.

---

## Layer 3: `user/const.lua` — User Override Constants

### File Content (Example)

```lua
-- user/const.lua — User constant overrides
-- Required by bootstrap/default.lua (Stage 0), AFTER sys.const.
-- Deep-merged on top of bootstrap+sys, so any matching key wins (last-write-wins).

return {
  -- Override application defaults
  ['M_terminal     = "ghostty",
  ['M_file_manager = "thunar",
  ['M_editor       = "nvim",

  -- Override resource paths
  ['W              = os.getenv("HOME") .. "/Pictures/my-wallpapers",
  ['Search_Engine  = "https://www.bing.com/search?q={}",

  -- Add custom constants
  ['M_browser      = "firefox",
}
```

### Characteristics

| Property            | Value                                         |
| ------------------- | --------------------------------------------- |
| **Dependencies**    | Layers 1 & 2 (can reference any constant)     |
| **Overrideable**    | N/A (final layer, last-write-wins)            |
| **Constants Count** | 5-10 (typical user)                           |
| **Edit Frequency**  | Often (user preferences change)              |
| **Analogy**         | User's .bashrc overriding system /etc/profile |

### Design Principles

1. **Incremental Override**: Only specify differences from defaults
2. **Minimal Configuration**: Don't copy entire sys/const.lua
3. **Early Loading**: Loaded in Stage 0 to affect all subsequent stages
4. **Documentation**: Comment why you're overriding (e.g., "for privacy reasons")

### Critical Design Decision: Stage 0 Loading

**Why `user/const.lua` is required in Stage 0, NOT Stage 3:**

```lua
-- CORRECT: User constants available everywhere
-- bootstrap/default.lua
local C = {}
deep_merge(C, require("bootstrap.const"))  -- Layer 1
deep_merge(C, require("sys.const"))        -- Layer 2
deep_merge(C, require("user.const"))       -- Layer 3 (LAST = WINS)

-- Now ALL sys/ files can read user overrides from C:
-- sys/misc.lua
hl.config({ misc = { swallow_regex = "^(" .. C['$M_terminal'] .. ")$" } })  -- uses "ghostty" ✓

-- sys/startup.lua
hl.on("hyprland.start", function()
  hl.exec_cmd("~/.config/hypr/sys/scripts/Dropterminal.sh " .. C['$M_terminal'])
  -- expands to: Dropterminal.sh ghostty ✓
end)
```

```lua
-- WRONG: User constants loaded too late
-- bootstrap/default.lua
require("sys.default")           -- uses $M_terminal = "kitty" from sys.const
require("user.const")           -- sets $M_terminal = "ghostty"  → TOO LATE!

-- Result: sys/misc.lua already used "kitty", can't change retroactively
```

**Impact Areas**:

- `sys/misc.lua` → `swallow_regex = "^(" .. C['$M_terminal'] .. ")$"`
- `sys/startup.lua` → `hl.exec_cmd("$S/Dropterminal.sh " .. C['$M_terminal'])`
- `sys/keybind.lua` → `hl.bind(C['$M'] .. " + Return", hl.dsp.exec_cmd(C['$M_terminal']))`
- All scripts that parse the merged const table

---

## Constant Resolution Example

### Scenario: Change Terminal from Kitty to Ghostty

**Step 1: User edits `user/const.lua`**

```lua
-- user/const.lua
return {
  ['M_terminal = "ghostty",
}
```

**Step 2: Resolution Process (`deep_merge` in `bootstrap/default.lua`)**

```lua
-- Pseudo-code for the bootstrap merge
local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v  -- last-write-wins
    end
  end
  return dst
end

local C = {}
deep_merge(C, require("bootstrap.const"))  -- C['sys = "~/.config/hypr/sys"
deep_merge(C, require("sys.const"))        -- C['M_terminal = "kitty"
deep_merge(C, require("user.const"))       -- C['M_terminal = "ghostty" (WINS)
return C  -- exported as the single source of truth for the rest of the pipeline
```

**Step 3: Final Resolved Values**

```lua
C['sys         = "~/.config/hypr/sys"
C['user        = "~/.config/hypr/user"
C['S           = "~/.config/hypr/sys/scripts"
C['M_terminal  = "ghostty"      -- ← user preference applied
C['M           = "SUPER"        -- ← inherited from sys.const
```

**Step 4: Propagation Throughout Pipeline**

```lua
-- Stage 3: sys/misc.lua
hl.config({ misc = { swallow_regex = "^(" .. C['$M_terminal'] .. ")$" } })
-- → hl.config({ misc = { swallow_regex = "^(ghostty)$" } })

-- Stage 4: sys/startup.lua
hl.on("hyprland.start", function()
  hl.exec_cmd("~/.config/hypr/sys/scripts/Dropterminal.sh " .. C['$M_terminal'])
  -- → hl.exec_cmd("~/.config/hypr/sys/scripts/Dropterminal.sh ghostty")
end)

-- Stage 5: sys/keybind.lua
hl.bind(C['$M'] .. " + Return", hl.dsp.exec_cmd(C['$M_terminal']))
-- → hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))
```

**Key Insight**: A single edit in `user/const.lua` propagates to **3 different stages** automatically — because they all read from the same merged `C` table.

---

## Constant Dependency Graph

```
bootstrap/const.lua (Layer 1 — returns table, no deps)
  ├── ['$Hypr']
  ├── ['$bootstrap']
  ├── ['$user'] ────────────────────────────────────────┐
  └── ['$sys'] ───────────────────────────────────┐     │
                                                │     │
sys/const.lua (Layer 2 — returns table)         │     │
  ├── ['$M'], ['$M_terminal'], ['$M_file_manager']      │
  ├── ['S   = '$sys' .. "/scripts" ──────────┤     │
  ├── ['H   = '$sys' .. "/hardware" ─────────┤     │
  ├── ['P   = '$sys' .. "/policy" ───────────┤     │
  ├── ['U   = '$user' ───────────────────────┘     │
  ├── ['$H_Cheat'], ['$H_Settings']                    │
  └── ['$W'], ['$Search_Engine']                       │
                                                       │
user/const.lua (Layer 3 — returns table)               │
  ├── ['M_terminal = "ghostty" ─────────────────────┤ (overrides Layer 2)
  ├── ['W          = "~/Pictures/custom" ───────────┘ (overrides Layer 2)
  └── ['M_browser  = "firefox"          (new constant)
```

**Invariant**: No circular dependencies allowed (Layer N cannot depend on Layer N+1).

---

## Resolution Algorithm — `deep_merge` in Lua

The bootstrap orchestrator uses a single recursive merge. Tables merge recursively; scalars replace:

```lua
-- bootstrap/default.lua (conceptual — see actual file in repo)

local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)   -- recurse for nested tables
    else
      dst[k] = v               -- last-write-wins for scalars (and type-changes)
    end
  end
  return dst
end

-- Stage 0: build the merged const table
local C = {}
deep_merge(C, require("bootstrap.const"))  -- Layer 1: paths
deep_merge(C, require("sys.const"))        -- Layer 2: system defaults
deep_merge(C, require("user.const"))       -- Layer 3: user overrides (WINS)

-- Optional: merge wallust color sub-table (Stage 2 will append more later)
-- deep_merge(C, require("sys.policy.wallust.wallust-hyprland"))

-- Export for later modules
package.loaded["bootstrap._const"] = C  -- so require("bootstrap._const") returns C

-- Stage 1+: continue the pipeline
require("sys.default")
```

**Why `deep_merge` instead of Hyprland's lexer?**: The `.conf` era relied on Hyprland to substitute `$var` on every use site. In `.lua`, that substitution happens **once** at bootstrap — explicit, debuggable, no hidden lexer behavior.

---

## "Use-Time Substitution" → "Explicit deep_merge at bootstrap"

The `.conf` era had a concept called **use-time substitution**: a `$var` was looked up by Hyprland's lexer every time the file was re-parsed. This had three problems:

1. **Order-dependent**: If you sourced `user/const.conf` *after* `sys/misc.conf`, the misc config already used the wrong value.
2. **Implicit**: The substitution was invisible — you couldn't trace where a `$var` came from.
3. **Cost**: Every re-parse walked the entire const table.

In `.lua`, this becomes **explicit deep_merge at bootstrap**:

| Aspect          | `.conf` (use-time substitution)               | `.lua` (bootstrap deep_merge)                  |
| --------------- | --------------------------------------------- | ---------------------------------------------- |
| When            | On every parse of every file                  | Once, at Stage 0 in `bootstrap/default.lua`   |
| Where           | Hyprland's internal lexer (hidden)            | `deep_merge(C, require("user.const"))` (visible) |
| Cost            | O(N) per file × M files                       | O(N+M) total                                   |
| Traceability    | Implicit (no debug surface)                   | Explicit (`print(vim.inspect(C))` works)       |
| Override safety | Source order matters across **all** files     | Only the **three** const files matter          |

**Migration impact**: If you came from `.conf`, you no longer need to worry about "is user/const.conf sourced before sys/misc.conf?" — the answer is always yes, because `user/const.lua` is `deep_merge`d into `C` before **any** other `require()` happens.

---

## Compiler Analogy

| Compiler Phase            | Config Equivalent                       | Example                                  |
| ------------------------- | --------------------------------------- | ---------------------------------------- |
| **Preprocessor Includes** | `bootstrap/const.lua` (returns table)   | `require("bootstrap.const")`             |
| **Standard Library**      | `sys/const.lua` (returns table)         | Default paths, modifiers                 |
| **User Headers**          | `user/const.lua` (returns table)        | Custom overrides                         |
| **Symbol Table**          | The merged `C` table                    | `C['$M_terminal']` → `"ghostty"`         |
| **Type Checking**         | Lookup of `C[key]` returns `nil` if unset | `C['$UNDEFINED']` → `nil` → visible error |
| **Linking**               | `deep_merge` finalization              | last-write-wins applied                  |

**Process**:

1. **Scan** all `const.lua` files (each returns a table)
2. **Build** the merged `C` table via `deep_merge`
3. **Resolve** dependencies (ensure no forward references inside individual tables)
4. **Apply** overrides (user/ wins over sys/)
5. **Validate** (look up `C[key]` at use site — `nil` is an immediate error)

---

## Common Constant Patterns

### Pattern 1: Application Defaults

```lua
-- sys/const.lua
return {
  ['M_terminal     = "kitty",
  ['M_browser      = "firefox",
  ['M_editor       = os.getenv("EDITOR") or "nano",
}

-- user/const.lua
return {
  ['M_terminal = "ghostty",  -- override only what you need
  -- ['$M_browser']   inherits "firefox"   (no override)
  -- ['$M_editor']    inherits the env-or-nano expression
}
```

**Benefit**: Minimal user config, maximum inheritance.

### Pattern 2: Path Composition

```lua
-- bootstrap/const.lua
return { ['Hypr = "~/.config/hypr" }

-- sys/const.lua  (composed at deep_merge time)
return {
  ['sys = "~/.config/hypr/sys",                 -- or computed from $Hypr
  ['S   = "~/.config/hypr/sys/scripts",         -- derived from $sys
}

-- Usage anywhere
hl.exec_cmd("~/.config/hypr/sys/scripts/Animations.sh")
-- (in proper Phase B form: hl.exec_cmd(C['$S'] .. "/Animations.sh"))
```

**Benefit**: Change base path once (in bootstrap/const.lua), all derived paths update.

### Pattern 3: Semantic Tags

```lua
-- sys/const.lua
return {
  ['H_Cheat    = "Help_Cheat",
  ['H_Settings = "Help_Settings",
}

-- sys/tags.lua
hl.window_rule({
  match = { title = "^(Quick Cheat Sheet)$" },
  tag   = "Help_Cheat",   -- using the const value directly
})

-- sys/rules.lua
hl.window_rule({ float = true, match = { tag = "Help_Cheat" } })
```

**Benefit**: Tag names abstracted via const table, easy to rename globally.

### Pattern 4: Resource Paths

```lua
-- sys/const.lua
return {
  ['W        = os.getenv("HOME") .. "/Pictures/wallpapers",
}

-- user/const.lua (override)
return {
  ['W = os.getenv("HOME") .. "/Pictures/my-custom-wallpapers",
}
-- $W inherits the new value; everything else inherits sys defaults
```

**Benefit**: Separate resource locations from logic.

---

## Debugging Constant Issues

### Problem 1: Variable Not Defined

**Symptom**:

```
[ERROR] attempt to concatenate a nil value (field 'C['$M_termnal']')
```

**Diagnosis**:

```bash
# Check all layers for typo (note: typo is "M_termnal" not "M_terminal")
rg 'M_termnal' bootstrap/ sys/ user/

# List all $M_* variables in the merged const table
rg "M_\w+" bootstrap/const.lua sys/const.lua user/const.lua
```

**Fix**: Correct typo in appropriate layer.

### Problem 2: Wrong Value Applied

**Symptom**: Terminal is still `kitty` despite setting `ghostty` in user/const.lua.

**Diagnosis**:

```bash
# Check require order in bootstrap/default.lua
cat bootstrap/default.lua

# Expected (in proper Phase B form):
--   local C = {}
--   deep_merge(C, require("bootstrap.const"))
--   deep_merge(C, require("sys.const"))
--   deep_merge(C, require("user.const"))   -- ← MUST be LAST

# Check for syntax errors in user/const.lua
luacheck ~/.config/hypr --codes
```

**Common Causes**:

1. `user/const.lua` required before `sys.const` (wrong order in `bootstrap/default.lua`)
2. Syntax error in `user/const.lua` (the `return { ... }` table fails to parse — file returns `nil`)
3. Typo in key name (`['$M_terrminal']` vs `['$M_terminal']`)

**Fix**:

```lua
-- bootstrap/default.lua — CORRECT ORDER
local C = {}
deep_merge(C, require("bootstrap.const"))  -- Layer 1
deep_merge(C, require("sys.const"))        -- Layer 2
deep_merge(C, require("user.const"))       -- Layer 3 (LAST = WINS)
```

### Problem 3: Circular Dependency

**Symptom**: Hyprland fails to start or `loop or previous error loading module 'sys.X'` from Lua.

**Diagnosis**:

```bash
# Check for circular requires across the const layer
rg 'require\("(sys|user|bootstrap)\.' bootstrap/const.lua sys/const.lua user/const.lua
```

**Example of BAD**:

```lua
-- bootstrap/const.lua (BAD — would-be circular if const files required each other)
return {
  ['sys  = "~/.config/hypr/sys",
  ['user = "~/.config/hypr/user",
}

-- sys/const.lua (BAD — tries to depend on user)
local user = require("user.const")  -- ← circular! user.const will require this file
return { ['U = user['$user'] }
```

**Fix**: Const files must be **leaf modules** — they `return` a table and `require` nothing (except `os` from stdlib). Compose paths in `bootstrap/default.lua` after the merge.

---

## Best Practices

### For Users

1. **Override Only What You Need**

   ```lua
   -- GOOD: Minimal overrides
   return {
     ['M_terminal = "ghostty",
   }

   -- BAD: Copying entire sys/const.lua
   return {
     ['M             = "SUPER",            -- unnecessary duplication
     ['M_terminal    = "ghostty",
     ['M_file_manager = "thunar",
     -- ... (20 more entries copied verbatim)
   }
   ```

2. **Use Descriptive Names for Custom Constants**

   ```lua
   -- GOOD: Clear purpose
   return {
     ['U_custom_scripts = os.getenv("HOME") .. "/.local/share/hypr-scripts",
   }

   -- BAD: Unclear abbreviation
   return { ['X = os.getenv("HOME") .. "/.local/share/hypr-scripts" }
   ```

3. **Comment Your Overrides**

   ```lua
   return {
     -- Switch to Bing for privacy reasons
     ['Search_Engine = "https://www.bing.com/search?q={}",
   }
   ```

### For Developers

1. **Document All Constants**

   ```lua
   -- sys/const.lua
   return {
     ['M_terminal     = "kitty",               -- Default terminal emulator
     ['M_file_manager = "nemo",                -- Default file manager (GNOME Files alternative)
     ['M_editor       = os.getenv("EDITOR") or "nano",  -- Respect EDITOR env var
   }
   ```

2. **Provide Override Examples**

   ```lua
   -- sys/const.lua
   return {
     -- Override in user/const.lua: return { ['W = "~/custom/path" }
     ['W = os.getenv("HOME") .. "/Pictures/wallpapers",
   }
   ```

3. **Group Related Constants**

   ```lua
   -- sys/const.lua
   return {
     -- ── Application Defaults ──────────────────────────────
     ['M_terminal  = "kitty",
     ['M_browser   = "firefox",

     -- ── Path Shortcuts ────────────────────────────────────
     ['S = "~/.config/hypr/sys/scripts",
     ['H = "~/.config/hypr/sys/hardware",
   }
   ```

4. **Avoid Hard-Coded Paths in Scripts**

   ```lua
   -- BAD: Hard-coded path
   local WALLPAPER_DIR = os.getenv("HOME") .. "/Pictures/wallpapers"

   -- GOOD: Read from merged const table
   local C = require("bootstrap._const")
   local WALLPAPER_DIR = C['$W']
   ```

### For Architecture Maintenance

1. **Keep Layer Boundaries Clear**
   - Layer 1: Only infrastructure paths
   - Layer 2: System defaults + semantic meaning
   - Layer 3: User preferences only

2. **Validate Constant Completeness**

   ```bash
   # Extract all $var lookups in sys/+user/ (excluding const files)
   rg -o "C\['\\\$[A-Za-z_][A-Za-z0-9_]*'\]" sys/ user/ \
     | sort -u > /tmp/used_vars

   # Extract all keys defined in const files
   rg -o "\['\\\$[A-Za-z_][A-Za-z0-9_]*'\]" \
       bootstrap/const.lua sys/const.lua user/const.lua \
     | sort -u > /tmp/defined_vars

   # Show undefined vars (lookups with no definition)
   comm -23 /tmp/used_vars /tmp/defined_vars
   ```

3. **Document Dependency Chains**

   ```lua
   -- sys/const.lua
   return {
     -- Depends: $sys (from bootstrap/const.lua, merged before this file)
     ['S  = "~/.config/hypr/sys/scripts",
     -- Depends: $P (defined above in this same table)
     ['P_w = "~/.config/hypr/sys/policy/wallust",
   }
   ```

---

## Performance Characteristics

### Load Time Breakdown

| Layer               | Constants | Time     | Percentage |
| ------------------- | --------- | -------- | ---------- |
| Layer 1 (bootstrap) | 5         | ~0.5ms   | 25%        |
| Layer 2 (sys)       | 20        | ~1ms     | 50%        |
| Layer 3 (user)      | 5-10      | ~0.5ms   | 25%        |
| **Total**           | **~30**   | **~2ms** | **100%**   |

**Conclusion**: Negligible impact (<2ms) — one `deep_merge` call, no per-file re-parsing.

### Memory Impact

- Each constant: ~50 bytes (key string + value + table overhead)
- Total constants: ~30
- **Total memory**: ~1.5KB (negligible)

### Runtime Overhead

**Zero**. Constants are resolved once at bootstrap via `deep_merge`, cached in the merged `C` table, and looked up by direct key access (O(1) Lua table lookup). No runtime re-walk of const files.

---

## Advanced Techniques

### Technique 1: Environment Variable Integration

```lua
-- sys/const.lua
return {
  ['M_editor = os.getenv("EDITOR") or "nano",  -- use EDITOR env var, else nano
}

-- user/env.lua (separate module, applied later in Stage 3)
hl.env("EDITOR", "nvim")
```

**Note**: `os.getenv("EDITOR")` runs at the moment `sys/const.lua` is `require`d. If `user/env.lua` sets `EDITOR` via `hl.env` *after* the const merge, that change does **not** retroactively update `C['$M_editor']`. For values that must reflect env changes, read `os.getenv` lazily at use site.

### Technique 2: Profile-Specific Constants

```lua
-- user/const.gaming.lua
return {
  ['M_terminal = "alacritty",  -- faster startup
  ['W          = "",           -- no wallpaper (performance)
}

-- user/const.productivity.lua
return {
  ['M_terminal = "kitty",
  ['W          = os.getenv("HOME") .. "/Pictures/wallpapers",
}
```

```bash
# Switch profiles manually:
ln -sf ~/.config/hypr/user/const.gaming.lua ~/.config/hypr/user/const.lua
hyprctl reload
```

**Use Case**: Different constant sets for different workflows.

### Technique 3: Conditional Constants (Lazy Lookup)

```lua
-- scripts/detect-terminal.lua (returns string on stdout)
-- #!/usr/bin/env lua
-- if io.popen  -- WARNING: wiki says avoid in bind handlers("command -v ghostty", "r"):read("*a"):find("ghostty") then
--   print("ghostty")
-- elseif io.popen  -- WARNING: wiki says avoid in bind handlers("command -v kitty", "r"):read("*a"):find("kitty") then
--   print("kitty")
-- else
--   print("alacritty")
-- end

-- user/const.lua (Lua-native conditional)
local function detect_terminal()
  local f = io.popen  -- WARNING: wiki says avoid in bind handlers("~/.config/hypr/sys/scripts/detect-terminal.lua")
  local out = f:read("*l") or "kitty"
  f:close()
  return out
end

return {
  ['M_terminal = detect_terminal(),  -- evaluated at require-time
}
```

**Improvement over `.conf`**: Lua can run real code at `require` time (functions, `io.popen  -- WARNING: wiki says avoid in bind handlers`, `os.getenv`) — the `.conf` era could not natively evaluate expressions.

---

## Summary Comparison Table

| Aspect               | Layer 1 (bootstrap)         | Layer 2 (sys)              | Layer 3 (user)            |
| -------------------- | --------------------------- | -------------------------- | ------------------------- |
| **File**             | `bootstrap/const.lua`       | `sys/const.lua`           | `user/const.lua`         |
| **Form**             | `return { ['Hypr = ... }`| `return { ['M = ... }` | `return { ['M_terminal = "ghostty" }` |
| **Purpose**          | Infrastructure paths        | System defaults           | User overrides            |
| **Dependencies**     | None                        | Layer 1                   | Layers 1 & 2              |
| **Overrideable**     | No                          | Yes                       | N/A (final layer)         |
| **Constants Count**  | ~5                          | ~20                       | ~5-10                     |
| **Edit Frequency**   | Rarely                      | Never                     | Often                     |
| **Analogy**          | Compiler include paths      | Standard library          | User headers              |
| **Examples**         | `C['$sys']`                 | `C['$M_terminal']`="kitty"| `C['$M_terminal']`="ghostty" |
| **Design Principle** | Single Source of Truth     | Default Values            | Incremental Override      |

---

## Key Principles

1. ✅ **Unidirectional Dependencies**: Layer 1 → Layer 2 → Layer 3 (never backward)
2. ✅ **Last-Write-Wins**: Later `deep_merge` keys override earlier ones
3. ✅ **Stage 0 Loading**: All three const files merged before any other module loads
4. ✅ **Minimal User Config**: Only specify differences from defaults
5. ✅ **No Circular Dependencies**: Strict DAG (const files are leaf modules — they `require` nothing)
6. ✅ **Dependency Inversion**: High-level configs depend on the abstract const table (`C`), not on concrete paths/values
7. ✅ **Explicit over Implicit**: `deep_merge` at bootstrap replaces the `.conf` era's hidden use-time substitution

---

## Historical .conf form

> The following examples show the **legacy `.conf` syntax** preserved here for historical context only. The current repo no longer contains `.conf` files — see git history for the migration.

### Example 1: Const file in `.conf` form

In the legacy `.conf` era, each const file was a list of top-level `$var = value` assignments resolved by Hyprland's lexer:

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
$W              = $HOME/Pictures/wallpapers
```

**Equivalence**: In `.lua`, each file becomes `return { ['var = value, ... }` (a plain Lua table). The `$var` syntax survives only as **table keys** (quoted strings) — never as bare assignments in `user/X.lua` or `sys/X.lua`.

### Example 2: Use-time substitution vs deep_merge

In `.conf`, substitution happened on every parse:

```conf
# sys/misc.conf  (LEGACY — not in current repo)
misc {
    swallow_regex = ^($M_terminal)$    # Hyprland's lexer substitutes $M_terminal at parse time
}
```

```conf
# sys/keybind.conf  (LEGACY — not in current repo)
hl.bind(const.M .. " + Return", hl.dsp.exec_cmd("$M_terminal   # $M and $M_terminal substituted by lexer"))  -- open terminal
```

**Equivalence**: In `.lua`, the same logic reads from the merged `C` table at `require` time (one merge, many lookups):

```lua
-- sys/misc.lua
hl.config({ misc = { swallow_regex = "^(" .. C['$M_terminal'] .. ")$" } })

-- sys/keybind.lua
hl.bind(C['$M'] .. " + Return", hl.dsp.exec_cmd(C['$M_terminal']))
```

The .lua form is **explicit** (you can `print(C['$M_terminal'])` to debug), **once-only** (no per-file re-walk), and **type-safe** (a missing key returns `nil`, which is immediately visible at the use site).

---

## References

- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [Compiler Design - Symbol Tables](https://en.wikipedia.org/wiki/Symbol_table)
- [UNIX Configuration Conventions](https://en.wikipedia.org/wiki/Configuration_file)
- [Hyprland Configuration Documentation](https://wiki.hyprland.org/Configuring/)
- [../../07-Lua-Reference/README.md](../../07-Lua-Reference/README.md) — .lua architecture overview
- [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md) — .lua syntax reference
- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) § Stage 0
- [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md) § Dependency Inversion
- [INDEX.md](INDEX.md) § Navigation Guide

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
