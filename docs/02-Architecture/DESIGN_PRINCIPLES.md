# Hyprland Configuration Architecture - Design Principles & Implementation

## Executive Summary

This is a **production-grade, layered pipeline architecture** for Hyprland ≥ 0.52.1 that applies software engineering principles from compiler design, state machine theory, dependency injection, and policy-based management. The configuration treats the desktop environment as a **compiled system** rather than a collection of scripts.

---

## Table of Contents

1. [Core Design Principles](#core-design-principles)
2. [Compilation Pipeline Architecture](#compilation-pipeline-architecture)
3. [Layered Architecture & Boundary Management](#layered-architecture--boundary-management)
4. [Dependency Inversion & Incremental Override Pattern](#dependency-inversion--incremental-override-pattern)
5. [State Machine Implementation](#state-machine-implementation)
6. [Tag-Driven Window Management System](#tag-driven-window-management-system)
7. [Policy Layer & Runtime Swapping](#policy-layer--runtime-swapping)
8. [Process Lifecycle Management](#process-lifecycle-management)
9. [Single Responsibility Principle Applied](#single-responsibility-principle-applied)
10. [Software Design Patterns Catalog](#software-design-patterns-catalog)

---

## Core Design Principles

### 1. Single Entry Point (Facade Pattern)

```
hyprland.conf → bootstrap/default.conf → entire system
```

**Rationale**:

- Eliminates circular dependencies
- Provides clear initialization sequence
- Enables deterministic config loading order
- Simplifies debugging (single trace path)

**Implementation**:

```bash
# hyprland.conf — NO LOGIC, ONLY SOURCING
source = ./bootstrap/default.conf
```

### 2. Incremental Override Pattern (Decorator Pattern)

Every `sys/X.conf` is immediately followed by `user/X.conf`:

```bash
source = $sys/env.conf      # vendor defaults
source = $user/env.conf     # user overrides (later wins)
```

**Benefits**:

- User files contain only deltas (minimal diff)
- Vendor updates don't overwrite user customizations
- Clear separation of concerns
- Git-friendly (user/ can be .gitignored or tracked separately)

### 3. Dependency Direction Control

Constants flow **downward only** through the pipeline:

```
Stage 0: bootstrap/const.conf    (path constants)
         ↓
Stage 0: user/const.conf         (user constant overrides)
         ↓
Stage 1: sys/default.conf        (all system configs now have access to $M, $S, etc.)
```

**Critical Design Decision**: `user/const.conf` is sourced in **Stage 0** (bootstrap), NOT Stage 1. This ensures all `$U_*`, `$M_*` variables are available throughout the entire pipeline, including `sys/` files.

### 4. Policy-Based Configuration

Swappable runtime policies without full reload:

- **Colors**: wallust-generated (`sys/policy/wallust/`)
- **Animations**: preset profiles (`sys/policy/animations/`)

**Runtime Switching**:

```bash
hyprctl keyword source "$full_path_to_animation.conf"
```

### 5. Tag-Driven Rule System (Strategy Pattern)

Tags decouple **window classification** from **window behavior**:

```
tags.conf  →  defines WHAT an app IS (browser, terminal, im)
rules.conf →  defines HOW it behaves (float, center, opacity)
```

**Benefits**:

- Single source of truth for tags
- Easy to audit completeness (every tag has rules)
- Compound conditions isolated to edge cases
- User extensions via `user/tags.conf` + `user/rules.conf`

---

## Compilation Pipeline Architecture

The configuration loading process mirrors a **compiler pipeline**:

### Phase 1: Lexical Analysis (Token Definition)

**Files**: `bootstrap/const.conf`, `sys/const.conf`, `user/const.conf`

**Purpose**: Define all symbolic constants (tokens):

```bash
$M              = SUPER          # modifier token
$S              = $sys/scripts   # script path token
$H_Cheat        = Help_Cheat     # semantic tag token
```

**Compiler Analogy**: Lexer converts raw text into tokens.

### Phase 2: Syntax Analysis (Grammar Rules)

**Files**: `sys/default.conf` (pipeline orchestrator)

**Purpose**: Define valid source order (grammar):

```bash
# Grammar rule: hardware must come before policy
source = $H/default.conf
source = $P/default.conf

# Grammar rule: env before misc
source = $sys/env.conf
source = $user/env.conf
source = $sys/misc.conf
```

**Compiler Analogy**: Parser validates token sequence against grammar.

### Phase 3: Semantic Analysis (Type Checking)

**Files**: `sys/tags.conf`, `sys/rules.conf`

**Purpose**: Ensure semantic correctness:

- Every tag referenced in `rules.conf` is defined in `tags.conf`
- No orphaned tags (every tag has at least one rule)
- Behavior tags orthogonal to category tags

**Compiler Analogy**: Type checker ensures variables are declared before use.

### Phase 4: Code Generation (Configuration Application)

**Files**: All `*.conf` files applied via `source`

**Purpose**: Generate final Hyprland configuration state:

```
Input:  44 source directives
Output: Fully resolved Hyprland config in memory
```

**Compiler Analogy**: Backend generates target machine code.

### Phase 5: Runtime Optimization (JIT Compilation)

**Scripts**: `ChangeLayout.sh`, `GameMode.sh`, `Animations.sh`

**Purpose**: Dynamic reconfiguration without restart:

```bash
# JIT compile new layout state
hyprctl keyword general:layout dwindle
hyprctl keyword bind SUPER,J,cyclenext
```

**Compiler Analogy**: Just-In-Time compilation for runtime performance.

---

## Layered Architecture & Boundary Management

### Layer Hierarchy (Dependency Graph)

```
┌─────────────────────────────────────────┐
│  hyprland.conf (Entry Point / Facade)   │
└──────────────┬──────────────────────────┘
               │ source
               ▼
┌─────────────────────────────────────────┐
│  bootstrap/ (Constant Definitions)      │
│  ├── const.conf   (Path tokens)         │
│  └── default.conf (Pipeline entry)      │
└──────────────┬──────────────────────────┘
               │ Stage 0 complete
               ▼
┌─────────────────────────────────────────┐
│  sys/ (System Defaults - Read Only)     │
│  ├── hardware/    (Physical layer)      │
│  ├── policy/      (Swappable policies)  │
│  ├── env.conf     (Environment vars)    │
│  ├── misc.conf    (Misc options)        │
│  ├── input.conf   (Input devices)       │
│  ├── layout.conf  (Tiling engines)      │
│  ├── decoration.conf (Visual effects)   │
│  ├── render.conf  (Render pipeline)     │
│  ├── startup.conf (Service lifecycle)   │
│  ├── keybind.conf (Input bindings)      │
│  ├── tags.conf    (Window taxonomy)     │
│  └── rules.conf   (Behavior rules)      │
└──────────────┬──────────────────────────┘
               │ Each sys/X.conf paired with:
               ▼
┌─────────────────────────────────────────┐
│  user/ (User Overrides - Write Here)    │
│  ├── const.conf   (Override $M_*, $W)   │
│  ├── env.conf     (HiDPI, NVIDIA, etc)  │
│  ├── input.conf   (kb_layout, etc)      │
│  ├── layout.conf  (startup layout)      │
│  ├── decoration.conf (colors, blur)     │
│  ├── keybind.conf (custom binds)        │
│  ├── tags.conf    (app classifications) │
│  └── rules.conf   (behavior overrides)  │
└─────────────────────────────────────────┘
```

### Boundary Contracts

Each layer has explicit contracts:

| Layer                 | Provides                                  | Consumes                  | Must Not                                      |
| --------------------- | ----------------------------------------- | ------------------------- | --------------------------------------------- |
| `bootstrap/`          | Path constants, variable definitions      | Nothing                   | Contain logic beyond `source`                 |
| `sys/hardware/`       | Monitor/laptop device config              | `$H` constant             | Reference user paths                          |
| `sys/policy/`         | Color vars (`$colorN`), animation presets | `$P` constant             | Modify non-policy settings                    |
| `sys/decoration.conf` | Visual rendering config                   | `$colorN` from policy     | Define colors directly                        |
| `sys/tags.conf`       | Window tag registry                       | `$H_Cheat`, `$H_Settings` | Contain behavior rules                        |
| `sys/rules.conf`      | Tag-driven window rules                   | Tags from `tags.conf`     | Use `match:class` directly (except compounds) |
| `user/*`              | User-specific overrides                   | All sys constants         | Edit sys/ files                               |

### Violation Detection

The architecture enforces boundaries through:

1. **Source Order**: Later sources override earlier ones (enforced by Hyprland)
2. **Variable Scoping**: Constants defined before use (compile-time check)
3. **Tag Completeness**: Every tag in rules must exist in tags (manual audit)
4. **File Naming**: `sys/` vs `user/` prefix makes violations obvious

---

## Dependency Inversion & Incremental Override Pattern

### Three-Layer Constant System

**📚 Complete Specification**: See [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) for full documentation of the bootstrap/sys/user constant system with dependency graphs, resolution examples, and debugging guides.

The configuration implements a sophisticated **three-layer constant system** that applies Dependency Inversion at multiple levels:

```
Layer 1 (bootstrap/const.conf): Infrastructure paths ($Hypr, $sys, $user)
  ↓ Provides path foundation
Layer 2 (sys/const.conf): System defaults ($M, $S, $H, $P, $W)
  ↓ Provides application defaults
Layer 3 (user/const.conf): User overrides ($M_terminal, custom paths)
  ↓ Last-write-wins semantics
```

**Key Design Decisions**:

1. All three layers load in **Stage 0** (before any other config)
2. Unidirectional dependencies (Layer 1 → Layer 2 → Layer 3)
3. No circular dependencies allowed (strict DAG)
4. User overrides propagate to all subsequent stages automatically

---

### Traditional Approach (Tight Coupling)

```bash
# BAD: Hard-coded values scattered across files
# sys/env.conf
env = EDITOR, nvim

# sys/keybind.conf
bind = SUPER, Return, exec, kitty

# Problem: Changing editor requires editing multiple files
```

### Dependency Inversion (Abstraction Layer)

```bash
# GOOD: Abstract through constants
# bootstrap/const.conf
$M_editor = ${EDITOR:-nano}
$M_terminal = kitty

# sys/env.conf
env = EDITOR, $M_editor

# sys/keybind.conf
bind = SUPER, Return, exec, $M_terminal

# user/const.conf (single change point)
$M_editor = vim
$M_terminal = ghostty
```

**Benefits**:

- **Open/Closed Principle**: Extend behavior without modifying existing code
- **Single Responsibility**: Each constant has one definition location
- **Testability**: Swap implementations by changing one file

### Incremental Override Mechanism

The pattern mirrors **CSS specificity** and **Linux config.d directories**:

```bash
# sys/input.conf (vendor default)
input {
    kb_layout = us
    sensitivity = 0.0
}

# user/input.conf (user delta - ONLY differences)
input {
    kb_layout = us,cn  # override only this
}
```

**Resolution Algorithm**:

```
1. Load sys/input.conf → kb_layout = us
2. Load user/input.conf → kb_layout = us,cn (overwrites)
3. Final state: kb_layout = us,cn
```

**Key Insight**: Hyprland's `source` directive implements **last-write-wins** semantics, enabling clean delta-based customization.

---

## State Machine Implementation

The configuration implements **three explicit state machines** with well-defined transitions:

### State Machine 1: Layout Engine

**States**: `scrolling` ↔ `dwindle` ↔ `master`

**Transition Function** (`ChangeLayout.sh`):

```bash
case "$CURRENT_STATE" in
"scrolling") _enter_dwindle  ;;  # scrolling → dwindle
"dwindle")   _enter_master   ;;  # dwindle → master
"master")    _enter_scrolling ;;  # master → scrolling
esac
```

**State Properties**:
| State | SUPER+J/K | SUPER+O | Owner |
|-------|-----------|---------|-------|
| `scrolling` | unbound | unbound | hyprscrolling plugin |
| `dwindle` | cyclenext | togglesplit | Hyprland core |
| `master` | cyclenext | unbound | Hyprland core |

**Atomicity Guarantee**: Each transition atomically updates:

1. Layout engine (`general:layout`)
2. Keybinds (bind/unbind J/K/O)
3. User notification (visual feedback)

**Initialization** (`KeybindsLayoutInit.sh`):

```bash
# Idempotent: reads current state and applies correct binds
LAYOUT=$(hyprctl -j getoption general:layout | jq -r '.str')
_apply_layout_binds "$LAYOUT"
```

### State Machine 2: Game Mode

**States**: `normal` ↔ `gaming`

**State Variable**: `animations:enabled` (1 = normal, 0 = gaming)

**Transition Functions**:

```bash
_gamemode_on() {
    # Disable visual effects (performance optimization)
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
    # Force full opacity (reduce compositor load)
    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    swww kill  # Kill wallpaper daemon (free GPU resources)
}

_gamemode_off() {
    # Restore full visual stack
    swww-daemon --format argb &
    swww img "$HOME/.config/rofi/.current_wallpaper"
    WallustSwww.sh  # Regenerate colors
    hyprctl reload  # Full config reload (restore all settings)
}
```

**Design Rationale**:

- **Asymmetric Transitions**: ON is fast (batch disable), OFF is slow (full reload)
- **State Persistence**: No cache file needed (read from `hyprctl getoption`)
- **Side Effect Management**: Wallpaper daemon lifecycle tied to game mode

### State Machine 3: Night Light (Hyprsunset)

**States**: `off` ↔ `on (@4500K)`

**State Persistence**: `~/.cache/.hyprsunset_state` (file-based)

**Transition Functions**:

```bash
cmd_toggle() {
    state="$(cat "$STATE_FILE")"

    # Always stop existing instance first (prevent CTM conflicts)
    if pgrep -x hyprsunset >/dev/null; then
        pkill -x hyprsunset
        sleep 0.2  # Race condition prevention
    fi

    if [[ "$state" == "on" ]]; then
        # OFF transition: apply identity matrix, exit
        hyprsunset -i >/dev/null &
        sleep 0.3 && pkill -x hyprsunset
        echo off >"$STATE_FILE"
    else
        # ON transition: start daemon with target temp
        nohup hyprsunset -t "$TARGET_TEMP" >/dev/null &
        echo on >"$STATE_FILE"
    fi
}
```

**Process Lifecycle Management**:

- **Startup** (`Hyprsunset.sh init`): Read state file, restore previous state
- **Status Query** (`Hyprsunset.sh status`): Check process + state file (live detection)
- **Toggle** (`Hyprsun
