# `.conf` ↔ `.lua` Compatibility Reference

> Pure `.lua` (Hyprland v0.55+). The repo no longer ships `.conf` files (except
> `hypridle.conf` and `hyprlock.conf`, because those daemons don't support Lua).
> This document helps users migrating from `.conf` syntax.

## Summary

| Aspect | `.conf` (hyprlang, ≤v0.54) | `.lua` (v0.55+) |
| --- | --- | --- |
| File extension | `.conf` | `.lua` |
| Entry point | `~/.config/hypr/hyprland.conf` | `~/.config/hypr/hyprland.lua` |
| Syntax | DSL (`key = value`) | Lua (`hl.config({key = value})`) |
| Reload | `hyprctl reload` | auto-reload on file save |
| Variables | `$var = value` | `_G.HYPR_CONST.var = value` |
| Binds | `bind = MOD, KEY, dispatcher, args` | `hl.bind("MOD + KEY", hl.dsp.X({...}))` |
| Window rules | `windowrule = match:class X, effect Y` | `hl.window_rule({ match={...}, effect=Y })` |
| Exec on start | `exec-once = cmd` | `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` |
| Lua functions in binds | ❌ impossible | ✅ `hl.bind("KEY", function() ... end)` |

## Syntax Translation Table

### Variables

```conf
# .conf (LEGACY)
$M_terminal = kitty
$M = SUPER
```

```lua
-- .lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.M_terminal = "kitty"
_G.HYPR_CONST.M = "SUPER"
```

> Note: In `.lua`, the `$var` is replaced by `_G.HYPR_CONST.var` (global table).
> No `deep_merge()` — last-write-wins on the same table.

### Configuration

```conf
# .conf (LEGACY)
input {
    kb_layout = us,cn
    follow_mouse = 1
}
```

```lua
-- .lua
hl.config({
  input = {
    kb_layout = "us,cn",
    follow_mouse = 1,
  },
})
```

### Binds

```conf
# .conf (LEGACY)
bind = SUPER, Return, exec, kitty
bind = SUPER, Q, killactive
bindl = , XF86AudioPlay, exec, playerctl play-pause
```

```lua
-- .lua
local const = _G.HYPR_CONST
hl.bind(const.M .. " + Return", hl.dsp.exec_cmd(const.M_terminal))
hl.bind(const.M .. " + Q", hl.dsp.window.close())
-- Locked flag (fires on lock screen):
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
```

**Key differences**:
- `bind = MOD, KEY, ...` becomes `hl.bind("MOD + KEY", ...)` — modifiers joined with ` + `
- `killactive` becomes `hl.dsp.window.close()`
- `bindl` (locked) becomes third-arg flags table `{ locked = true }`

### Window Rules

```conf
# .conf (LEGACY)
windowrule = float, class:^(firefox)$
windowrule = opacity 0.9 0.8, class:^(kitty)$
windowrule = move 100 200, class:^(discord)$, title:^(Library)$
windowrule = size 800 600, class:^(calculator)$
```

```lua
-- .lua
hl.window_rule({ float = true, match = { class = "^([Ff]irefox)$" } })
hl.window_rule({ opacity = "0.9 0.8", match = { class = "^(kitty)$" } })
hl.window_rule({
  move = { "100", "200" },
  match = { class = "^([Dd]iscord)$", title = "^(Library)$" },  -- AND combined
})
hl.window_rule({ size = "800 600", match = { class = "^([Cc]alculator)$" } })
```

**Key differences**:
- `windowrule = effect, match:class ^X$` becomes `hl.window_rule({ effect=value, match={class="^X$"} })`
- Multiple `match:` conditions are AND-combined in one Lua table
- For OR logic, use multiple `hl.window_rule` calls
- `size` and `move` use Lua table form for expressions: `{ "monitor_w * 0.5", "monitor_h * 0.5" }`
- Empty `class = ""` is a BUG (matches all windows) — never use it

### Exec on Start

```conf
# .conf (LEGACY)
exec-once = waybar
exec-once = swaync
exec-once = hyprsunset -t 4500
```

```lua
-- .lua
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("hyprsunset -t 4500")
end)
```

**Bonus**: `.lua` also supports `hl.on("hyprland.shutdown", fn)` for cleanup — impossible in `.conf`.

### Workspace Rules

```conf
# .conf (LEGACY)
workspace = 1, monitor:DP-1
workspace = 2, defaultName:browser
```

```lua
-- .lua
hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", defaultName = "browser" })
```

### Monitors

```conf
# .conf (LEGACY)
monitor = , preferred, auto, 1.0
monitor = DP-1, 2560x1440@60, 0x0, 1.0
```

```lua
-- .lua
hl.monitor({ output = "", resolution = "preferred", position = "auto", scale = 1.0 })
hl.monitor({ output = "DP-1", resolution = "2560x1440@60", position = "0x0", scale = 1.0 })
```

## Common Pitfalls

### 1. `size` expression format

```lua
-- BAD (string with parens — Hyprland may misparse)
hl.window_rule({ size = "(monitor_w*0.60) (monitor_h*0.70)", match = { tag = "im" } })

-- GOOD (Lua table form)
hl.window_rule({ size = { "monitor_w * 0.60", "monitor_h * 0.70" }, match = { tag = "im" } })
```

### 2. `fullscreen` is bool

```lua
-- BAD (string — truthy in Lua, but not a valid effect value)
hl.window_rule({ fullscreen = "0", match = { tag = "games" } })

-- GOOD (boolean)
hl.window_rule({ fullscreen = true, match = { tag = "games" } })
```

### 3. `keep_aspect_ratio` is NOT a window_rule effect

```lua
-- BAD (it's a resize() dispatcher param, not a rule effect)
hl.window_rule({ keep_aspect_ratio = true, match = { tag = "pip" } })

-- (Remove from rule; configure via app or dispatcher)
```

### 4. `ignore_alpha` is number

```lua
-- BAD (string)
hl.layer_rule({ ignore_alpha = "0.5", match = { namespace = "..." } })

-- GOOD (number)
hl.layer_rule({ ignore_alpha = 0.5, match = { namespace = "..." } })
```

### 5. Empty `class = ""` matches all windows

```lua
-- BAD (matches every window — bug!)
hl.window_rule({ match = { class = "" }, tag = "settings" })

-- GOOD (specific class or title)
hl.window_rule({ match = { class = "^([Cc]alculator)$" }, tag = "calculator" })
```

## Daemons That Still Need `.conf`

Two daemons don't support Lua config, so the repo ships `.conf` for them (as symlinks):

| Daemon | Config | Why |
| --- | --- | --- |
| `hypridle` | `~/.config/hypr/hypridle.conf` → `sys/hypridle.conf` | Daemon uses hyprlang, not Lua |
| `hyprlock` | `~/.config/hypr/hyprlock.conf` → `sys/hyprlock.conf` | Daemon uses hyprlang, not Lua |

These are NOT Hyprland config — they're separate daemons with their own config format.

## References

- [Hyprland Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/) — full effect list
- [Hyprland Dispatchers wiki](https://wiki.hypr.land/Configuring/Basics/Dispatchers/) — `hl.dsp.*` spec
- [Hyprland 0.54 wiki (legacy .conf)](https://wiki.hypr.land/0.54.0/) — historical syntax
- [Project README](../../README.md) — current state
