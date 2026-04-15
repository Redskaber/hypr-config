---
inclusion: always
---

# Architecture Overview

This is a layered, pipeline-driven Hyprland configuration. All edits should respect the layer boundaries described below.

## Pipeline

```
hyprland.conf
  └── bootstrap/default.conf
        ├── Stage 0: bootstrap/const.conf      (path/variable constants)
        ├── Stage 0: user/const.conf           (user constant overrides)
        └── Stage 1: sys/default.conf          (system pipeline)
              ├── sys/hardware/laptop.conf
              ├── sys/hardware/monitors.conf
              ├── sys/policy/default.conf       (wallust colors → animations)
              ├── sys/env.conf  →  user/env.conf
              ├── sys/misc.conf  →  user/misc.conf
              ├── sys/input.conf  →  user/input.conf
              ├── sys/layout.conf  →  user/layout.conf
              ├── sys/decoration.conf  →  user/decoration.conf
              ├── sys/render.conf  →  user/render.conf
              ├── sys/startup.conf  →  user/startup.conf
              ├── sys/keybind.conf  →  user/keybind.conf
              ├── sys/tags.conf  →  user/tags.conf
              └── sys/rules.conf  →  user/rules.conf
```

Source order = override priority: **later wins**.

## Layer Responsibilities

| Layer     | Path            | Responsibility                                       |
| --------- | --------------- | ---------------------------------------------------- |
| Bootstrap | `bootstrap/`    | Path constants, variable definitions, pipeline entry |
| System    | `sys/`          | Vendor defaults — never edit directly                |
| Policy    | `sys/policy/`   | Swappable runtime policies (colors, animations)      |
| User      | `user/`         | All user customizations — edit only these            |
| Hardware  | `sys/hardware/` | Monitor, laptop, workspace rules                     |
| Scripts   | `sys/scripts/`  | Runtime scripts; user scripts in `user/scripts/`     |

## Design Principles

**Single entry point** — `hyprland.conf` only sources `bootstrap/default.conf`. No logic.

**Incremental override** — every `sys/X.conf` is immediately followed by `user/X.conf`. User files only contain differences.

**Dependency direction** — constants flow downward only. `user/const.conf` is sourced in Stage 0 (bootstrap), before `sys/default.conf`, so user variable overrides are available throughout the entire pipeline.

**Policy layer** — wallust colors must be sourced before `sys/decoration.conf`. The pipeline in `sys/default.conf` guarantees this: `policy/default.conf` is sourced before the rendering section.

**Tag-driven rules** — `sys/tags.conf` is the single source of truth for all window tags. `sys/rules.conf` consumes only tags. Direct `match:class` in rules is only permitted for compound conditions that the tag system cannot express (e.g., `class + negative:title`).

**State machines** — runtime state (game mode, layout, night light) is managed by scripts with explicit on/off functions. State is read from `hyprctl getoption` or a cache file, never from implicit side effects.

**Process lifecycle** — any daemon that runs in its own process context (hypridle, hyprsunset) must use absolute paths for config files, since Hyprland `$variables` are not available in child process environments.

## Adding a New App

1. Add a `windowrule = match:class ^(appname)$, tag +tagname` line to `sys/tags.conf` (or `user/tags.conf` for personal apps).
2. If the tag is new, add corresponding rules to `sys/rules.conf` (or `user/rules.conf`).
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
```

## Environment Variables for Scripts

Scripts read these env vars (set in `user/env.conf`):

| Variable             | Default                 | Used by                                                          |
| -------------------- | ----------------------- | ---------------------------------------------------------------- |
| `HYPR_TERMINAL`      | `kitty`                 | WallpaperSelect, WallpaperEffects, sddm_wallpaper, WaybarScripts |
| `HYPR_WALLPAPER_DIR` | `~/Pictures/wallpapers` | WallpaperSelect, WallpaperRandom                                 |
| `HYPR_FILE_MANAGER`  | `nemo`                  | WaybarScripts                                                    |

## Tag Registry

All tags are defined in `sys/tags.conf`. The tag system is fully symmetric: every registered tag has at least one rule in `sys/rules.conf`, and every rule references a registered tag.

Current tags: `browser` `terminal` `im` `projects` `email` `file-manager` `multimedia` `multimedia_video` `screenshare` `games` `gamestore` `settings` `audio-mixer` `utils` `text-editor` `misc-apps` `viewer` `wallpaper` `notif` `$H_Cheat` `$H_Settings` `keybindings` `auth-dialog` `pip` `file-dialog` `no-steal-focus` `suppress-activate`
