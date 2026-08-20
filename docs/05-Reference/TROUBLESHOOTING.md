# Troubleshooting Guide

> Systematic problem-solving for the `.lua` Hyprland config (v0.55+).
> All commands verified against actual project structure.

---

## 🔍 Diagnostic Framework

When encountering issues, follow this flow:

```
1. Identify symptoms
2. luacheck (static analysis)
3. hypr-sim (runtime pipeline simulator)
4. hyprland --verify-config (gold standard)
5. Check runtime logs
6. Isolate component
7. Apply fix
8. Re-verify
```

### Quick triage

| Symptom | Likely Cause | Quick Fix |
| --- | --- | --- |
| Config won't load | Lua syntax / require error | `luacheck` + `python3 hypr-sim.py` |
| `module 'X' not found` | Wrong require path | [Issue 1](#issue-1-module-not-found) |
| `attempt to index global 'hl' (a nil value)` | Hyprland < 0.55 | Upgrade Hyprland |
| `attempt to call a nil value (field 'X')` | Unknown `hl.X` API | [Issue 2](#issue-2-unknown-hl-api) |
| Black screen after `Welcome to Hyprland` | GPU/CBackend (not config) | [Issue 3](#issue-3-hyprland-wont-start) |
| No waybar | Waybar not started / not installed | [Issue 4](#issue-4-daemon-not-starting) |
| Wrong colors | Wallust not applied | [Issue 5](#issue-5-colors-not-applied) |
| Keybinds not responding | Wrong keysym / SM fallback | [Issue 6](#issue-6-keybinds-not-responding) |
| Window rules not applying | Wrong class regex / empty class | [Issue 7](#issue-7-window-rules-not-applying) |
| `size` rule ignored | Wrong expression format | [Issue 8](#issue-8-size-expression-format) |

---

## 🛠️ Diagnostic Tools

### 1. luacheck (static analysis)

```bash
luacheck ~/.config/hypr --codes
```
- Catches: undefined globals, unused variables, syntax errors
- Config: [`.luacheckrc`](../../.luacheckrc) (declares `hl` as known global)

### 2. hypr-sim (runtime simulator)

```bash
cd ~/.config/hypr && python3 hypr-sim.py
```
- **Executes the full require pipeline** (catches errors luacheck misses)
- Validates all `hl.window_rule` effects against wiki API whitelist
- Reports: registered rules count, orphaned tags, unknown effects, type mismatches

Expected output:
```
✅ Pipeline loaded successfully
Window rules registered: 134
Layer rules registered:   5
Binds registered:        145
✅ No errors found
```

### 3. hyprland --verify-config (gold standard)

```bash
hyprland --verify-config
```
- Runs the real Hyprland config loader
- Needs nix store access (or Hyprland installed system-wide)

### 4. Runtime logs

```bash
# Active session log
journalctl -u hyprland-session -f
# or (no systemd):
cat ~/.cache/hyprland/$(ls /tmp/hypr/ 2>/dev/null | head -1)/hyprland.log | tail -50

# Check Hyprland instance
echo $HYPRLAND_INSTANCE_SIGNATURE
ls /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/
```

---

## 🐛 Common Issues

### Issue 1: `module 'X' not found`

**Cause**: `require("X")` cannot resolve module X.

**Diagnosis**:
```bash
# Check package.path (where Lua looks for modules)
hyprctl eval 'return package.path'
```

**Common causes**:
- File doesn't exist (check spelling)
- File is in wrong directory (Lua's `package.path` doesn't include it)
- Using `require("const")` instead of `_G.HYPR_CONST` (const is not a module!)

**Fix**:
```lua
-- BAD: require("const")  ← fails, "const" is not a module
-- GOOD:
local const = _G.HYPR_CONST
```

### Issue 2: Unknown `hl.*` API

**Cause**: Calling an `hl.X` function that doesn't exist in Hyprland's API.

**Diagnosis**:
```bash
# Check if the API exists
hyprctl eval 'return type(hl.X)'   # should be "function", not "nil"
```

**Common mistakes** (verified against wiki):
- `hl.keep_aspect_ratio` — NOT a window_rule effect, it's a `resize()` dispatcher param
- `hl.window_rule({ fullscreen = "0" })` — `fullscreen` is bool, not string
- `hl.layer_rule({ ignore_alpha = "0.5" })` — `ignore_alpha` is number, not string

**Fix**: Check the [Hyprland Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/) for the complete effect list and types.

### Issue 3: Hyprland won't start

**Symptom**: `Welcome to Hyprland!` then black screen / crash.

**Cause**: Usually GPU/CBackend issue, not config.

**Diagnosis**:
```bash
# Run Hyprland with verbose logging
HYPRLAND_LOG=1 Hyprland

# Check GPU
lspci -k | grep -A 2 -E "VGA|3D"

# Check DRM
ls /dev/dri/
```

**Common fixes**:
- NVIDIA: install `nvidia-drm` kernel module, set `nvidia_drm.modeset=1`
- VirtualBox/VM: use `WLR_NO_HARDWARE_CURSORS=1`
- See [GPU_VERIFICATION_CHECKLIST.md](GPU_VERIFICATION_CHECKLIST.md) for full guide

### Issue 4: Daemon not starting

**Symptom**: waybar / swaync / awww not running.

**Diagnosis**:
```bash
# Check if daemon is installed
which waybar swaync awww-daemon

# Check if it's running
pgrep -a waybar swaync awww-daemon

# Run it manually to see errors
waybar
swaync
awww-daemon
```

**Cause**: `sys/startup.lua` launches daemons via `deps.get("name")`. If `found` is false, the daemon isn't installed.

**Fix**:
```bash
# Install missing daemon
sudo pacman -S waybar swaync
# Or override via env var (if your tool has a different name)
export HYPR_BAR=yambar   # override "bar" dep
```

### Issue 5: Colors not applied

**Symptom**: Wallust colors not loaded.

**Cause**: Pipeline order — `sys/policy/default.lua` must load BEFORE `sys/decoration.lua`.

**Verification** (in `sys/default.lua`):
```lua
require("sys.policy.default")   -- ← loads wallust colors + animation preset
require("sys.env")
require("sys.misc")
-- ...
require("sys.decoration")        -- ← decoration AFTER policy
```

**Fix**: Run wallpaper selector to regenerate colors:
```bash
# Press SUPER + W (wallpaper selector)
# Or manually:
~/.config/hypr/sys/scripts/WallpaperSelect.sh
```

### Issue 6: Keybinds not responding

**Diagnosis**:
```bash
# Check if bind is registered
hyprctl binds -j | jq '.[] | select(.key | test("SUPER"))'

# Check exact keysym (case-sensitive!)
# XF86 keysyms must be CamelCase: XF86AudioPlay, not xf86audioplay
hyprctl clients -j | jq '.[].class'  # check active window
```

**Common causes**:
- Keysym case (XF86 must be CamelCase)
- Layout SM failed (fell back to .sh, but .sh also failed)
- Modifier mismatch (`SUPER` vs `SUPER + SHIFT`)

**Fix**:
```bash
# Re-initialize layout-aware binds
~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh

# Or check for Lua errors
luacheck ~/.config/hypr --codes
```

### Issue 7: Window rules not applying

**Diagnosis**:
```bash
# Check the window's tag
hyprctl activewindow -j | jq '{class, title, tags}'

# Check exact class string (regex must match)
hyprctl clients -j | jq '.[] | .class' | sort -u
```

**Common mistakes**:
- `match = { class = "" }` — empty regex matches ALL windows (bug!)
- `class = "^X$,"` — trailing comma in regex (literal char, never matches)
- Tag not defined in `sys/tags.lua` (orphaned)

**Fix**:
```lua
-- BAD: empty class
hl.window_rule({ match = { class = "" }, tag = "settings" })  -- matches all!

-- GOOD: specific class
hl.window_rule({ match = { class = "^([Cc]alculator)$" }, tag = "calculator" })

-- GOOD: title-based (for dialogs)
hl.window_rule({ match = { title = "^(Open File)$" }, tag = "file-dialog" })
```

### Issue 8: `size` expression format

**Cause**: Using string form for monitor-relative expressions.

**BAD**:
```lua
hl.window_rule({ size = "(monitor_w*0.60) (monitor_h*0.70)", match = { tag = "im" } })
```

**GOOD** (wiki-confirmed):
```lua
hl.window_rule({
  size = { "monitor_w * 0.60", "monitor_h * 0.70" },
  match = { tag = "im" },
})
```

> `size` accepts either:
> - String of pure numbers: `"800 600"` (absolute pixels)
> - Lua table of expressions: `{ "monitor_w * 0.5", "monitor_h * 0.5" }` (relative)

---

## 🔧 Reset & Recovery

### Reset to defaults

```bash
# Backup current config
cp -r ~/.config/hypr ~/.config/hypr.bak.$(date +%s)

# Re-clone
rm -rf ~/.config/hypr
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr
```

### Clear runtime state

```bash
# Clear dropdown terminal state
rm -f /tmp/dropdown_terminal_addr

# Restart waybar + swaync
~/.config/hypr/sys/scripts/Refresh.sh

# Full Hyprland reload
hyprctl reload
```

---

## 📚 References

- [Hyprland Wiki](https://wiki.hypr.land/) — official API
- [Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/) — `hl.window_rule` spec
- [Dispatchers wiki](https://wiki.hypr.land/Configuring/Basics/Dispatchers/) — `hl.dsp.*` spec
- [GPU Verification Checklist](GPU_VERIFICATION_CHECKLIST.md)
- [Tag System](../03-Core-Systems/TAG_SYSTEM.md) — window classification
- [Architecture Overview](../02-Architecture/ARCHITECTURE_OVERVIEW.md) — design
