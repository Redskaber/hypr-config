---
inclusion: always
---

# Architecture Overview

This is a layered, pipeline-driven Hyprland configuration for Hyprland ≥ 0.52.1.
All edits should respect the layer boundaries described below.

## Pipeline

```
hyprland.conf                          (single entry point — no logic)
  └── bootstrap/default.conf
        ├── Stage 0: bootstrap/const.conf      (path/variable constants)
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

## Layer Responsibilities

| Layer     | Path                    | Responsibility                                        |
| --------- | ----------------------- | ----------------------------------------------------- |
| Bootstrap | `bootstrap/`            | Path constants, variable definitions, pipeline entry  |
| System    | `sys/`                  | Vendor defaults — never edit directly                 |
| Hardware  | `sys/hardware/`         | Monitor, laptop keys, workspace rules                 |
| Policy    | `sys/policy/`           | Swappable runtime policies (colors, animations)       |
| Scripts   | `sys/scripts/`          | Runtime scripts; user scripts in `user/scripts/`      |
| User      | `user/`                 | All user customizations — edit only these             |

## Design Principles

**Single entry point** — `hyprland.conf` only sources `bootstrap/default.conf`. No logic.

**Incremental override** — every `sys/X.conf` is immediately followed by `user/X.conf`. User files only contain differences.

**Dependency direction** — constants flow downward only. `user/const.conf` is sourced in Stage 0 (bootstrap), before `sys/default.conf`, so user variable overrides are available throughout the entire pipeline.

**Policy layer** — wallust colors must be sourced before `sys/decoration.conf`. The pipeline in `sys/default.conf` guarantees this: `policy/default.conf` is sourced before the rendering section.

**Tag-driven rules** — `sys/tags.conf` is the single source of truth for all window tags. `sys/rules.conf` consumes only tags. Direct `match:class` in rules is only permitted for compound conditions that the tag system cannot express (e.g., `class + negative:title`).

**State machines** — runtime state (game mode, layout, night light) is managed by scripts with explicit state-transition functions. State is read from `hyprctl getoption` or a cache file, never from implicit side effects.

**Process lifecycle** — any daemon that runs in its own process context (hypridle, hyprsunset) must use absolute paths for config files and notification icons, since Hyprland `$variables` are not available in child process environments.

## Layout State Machine

Three layouts are supported. `ChangeLayout.sh` implements an explicit three-state cycle:

```
scrolling  ──►  dwindle  ──►  master  ──►  scrolling  ──► …
```

Each transition atomically manages three keybinds:

| Layout | `SUPER+J/K` | `SUPER+O` | Notes |
|--------|-------------|-----------|-------|
| `scrolling` | unbound | unbound | hyprscrolling plugin owns column navigation |
| `dwindle` | `cyclenext` / `cyclenext,prev` | `togglesplit` | |
| `master` | `cyclenext` / `cyclenext,prev` | unbound | |

`KeybindsLayoutInit.sh` runs at startup and applies the same bind logic based on the current layout (which may be `scrolling` if set in `user/layout.conf`).

`sys/layout.conf` provides:
- sys-level default layout: `dwindle` (functional without hyprscrolling plugin)
- `plugin:hyprscrolling {}` defaults (correct plugin config block name)
- `dwindle {}`, `master {}`, `binds {}` configuration

`user/layout.conf` sets the startup layout (default: `scrolling`).

### hyprscrolling Plugin Config

Plugin: `hyprwm/hyprland-plugins/hyprscrolling` — install via `hyprpm`.

Config block: `plugin:hyprscrolling` in `sys/layout.conf` (override in `user/layout.conf`).

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `column_width` | float [0-1] | `0.5` | Default column width as fraction of monitor width |
| `fullscreen_on_one_column` | bool | `false` | Make single column fullscreen |
| `explicit_column_widths` | string | `0.333, 0.5, 0.667, 1.0` | Widths for `+conf`/`-conf` cycling |
| `focus_fit_method` | int (0\|1) | `0` | 0=center, 1=fit when focusing a column |
| `follow_focus` | bool | `true` | Move layout to make focused window visible |
| `follow_debounce_ms` | int | `0` | Debounce time for focus events |

### hyprscrolling layoutmsg Commands

Available via `hyprctl dispatch layoutmsg <cmd>` or keybinds:

| Command | Description |
|---------|-------------|
| `move +col` / `move -col` | Move layout by one column |
| `move +200` / `move -200` | Move layout by logical px |
| `colresize 0.5` / `colresize +0.2` | Resize current column |
| `colresize +conf` / `colresize -conf` | Cycle through `explicit_column_widths` |
| `colresize all 0.5` | Resize all columns to a specific width |
| `movewindowto r/l/u/d` | Move window to adjacent column (promotes at edge) |
| `fit active` | Fit active column into view |
| `fit visible` | Fit all visible columns |
| `fit all` / `fit toend` / `fit tobeg` | Other fit modes |
| `focus r/l/u/d` | Move focus with wrapping (no monitor switch) |
| `promote` | Move window to its own new column |
| `swapcol l` / `swapcol r` | Swap current column with neighbor (wraps) |
| `movecoltoworkspace 2` | Move entire column to workspace |
| `togglefit` | Toggle `focus_fit_method` (center ↔ fit) |

## Hardware Layer

`sys/hardware/default.conf` aggregates three hardware files:

```
sys/hardware/default.conf
  ├── laptop.conf          — laptop keys, touchpad device, ASUS ROG binds, lid switch
  ├── monitors.conf        — monitor configuration (managed by nwg-displays)
  └── workspaces.conf      — workspace → monitor assignment
```

`sys/hardware/laptop-display.conf` is written by lid-switch rules and controls eDP-1 state.

## Policy Layer

`sys/policy/default.conf` aggregates two policy files:

```
sys/policy/default.conf
  ├── wallust/wallust-hyprland.conf   — $colorN variables (auto-generated by wallust)
  └── animations/default.conf        — active animation preset
```

Animation presets in `sys/policy/animations/`: `default` `disable` `end4` `hyde-optimized` `hyde-vertical` `ml4w-fast`

Switch at runtime with `SUPER+SHIFT+A` (Animations.sh).

## Tag Registry

All tags are defined in `sys/tags.conf`. The tag system is fully symmetric:
every registered tag has at least one rule in `sys/rules.conf`, and every rule references a registered tag.

Tags are grouped into three categories:

**Category tags** — describe what an app is (27 total):

| Group | Tags |
|-------|------|
| Web | `browser` |
| Productivity | `terminal` `projects` `email` `text-editor` |
| Communication | `im` |
| Files | `file-manager` |
| Media | `multimedia` `multimedia-video` `screenshare` |
| Gaming | `games` `gamestore` |
| System | `settings` `audio-mixer` `utils` `calculator` `viewer` `wallpaper` `notif` |

**Behavior tags** — describe how a window should behave (orthogonal to category):
`pip` `auth-dialog` `file-dialog` `no-steal-focus` `suppress-activate`

**Helper window tags** — keyed by `$H_*` variables from `bootstrap/const.conf`:
`$H_Cheat` `$H_Settings` `keybindings`

## Adding a New App

1. Add to `user/tags.conf`:
   ```ini
   windowrule = match:class ^(AppClass)$, tag +tagname
   ```
2. Add rules to `user/rules.conf`:
   ```ini
   windowrule = float on,  match:tag tagname
   windowrule = center on, match:tag tagname
   ```
3. Do not add direct `match:class` rules to `sys/rules.conf` unless a compound condition is required.

## Adding a User Keybind

Edit `user/keybind.conf`. To remap an existing bind, unbind it first:

```ini
unbind = SUPER, Return, Open terminal, exec, $M_terminal
bindd  = SUPER, Return, Open terminal, exec, ghostty
```

## Overriding Constants

Edit `user/const.conf`. Changes take effect on next Hyprland reload.

```ini
$M_terminal     = ghostty
$M_file_manager = thunar
$W              = $HOME/Pictures/my-wallpapers
$Search_Engine  = "https://google.com/search?q={}"
```

## Environment Variables for Scripts

Scripts read these env vars (set in `user/env.conf`):

| Variable             | Default                 | Used by                                                           |
| -------------------- | ----------------------- | ----------------------------------------------------------------- |
| `HYPR_TERMINAL`      | `kitty`                 | WallpaperSelect, WallpaperEffects, sddm_wallpaper, WaybarScripts  |
| `HYPR_WALLPAPER_DIR` | `~/Pictures/wallpapers` | WallpaperSelect, WallpaperRandom                                  |
| `HYPR_FILE_MANAGER`  | `nemo`                  | WaybarScripts                                                     |

## Process Lifecycle Notes

- `hypridle` — runs in its own process; config path and notification icon paths must be absolute (`~/.config/hypr/sys/hypridle.conf`, `~/.config/hypr/icon.png`)
- `hyprsunset` — runs in its own process; state persisted in `~/.cache/.hyprsunset_state`
- `swww-daemon` — started by `sys/startup.conf`; wallpaper path cached in `~/.cache/swww/`
- `waybar` / `swaync` — restarted by `Refresh.sh`; theme-only refresh via `RefreshNoWaybar.sh`
