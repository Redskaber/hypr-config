# Lua Reference — API Quick Card

> Pure `.lua` (Hyprland v0.55+). This is a quick reference — for full API,
> see the [Hyprland wiki](https://wiki.hypr.land/).

## `hl.*` Top-Level Functions

| Function | Purpose | Example |
| --- | --- | --- |
| `hl.config(opts)` | Set Hyprland config section | `hl.config({ input = { kb_layout = "us" } })` |
| `hl.bind(key, action, flags?)` | Register a keybind | `hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))` |
| `hl.unbind(key)` | Remove a keybind | `hl.unbind("SUPER + O")` |
| `hl.window_rule(opts)` | Register a window rule | `hl.window_rule({ float = true, match = { class = "^firefox$" } })` |
| `hl.layer_rule(opts)` | Register a layer rule | `hl.layer_rule({ blur = true, match = { namespace = "waybar" } })` |
| `hl.on(event, fn)` | Event hook | `hl.on("hyprland.start", function() ... end)` |
| `hl.env(key, value)` | Set env var | `hl.env("EDITOR", "nvim")` |
| `hl.exec_cmd(cmd)` | Execute a command (async) | `hl.exec_cmd("waybar")` |
| `hl.monitor(opts)` | Configure a monitor | `hl.monitor({ output = "DP-1", resolution = "2560x1440", scale = 1.0 })` |
| `hl.device(opts)` | Configure an input device | `hl.device({ name = "touchpad", enabled = true })` |
| `hl.gesture(opts)` | Configure a gesture | `hl.gesture({ swipe = 3, ... })` |
| `hl.workspace_rule(opts)` | Workspace rule | `hl.workspace_rule({ workspace = "1", monitor = "DP-1" })` |
| `hl.animation(name, ...)` | Define an animation | — |
| `hl.curve(name, ...)` | Define a bezier curve | — |

## `hl.dsp.*` Dispatchers

> Dispatchers return tables describing an action; must be passed to `hl.bind()` or wrapped in `hl.dispatch()`.

### General

| Dispatcher | Purpose |
| --- | --- |
| `hl.dsp.exec_cmd(cmd, rules?)` | Execute a command (rules = window rule effects to apply) |
| `hl.dsp.exec_raw(cmd)` | Execute raw command (no sh -c) |
| `hl.dsp.focus({...})` | Move focus (`direction`/`monitor`/`workspace`/`window`/`urgent_or_last`/`last`) |
| `hl.dsp.exit()` | Quit Hyprland |
| `hl.dsp.submap(name)` | Switch to a submap |
| `hl.dsp.pass({window?})` | Pass shortcut to a window |
| `hl.dsp.layout(message)` | Send a layout message |
| `hl.dsp.dpms({action?, monitor?})` | Toggle monitors on/off |

### Window (`hl.dsp.window.*`)

| Method | Purpose |
| --- | --- |
| `hl.dsp.window.close({window?})` | Graceful close |
| `hl.dsp.window.kill({window?})` | SIGKILL the process |
| `hl.dsp.window.float({action?, window?})` | Set floating state (`toggle`/`enable`/`disable`) |
| `hl.dsp.window.fullscreen({mode?, action?, window?})` | Set fullscreen state |
| `hl.dsp.window.pin({action?, window?})` | Pin (show on all workspaces) |
| `hl.dsp.window.move({workspace, follow?, window?})` | Move to workspace |
| `hl.dsp.window.move({x, y, relative?, window?})` | Move to pixel coords |
| `hl.dsp.window.resize({x, y, relative?, window?})` | Resize |
| `hl.dsp.window.center({window?})` | Center on monitor |
| `hl.dsp.window.cycle_next({next?, tiled?, floating?, window?})` | Focus next |
| `hl.dsp.window.tag({tag, window?})` | Tag a window |
| `hl.dsp.window.clear_tags({window?})` | Clear all tags |
| `hl.dsp.window.set_prop({prop, value, window?})` | Set a dynamic property |

### Workspace (`hl.dsp.workspace.*`)

| Method | Purpose |
| --- | --- |
| `hl.dsp.workspace.rename({workspace, name?})` | Rename workspace |
| `hl.dsp.workspace.change_id({workspace, id})` | Change workspace ID |
| `hl.dsp.workspace.move({workspace?, monitor})` | Move workspace to monitor |
| `hl.dsp.workspace.toggle_special(special_name)` | Toggle a special workspace |

### Group (`hl.dsp.group.*`)

| Method | Purpose |
| --- | --- |
| `hl.dsp.group.toggle({window?})` | Toggle group |
| `hl.dsp.group.next({window?})` | Next in group |
| `hl.dsp.group.prev({window?})` | Previous in group |
| `hl.dsp.group.lock({action?, window?})` | Lock group |

### Cursor (`hl.dsp.cursor.*`)

| Method | Purpose |
| --- | --- |
| `hl.dsp.cursor.move({x, y})` | Move cursor to coord |
| `hl.dsp.cursor.move_to_corner({corner, window?})` | Move to window corner (0-3) |

## `hl.on` Events

| Event | Fires when |
| --- | --- |
| `hyprland.start` | Hyprland starts |
| `hyprland.shutdown` | Hyprland shuts down |
| `window.title` | A window's title changes |
| `window.create` | A window is created |
| `window.close` | A window closes |
| `workspace` | Active workspace changes |

## Window Selector Syntax (for `window` parameter)

| Selector | Example |
| --- | --- |
| `address:0x...` | Specific window by address |
| `pid:N` | By process ID |
| `class:regex` | By class regex |
| `title:regex` | By title regex |
| `tag:name` | By tag |
| `activewindow` | Currently focused window |

## Window Rule Effects (verified)

See [TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) for the full list of
static + dynamic effects with types.

### Key type rules (from wiki)

| Effect | Type | Example |
| --- | --- | --- |
| `float` | bool | `float = true` |
| `size` | string (numbers) or table (expressions) | `size = "800 600"` or `size = { "monitor_w * 0.5", "monitor_h * 0.5" }` |
| `move` | string or table | Same as `size` |
| `opacity` | string | `opacity = "0.9 0.7"` (active inactive) |
| `fullscreen` | bool | `fullscreen = true` |
| `pin` | bool | `pin = true` (requires `float = true`) |
| `ignore_alpha` (layer) | number | `ignore_alpha = 0.5` |

## References

- [Hyprland Dispatchers wiki](https://wiki.hypr.land/Configuring/Basics/Dispatchers/) — full `hl.dsp.*` list
- [Hyprland Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/) — effect list
- [Hyprland Using-hyprctl wiki](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Using-hyprctl/) — `hyprctl eval` / `dispatch`
- [COMPATIBILITY.md](COMPATIBILITY.md) — `.conf` ↔ `.lua` translation
- [TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) — tag-driven window management
