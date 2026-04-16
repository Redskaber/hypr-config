# Hyprland Dotfiles

A layered, pipeline-driven Hyprland configuration for Hyprland ≥ 0.52.1.

## Quick Start

```bash
git clone <repo> ~/.config/hypr
# Edit user/const.conf — set your terminal, file manager, wallpaper dir
# Edit user/env.conf  — HiDPI, NVIDIA, custom env vars
# Launch Hyprland
```

## Directory Structure

```
~/.config/hypr/
├── hyprland.conf              # single entry point — sources bootstrap only
├── icon.png                   # notification icon used by hypridle
├── bootstrap/
│   ├── const.conf             # all path/variable constants ($M, $S, $H, $P …)
│   └── default.conf           # pipeline: Stage 0 constants → Stage 1 sys
├── sys/                       # system defaults — do not edit directly
│   ├── default.conf           # sys pipeline (each sys/* paired with user/*)
│   ├── env.conf               # wayland / qt / app environment variables
│   ├── misc.conf              # misc hyprland options
│   ├── input.conf             # keyboard, touchpad, gestures
│   ├── layout.conf            # dwindle / master / scrolling (hyprscrolling)
│   ├── decoration.conf        # colors, blur, shadow, opacity (needs $colorN)
│   ├── render.conf            # render pipeline, xwayland, cursor
│   ├── startup.conf           # exec-once services
│   ├── keybind.conf           # canonical keybind table
│   ├── tags.conf              # unified window tag registry
│   ├── rules.conf             # tag-driven window & layer rules
│   ├── hypridle.conf          # idle / lock timeouts (absolute paths only)
│   ├── hardware/
│   │   ├── default.conf       # hardware aggregator (laptop + monitors + workspaces)
│   │   ├── laptop.conf        # laptop keys, touchpad, ASUS ROG binds
│   │   ├── laptop-display.conf# lid-switch display state
│   │   ├── monitors.conf      # monitor configuration
│   │   └── workspaces.conf    # workspace → monitor assignment
│   ├── policy/
│   │   ├── default.conf       # policy aggregator (wallust colors → animations)
│   │   ├── wallust/           # wallust-generated color variables
│   │   └── animations/        # animation presets (default, disable, end4 …)
│   └── scripts/               # runtime scripts (~55 scripts)
└── user/                      # your overrides — edit only these
    ├── const.conf             # override $M_terminal, $W, $Search_Engine, etc.
    ├── env.conf               # override / add env vars (NVIDIA, HiDPI, EDITOR …)
    ├── misc.conf              # override misc options (vfr, vrr, swallow …)
    ├── input.conf             # override keyboard layout, sensitivity
    ├── layout.conf            # startup layout + gap / scroller overrides
    ├── decoration.conf        # override colors, blur, rounding
    ├── render.conf            # override render / cursor settings
    ├── startup.conf           # add exec-once services
    ├── keybind.conf           # add / override keybinds
    ├── tags.conf              # add window tags
    └── rules.conf             # add window rules
```

## Pipeline

```
hyprland.conf
  └── bootstrap/default.conf
        ├── Stage 0: bootstrap/const.conf   (constants)
        ├── Stage 0: user/const.conf        (user constant overrides)
        └── Stage 1: sys/default.conf
              ├── sys/hardware/default.conf → laptop + monitors + workspaces
              ├── sys/policy/default.conf   → wallust colors + animations
              ├── sys/env.conf    → user/env.conf
              ├── sys/misc.conf   → user/misc.conf
              ├── sys/input.conf  → user/input.conf
              ├── sys/layout.conf → user/layout.conf
              ├── sys/decoration.conf → user/decoration.conf
              ├── sys/render.conf → user/render.conf
              ├── sys/startup.conf → user/startup.conf
              ├── sys/keybind.conf → user/keybind.conf
              ├── sys/tags.conf   → user/tags.conf
              └── sys/rules.conf  → user/rules.conf
```

Source order = override priority: **later wins**.

## User Customization

Every `sys/` file has a paired `user/` override. Edit only the `user/` files.

**Common overrides:**

```ini
# user/const.conf
$M_terminal     = ghostty
$M_file_manager = thunar
$W              = $HOME/Pictures/my-wallpapers
$Search_Engine  = "https://google.com/search?q={}"

# user/env.conf
env = EDITOR,              nvim
env = HYPR_TERMINAL,       ghostty       # used by wallpaper/waybar scripts
env = HYPR_WALLPAPER_DIR,  /path/to/wallpapers
env = HYPR_FILE_MANAGER,   thunar        # used by WaybarScripts.sh
env = GDK_SCALE,           1.5           # HiDPI
env = QT_SCALE_FACTOR,     1.5

# user/layout.conf — startup layout (scrolling requires hyprscrolling plugin)
general { layout = dwindle }

# user/input.conf
input { kb_layout = us,cn }

# user/misc.conf
misc { vfr = true }   # variable frame rate (power saving)
```

## Layout System

Three layouts are supported, cycled at runtime with `SUPER+ALT+L`:

```
scrolling  →  dwindle  →  master  →  scrolling  → …
```

| Layout | Description | `SUPER+J/K` | `SUPER+O` |
|--------|-------------|-------------|-----------|
| `scrolling` | hyprscrolling plugin (column-based) | plugin-owned (column nav) | unbound |
| `dwindle` | binary space partitioning | `cyclenext` / `cyclenext,prev` | `togglesplit` |
| `master` | master-stack | `cyclenext` / `cyclenext,prev` | unbound |

The startup layout is set in `user/layout.conf` (default: `scrolling`).
The sys-level default is `dwindle` so the config works without the plugin.

`sys/layout.conf` provides `plugin:hyprscrolling {}` defaults for hyprscrolling.

### hyprscrolling Keybinds

| Key | Action |
|-----|--------|
| `SUPER + .` | Move column right |
| `SUPER + ,` | Move column left |
| `SUPER + SHIFT + .` | Move window to right column |
| `SUPER + SHIFT + ,` | Move window to left column |
| `SUPER + SHIFT + ↑/↓` | Move window up/down |
| `SUPER + ]` | Resize column wider (+0.1) |
| `SUPER + [` | Resize column narrower (-0.1) |
| `SUPER + CTRL + ]` | Cycle column width up (`+conf`) |
| `SUPER + CTRL + [` | Cycle column width down (`-conf`) |
| `SUPER + ALT + F` | Fit active column into view |
| `SUPER + ALT + SHIFT + F` | Fit all visible columns |
| `SUPER + CTRL + ,` | Swap column left |
| `SUPER + CTRL + .` | Swap column right |
| `SUPER + '` | Promote window to its own column |
| `SUPER + CTRL + T` | Toggle fit method (center ↔ fit) |

Override `plugin:hyprscrolling` defaults in `user/layout.conf`.

## Keybinds

| Key | Action |
|-----|--------|
| `SUPER + H` | Cheat sheet |
| `SUPER + SHIFT + K` | Search keybinds |
| `SUPER + SHIFT + E` | Quick settings menu |
| `SUPER + D` | App launcher (rofi) |
| `SUPER + Return` | Terminal |
| `SUPER + W` | Wallpaper selector |
| `SUPER + ALT + L` | Cycle layout (scrolling → dwindle → master → scrolling) |
| `SUPER + J / K` | Cycle windows (dwindle/master) · column nav (scrolling) |
| `SUPER + O` | Toggle split (dwindle only) |
| `SUPER + SHIFT + G` | Toggle game mode |
| `SUPER + N` | Toggle night light |
| `SUPER + ALT + R` | Refresh waybar + swaync |

See `sys/keybind.conf` for the full table, or press `SUPER + SHIFT + K` at runtime.

## Scripts

All scripts live in `sys/scripts/`. User-specific scripts go in `user/scripts/`.

| Script | Trigger | Purpose |
|--------|---------|---------|
| `ChangeLayout.sh` | `SUPER+ALT+L` | Three-state layout cycle; manages J/K and O binds |
| `KeybindsLayoutInit.sh` | startup | Initialize layout-aware binds based on current layout |
| `GameMode.sh` | `SUPER+SHIFT+G` | Toggle animations/blur/gaps off for gaming |
| `WallpaperSelect.sh` | `SUPER+W` | Pick wallpaper + apply wallust colors |
| `Animations.sh` | `SUPER+SHIFT+A` | Switch animation preset |
| `DarkLight.sh` | Quick Settings | Toggle dark/light theme system-wide |
| `Refresh.sh` | `SUPER+ALT+R` | Restart waybar + swaync |
| `RefreshNoWaybar.sh` | wallpaper change | Refresh theme without restarting waybar |
| `Hyprsunset.sh` | `SUPER+N` | Toggle night light (state persists across sessions) |
| `Hypridle.sh` | waybar module | Toggle hypridle on/off |
| `Quick_Settings.sh` | `SUPER+SHIFT+E` | Open user config files in editor |

## Policies

Swappable at runtime without reloading the full config:

- **Animations** — presets in `sys/policy/animations/`: `default` `disable` `end4` `hyde-optimized` `hyde-vertical` `ml4w-fast`
- **Colors** — generated by wallust into `sys/policy/wallust/wallust-hyprland.conf` on wallpaper change

## Window Tags

Tags are defined in `sys/tags.conf` and consumed by `sys/rules.conf`.
Add personal app tags in `user/tags.conf` with matching rules in `user/rules.conf`.

**Category tags** (what an app is):
`browser` `terminal` `im` `email` `projects` `file-manager` `multimedia` `multimedia-video` `screenshare` `games` `gamestore` `viewer` `text-editor` `utils` `calculator` `settings` `audio-mixer` `wallpaper` `notif`

**Behavior tags** (how a window behaves):
`pip` `auth-dialog` `file-dialog` `no-steal-focus` `suppress-activate`

**Helper tags**: `$H_Cheat` `$H_Settings` `keybindings`

## Dependencies

**Required:** `hyprland` `hyprlock` `hypridle` `swww` `waybar` `swaync` `rofi-wayland` `cliphist` `wl-clipboard` `grim` `slurp` `pamixer` `playerctl` `brightnessctl` `nm-applet` `wallust` `jq`

**Optional:** `hyprscrolling` (scrolling layout, install via hyprpm) · `mpvpaper` (live wallpapers) · `fcitx5` (input method) · `nwg-displays` (monitor config GUI) · `kvantummanager` (Qt theming) · `qs` / `quickshell` (overview widget) · `swappy` (screenshot annotation)
