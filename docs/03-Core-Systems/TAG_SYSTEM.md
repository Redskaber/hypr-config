# Tag-Driven Window Management System

> Pure `.lua` config (Hyprland v0.55+). All examples below are verified against
> the actual code in [`sys/tags.lua`](../../sys/tags.lua) and
> [`sys/rules.lua`](../../sys/rules.lua), and against the
> [official Hyprland Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/).

## Overview

This configuration implements a **tag-driven window management system** that
decouples window classification (WHAT an app IS) from window behavior
(HOW it should behave). This architecture applies the **Strategy design pattern**
and **Single Responsibility Principle** to window rule management.

```
sys/tags.lua   ← classify (WHAT)   → assigns tags to windows
sys/rules.lua   ← apply behavior (HOW) → applies effects based on tag
```

---

## Architecture

### Why Tags (vs Direct Class Matching)

Traditional configs repeat class regexes in every rule:

```lua
-- BAD: scattered, hard to maintain
hl.window_rule({ float = true,   match = { class = "^(firefox)$" } })
hl.window_rule({ opacity = "0.9", match = { class = "^(firefox)$" } })
hl.window_rule({ float = true,   match = { class = "^(discord)$" } })
hl.window_rule({ center = true,  match = { class = "^(discord)$" } })
```

Problems: no SSOT, rules scattered, hard to audit, violates DRY.

This config separates concerns:

```lua
-- sys/tags.lua — STEP 1: classify apps (run once at config load)
hl.window_rule({ match = { class = "^([Ff]irefox)$" }, tag = "browser" })
hl.window_rule({ match = { class = "^([Dd]iscord)$" }, tag = "im" })

-- sys/rules.lua — STEP 2: define behavior (referenced by tag)
hl.window_rule({ opacity = "1.00 0.85", match = { tag = "browser" } })
hl.window_rule({ float = true,          match = { tag = "im" } })
hl.window_rule({ center = true,         match = { tag = "im" } })
```

Benefits: SSOT, rules grouped by category, easy to add new apps (tag + inherit), Open/Closed Principle.

### Design Patterns Applied

| Pattern | Application |
| --- | --- |
| **Strategy** | Each tag is a "behavior strategy" — `browser` strategy is tiled + opaque |
| **Single Responsibility** | `tags.lua` classifies, `rules.lua` applies effects |
| **Template Method** | All apps with the same tag follow the same rule template |
| **Registry** | `tags.lua` is the registry of known app classes |
| **Open/Closed** | User extends via `user/tags.lua` + `user/rules.lua` without modifying `sys/` |

---

## Tag Taxonomy

This config defines **26 tags** in [`sys/tags.lua`](../../sys/tags.lua):

### Category Tags (20) — "What an app IS"

| Tag | Apps | Default behavior (from `rules.lua`) |
| --- | --- | --- |
| `browser` | Firefox, Chrome, Chromium, Edge, Brave, Zen, Qutebrowser | tiled, opacity `1.00 0.85`, idle_inhibit fullscreen |
| `terminal` | kitty, alacritty, wezterm, foot, ghostty | tiled, opacity `0.90 0.80` |
| `im` | Discord, Telegram, WhatsApp, Element, Slack | float + center + size `{monitor_w*0.60, monitor_h*0.70}` + opacity `0.94 0.86` |
| `email` | Thunderbird, Evolution, Betterbird | tiled, opacity `0.95 0.88` |
| `projects` | VSCode, VSCodium, JetBrains IDEs | tiled, opacity `0.98 0.90` |
| `notes` | Obsidian, Logseq, Gnote | float + center + size `{monitor_w*0.55, monitor_h*0.80}` + opacity `0.98 0.90` |
| `file-manager` | Thunar, Nautilus, nemo, pcmanfm-qt, Warp | float + center + size `{monitor_w*0.70, monitor_h*0.75}` + opacity `0.92 0.82` |
| `multimedia` | Audacious, ncspot, listen1, lx-music-desktop | tiled, opacity `0.94 0.86` |
| `multimedia-video` | mpv, VLC, Clapper | float + opacity `1.0` + no_blur + idle_inhibit always |
| `screenshare` | OBS, easyeffects | float + opacity `1.0` + no_blur + idle_inhibit always |
| `games` | gamescope, steam_app_NNNN, prismlauncher | no_blur + rounding 0 + idle_inhibit always |
| `gamestore` | Steam, Lutris, Heroic | float + center + size `{monitor_w*0.65, monitor_h*0.80}` |
| `viewer` | evince, eog, gnome-system-monitor, MissionCenter | float + center + size `{monitor_w*0.70, monitor_h*0.75}` + opacity `0.85 0.75` |
| `text-editor` | gnome-texteditor, mousepad, gedit, xed, kate | float + center + size `{monitor_w*0.65, monitor_h*0.75}` + opacity `0.95 0.85` |
| `utils` | rbw, seahorse, clash-verge, qbittorrent, virt-manager, fcitx5, deluge, transmission | float + center + size `{monitor_w*0.65, monitor_h*0.75}` + opacity `0.92 0.82` |
| `calculator` | gnome-calculator, qalculate, galculator | float + center + size `480 640` |
| `settings` | nm-applet, qt5ct/qt6ct, baobab, gnome-disks, file-roller, polkit-kde, nwg-displays, xdg-desktop-portal-gtk + (title "Settings/Preferences/Configuration") | float + center + size `{monitor_w*0.60, monitor_h*0.70}` + opacity `0.95 0.85` |
| `audio-mixer` | pavucontrol, pwvucontrol | float + center + size `900 600` + opacity `0.95 0.85` |
| `wallpaper` | waytrogen, waypaper | float + center + size `{monitor_w*0.70, monitor_h*0.70}` + opacity `0.95 0.85` |
| `notif` | swaync | float |

### Behavior Tags (6) — "How a window behaves"

| Tag | Match | Effect |
| --- | --- | --- |
| `pip` | title `^(Picture-in-Picture|Picture in Picture)$` | float + move `{monitor_w*0.72, monitor_h*0.07}` + pin + opacity `0.95 0.75` + dim_around |
| `auth-dialog` | title `^(Authentication Required\|Password Required\|Polkit)$` | float + center + size `{monitor_w*0.35, monitor_h*0.25}` |
| `file-dialog` | title `^(Open File\|Open Files\|Save File\|Select Folder\|Open Folder)$` | float + center + size `{monitor_w*0.65, monitor_h*0.65}` |
| `no-steal-focus` | class `^(wechat\|qq)$`, `^(jetbrains-.+)$`, OR `modal = true` | `no_initial_focus = true` |
| `suppress-activate` | class `^(vesktop)$` | `suppress_event = "activate"` |

### Helper Tags (2)

| Tag | Match | Effect |
| --- | --- | --- |
| `Help_Cheat` | title `^(Quick Cheat Sheet)$` | float + center + size `{monitor_w*0.65, monitor_h*0.90}` + opacity `0.85 0.85` |
| `Help_Settings` | title `^(Hyprland Settings)$` | float + center + size `{monitor_w*0.65, monitor_h*0.80}` |
| `keybindings` | title `^(Keybindings\|Search Keybinds)$` | float + center + size `{monitor_w*0.65, monitor_h*0.80}` |

---

## API Reference (verified against Hyprland 0.55+ wiki)

### `hl.window_rule({ match = {...}, effect = value, ... })`

Rules are split into **props** (inside the `match` table) and **effects** (top-level keys).
All props must match for a rule to apply.

#### Props (`match` table fields)

| Field | Type | Description |
| --- | --- | --- |
| `class` | RegEx | Match window class |
| `title` | RegEx | Match window title |
| `initial_class` | RegEx | Match initial class |
| `initial_title` | RegEx | Match initial title |
| `tag` | name | Match window with tag |
| `xwayland` | bool | Xwayland windows |
| `float` | bool | Floating windows |
| `fullscreen` | bool | Fullscreen windows |
| `pin` | bool | Pinned windows |
| `focus` | bool | Currently focused |
| `group` | bool | Grouped windows |
| `modal` | bool | Modal dialogs |
| `workspace` | workspace | On matching workspace (id, `"name:string"`, or selector) |
| `content` | string | `none`/`photo`/`video`/`game` |
| `xdg_tag` | RegEx | Match by xdgTag |

> ⚠️ Multiple props in the same `match = {...}` table are **AND**-combined.
> For OR logic, use multiple separate `hl.window_rule` calls.

#### Effects — Static (evaluated once on window open)

| Effect | Type | Description |
| --- | --- | --- |
| `float` | bool | Float the window |
| `tile` | bool | Tile the window |
| `fullscreen` | bool | Fullscreen |
| `maximize` | bool | Maximize |
| `move` | string/table | Move floating window. E.g. `{100, 200}` or `{"monitor_w * 0.5", "monitor_h * 0.5"}` |
| `size` | string/table | Resize floating window. E.g. `"800 600"` or `{"monitor_w * 0.5", "monitor_h * 0.5"}` |
| `center` | bool | Center on monitor (floating) |
| `monitor` | string | Open on monitor. E.g. `"1"` or `"DP-1"` (suffix `" silent"` allowed) |
| `workspace` | string | Open on workspace (`"name"`, `"unset"`, or suffix `" silent"`) |
| `pin` | bool | Pin (show on all workspaces). Requires `float = true` |
| `no_initial_focus` | bool | Disable initial focus |
| `group` | string | Group properties |
| `suppress_event` | string | Ignore events: `"fullscreen" "maximize" "activate" ...` |
| `content` | string | `none`/`photo`/`video`/`game` |
| `fullscreen_state` | string | E.g. `"1 2"` (internal client) |

#### Effects — Dynamic (re-evaluated on property change)

| Effect | Type | Description |
| --- | --- | --- |
| `opacity` | string | `"0.8"` / `"0.9 0.7"` (active inactive) / `"1.0 0.8 0.9"` (active inactive fullscreen) |
| `border_color` | gradient | `"rgb(FF0000)"` or `{colors={"...","..."}, angle=45}` |
| `border_size` | int | Border thickness |
| `rounding` | int | Forced rounding pixels |
| `rounding_power` | number | Override rounding power |
| `idle_inhibit` | string | `"none"` / `"always"` / `"focus"` / `"fullscreen"` |
| `no_blur` | bool | Disable blur |
| `no_dim` | bool | Disable dimming |
| `no_focus` | bool | Disable focus |
| `no_anim` | bool | Disable animations |
| `dim_around` | bool | Dim everything around |
| `keep_aspect_ratio` | — | ⚠️ **NOT a window_rule effect** — it's a `resize()` dispatcher param |
| `stay_focused` | bool | Force focus while visible |
| `persistent_size` | bool | Store size for reuse |
| `animation` | string | Force animation style (`"popin"`, `"popin 80%"`) |

#### Expression syntax (for `move`/`size`)

Space-separated expressions inside a Lua table:
```lua
size = { "monitor_w * 0.5", "monitor_h * 0.5" }
move = { "window_w * 0.5", "(monitor_h / 2) + 17" }
```

Variables (monitor-local):
- `monitor_w`, `monitor_h` — monitor dimensions
- `window_x`, `window_y`, `window_w`, `window_h` — window pos/size
- `cursor_x`, `cursor_y` — cursor position

### `hl.layer_rule({ match = { namespace = "..." }, effect = ... })`

Same syntax as `hl.window_rule`. Layer rules apply to layer-shell surfaces
(waybar, rofi, swaync, etc.).

#### Layer Props

| Field | Type | Description |
| --- | --- | --- |
| `namespace` | RegEx | Layer namespace (check with `hyprctl layers`) |

#### Layer Effects

| Effect | Type | Description |
| --- | --- | --- |
| `no_anim` | bool | Disable animations |
| `blur` | bool | Enable blur |
| `blur_popups` | bool | Enable blur for popups |
| `ignore_alpha` | number (0-1) | Blur ignores pixels with opacity ≤ value |
| `dim_around` | bool | Dim everything behind |
| `xray` | bool | Blur xray mode |
| `animation` | string | Animation style |
| `order` | int | Layer order (higher = closer to edge) |
| `above_lock` | int | Render above lockscreen (`2` = interactive on lock) |
| `no_screen_share` | bool | Hide from screen sharing |

---

## Implementation Details

### Rule Application Order (Hyprland wiki confirmed)

Hyprland applies rules in **source order** (top-to-bottom, file-by-file as `require`d):
```
1. sys/tags.lua    → windows get tagged
2. user/tags.lua   → user adds more tags (extends)
3. sys/rules.lua   → effects applied by tag
4. user/rules.lua  → user adds/overrides effects (later wins)
```

### Multiple Tags Per Window

A window can have multiple tags. All matching rules apply (later wins on conflict):
```lua
-- Discord is both IM and might steal focus
hl.window_rule({ match = { class = "^([Dd]iscord)$" }, tag = "im" })
hl.window_rule({ match = { class = "^([Dd]iscord)$" }, tag = "no-steal-focus" })
```

### Compound Conditions (AND logic)

Multiple fields in `match` are AND-combined:
```lua
-- Match ONLY if BOTH class AND title match
hl.window_rule({
  float = true,
  match = { class = "^([Tt]hunar)$", title = "^Files$" },
})
```

### Negative Match (Regex `negative:` prefix)

Wiki supports negating a regex with `negative:` prefix:
```lua
-- Match windows whose title is NOT "Mozilla Firefox"
hl.window_rule({
  float = true,
  match = { class = "^([Ff]irefox)$", title = "negative:^(Mozilla Firefox)$" },
})
```

> ⚠️ **Static effects cannot match on dynamically-changing titles** — wiki warns:
> "It is not possible to float (or any other static rule) a window based on a
> change in the title after the window has been created."
> For dynamic title matching, use `hl.on("window.title", fn)` + `hl.dispatch(hl.dsp.window.float({action="set"}))`.

---

## User Extension Pattern

### Step 1: Add a tag in `user/tags.lua`

```lua
-- user/tags.lua
-- Add Signal to the existing "im" category
hl.window_rule({
  match = { class = "^(signal)$" },
  tag = "im",
})

-- Add a brand-new category
hl.window_rule({
  match = { class = "^(davinci-resolve)$" },
  tag = "video-editing",
})
```

### Step 2: Add behavior rules in `user/rules.lua`

```lua
-- user/rules.lua
-- Signal inherits all "im" rules automatically.
-- Add only what differs:
hl.window_rule({
  size = { "monitor_w * 0.50", "monitor_h * 0.60" },
  match = { tag = "signal" },
})

-- Custom app needs full rule set
hl.window_rule({ opacity = "1.0",           match = { tag = "video-editing" } })
hl.window_rule({ no_blur = true,             match = { tag = "video-editing" } })
hl.window_rule({ idle_inhibit = "always",    match = { tag = "video-editing" } })
```

### Naming Convention

- **Tags**: kebab-case for multi-word (`video-editing`, not `videoEditing`)
- **Helper tags**: `PascalCase` (`Help_Cheat`, `Help_Settings`)

---

## Tag Completeness Invariant

**Every tag defined in `sys/tags.lua` MUST have at least one rule in `sys/rules.lua`.**

Orphaned tags indicate unfinished work or migration leftovers.

### Audit script

```bash
# Find tags defined but never referenced in rules
defined=$(grep -oE 'tag = "[a-z_-]+"' sys/tags.lua | sort -u)
used=$(grep -oE 'tag = "[a-z_-]+"' sys/rules.lua | sort -u)
comm -23 <(echo "$defined") <(echo "$used")
# (empty output = all tags have rules)
```

Run in repo root:
```bash
cd ~/.config/hypr && bash -c '
  defined=$(grep -oE "tag = \"[a-z_-]+\"" sys/tags.lua | sort -u)
  used=$(grep -oE "tag = \"[a-z_-]+\"" sys/rules.lua | sort -u)
  echo "=== Orphaned tags (defined but no rule) ==="
  comm -23 <(echo "$defined") <(echo "$used")
'
```

---

## Debugging

### Check tags on a window

```bash
# Get active window's tags
hyprctl activewindow -j | jq '.tags'

# List all windows with their tags
hyprctl clients -j | jq '.[] | {class, title, tags}'
```

### Common Issues

| Symptom | Cause | Fix |
| --- | --- | --- |
| App not following rules | Tag not assigned (regex mismatch) | Check `hyprctl clients -j` for exact class string |
| All windows get unwanted tag | Empty `class = ""` matches all (regex `^$` matches empty string... but empty pattern matches any string!) | Use specific class/title, never `class = ""` |
| Size rule ignored | Wrong expression format | Use `size = { "expr1", "expr2" }` (Lua table), NOT `"(expr1) (expr2)"` (single string with parens) |
| `fullscreen = "0"` rejected | `fullscreen` is bool, not string | Use `fullscreen = true` or `fullscreen_state` for fine control |
| `keep_aspect_ratio` ignored | It's a `resize()` dispatcher param, not a rule effect | Remove from rule; configure via app or dispatcher |
| Effect `ignore_alpha` rejected as string | wiki: number, not string | Use `ignore_alpha = 0.5`, not `"0.5"` |
| Class regex with trailing comma | `^X$,` includes literal comma | Remove comma; use `match = { class = "^X$" }` |

### Validation Checklist

When adding a new app:
- [ ] Added tag in `user/tags.lua` (or reused existing tag)
- [ ] Added rules in `user/rules.lua` (if new tag)
- [ ] Verified tag appears: `hyprctl activewindow -j | jq '.tags'`
- [ ] Verified behavior (float/tile/center/size/opacity)
- [ ] Ran tag completeness audit (above)
- [ ] `hyprland --verify-config` passes (or `luacheck ~/.config/hypr --codes`)

---

## References

- [Hyprland Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/) — official API reference
- [Hyprland Dispatchers wiki](https://wiki.hypr.land/Configuring/Basics/Dispatchers/) — `hl.dsp.window.*` for runtime actions
- [Strategy Pattern (refactoring.guru)](https://refactoring.guru/design-patterns/strategy)
- [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single-responsibility_principle)
- Project files: [`sys/tags.lua`](../../sys/tags.lua), [`sys/rules.lua`](../../sys/rules.lua)
