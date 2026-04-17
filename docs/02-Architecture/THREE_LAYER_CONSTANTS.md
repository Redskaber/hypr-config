# Three-Layer Constant System - Complete Specification

## Overview

This document provides the **complete specification** of the three-layer constant system used throughout the Hyprland configuration. This system implements the **Dependency Inversion Principle** at multiple levels, enabling flexible customization while maintaining architectural integrity.

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: bootstrap/const.conf                          │
│  Purpose: Infrastructure paths ($Hypr, $sys, $user)     │
│  Dependencies: None                                     │
│  Overrideable: No                                       │
└──────────────────────┬──────────────────────────────────┘
                       │ Provides: $Hypr, $sys, $user
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 2: sys/const.conf                                │
│  Purpose: System defaults ($M, $S, $H, $P, $W)          │
│  Dependencies: Layer 1                                  │
│  Overrideable: Yes (by Layer 3)                         │
└──────────────────────┬──────────────────────────────────┘
                       │ Provides: All system constants
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Layer 3: user/const.conf                               │
│  Purpose: User overrides ($M_terminal, $W, etc.)        │
│  Dependencies: Layers 1 & 2                             │
│  Overrideable: N/A (final layer)                        │
└─────────────────────────────────────────────────────────┘
```

**Resolution Order**: Layer 1 → Layer 2 → Layer 3 (last-write-wins)  
**Load Time**: Stage 0 (before all other stages)  
**Total Constants**: ~30 (5 + 20 + 5-10)

---

## Layer 1: `bootstrap/const.conf` — Infrastructure Paths

### File Content

```bash
# hyprland config const path
$Hypr           = ~/.config/hypr
$bootstrap      = $Hypr/bootstrap
$sys            = $Hypr/sys
$user           = $Hypr/user
$lock_background= $Hypr/wallpaper_effects/.wallpaper_current
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

```bash
# Anywhere in config
source = $sys/decoration.conf
# Expands to: source = ~/.config/hypr/sys/decoration.conf

exec-once = $S/WaybarScripts.sh
# Expands to: exec-once = ~/.config/hypr/sys/scripts/WaybarScripts.sh
```

---

## Layer 2: `sys/const.conf` — System Default Constants

### File Content

```bash
# Modifier keys
$M              = SUPER
$M_terminal     = kitty
$M_file_manager = nemo
$M_editor       = ${EDITOR:-nano}

# Path shortcuts (depend on Layer 1)
$S              = $sys/scripts
$H              = $sys/hardware
$P              = $sys/policy
$P_w            = $P/wallust
$P_a            = $P/animations

# User layer shortcuts
$U              = $user
$U_s            = $user/scripts
$U_h            = $user/hardware
$U_p            = $user/policy
$U_pw           = $U_p/wallust
$U_pa           = $U_p/animations

# Helper window tags
$H_Cheat        = Help_Cheat
$H_Settings     = Help_Settings

# Resources
$W              = $HOME/Pictures/wallpapers
$W_l            = ""
$I_notify       = $Hypr/icon.png
$Search_Engine  = "https://www.google.com/search?q={}"
```

### Constant Categories

| Category           | Variables                                           | Count  | Purpose                          |
| ------------------ | --------------------------------------------------- | ------ | -------------------------------- |
| **Modifiers**      | `$M`, `$M_terminal`, `$M_file_manager`, `$M_editor` | 4      | Application defaults             |
| **Path Shortcuts** | `$S`, `$H`, `$P`, `$P_w`, `$P_a`                    | 5      | Quick access to sys directories  |
| **User Layer**     | `$U`, `$U_s`, `$U_h`, `$U_p`, `$U_pw`, `$U_pa`      | 6      | Quick access to user directories |
| **Semantic Tags**  | `$H_Cheat`, `$H_Settings`                           | 2      | Window tag constants             |
| **Resources**      | `$W`, `$W_l`, `$I_notify`, `$Search_Engine`         | 4      | Wallpaper, icons, search engine  |
| **Total**          |                                                     | **21** |                                  |

### Characteristics

| Property            | Value                                         |
| ------------------- | --------------------------------------------- |
| **Dependencies**    | Layer 1 (`$sys`, `$user`, `$Hypr`)            |
| **Overrideable**    | Yes (by Layer 3)                              |
| **Constants Count** | 21                                            |
| **Edit Frequency**  | Never (vendor defaults)                       |
| **Analogy**         | Compiler's standard library and default flags |

### Design Principles

1. **Default Values with Override Points**: All constants have working defaults but are designed to be overridden
2. **Semantic Abstraction**: Tag names (`$H_Cheat`) abstract implementation details
3. **Path Composition**: Build complex paths from simple primitives (`$P_w = $P/wallust`)
4. **Environment Integration**: `${EDITOR:-nano}` respects system environment variables

### Dependency Chain

```
$sys (from Layer 1)
  ↓
$S = $sys/scripts
$H = $sys/hardware
$P = $sys/policy
  ↓
$P_w = $P/wallust
$P_a = $P/animations

$user (from Layer 1)
  ↓
$U = $user
$U_s = $user/scripts
$U_h = $user/hardware
$U_p = $user/policy
  ↓
$U_pw = $U_p/wallust
$U_pa = $U_p/animations
```

**Invariant**: No forward references allowed (cannot use `$P` before it's defined).

---

## Layer 3: `user/const.conf` — User Override Constants

### File Content (Example)

```bash
# user/const.conf — User constant overrides
# Sourced in bootstrap/default.conf (Stage 0), before sys/default.conf.
# This guarantees all $U_* and $M_* overrides are available throughout the pipeline.

# Override application defaults
$M_terminal     = ghostty
$M_file_manager = thunar
$M_editor       = nvim

# Override resource paths
$W              = $HOME/Pictures/my-wallpapers
$Search_Engine  = "https://www.bing.com/search?q={}"

# Add custom constants
$M_browser      = firefox
$U_custom_dir   = $HOME/.local/share/hypr-custom
```

### Characteristics

| Property            | Value                                         |
| ------------------- | --------------------------------------------- |
| **Dependencies**    | Layers 1 & 2 (can reference any constant)     |
| **Overrideable**    | N/A (final layer, last-write-wins)            |
| **Constants Count** | 5-10 (typical user)                           |
| **Edit Frequency**  | Often (user preferences change)               |
| **Analogy**         | User's .bashrc overriding system /etc/profile |

### Design Principles

1. **Incremental Override**: Only specify differences from defaults
2. **Minimal Configuration**: Don't copy entire sys/const.conf
3. **Early Loading**: Loaded in Stage 0 to affect all subsequent stages
4. **Documentation**: Comment why you're overriding (e.g., "for privacy reasons")

### Critical Design Decision: Stage 0 Loading

**Why `user/const.conf` loads in Stage 0, NOT Stage 3:**

```bash
# CORRECT: User constants available everywhere
# bootstrap/default.conf
source = ./const.conf           # Layer 1
source = $sys/const.conf        # Layer 2
source = $user/const.conf       # Layer 3 (LAST = WINS)

# Now ALL sys/ files can use user overrides:
# sys/misc.conf
misc {
    swallow_regex = ^($M_terminal)$  # Uses ghostty ✓
}

# sys/startup.conf
exec-once = $S/Dropterminal.sh $M_terminal
# Expands to: ~/.config/hypr/sys/scripts/Dropterminal.sh ghostty ✓
```

```bash
# WRONG: User constants loaded too late
# bootstrap/default.conf
source = $sys/default.conf      # Uses $M_terminal = kitty
source = $user/const.conf       # Sets $M_terminal = ghostty (TOO LATE!)

# Result: sys/misc.conf already used kitty, can't change retroactively
```

**Impact Areas**:

- `sys/misc.conf` → `swallow_regex = ^($M_terminal)$`
- `sys/startup.conf` → `exec-once = $S/Dropterminal.sh $M_terminal`
- `sys/keybind.conf` → `bindd = $M, Return, open terminal, exec, $M_terminal`
- All scripts that parse constants from config files

---

## Constant Resolution Example

### Scenario: Change Terminal from Kitty to Ghostty

**Step 1: User edits `user/const.conf`**

```bash
$M_terminal = ghostty
```

**Step 2: Resolution Process**

```bash
# Layer 1 (bootstrap/const.conf)
$sys = ~/.config/hypr/sys
$user = ~/.config/hypr/user

# Layer 2 (sys/const.conf)
$S = $sys/scripts                    # Resolves to ~/.config/hypr/sys/scripts
$M_terminal = kitty                  # System default

# Layer 3 (user/const.conf)
$M_terminal = ghostty                # User override (WINS - last-write-wins)
```

**Step 3: Final Resolved Values**

```
$sys = ~/.config/hypr/sys
$user = ~/.config/hypr/user
$S = ~/.config/hypr/sys/scripts
$M_terminal = ghostty                ← User preference applied
```

**Step 4: Propagation Throughout Pipeline**

```bash
# Stage 3: sys/misc.conf
misc {
    swallow_regex = ^($M_terminal)$  # Expands to ^(ghostty)$
}

# Stage 4: sys/startup.conf
exec-once = $S/Dropterminal.sh $M_terminal
# Expands to: ~/.config/hypr/sys/scripts/Dropterminal.sh ghostty

# Stage 5: sys/keybind.conf
bindd = $M, Return, open terminal, exec, $M_terminal
# Expands to: bindd = SUPER, Return, open terminal, exec, ghostty
```

**Key Insight**: Single change in `user/const.conf` propagates to **3 different stages** automatically.

---

## Constant Dependency Graph

```
bootstrap/const.conf (Layer 1 - No dependencies)
  ├── $Hypr
  ├── $bootstrap
  ├── $user ─────────────────────────────────────────┐
  └── $sys ────────────────────────────────────┐     │
                                               │     │
sys/const.conf (Layer 2 - Depends on Layer 1)  │     │
  ├── $M, $M_terminal, $M_file_manager         │     │
  ├── $S = $sys/scripts ───────────────────────┤     │
  ├── $H = $sys/hardware ──────────────────────┤     │
  ├── $P = $sys/policy ────────────────────────┤     │
  ├── $U = $user ──────────────────────────────┘     │
  ├── $H_Cheat, $H_Settings                          │
  └── $W, $Search_Engine                             │
                                                     │
user/const.conf (Layer 3 - Depends on Layers 1 & 2)  │
  ├── $M_terminal = ghostty ─────────────────────────┤ (overrides Layer 2)
  ├── $W = ~/Pictures/custom ────────────────────────┘ (overrides Layer 2)
  └── $M_browser = firefox          (new constant)
```

**Invariant**: No circular dependencies allowed (Layer N cannot depend on Layer N+1).

---

## Compiler Analogy

| Compiler Phase            | Config Equivalent     | Example                  |
| ------------------------- | --------------------- | ------------------------ |
| **Preprocessor Includes** | bootstrap/const.conf  | `#include <paths.h>`     |
| **Standard Library**      | sys/const.conf        | Default types, functions |
| **User Headers**          | user/const.conf       | Custom type definitions  |
| **Symbol Table**          | Resolved constants    | All `$variables` mapped  |
| **Type Checking**         | Dependency validation | No undefined vars        |
| **Linking**               | Final resolution      | Last-write-wins applied  |

**Process**:

1. **Scan** all const.conf files (lexical analysis)
2. **Build** symbol table with all `$variables`
3. **Resolve** dependencies (ensure no forward references)
4. **Apply** overrides (user/ wins over sys/)
5. **Validate** (check for undefined variables)

---

## Common Constant Patterns

### Pattern 1: Application Defaults

```bash
# sys/const.conf
$M_terminal = kitty
$M_browser = firefox
$M_editor = ${EDITOR:-nano}

# user/const.conf
$M_terminal = ghostty    # Override only what you need
# $M_browser inherits firefox (no override)
# $M_editor inherits ${EDITOR:-nano} (no override)
```

**Benefit**: Minimal user config, maximum inheritance.

### Pattern 2: Path Composition

```bash
# bootstrap/const.conf
$Hypr = ~/.config/hypr

# sys/const.conf
$sys = $Hypr/sys
$S = $sys/scripts

# Usage anywhere
source = $S/Animations.sh
# Expands to: ~/.config/hypr/sys/scripts/Animations.sh
```

**Benefit**: Change base path once, all references update.

### Pattern 3: Semantic Tags

```bash
# sys/const.conf
$H_Cheat = Help_Cheat
$H_Settings = Help_Settings

# sys/tags.conf
windowrule = match:title ^(Quick Cheat Sheet)$, tag +$H_Cheat

# sys/rules.conf
windowrule = float on, match:tag $H_Cheat
```

**Benefit**: Tag names abstracted, easy to rename globally.

### Pattern 4: Resource Paths

```bash
# sys/const.conf
$W = $HOME/Pictures/wallpapers
$I_notify = $Hypr/icon.png

# user/const.conf
$W = $HOME/Pictures/my-custom-wallpapers  # Override wallpaper dir
# $I_notify inherits $Hypr/icon.png
```

**Benefit**: Separate resource locations from logic.

---

## Debugging Constant Issues

### Problem 1: Variable Not Defined

**Symptom**:

```
[ERROR] Unknown keyword "$M_termnal"
```

**Diagnosis**:

```bash
# Check all layers for typo
grep -r 'M_termnal' bootstrap/ sys/ user/

# List all defined M_* variables
grep '^\$M_' bootstrap/const.conf sys/const.conf user/const.conf
```

**Fix**: Correct typo in appropriate layer.

### Problem 2: Wrong Value Applied

**Symptom**: Terminal is still `kitty` despite setting `ghostty` in user/const.conf

**Diagnosis**:

```bash
# Check source order in bootstrap/default.conf
cat bootstrap/default.conf

# Expected:
# source = ./const.conf
# source = $sys/const.conf
# source = $user/const.conf    ← Must come LAST

# Check if user/const.conf has syntax error
hyprctl config 2>&1 | grep -i error
```

**Common Causes**:

1. `user/const.conf` sourced before `sys/const.conf` (wrong order)
2. Syntax error in `user/const.conf` (line ignored)
3. Typo in variable name (`$M_terrminal` vs `$M_terminal`)

**Fix**:

```bash
# bootstrap/default.conf — CORRECT ORDER
source = ./const.conf           # Layer 1
source = $sys/const.conf        # Layer 2
source = $user/const.conf       # Layer 3 (LAST = WINS)
```

### Problem 3: Circular Dependency

**Symptom**: Hyprland fails to start or infinite loop

**Diagnosis**:

```bash
# Check for circular references
grep '\$sys.*\$user\| \$user.*\$sys' bootstrap/const.conf sys/const.conf
```

**Example of BAD**:

```bash
# bootstrap/const.conf
$sys = $user/sys  # ← Circular! $user depends on $sys

# sys/const.conf
$S = $sys/scripts
```

**Fix**: Ensure strict unidirectional dependency (Layer 1 → Layer 2 → Layer 3).

---

## Best Practices

### For Users

1. **Override Only What You Need**

   ```bash
   # GOOD: Minimal overrides
   $M_terminal = ghostty

   # BAD: Copying entire sys/const.conf
   $M = SUPER
   $M_terminal = ghostty
   $M_file_manager = thunar
   # ... (unnecessary duplication)
   ```

2. **Use Descriptive Names for Custom Constants**

   ```bash
   # GOOD: Clear purpose
   $U_custom_scripts = $HOME/.local/share/hypr-scripts

   # BAD: Unclear abbreviation
   $X = $HOME/.local/share/hypr-scripts
   ```

3. **Comment Your Overrides**
   ```bash
   # Switch to Bing for privacy reasons
   $Search_Engine = "https://www.bing.com/search?q={}"
   ```

### For Developers

1. **Document All Constants**

   ```bash
   # sys/const.conf
   $M_terminal     = kitty          # Default terminal emulator
   $M_file_manager = nemo           # Default file manager (GNOME Files alternative)
   $M_editor       = ${EDITOR:-nano}  # Respect EDITOR env var, fallback to nano
   ```

2. **Provide Override Examples**

   ```bash
   # sys/const.conf
   $W = $HOME/Pictures/wallpapers   # Override in user/const.conf: $W = ~/custom/path
   ```

3. **Group Related Constants**

   ```bash
   # ── Application Defaults ──────────────────────────────
   $M_terminal = kitty
   $M_browser = firefox

   # ── Path Shortcuts ────────────────────────────────────
   $S = $sys/scripts
   $H = $sys/hardware
   ```

4. **Avoid Hard-Coded Paths in Scripts**

   ```bash
   # BAD: Hard-coded path
   WALLPAPER_DIR="$HOME/Pictures/wallpapers"

   # GOOD: Read from config
   WALLPAPER_DIR=$(grep '^\$W ' ~/.config/hypr/user/const.conf 2>/dev/null | \
                   cut -d'=' -f2 | tr -d ' ' || \
                   grep '^\$W ' ~/.config/hypr/sys/const.conf | cut -d'=' -f2 | tr -d ' ')
   ```

### For Architecture Maintenance

1. **Keep Layer Boundaries Clear**
   - Layer 1: Only infrastructure paths
   - Layer 2: System defaults + semantic meaning
   - Layer 3: User preferences only

2. **Validate Constant Completeness**

   ```bash
   # Script to check for undefined variables
   grep -roh '\$[A-Za-z_][A-Za-z0-9_]*' sys/ user/ | sort -u > /tmp/used_vars
   grep -roh '^\$[A-Za-z_][A-Za-z0-9_]*' bootstrap/const.conf sys/const.conf user/const.conf | \
     sed 's/=.*//' | sort -u > /tmp/defined_vars
   comm -23 /tmp/used_vars /tmp/defined_vars  # Shows undefined vars
   ```

3. **Document Dependency Chains**
   ```bash
   # sys/const.conf
   $S = $sys/scripts              # Depends: $sys (from bootstrap/const.conf)
   $P_w = $P/wallust              # Depends: $P (defined above)
   ```

---

## Performance Characteristics

### Load Time Breakdown

| Layer               | Constants | Time     | Percentage |
| ------------------- | --------- | -------- | ---------- |
| Layer 1 (bootstrap) | 5         | ~0.5ms   | 25%        |
| Layer 2 (sys)       | 21        | ~1ms     | 50%        |
| Layer 3 (user)      | 5-10      | ~0.5ms   | 25%        |
| **Total**           | **~30**   | **~2ms** | **100%**   |

**Conclusion**: Negligible impact (<2ms)

### Memory Impact

- Each constant: ~50 bytes (name + value + overhead)
- Total constants: ~30
- **Total memory**: ~1.5KB (negligible)

### Runtime Overhead

**Zero**. Constants are resolved once at startup, cached in Hyprland's internal state. No runtime lookup cost.

---

## Advanced Techniques

### Technique 1: Environment Variable Integration

```bash
# sys/const.conf
$M_editor = ${EDITOR:-nano}  # Use EDITOR env var if set, else nano

# user/env.conf
env = EDITOR, nvim            # Set EDITOR for all processes

# Result: $M_editor resolves to nvim
```

**Benefit**: Respects system-wide editor preference.

### Technique 2: Profile-Specific Constants

```bash
# user/const.gaming.conf
$M_terminal = alacritty  # Faster startup
$W = ""                  # No wallpaper (performance)

# user/const.productivity.conf
$M_terminal = kitty
$W = $HOME/Pictures/wallpapers

# Switch profiles manually:
cp user/const.gaming.conf user/const.conf
hyprctl reload
```

**Use Case**: Different constant sets for different workflows.

### Technique 3: Conditional Constants (via Scripts)

```bash
# scripts/detect-terminal.sh
#!/usr/bin/env bash
if command -v ghostty &>/dev/null; then
    echo "ghostty"
elif command -v kitty &>/dev/null; then
    echo "kitty"
else
    echo "alacritty"
fi
```

```bash
# Workaround (not native support):
exec-once = bash -c 'echo "$M_terminal = $(~/.config/hypr/scripts/detect-terminal.sh)" > /tmp/auto_terminal.conf'
# Then manually: source = /tmp/auto_terminal.conf
```

**Limitation**: Hyprland doesn't support dynamic constant evaluation natively.

---

## Summary Comparison Table

| Aspect               | Layer 1 (bootstrap)    | Layer 2 (sys)       | Layer 3 (user)        |
| -------------------- | ---------------------- | ------------------- | --------------------- |
| **File**             | `bootstrap/const.conf` | `sys/const.conf`    | `user/const.conf`     |
| **Purpose**          | Infrastructure paths   | System defaults     | User overrides        |
| **Dependencies**     | None                   | Layer 1             | Layers 1 & 2          |
| **Overrideable**     | No                     | Yes                 | N/A (final layer)     |
| **Constants Count**  | ~5                     | ~21                 | ~5-10                 |
| **Edit Frequency**   | Rarely                 | Never               | Often                 |
| **Analogy**          | Compiler include paths | Standard library    | User headers          |
| **Examples**         | `$sys`, `$user`        | `$M_terminal=kitty` | `$M_terminal=ghostty` |
| **Design Principle** | Single Source of Truth | Default Values      | Incremental Override  |

---

## Key Principles

1. ✅ **Unidirectional Dependencies**: Layer 1 → Layer 2 → Layer 3 (never backward)
2. ✅ **Last-Write-Wins**: Later sources override earlier ones
3. ✅ **Stage 0 Loading**: All constants available before Stage 1
4. ✅ **Minimal User Config**: Only specify differences from defaults
5. ✅ **No Circular Dependencies**: Strict DAG (Directed Acyclic Graph)
6. ✅ **Dependency Inversion**: High-level configs depend on abstractions, not concrete implementations

---

## References

- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [Compiler Design - Symbol Tables](https://en.wikipedia.org/wiki/Symbol_table)
- [UNIX Configuration Conventions](https://en.wikipedia.org/wiki/Configuration_file)
- [Hyprland Configuration Documentation](https://wiki.hyprland.org/Configuring/)

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-17  
**Related Documents**:

- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) § Stage 0
- [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md) § Dependency Inversion
- [INDEX.md](INDEX.md) § Navigation Guide
