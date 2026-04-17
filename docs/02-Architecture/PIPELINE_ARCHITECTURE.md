# Pipeline Architecture - Layered Configuration Flow

## Overview

This document describes the **pipeline-based configuration loading architecture** that treats Hyprland configuration as a **compiled system** with distinct compilation phases, dependency management, and incremental override patterns.

---

## Layered Pipeline Data Flow

### Complete Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────┐
│                     hyprland.conf (Entry Point)                     │
│                    source bootstrap/default.conf                    │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 0: CONSTANT DEFINITION (Lexical Analysis / Tokenization)     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  bootstrap/const.conf                                         │  │
│  │  ├── $Hypr = ~/.config/hypr                                   │  │
│  │  ├── $sys = $Hypr/sys                                         │  │
│  │  └── $user = $Hypr/user                                       │  │
│  │                                                               │  │
│  │  sys/const.conf                                               │  │
│  │  ├── $M = SUPER                                               │  │
│  │  ├── $S = $sys/scripts                                        │  │
│  │  ├── $H = $sys/hardware                                       │  │
│  │  └── $P = $sys/policy                                         │  │
│  │                                                               │  │
│  │  user/const.conf (OVERRIDES)                                  │  │
│  │  ├── $M_terminal = ghostty                                    │  │
│  │  └── $W = ~/Pictures/wallpapers                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Output: Symbol table with all $variables resolved                  │
│  Invariant: All constants defined before use in later stages        │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ All $variables available globally
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 1: HARDWARE ABSTRACTION (Physical Layer / Device Config)     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/hardware/default.conf                                    │  │
│  │  ├── laptop.conf                                              │  │
│  │  │   ├── Laptop function keys (brightness, touchpad)          │  │
│  │  │   ├── Touchpad device config ($Touchpad_Device)            │  │
│  │  │   └── Lid switch rules → laptop-display.conf               │  │
│  │  ├── monitors.conf                                            │  │
│  │  │   └── Monitor definitions (resolution, refresh, position)  │  │
│  │  └── workspaces.conf                                          │  │
│  │      └── Workspace→monitor assignments                        │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: $H, $S from Stage 0                                  │
│  Output: Physical device state (monitors, input devices)            │
│  Invariant: Hardware configured before visual policies              │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Devices ready
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 2: POLICY APPLICATION (Strategy Pattern / Visual Policies)   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/policy/default.conf                                      │  │
│  │  ├── wallust/wallust-hyprland.conf                            │  │
│  │  │   ├── $background = rgb(1E1F1F)                            │  │
│  │  │   ├── $foreground = rgb(EBEBEB)                            │  │
│  │  │   └── $color0-$color15 (16 color variables)                │  │
│  │  └── animations/default.conf                                  │  │
│  │      ├── bezier curves (wind, winIn, winOut, etc.)            │  │
│  │      └── animation definitions (windows, fade, workspaces)    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: $P, $P_w, $P_a from Stage 0                          │
│  CRITICAL CONSTRAINT: Colors MUST load before decoration.conf       │
│  Output: Visual policy active ($colorN vars + animation presets)    │
│  Invariant: Policy layer complete before core rendering config      │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Policies loaded ($color0-$color15 available)
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 3: CORE CONFIGURATION (Semantic Analysis / Behavior Setup)   │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  For each domain X (incremental override pattern):            │  │
│  │    source = $sys/X.conf    (vendor defaults)                  │  │
│  │    source = $user/X.conf   (user deltas - LATER WINS)         │  │
│  │                                                               │  │
│  │  Domain Load Order (critical dependencies):                   │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │ 1. env.conf       → Environment variables               │  │  │
│  │  │    ├── Wayland display vars                             │  │  │
│  │  │    ├── Qt/GTK theme engines                             │  │  │
│  │  │    └── App defaults (EDITOR, BROWSER, etc.)             │  │  │
│  │  │                                                         │  │  │
│  │  │ 2. misc.conf      → Miscellaneous options               │  │  │
│  │  │    ├── disable_hyprland_logo                            │  │  │
│  │  │    ├── vrr (variable refresh rate)                      │  │  │
│  │  │    └── swallow_regex (uses $M_terminal)                 │  │  │
│  │  │                                                         │  │  │
│  │  │ 3. input.conf     → Input devices                       │  │  │
│  │  │    ├── Keyboard layout (kb_layout)                      │  │  │
│  │  │    ├── Touchpad settings                                │  │  │
│  │  │    └── Mouse sensitivity                                │  │  │
│  │  │                                                         │  │  │
│  │  │ 4. layout.conf    → Tiling engines                      │  │  │
│  │  │    ├── general { layout = dwindle }                     │  │  │
│  │  │    ├── dwindle { pseudotile, preserve_split }           │  │  │
│  │  │    ├── master { new_status, mfact }                     │  │  │
│  │  │    └── plugin:hyprscrolling { column_width, ... }       │  │  │
│  │  │                                                         │  │  │
│  │  │ 5. decoration.conf → Visual effects ⚠️ DEPENDS ON STAGE2│  │  │
│  │  │    ├── rounding, opacity                                │  │  │
│  │  │    ├── blur { size, passes }                            │  │  │
│  │  │    └── shadow { color = $color12 } ← Uses policy colors │  │  │
│  │  │                                                         │  │  │
│  │  │ 6. render.conf    → Render pipeline                     │  │  │
│  │  │    ├── col.active_border = $color12 ← Uses policy colors│  │  │
│  │  │    ├── direct_scanout                                   │  │  │
│  │  │    └── cursor { no_warps, enable_hyprcursor }           │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: All $variables from Stage 0, $colorN from Stage 2    │
│  Output: Core behavior configured (input, layout, visuals)          │
│  Invariant: Each domain's user/ override immediately follows sys/   │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Core behavior ready
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 4: SERVICE LIFECYCLE (Process Initialization / Daemon Mgmt)  │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/startup.conf                                             │  │
│  │  ├── Environment propagation                                  │  │
│  │  │   ├── dbus-update-activation-environment                   │  │
│  │  │   └── systemctl --user import-environment                  │  │
│  │  ├── Wallpaper daemon                                         │  │
│  │  │   └── swww-daemon --format xrgb                            │  │
│  │  ├── Authentication                                           │  │
│  │  │   └── Polkit-NixOS.sh                                      │  │
│  │  ├── System services                                          │  │
│  │  │   ├── nm-applet --indicator                                │  │
│  │  │   ├── swaync (notifications)                               │  │
│  │  │   └── waybar (status bar)                                  │  │
│  │  ├── Clipboard                                                │  │
│  │  │   ├── wl-paste --type text --watch cliphist store          │  │
│  │  │   └── wl-paste --type image --watch cliphist store         │  │
│  │  ├── Idle management                                          │  │
│  │  │   └── hypridle (absolute path required)                    │  │
│  │  └── Night light initialization                               │  │
│  │      └── Hyprsunset.sh init (restores previous state)         │  │
│  │                                                               │  │
│  │  user/startup.conf (ADDITIONAL SERVICES)                      │  │
│  │  ├── fcitx5 -d -r (input method)                              │  │
│  │  └── Custom user services                                     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: $S, $sys from Stage 0                                │
│  CRITICAL: Services start AFTER core config is complete             │
│  Output: Background processes running (daemons initialized)         │
│  Invariant: Process lifecycle managed (absolute paths for daemons)  │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Services started
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STAGE 5: WINDOW MANAGEMENT (Rule Compilation / Tag System)         │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  sys/tags.conf          → Window tag registry (WHAT apps ARE) │  │
│  │  ├── Category tags (28): browser, terminal, im, projects...   │  │
│  │  ├── Behavior tags (5): pip, auth-dialog, file-dialog...      │  │
│  │  └── Helper tags (3): $H_Cheat, $H_Settings, keybindings      │  │
│  │                                                               │  │
│  │  user/tags.conf         → User tag additions                  │  │
│  │  └── windowrule = match:class ^(signal)$, tag +im             │  │
│  │                                                               │  │
│  │  sys/rules.conf         → Tag-driven rules (HOW windows act)  │  │
│  │  ├── Browser rules: opacity, idle_inhibit                     │  │
│  │  ├── IM rules: float, center, size, opacity                   │  │
│  │  ├── Game rules: fullscreen, no_blur, idle_inhibit            │  │
│  │  └── ... (rules for all 28 category tags)                     │  │
│  │                                                               │  │
│  │  user/rules.conf        → User rule additions/overrides       │  │
│  │  └── windowrule = float on, match:tag signal                  │  │
│  │                                                               │  │
│  │  POST-PROCESSING: KeybindsLayoutInit.sh                       │  │
│  │  └── Applies layout-specific binds based on current layout    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│  Dependencies: Tags from bootstrap ($H_Cheat, $H_Settings)          │
│  INVARIANT: Every tag in tags.conf has ≥1 rule in rules.conf        │
│  Output: Window classification + behavior rules compiled            │
│  Final State: Fully configured Hyprland instance ready              │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow Characteristics

**Direction**: Strictly unidirectional (Stage 0 → Stage 5)

**Dependencies**:

- Stage 0 provides: All `$variables` (constants)
- Stage 1 provides: Hardware state (monitors, input devices)
- Stage 2 provides: Visual policies (`$color0-$color15`, animations)
- Stage 3 provides: Core behavior (layout, decoration, rendering)
- Stage 4 provides: Running services (daemons)
- Stage 5 provides: Window management rules

**Critical Constraints**:

1. Stage 2 (policy) MUST complete before Stage 3 decoration.conf (needs `$colorN`)
2. Stage 0 constants MUST be available to all subsequent stages
3. Stage 4 services start AFTER Stage 3 core config is complete
4. Stage 5 tag registry MUST be complete before rules are applied

**Incremental Override Points**:

- Stage 0: `user/const.conf` overrides constants
- Stage 3: Each domain has `user/X.conf` overriding `sys/X.conf`
- Stage 4: `user/startup.conf` adds services
- Stage 5: `user/tags.conf` and `user/rules.conf` extend window rules

---

## Pipeline Stages

The configuration loading process follows a strict **5-stage pipeline**:

```
┌──────────────────────────────────────────────────────────────┐
│  STAGE 0: Constant Definition (Lexical Analysis)             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ bootstrap/const.conf   → Path constants ($Hypr, $sys)  │  │
│  │ sys/const.conf         → System defaults ($M, $S, $H)  │  │
│  │ user/const.conf        → User overrides ($M_terminal)  │  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: All $variables resolved                             │
└──────────────────────┬───────────────────────────────────────┘
                       │ All constants available
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 1: Hardware Abstraction (Physical Layer)              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ sys/hardware/default.conf                              │  │
│  │   ├── laptop.conf        → Laptop keys, touchpad       │  │
│  │   ├── monitors.conf      → Display configuration       │  │
│  │   └── workspaces.conf    → Workspace→monitor mapping   │  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: Physical device state configured                    │
└──────────────────────┬───────────────────────────────────────┘
                       │ Hardware ready
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 2: Policy Application (Strategy Pattern)              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ sys/policy/default.conf                                │  │
│  │   ├── wallust/wallust-hyprland.conf  → $colorN vars    │  │
│  │   └── animations/default.conf        → Animation preset│  │
│  └────────────────────────────────────────────────────────┘  │
│  Critical: Colors MUST be defined before decoration.conf     │
│  Output: Visual policy active ($color0-$color15 available)   │
└──────────────────────┬───────────────────────────────────────┘
                       │ Policy loaded
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 3: Core Configuration (Semantic Analysis)             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ For each config domain X:                              │  │
│  │   source = $sys/X.conf    (vendor defaults)            │  │
│  │   source = $user/X.conf   (user deltas)                │  │
│  │                                                        │  │
│  │ Domains (in order):                                    │  │
│  │   env → misc → input → layout → decoration → render    │  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: Core behavior configured                            │
└──────────────────────┬───────────────────────────────────────┘
                       │ Core ready
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 4: Service Lifecycle (Process Initialization)         │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ sys/startup.conf   → exec-once services                │  │
│  │ user/startup.conf  → user services                     │  │
│  └────────────────────────────────────────────────────────┘  │
│  Services: swww-daemon, waybar, swaync, cliphist, hypridle   │
│  Output: Background processes running                        │
└──────────────────────┬───────────────────────────────────────┘
                       │ Services started
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  STAGE 5: Window Management (Rule Compilation)               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ sys/tags.conf      → Window tag registry               │  │
│  │ user/tags.conf     → User tag additions                │  │
│  │ sys/rules.conf     → Tag-driven rules                  │  │
│  │ user/rules.conf    → User rule additions               │  │
│  └────────────────────────────────────────────────────────┘  │
│  Output: Window classification + behavior rules active       │
└──────────────────────────────────────────────────────────────┘
```

---

## Stage Dependency Matrix

This matrix shows which stages depend on outputs from previous stages:

| Stage       | Depends On                                                  | Provides To                                               | Critical Variables                                                     |
| ----------- | ----------------------------------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------------------- |
| **Stage 0** | None (root)                                                 | All stages                                                | `$Hypr`, `$sys`, `$user`, `$M`, `$S`, `$H`, `$P`, `$colorN` (indirect) |
| **Stage 1** | Stage 0 (`$H`, `$S`)                                        | Stage 3 (input devices affect layout)                     | Monitor config, touchpad state                                         |
| **Stage 2** | Stage 0 (`$P`, `$P_w`, `$P_a`)                              | Stage 3 (decoration needs `$colorN`)                      | `$color0-$color15`, animation presets                                  |
| **Stage 3** | Stage 0 (all `$vars`), Stage 2 (`$colorN`)                  | Stage 4 (services use config), Stage 5 (rules use layout) | Layout engine, decoration settings, render options                     |
| **Stage 4** | Stage 0 (`$S`, `$sys`), Stage 3 (core config)               | Stage 5 (services provide runtime context)                | Running daemons (swww, waybar, swaync, hypridle)                       |
| **Stage 5** | Stage 0 (`$H_Cheat`, `$H_Settings`), Stage 3 (layout state) | Runtime (window management active)                        | Tag registry, window rules, keybinds                                   |

### Dependency Violation Examples

**❌ VIOLATION: Using `$color12` before Stage 2**

```
# BAD: sys/decoration.conf loaded before sys/policy/default.conf
source = $sys/decoration.conf  # Tries to use $color12 → EMPTY
source = $P/default.conf       # Defines $color12 → Too late!
```

**✅ CORRECT: Policy before decoration**

```
# GOOD: Policy defines colors first
source = $P/default.conf       # Defines $color0-$color15
source = $sys/decoration.conf  # Uses $color12 → Resolved correctly
```

**❌ VIOLATION: User constants in Stage 3**

```
# BAD: user/const.conf loaded too late
source = $sys/default.conf     # Uses $M_terminal = kitty (sys default)
source = $user/const.conf      # Sets $M_terminal = ghostty → Already used!
```

**✅ CORRECT: User constants in Stage 0**

```
# GOOD: User constants available throughout pipeline
source = $user/const.conf      # Sets $M_terminal = ghostty
source = $sys/default.conf     # Uses $M_terminal = ghostty → Correct!
```

---

## Pipeline Execution Timeline

### Millisecond-by-Millisecond Startup Sequence

```
Time    Stage   Action                                          State Change
────    ─────   ──────────────────────────────────────────      ────────────
0ms     S0      hyprland.conf sources bootstrap/default.conf    Pipeline start
1ms     S0      Load bootstrap/const.conf                       $sys, $user defined
2ms     S0      Load sys/const.conf                             $M, $S, $H, $P defined
3ms     S0      Load user/const.conf                            $M_terminal=ghostty (override)
        │
4ms     S1      Load sys/hardware/default.conf                  Hardware stage start
5ms     S1      ├─ laptop.conf                                  Touchpad configured
6ms     S1      ├─ monitors.conf                                eDP-1: 2560x1440@165
7ms     S1      └─ workspaces.conf                              Workspace assignments set
        │
8ms     S2      Load sys/policy/default.conf                    Policy stage start
9ms     S2      ├─ wallust-hyprland.conf                        $color0-$color15 defined
10ms    S2      └─ animations/default.conf                      Animation preset loaded
        │
11ms    S3      Core configuration begins                       Semantic analysis start
12ms    S3      ├─ env.conf → user/env.conf                     EDITOR=nvim, GDK_SCALE=1.5
13ms    S3      ├─ misc.conf → user/misc.conf                   vfr=true, vrr=2
14ms    S3      ├─ input.conf → user/input.conf                 kb_layout=us,cn
15ms    S3      ├─ layout.conf → user/layout.conf               layout=scrolling
16ms    S3      ├─ decoration.conf → user/decoration.conf       Uses $color12 ✓, rounding=16
17ms    S3      └─ render.conf → user/render.conf               Uses $color12 ✓, cursor config
        │
18ms    S4      Service lifecycle begins                        Process initialization
19ms    S4      ├─ dbus-update-activation-environment           Env propagated
20ms    S4      ├─ swww-daemon --format xrgb                    Wallpaper daemon started
21ms    S4      ├─ Polkit-NixOS.sh                              Auth agent running
22ms    S4      ├─ nm-applet, swaync, waybar                    System services up
23ms    S4      ├─ cliphist store (text + image)               Clipboard managers ready
24ms    S4      ├─ hypridle                                     Idle daemon running
25ms    S4      └─ Hyprsunset.sh init                           Night light restored
        │
26ms    S5      Window management begins                        Rule compilation start
27ms    S5      ├─ sys/tags.conf                                28 category tags registered
28ms    S5      ├─ user/tags.conf                               User tags added
29ms    S5      ├─ sys/rules.conf                               200+ rules compiled
30ms    S5      ├─ user/rules.conf                              User rules added
31ms    S5      └─ KeybindsLayoutInit.sh                        Layout-specific binds applied
        │
32ms    -       Configuration load complete                     Hyprland ready for use
```

**Total Load Time**: ~32ms (excluding service startup overhead)

**Key Observations**:

- Stage 0 (constants): 3ms — Fast token definition
- Stage 1 (hardware): 4ms — Device configuration
- Stage 2 (policy): 2ms — Color/animation policy
- Stage 3 (core): 7ms — Behavior configuration (largest stage)
- Stage 4 (services): 8ms — Process initialization
- Stage 5 (rules): 6ms — Window rule compilation

**Bottleneck**: Stage 4 (service startup) — dominated by external process launch times

---

## Incremental Override Mechanism - Detailed Flow

### How `sys/X.conf` → `user/X.conf` Works

For each configuration domain in Stage 3, the incremental override pattern applies:

```
Example: input.conf domain

Step 1: Load sys/input.conf
┌─────────────────────────────────────┐
│ input {                             │
│     kb_layout = us                  │  ← System default
│     sensitivity = 0.0               │
│     touchpad {                      │
│         natural_scroll = true       │
│     }                               │
│ }                                   │
└─────────────────────────────────────┘
        ↓ Hyprland internal state: kb_layout = "us"

Step 2: Load user/input.conf
┌─────────────────────────────────────┐
│ input {                             │
│     kb_layout = us,cn               │  ← User override (LATER WINS)
│ }                                   │
└─────────────────────────────────────┘
        ↓ Hyprland internal state: kb_layout = "us,cn" (OVERWRITTEN)

Final State: kb_layout = "us,cn"
```

**Mechanism**: Hyprland's `source` directive uses **last-write-wins** semantics. When the same setting is defined multiple times, the last definition takes precedence.

**Benefits**:

1. **Minimal Diffs**: User files only contain changes, not full config
2. **Vendor Updates Safe**: Updating `sys/` doesn't affect `user/` overrides
3. **Clear Intent**: Easy to see what's customized vs default
4. **Git-Friendly**: `user/` can be tracked separately or ignored

### Override Chain Example

```
Configuration Domain: decoration.conf

sys/decoration.conf (vendor defaults):
  decoration {
      rounding = 10
      blur {
          size = 6
          passes = 2
      }
      shadow {
          color = $color12  ← Resolved from Stage 2
      }
  }

user/decoration.conf (user deltas):
  decoration {
      rounding = 16         ← Override: larger rounding
      blur {
          size = 8          ← Override: stronger blur
      }
  }

Resolution Process:
  1. Load sys/decoration.conf → rounding=10, blur.size=6
  2. Load user/decoration.conf → rounding=16, blur.size=8 (overrides)
  3. Final state: rounding=16, blur.size=8, blur.passes=2 (inherited), shadow.color=$color12 (inherited)
```

**Important**: Unspecified settings in `user/` files inherit from `sys/` files. Only explicit overrides change values.

---

## Stage 0: Constant Definition (Lexical Analysis)

### Purpose

Define all symbolic constants (tokens) used throughout the configuration. This is equivalent to a compiler's **lexical analysis phase**, where raw text is converted into meaningful tokens.

### Files & Responsibilities

#### `bootstrap/const.conf` — Path Constants

```bash
# Absolute path definitions (no dependencies)
$Hypr           = ~/.config/hypr
$bootstrap      = $Hypr/bootstrap
$sys            = $Hypr/sys
$user           = $Hypr/user
$lock_background= $Hypr/wallpaper_effects/.wallpaper_current
```

**Design Principle**: **Single Source of Truth** for paths. Changing `$sys` updates all references automatically.

#### `sys/const.conf` — System Defaults

```bash
# Modifier keys
$M              = SUPER
$M_terminal     = kitty
$M_file_manager = nemo
$M_editor       = ${EDITOR:-nano}

# Path shortcuts
$S              = $sys/scripts
$H              = $sys/hardware
$P              = $sys/policy
$P_w            = $P/wallust
$P_a            = $P/animations

# Semantic tags
$H_Cheat        = Help_Cheat
$H_Settings     = Help_Settings

# Resources
$W              = $HOME/Pictures/wallpapers
$Search_Engine  = "https://www.google.com/search?q={}"
```

**Design Principle**: **Default Values**. All constants have sensible defaults that work out-of-the-box.

#### `user/const.conf` — User Overrides

```bash
# Override system defaults (examples)
$M_terminal     = ghostty
$M_file_manager = thunar
$W              = $HOME/Pictures/my-wallpapers
$Search_Engine  = "https://www.bing.com/search?q={}"
```

**Design Principle**: **Incremental Override**. Only specify differences from defaults.

### Three-Layer Constant System

**📚 Complete Documentation**: See [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md) for full specification with dependency graphs, resolution examples, debugging guides, and best practices.

The configuration implements a **three-layer constant resolution system** that applies the Dependency Inversion Principle at multiple levels:

```
Layer 1: bootstrap/const.conf  — Path infrastructure constants ($Hypr, $sys, $user)
Layer 2: sys/const.conf        — System default constants ($M, $S, $H, $P, $W)
Layer 3: user/const.conf       — User override constants ($M_terminal, custom paths)
```

**Resolution Order** (last-write-wins):

```bash
1. bootstrap/const.conf   → Defines infrastructure paths
2. sys/const.conf         → Defines system defaults
3. user/const.conf        → Overrides user preferences

Final value = Last definition wins
```

**Critical Design Decision**: All three layers load in **Stage 0**, ensuring constants are available to ALL subsequent stages.

For complete details including:

- Full constant listings for all three layers
- Dependency graph visualization
- Resolution examples with step-by-step expansion
- Debugging guides for common issues
- Best practices for users and developers
- Performance characteristics
- Advanced techniques (profiles, environment integration)

→ Read [THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md)

### Compiler Analogy

| Compiler Phase   | Config Equivalent  | Example              |
| ---------------- | ------------------ | -------------------- |
| Character Stream | Raw `.conf` files  | Text content         |
| Tokenization     | Variable expansion | `$M` → `SUPER`       |
| Symbol Table     | Constant registry  | All `$` variables    |
| Error Detection  | Undefined variable | `$UNDEFINED` → error |

---

## Stage 1: Hardware Abstraction (Physical Layer)

### Purpose

Configure physical devices (monitors, keyboards, touchpads) before applying higher-level policies. This mirrors the **hardware abstraction layer (HAL)** in operating systems.

### Pipeline

```
sys/hardware/default.conf
  ├── laptop.conf          → Laptop-specific binds
  ├── monitors.conf        → Display configuration
  └── workspaces.conf      → Workspace assignments
```

### Key Design Patterns

#### 1. Device-Specific Configuration

```bash
# sys/hardware/laptop.conf
$Touchpad_Device = asue1209:00-04f3:319f-touchpad

device {
    name    = $Touchpad_Device
    enabled = $TOUCHPAD_ENABLED
}
```

**Principle**: **Parameterization**. Device names are parameterized for easy swapping.

#### 2. Conditional Behavior via Lid Switch

```bash
# OPTION B — File-based state management
bindl = , switch:off:Lid Switch, exec, \
  echo "monitor = eDP-1, preferred, auto, 1" > $H/laptop-display.conf
bindl = , switch:on:Lid Switch, exec, \
  echo "monitor = eDP-1, disable" > $H/laptop-display.conf

source = $H/laptop-display.conf
```

**Principle**: **State Persistence**. Lid switch state persists across reloads via file I/O.

#### 3. Monitor Profile Swapping

```bash
# sys/hardware/monitors.conf
# Managed by nwg-displays; manual edits may be overwritten
monitor = , preferred, auto, 1

# Switch at runtime: scripts/MonitorProfiles.sh
```

**Principle**: **External Management**. Complex monitor configs delegated to GUI tool (nwg-displays).

### Boundary Contract

**Provides**:

- Monitor resolution/refresh rate
- Keyboard layout/touchpad settings
- Laptop function key bindings

**Consumes**:

- `$H` constant (from Stage 0)
- `$S` constant (for script paths)

**Must Not**:

- Reference user-specific paths directly
- Define visual policies (colors, animations)
- Modify window rules

---

## Stage 2: Policy Application (Strategy Pattern)

### Purpose

Apply swappable visual policies (colors, animations) that can be changed at runtime without full config reload. Implements the **Strategy design pattern**.

### Pipeline

```
sys/policy/default.conf
  ├── wallust/wallust-hyprland.conf  → Color variables
  └── animations/default.conf        → Animation preset
```

### Color Policy (Wallust Integration)

#### Generation Process

```bash
# Triggered by WallpaperSelect.sh or WallpaperAutoChange.sh
wallust run -s "$wallpaper_path"
# Outputs: sys/policy/wallust/wallust-hyprland.conf
```

#### Generated Output

```bash
# /* wallust template - colors-hyprland */
$background = rgb(1E1F1F)
$foreground = rgb(EBEBEB)
$color0 = rgb(444545)
$color1 = rgb(151718)
# ... $color2-$color15
```

**Design Principle**: **Code Generation**. Colors are programmatically generated, not manually specified.

#### Dependency Constraint

```bash
# sys/default.conf — CRITICAL ORDER
source = $P/default.conf          # Defines $colorN
source = $sys/decoration.conf     # Uses $colorN
```

**Violation Consequence**: If `decoration.conf` loads before `policy/default.conf`, all `$colorN` references resolve to empty strings → invisible borders.

### Animation Policy (Preset Swapping)

#### Available Presets

| Preset                | Style                  | Performance | Use Case           |
| --------------------- | ---------------------- | ----------- | ------------------ |
| `default.conf`        | Smooth slide           | Medium      | General use        |
| `disable.conf`        | None                   | Maximum     | Gaming, low-power  |
| `end4.conf`           | Material Design pop-in | High        | Modern aesthetic   |
| `hyde-optimized.conf` | Fast deceleration      | Low-Medium  | Productivity       |
| `ml4w-fast.conf`      | Minimal pop-in         | Low         | Quick interactions |

#### Runtime Switching

```bash
# sys/scripts/Animations.sh
chosen_file="end4"
full_path="$animations_dir/$chosen_file.conf"
hyprctl keyword source "$full_path"
```

**Mechanism**: `hyprctl keyword source` dynamically loads new animation definitions without restart.

**State Management**: No state file needed — current animation state readable via:

```bash
hyprctl getoption animations:enabled
```

### Strategy Pattern Implementation

```
┌─────────────────────────────────────┐
│  Context: sys/policy/default.conf   │
│  ┌───────────────────────────────┐  │
│  │ Strategy: wallust colors      │  │
│  │ Strategy: animation preset    │  │
│  └───────────────────────────────┘  │
│  Interface: $colorN, bezier curves  │
└─────────────────────────────────────┘
           │
           │ Runtime swap via:
           │ hyprctl keyword source
           ▼
┌─────────────────────────────────────┐
│  Concrete Strategies:               │
│  ├── default.conf                   │
│  ├── end4.conf                      │
│  ├── hyde-optimized.conf            │
│  └── ml4w-fast.conf                 │
└─────────────────────────────────────┘
```

**Benefits**:

- **Open/Closed Principle**: Add new presets without modifying existing code
- **Runtime Flexibility**: Swap strategies without restart
- **Testability**: Each preset is independently testable

---

## Stage 3: Core Configuration (Semantic Analysis)

### Purpose

Apply core behavioral settings with incremental override pattern. This is the **semantic analysis phase**, ensuring configuration correctness and applying user customizations.

### Incremental Override Pattern

For each configuration domain `X`:

```bash
source = $sys/X.conf      # Vendor defaults (read-only)
source = $user/X.conf     # User deltas (write here)
```

### Configuration Domains (Load Order)

#### 1. Environment Variables (`env.conf`)

```bash
# sys/env.conf
env = EDITOR, nvim
env = QT_QPA_PLATFORMTHEME, qt6ct

# user/env.conf
env = GDK_SCALE, 1.5        # HiDPI override
env = LIBVA_DRIVER_NAME, nvidia  # NVIDIA support
```

**Use Cases**:

- HiDPI scaling
- NVIDIA driver enablement
- Default application selection
- Theme engine configuration

#### 2. Miscellaneous Options (`misc.conf`)

```bash
# sys/misc.conf
misc {
    disable_hyprland_logo = true
    vrr = 2                 # Fullscreen only
    enable_swallow = off
    swallow_regex = ^($M_terminal)$
}

# user/misc.conf
misc {
    vfr = true              # Variable frame rate (power saving)
}
```

**Key Feature**: `swallow_regex` uses `$M_terminal` constant → respects user terminal choice.

#### 3. Input Devices (`input.conf`)

```bash
# sys/input.conf
input {
    kb_layout = us
    touchpad {
        natural_scroll = true
    }
}

# user/input.conf
input {
    kb_layout = us,cn       # Add Chinese layout
}
```

**Per-Window Layout**: Advanced users can enable `Tak0-Per-Window-Switch.sh` for per-application keyboard layouts.

#### 4. Layout Engine (`layout.conf`)

```bash
# sys/layout.conf
general {
    layout = dwindle        # Sys default (works without plugins)
}

# user/layout.conf
general {
    layout = scrolling      # User preference (requires hyprscrolling plugin)
}

plugin:hyprscrolling {
    column_width = 0.5
    follow_focus = true
}
```

**Layout State Machine**: See [State Machine Documentation](STATE_MACHINES.md#layout-engine).

#### 5. Visual Decoration (`decoration.conf`)

```bash
# sys/decoration.conf
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 6
        passes = 2
    }
    shadow {
        enabled = true
        color = $color12    # From policy layer
    }
}

# user/decoration.conf
decoration {
    rounding = 16           # User override
    blur {
        size = 8            # Stronger blur
    }
}
```

**Dependency**: Requires `$colorN` from Stage 2 (policy layer).

#### 6. Render Pipeline (`render.conf`)

```bash
# sys/render.conf
general {
    col.active_border = $color12
    col.inactive_border = $color10
}

render {
    direct_scanout = 0
}

cursor {
    no_warps = true
    enable_hyprcursor = true
}
```

**Responsibility**: Low-level rendering settings (scanout, cursor warping).

### Load Order Rationale

```
env → misc → input → layout → decoration → render
```

**Reasoning**:

1. **env**: Must be first (affects all subsequent processes)
2. **misc**: Basic behavior before visual settings
3. **input**: Input devices before layout (keyboard affects layout navigation)
4. **layout**: Tiling engine before decoration (layout determines window positions)
5. **decoration**: Visual effects need layout context
6. **render**: Lowest-level settings last (depends on all above)

---

## Stage 4: Service Lifecycle (Process Initialization)

### Purpose

Start background services required for desktop functionality. Implements **process lifecycle management**.

### Pipeline

```bash
# sys/startup.conf
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Wallpaper daemon
exec-once = swww-daemon --format xrgb
exec-once = $S/WallpaperAutoChange.sh $W

# Authentication
exec-once = $S/Polkit-NixOS.sh

# System services
exec-once = nm-applet --indicator
exec-once = swaync
exec-once = waybar

# Clipboard
exec-once = wl-paste --type text  --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

# Idle management
exec-once = hypridle

# Night light (restore previous state)
exec-once = $S/Hyprsunset.sh init
```

### Process Lifecycle Patterns

#### Pattern 1: Stateless Services

```bash
exec-once = waybar
exec-once = swaync
```

**Characteristics**:

- No state persistence
- Can be restarted freely
- Configuration via separate files

#### Pattern 2: Stateful Daemons

```bash
# sys/startup.conf
exec-once = hypridle

# hypridle manages its own state internally
# Config: sys/hypridle.conf (absolute path required)
```

**Characteristics**:

- Maintains internal state (idle timers)
- Config path must be absolute (process isolation)
- Restart requires state restoration

#### Pattern 3: State-Persisted Services

```bash
# Hyprsunset — state in ~/.cache/.hyprsunset_state
exec-once = $S/Hyprsunset.sh init

# Script reads state file and restores previous state
cmd_init() {
    state="$(cat "$STATE_FILE")"
    if [[ "$state" == "on" ]]; then
        nohup hyprsunset -t "$TARGET_TEMP" >/dev/null &
    fi
}
```

**Characteristics**:

- State persisted to file
- Startup script restores state
- Toggle script updates state file

#### Pattern 4: Pre-Spawned Terminals

```bash
exec-once = $S/Dropterminal.sh $M_terminal &

# Script pre-spawns terminal in special:scratchpad workspace
# Enables instant drop-down terminal (SUPER+SHIFT+Return)
```

**Characteristics**:

- Pre-initialization for performance
- Hidden until triggered
- Address cached for quick access

### Service Dependencies

```
dbus/systemd environment propagation
  ↓
swww-daemon (wallpaper)
  ↓
waybar (depends on swww for wallpaper info)
  ↓
swaync (notifications)
  ↓
cliphist (clipboard manager)
  ↓
hypridle (idle management)
```

**Design Principle**: **Explicit Ordering**. Services started in dependency order.

### User Service Addition

```bash
# user/startup.conf
exec-once = fcitx5 -d -r          # Input method
exec-once = blueman-applet         # Bluetooth
exec-once = $S/RainbowBorders.sh   # Visual effect
```

**Rule**: User services start AFTER system services (source order guarantee).

---

## Stage 5: Window Management (Rule Compilation)

### Purpose

Compile window classification and behavior rules. This is the most complex stage, implementing a **tag-driven rule system** with clear separation of concerns.

### Pipeline

```
sys/tags.conf       → Define window tags (WHAT an app IS)
user/tags.conf      → Add user tags
sys/rules.conf      → Apply rules based on tags (HOW it behaves)
user/rules.conf     → Add user rules
```

### Tag System Architecture

#### Tag Categories

**Category Tags** (What an app IS):

- `browser`, `terminal`, `im`, `email`, `projects`, `notes`
- `file-manager`, `multimedia`, `games`, `settings`, etc.

**Behavior Tags** (How it behaves):

- `pip`, `auth-dialog`, `file-dialog`
- `no-steal-focus`, `suppress-activate`

**Helper Tags**:

- `$H_Cheat`, `$H_Settings`, `keybindings`

#### Tag Definition Example

```bash
# sys/tags.conf
windowrule = match:class ^(firefox|chromium)$, tag +browser
windowrule = match:class ^(kitty|ghostty)$, tag +terminal
windowrule = match:class ^(discord|telegram)$, tag +im
```

**Principle**: One tag per semantic category. Apps can have multiple tags.

#### Rule Application Example

```bash
# sys/rules.conf
# Browser rules
windowrule = opacity 1.00 0.85, match:tag browser
windowrule = idle_inhibit fullscreen, match:tag browser

# IM rules
windowrule = float on, match:tag im
windowrule = center on, match:tag im
windowrule = size (monitor_w*0.60) (monitor_h*0.70), match:tag im
```

**Principle**: Rules grouped by tag, not by rule type (easier auditing).

### Compound Conditions (Edge Cases)

Some scenarios require conditions beyond simple tags:

```bash
# Browser sub-windows: float dialogs but not main window
windowrule = float on, \
  match:class ^(firefox)$, \
  match:title negative:^(Mozilla Firefox)$
```

**Rationale**: Main Firefox window has title "Mozilla Firefox", dialogs don't. Tag alone can't distinguish.

**Rule**: Direct `match:class` only for compound conditions that tags cannot express.

### Tag Completeness Invariant

**Invariant**: Every tag defined in `tags.conf` must have at least one rule in `rules.conf`.

**Audit Method**:

```bash
# Extract all tags from tags.conf
grep 'tag +' sys/tags.conf | sed 's/.*tag +//' | sort -u > /tmp/defined_tags

# Extract all tags from rules.conf
grep 'match:tag' sys/rules.conf | sed 's/.*match:tag //' | sort -u > /tmp/used_tags

# Check for orphaned tags
diff /tmp/defined_tags /tmp/used_tags
```

**Violation**: Orphaned tags indicate incomplete configuration (tag defined but never used).

### User Extension Pattern

```bash
# user/tags.conf
windowrule = match:class ^(signal)$, tag +im

# user/rules.conf
windowrule = float on, match:tag signal
windowrule = center on, match:tag signal
windowrule = size (monitor_w*0.50) (monitor_h*0.60), match:tag signal
```

**Pattern**: Add tag in `user/tags.conf`, add rules in `user/rules.conf`.

---

## Pipeline Execution Trace

### Example: Fresh Hyprland Start

```
[00:00.000] hyprland.conf sources bootstrap/default.conf
[00:00.001] Stage 0: Load bootstrap/const.conf
            → $sys = ~/.config/hypr/sys
[00:00.002] Stage 0: Load sys/const.conf
            → $M = SUPER, $M_terminal = kitty
[00:00.003] Stage 0: Load user/const.conf
            → $M_terminal = ghostty (override)
[00:00.004] Stage 1: Load sys/hardware/default.conf
            → Monitor: eDP-1, 2560x1440@165
            → Touchpad: asue1209 enabled
[00:00.005] Stage 2: Load sys/policy/default.conf
            → Load wallust colors ($color0-$color15)
            → Load default animations
[00:00.006] Stage 3: Load sys/env.conf → user/env.conf
            → EDITOR=nvim, GDK_SCALE=1.5
[00:00.007] Stage 3: Load sys/misc.conf → user/misc.conf
            → vfr=true, vrr=2
[00:00.008] Stage 3: Load sys/input.conf → user/input.conf
            → kb_layout=us,cn
[00:00.009] Stage 3: Load sys/layout.conf → user/layout.conf
            → layout=scrolling (with hyprscrolling plugin)
[00:00.010] Stage 3: Load sys/decoration.conf → user/decoration.conf
            → rounding=16, blur size=8
[00:00.011] Stage 3: Load sys/render.conf → user/render.conf
            → Borders use $color12
[00:00.012] Stage 4: Load sys/startup.conf
            → Start swww-daemon, waybar, swaync, hypridle
[00:00.013] Stage 4: Load user/startup.conf
            → Start fcitx5
[00:00.014] Stage 5: Load sys/tags.conf → user/tags.conf
            → Register 28 category tags + 5 behavior tags
[00:00.015] Stage 5: Load sys/rules.conf → user/rules.conf
            → Apply 200+ window rules
[00:00.016] Stage 5: Execute KeybindsLayoutInit.sh
            → Bind J/K based on current layout (scrolling)
[00:00.017] Configuration load complete
```

**Total Load Time**: ~17ms (excluding service startup)

---

## Error Handling & Diagnostics

### Common Pipeline Errors

#### 1. Undefined Variable

```
Error: unknown keyword "$UNDEFINED_VAR"
```

**Cause**: Variable used before definition or typo.

**Fix**: Check Stage 0 constant definitions. Ensure correct source order.

#### 2. Missing Color Variables

```
Warning: $color12 not defined
```

**Cause**: `decoration.conf` loaded before `policy/default.conf`.

**Fix**: Verify Stage 2 loads before Stage 3 decoration section.

#### 3. Circular Dependency

```
Error: max source depth exceeded
```

**Cause**: File A sources B, B sources A.

**Fix**: Refactor to eliminate circular reference. Use constants instead.

### Debugging Techniques

#### Trace Variable Resolution

```bash
# Check final value of a constant
hyprctl getoption general:border_size

# List all defined variables (Hyprland 0.52+)
hyprctl keywords | grep '^\$'
```

#### Inspect Loaded Config

```bash
# View active configuration
hyprctl config

# Check specific option
hyprctl getoption animations:enabled
```

#### Validate Tag Completeness

```bash
# Script to check tag completeness
./scripts/validate_tags.sh
```

---

## Performance Considerations

### Load Time Optimization

1. **Minimize File I/O**: Fewer, larger files vs many small files
2. **Avoid Redundant Sources**: Don't source same file twice
3. **Lazy Loading**: Defer non-critical services (e.g., wallpaper auto-change)

### Runtime Performance

1. **Batch Commands**: Use `hyprctl --batch` for atomic updates
2. **Avoid Full Reloads**: Use `hyprctl keyword` for single setting changes
3. **Cache Expensive Operations**: Store computed values in files

### Memory Usage

1. **Disable Unused Features**: `disable_hyprland_logo = true`
2. **Limit Blur Passes**: `blur { passes = 2 }` (not 4+)
3. **Reduce Shadow Range**: `shadow { range = 3 }` (not 10+)

---

## Best Practices

### For Users

1. **Edit Only `user/` Files**: Never modify `sys/` directly
2. **Minimal Deltas**: Only override what you need
3. **Comment Your Changes**: Explain WHY, not WHAT
4. **Test Incrementally**: Change one thing at a time

### For Developers

1. **Maintain Invariants**: Every tag must have rules
2. **Document Dependencies**: Comment critical load order
3. **Use Constants**: Never hard-code paths in scripts
4. **Validate Changes**: Run tag completeness check after modifications

### For Contributors

1. **Follow Naming Conventions**: `$M_*` for apps, `$H_*` for helpers
2. **Preserve Backwards Compatibility**: Don't break existing user configs
3. **Update Documentation**: Changes require doc updates
4. **Test Edge Cases**: Empty configs, missing files, invalid values

---

## Comparison with Other Approaches

### Traditional Monolithic Config

```
# Single 2000-line hyprland.conf
# Problems:
# - Hard to maintain
# - No separation of concerns
# - Updates require manual merge
# - No user/vendor separation
```

### Directory-Based (config.d)

```
/etc/hypr/conf.d/
  ├── 01-monitors.conf
  ├── 02-input.conf
  └── 99-user.conf

# Problems:
# - Numeric prefixes fragile
# - No clear override mechanism
# - Hard to track dependencies
```

### This Pipeline Architecture

```
✅ Clear stage separation
✅ Incremental override pattern
✅ Dependency management
✅ User/vendor separation
✅ Runtime policy swapping
✅ Tag-driven extensibility
```

---

## Future Enhancements

### Potential Improvements

1. **Config Validation Tool**: Static analysis for common errors
2. **Dependency Graph Visualization**: Auto-generate pipeline diagram
3. **Hot Reload for Specific Stages**: Reload only decoration, not entire config
4. **Configuration Profiles**: Save/switch between complete config sets
5. **Migration Assistant**: Auto-convert monolithic configs to pipeline format

### Research Directions

1. **Formal Verification**: Prove configuration correctness properties
2. **Incremental Compilation**: Only recompile changed stages
3. **Plugin System**: Third-party stage extensions
4. **Declarative Policies**: YAML/JSON policy definitions compiled to Hyprland syntax

---

## References

- [Hyprland Wiki - Configuration](https://wiki.hyprland.org/Configuring/)
- [Compiler Design - Pipeline Architecture](https://en.wikipedia.org/wiki/Compiler)
- [Design Patterns - Strategy Pattern](https://refactoring.guru/design-patterns/strategy)
- [Linux config.d Convention](https://en.wikipedia.org/wiki/Configuration_file)
- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
