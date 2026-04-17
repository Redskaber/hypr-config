---
inclusion: always
---

# Architecture Overview — Quick Reference

This is a **layered, pipeline-driven Hyprland configuration** for Hyprland ≥ 0.52.1 that applies software engineering principles from compiler design, state machine theory, and policy-based management.

**📚 For detailed architectural documentation, see:**

- **[DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md)** — Core design principles, compilation pipeline analogy, dependency inversion, tag system, software patterns catalog
- **[PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)** — Complete 5-stage pipeline with layer boundaries, incremental override pattern, error handling
- **[STATE_MACHINES.md](STATE_MACHINES.md)** — Formal state machine definitions (layout, game mode, night light) with transition functions and invariants

This document provides a **concise reference** for daily use. For deep understanding, read the detailed docs above.

---

## Pipeline (Quick View)

```
hyprland.conf                          (single entry point — no logic)
  └── bootstrap/default.conf
        ├── Stage 0: bootstrap/const.conf      (path/variable constants)
        ├── Stage 0: sys/const.conf            (sys constant overrides)
        ├── Stage 0: user/const.conf           (user constant overrides)
        └── Stage 1: sys/default.conf
              ├── sys/hardware/default.conf    (aggregates laptop + monitors + workspaces)
              ├── sys/policy/default.conf      (wallust colors → animations)
              ├── sys/env.conf        →  user/env.conf
              ├── sys/misc.conf       →  user/misc.conf
              ├── sys/input.conf      →  user/input.conf
              ├── sys/layout.conf     →  user/layout.conf
              ├── sys/decoration.conf →  user/decoration.conf
              ├── sys/render.conf     →  user/render.conf
              ├── sys/startup.conf    →  user/startup.conf
              ├── sys/keybind.conf    →  user/keybind.conf
              ├── sys/tags.conf       →  user/tags.conf
              └── sys/rules.conf      →  user/rules.conf
```

Source order = override priority: **later wins**.

**Key Insight**: `user/const.conf` loads in **Stage 0** (bootstrap), making user constant overrides available throughout the entire pipeline.

**Full Documentation**: [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)

---

## Layer Responsibilities

| Layer     | Path            | Responsibility                                       | Edit?               |
| --------- | --------------- | ---------------------------------------------------- | ------------------- |
| Bootstrap | `bootstrap/`    | Path constants, variable definitions, pipeline entry | ❌ Rarely           |
| System    | `sys/`          | Vendor defaults — never edit directly                | ❌ No               |
| Hardware  | `sys/hardware/` | Monitor, laptop keys, workspace rules                | ⚠️ Via nwg-displays |
| Policy    | `sys/policy/`   | Swappable runtime policies (colors, animations)      | ⚠️ Via scripts      |
| Scripts   | `sys/scripts/`  | Runtime scripts; user scripts in `user/scripts/`     | ⚠️ Advanced only    |
| User      | `user/`         | All user customizations — edit only these            | ✅ Yes              |

**Design Principle**: Single Responsibility — each layer has one clear purpose. See [DESIGN_PRINCIPLES.md § Layered Architecture](DESIGN_PRINCIPLES.md#layered-architecture--boundary-management).

---

## Design Principles (Summary)

**Single entry point** — `hyprland.conf` only sources `bootstrap/default.conf`. No logic.

**Incremental override** — every `sys/X.conf` is immediately followed by `user/X.conf`. User files only contain differences.

**Dependency direction** — constants flow downward only. `user/const.conf` is sourced in Stage 0 (bootstrap), before `sys/default.conf`, so user variable overrides are available throughout the entire pipeline.

**Policy layer** — wallust colors must be sourced before `sys/decoration.conf`. The pipeline in `sys/default.conf` guarantees this: `policy/default.conf` is sourced before the rendering section.

**Tag-driven rules** — `sys/tags.conf` is the single source of truth for all window tags. `sys/rules.conf` consumes only tags. Direct `match:class` in rules is only permitted for compound conditions that the tag system cannot express (e.g., `class + negative:title`).

**State machines** — runtime state (game mode, layout, night light) is managed by scripts with explicit state-transition functions. State is read from `hyprctl getoption` or a cache file, never from implicit side effects.

**Process lifecycle** — any daemon that runs in its own process context (hypridle, hyprsunset) must use absolute paths for config files and notification icons, since Hyprland `$variables` are not available in child process environments.

**Full Documentation**: [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md)

---

## Layout State Machine (Quick Reference)

Three layouts are supported. `ChangeLayout.sh` implements an explicit three-state cycle:

```bash
scrolling  ──►  dwindle  ──►  master  ──►  scrolling  ──► …
```

Each transition atomically manages three keybinds:

| Layout      | `SUPER+J/K`                    | `SUPER+O`     | Notes                                       |
| ----------- | ------------------------------ | ------------- | ------------------------------------------- |
| `scrolling` | unbound                        | unbound       | hyprscrolling plugin owns column navigation |
| `dwindle`   | `cyclenext` / `cyclenext,prev` | `togglesplit` |                                             |
| `master`    | `cyclenext` / `cyclenext,prev` | unbound       |                                             |

`KeybindsLayoutInit.sh` runs at startup and applies the same bind logic based on the current layout (which may be `scrolling` if set in `user/layout.conf`).

**Full Documentation**: [STATE_MACHINES.md § Layout Engine](STATE_MACHINES.md#layout-engine-state-machine)

### hyprscrolling Plugin Config

Plugin: `hyprwm/hyprland-plugins/hyprscrolling` — install via `hyprpm`.

Config block: `plugin:hyprscrolling` in `sys/layout.conf` (override in `user/layout.conf`).

| Field                      | Type        | Default                  | Description                                       |
| -------------------------- | ----------- | ------------------------ | ------------------------------------------------- |
| `column_width`             | float [0-1] | `0.5`                    | Default column width as fraction of monitor width |
| `fullscreen_on_one_column` | bool        | `false`                  | Make single column fullscreen                     |
| `explicit_column_widths`   | string      | `0.333, 0.5, 0.667, 1.0` | Widths for `+conf`/`-conf` cycling                |
| `focus_fit_method`         | int (0\|1)  | `0`                      | 0=center, 1=fit when focusing a column            |
| `follow_focus`             | bool        | `true`                   | Move layout to make focused window visible        |
| `follow_debounce_ms`       | int         | `0`                      | Debounce time for focus events                    |

### hyprscrolling layoutmsg Commands

Available via `hyprctl dispatch layoutmsg <cmd>` or keybinds:

| Command                               | Description                                       |
| ------------------------------------- | ------------------------------------------------- |
| `move +col` / `move -col`             | Move layout by one column                         |
| `move +200` / `move -200`             | Move layout by logical px                         |
| `colresize 0.5` / `colresize +0.2`    | Resize current column                             |
| `colresize +conf` / `colresize -conf` | Cycle through `explicit_column_widths`            |
| `colresize all 0.5`                   | Resize all columns to a specific width            |
| `movewindowto r/l/u/d`                | Move window to adjacent column (promotes at edge) |
| `fit active`                          | Fit active column into view                       |
| `fit visible`                         | Fit all visible columns                           |
| `fit all` / `fit toend` / `fit tobeg` | Other fit modes                                   |
| `focus r/l/u/d`                       | Move focus with wrapping (no monitor switch)      |
| `promote`                             | Move window to its own new column                 |
| `swapcol l` / `swapcol r`             | Swap current column with neighbor (wraps)         |
| `movecoltoworkspace 2`                | Move entire column to workspace                   |
| `togglefit`                           | Toggle `focus_fit_method` (center ↔ fit)          |

---

## Hardware Layer

`sys/hardware/default.conf` aggregates three hardware files:

```
sys/hardware/default.conf
  ├── laptop.conf          — laptop keys, touchpad device, ASUS ROG binds, lid switch
  ├── monitors.conf        — monitor configuration (managed by nwg-displays)
  └── workspaces.conf      — workspace → monitor assignment
```

`sys/hardware/laptop-display.conf` is written by lid-switch rules and controls eDP-1 state.

**Full Documentation**: [PIPELINE_ARCHITECTURE.md § Stage 1](PIPELINE_ARCHITECTURE.md#stage-1-hardware-abstraction-physical-layer)

---

## Policy Layer

`sys/policy/default.conf` aggregates two policy files:

```bash
sys/policy/default.conf
  ├── wallust/wallust-hyprland.conf   — $colorN variables (auto-generated by wallust)
  └── animations/default.conf        — active animation preset
```

Animation presets in `sys/policy/animations/`: `default` `disable` `end4` `hyde-optimized` `hyde-vertical` `ml4w-fast`

Switch at runtime with `SUPER+SHIFT+A` (Animations.sh).

**Design Pattern**: Strategy Pattern — policies are interchangeable algorithms.

**Full Documentation**: [PIPELINE_ARCHITECTURE.md § Stage 2](PIPELINE_ARCHITECTURE.md#stage-2-policy-application-strategy-pattern)

---

## Tag Registry

All tags are defined in `sys/tags.conf`. The tag system is fully symmetric:
every registered tag has at least one rule in `sys/rules.conf`, and every rule references a registered tag.

Tags are grouped into three categories:

**Category tags** — describe what an app is (28 total):

| Group         | Tags                                                                       |
| ------------- | -------------------------------------------------------------------------- |
| Web           | `browser`                                                                  |
| Productivity  | `terminal` `projects` `notes` `email` `text-editor`                        |
| Communication | `im`                                                                       |
| Files         | `file-manager`                                                             |
| Media         | `multimedia` `multimedia-video` `screenshare`                              |
| Gaming        | `games` `gamestore`                                                        |
| System        | `settings` `audio-mixer` `utils` `calculator` `viewer` `wallpaper` `notif` |

**Behavior tags** — describe how a window should behave (orthogonal to category):
`pip` `auth-dialog` `file-dialog` `no-steal-focus` `suppress-activate`

**Helper window tags** — keyed by `$H_*` variables from `bootstrap/const.conf`:
`$H_Cheat` `$H_Settings` `keybindings`

**Architecture**: Tag-driven rule system decouples classification from behavior. See [DESIGN_PRINCIPLES.md § Tag-Driven System](DESIGN_PRINCIPLES.md#tag-driven-window-management-system) and [PIPELINE_ARCHITECTURE.md § Stage 5](PIPELINE_ARCHITECTURE.md#stage-5-window-management-rule-compilation).

---

## Adding a New App

1. Add to `user/tags.conf`:
   ```bash
   windowrule = match:class ^(AppClass)$, tag +tagname
   ```
2. Add rules to `user/rules.conf`:
   ```bash
   windowrule = float on,  match:tag tagname
   windowrule = center on, match:tag tagname
   ```
3. Do not add direct `match:class` rules to `sys/rules.conf` unless a compound condition is required.

**Full Documentation**: [PIPELINE_ARCHITECTURE.md § Tag System](PIPELINE_ARCHITECTURE.md#tag-system-architecture)

---

## Adding a User Keybind

Edit `user/keybind.conf`. To remap an existing bind, unbind it first:

```bash
unbind = SUPER, Return, Open terminal, exec, $M_terminal
bindd  = SUPER, Return, Open terminal, exec, ghostty
```

---

## Overriding Constants

Edit `user/const.conf`. Changes take effect on next Hyprland reload.

```bash
$M_terminal     = ghostty
$M_file_manager = thunar
$W              = $HOME/Pictures/my-wallpapers
$Search_Engine  = "https://google.com/search?q={}"
```

**Critical**: `user/const.conf` loads in Stage 0, so overrides are available everywhere.

---

## Script Constant Resolution

Scripts that read Hyprland `$variables` at runtime (outside the Hyprland process) cannot use the Hyprland variable system directly. They implement the same incremental-override pattern as the config pipeline by parsing conf files in order:

```bash
user/const.conf  →  sys/const.conf  →  hard-coded fallback
```

`RofiSearch.sh` applies this pattern for `$Search_Engine`:

1. Reads `user/const.conf` — user override wins if present.
2. Falls back to `sys/const.conf` — system default.
3. Falls back to `https://www.google.com/search?q={}` — last resort.

This mirrors the **Dependency Inversion Principle**: the script depends on the abstraction (`$Search_Engine`), not on a specific file location.

**Full Documentation**: [DESIGN_PRINCIPLES.md § Dependency Inversion](DESIGN_PRINCIPLES.md#dependency-inversion--incremental-override-pattern)

---

## Environment Variables for Scripts

Scripts read these env vars (set in `user/env.conf`):

| Variable             | Default                 | Used by                                                          |
| -------------------- | ----------------------- | ---------------------------------------------------------------- |
| `HYPR_TERMINAL`      | `kitty`                 | WallpaperSelect, WallpaperEffects, sddm_wallpaper, WaybarScripts |
| `HYPR_WALLPAPER_DIR` | `~/Pictures/wallpapers` | WallpaperSelect, WallpaperRandom                                 |
| `HYPR_FILE_MANAGER`  | `nemo`                  | WaybarScripts                                                    |

---

## Process Lifecycle Notes

- `hypridle` — runs in its own process; config path and notification icon paths must be absolute (`~/.config/hypr/sys/hypridle.conf`, `~/.config/hypr/icon.png`)
- `hyprsunset` — runs in its own process; state persisted in `~/.cache/.hyprsunset_state`
- `swww-daemon` — started by `sys/startup.conf`; wallpaper path cached in `~/.cache/swww/`
- `waybar` / `swaync` — restarted by `Refresh.sh`; theme-only refresh via `RefreshNoWaybar.sh`

**Full Documentation**: [STATE_MACHINES.md § State Persistence](STATE_MACHINES.md#state-persistence-strategies)

---

## State Machines (Quick Reference)

Three explicit state machines manage runtime behavior:

### 1. Layout Engine

- **States**: `scrolling` ↔ `dwindle` ↔ `master`
- **Trigger**: `SUPER+ALT+L`
- **State Storage**: Hyprland internal (`general:layout`)
- **Script**: `ChangeLayout.sh`

### 2. Game Mode

- **States**: `NORMAL` ↔ `GAMING`
- **Trigger**: `SUPER+SHIFT+G`
- **State Storage**: Hyprland internal (`animations:enabled`)
- **Script**: `GameMode.sh`
- **Effect**: Disables animations/blur/shadows/gaps for gaming performance

### 3. Night Light

- **States**: `OFF` ↔ `ON (@4500K)`
- **Trigger**: `SUPER+N`
- **State Storage**: File-based (`~/.cache/.hyprsunset_state`)
- **Script**: `Hyprsunset.sh`
- **Effect**: Reduces blue light for eye comfort

**Full Documentation**: [STATE_MACHINES.md](STATE_MACHINES.md)

---

## Common Tasks

### Change Terminal

```bash
# user/const.conf
$M_terminal = ghostty
```

### Add HiDPI Support

```bash
# user/env.conf
env = GDK_SCALE, 1.5
env = QT_SCALE_FACTOR, 1.5
```

### Enable NVIDIA

```bash
# user/env.conf
env = LIBVA_DRIVER_NAME, nvidia
env = __GLX_VENDOR_LIBRARY_NAME, nvidia
env = NVD_BACKEND, direct
```

### Switch Layout Startup Default

```bash
# user/layout.conf
general { layout = dwindle }
```

### Add Custom Keybind

```bash
# user/keybind.conf
bindd = $M, Z, My custom app, exec, myapp
```

### Add Window Rule

```bash
# user/tags.conf
windowrule = match:class ^(signal)$, tag +im

# user/rules.conf
windowrule = float on, match:tag signal
windowrule = center on, match:tag signal
```

---

## Debugging

### Check Current Layout

```bash
hyprctl getoption general:layout
```

### Check Active Binds

```bash
hyprctl binds | grep super
```

### Validate Tag Completeness

```bash
# Extract defined tags
grep 'tag +' sys/tags.conf | sed 's/.*tag +//' | sort -u > /tmp/defined

# Extract used tags
grep 'match:tag' sys/rules.conf | sed 's/.*match:tag //' | sort -u > /tmp/used

# Find orphaned tags
diff /tmp/defined /tmp/used
```

### Inspect Loaded Config

```bash
hyprctl config
```

---

## Performance Tips

1. **Enable VFR** (Variable Frame Rate):

   ```bash
   # user/misc.conf
   misc { vfr = true }
   ```

2. **Reduce Blur Passes**:

   ```bash
   # user/decoration.conf
   decoration {
       blur { passes = 2 }  # Not 4+
   }
   ```

3. **Use Game Mode** for GPU-intensive tasks:
   ```bash
   SUPER+SHIFT+G  # Toggle
   ```

---

## Further Reading

**Essential**:

- [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md) — Understand the "why" behind the architecture
- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) — Deep dive into the 5-stage pipeline
- [STATE_MACHINES.md](STATE_MACHINES.md) — Formal state machine definitions and implementations

**Reference**:

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Hyprland IPC Documentation](https://wiki.hyprland.org/IPC/)
- [Compiler Design Theory](https://en.wikipedia.org/wiki/Compiler)
- [Design Patterns Catalog](https://refactoring.guru/design-patterns/)
