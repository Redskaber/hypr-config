# Script Audit & Capability Boundary

> Round 115 — comprehensive audit of all 59 `.sh` scripts in `sys/scripts/`.
> Defines the **capability boundary** between Hyprland's Lua API (`hl.*`) and
> shell scripts (`*.sh`), and documents the systemic fixes applied.
>
> **Round 115 changes**: Synced README.md stats (were stale: 4 libs/25 deps →
> 8 libs/35 deps), updated README structure block to list all 8 lib/ modules.
> Deep Hyprland log inspection confirms 0 config warnings/errors. Dead code
> audit confirms 0 unused variables/functions.

## TL;DR

| Metric | Value |
|---|---|
| Total `.sh` scripts | 59 (+1 utility: `validate_tags.sh`) |
| Lua-able scripts (could be pure Lua) | 4 (`KillActiveProcess`, `LockScreen`, `Wlogout`, `desktop-overview`) |
| Scripts that MUST stay in sh | 55 |
| `bash -n` pass rate | 59/59 (100%) |
| `luac -p` pass rate | 55/55 (100%) |
| `true # exit removed` no-ops | 0 (fixed in Round 104) |
| Hardcoded tool commands (non-comment) | 0 |
| Hardcoded daemon kills (swaync/awww-daemon/hypridle/hyprlock) | 0 |
| Real Hyprland 0.56.2 verify | ✅ CONFIG_LOADED_OK (0 config warnings) |
| Dead `_G.HYPR_CONST` doc refs | 0 (89 → 0, fixed in Round 105) |
| Orphaned Lua code | 0 (314 lines deleted in Round 105) |
| Sh→Lua migrations in Round 107 | 1 (cursor zoom) |
| Hardcoded tools eliminated in Round 108 | 6 |
| Hardcoded `$HOME/.cache` eliminated in Round 109 | 7 scripts + 2 state machines |
| External deps in `lib/deps.lua` | 35 |
| `common.sh` helpers | 23 |
| Runtime bugs fixed (Round 110-111) | 6 (TouchPad + Sounds.sh) |
| XDG-aware paths (Round 109-112) | config + cache + external + data + ags + rofi-themes |
| Process management bugs fixed (Round 113) | 3 (PortalHyprland + Polkit + Polkit-NixOS) |
| Header completeness (Round 114) | 100% (`@path` + `@author` + `@date` + `@description` on all 59 scripts) |
| Dead code audit (Round 115) | 0 unused variables, 0 unused functions |
| README/docs sync (Round 115) | All stats current (8 libs, 35 deps, 59 sh, 55 lua) |

## Capability Boundary — What Can Be Lua vs What Must Be sh

### Why Most Scripts Stay in sh

Hyprland's Lua API (v0.55+) provides:

- `hl.bind(keys, dispatcher)` — keybind registration
- `hl.dsp.*` — window/workspace/group dispatchers
- `hl.on(event, callback)` — event listeners
- `hl.get_active_window()`, `hl.get_monitors()`, etc. — state queries
- `hl.config({...})` — config declaration
- `hl.exec_cmd(cmd)` — execute shell command (async)

**What Lua CANNOT do (requires sh):**

1. **Interactive rofi prompts** (`rofi -dmenu`) — no GUI API in Lua
2. **System CLIs** (`pamixer`, `playerctl`, `brightnessctl`, `grim`, `slurp`, `wl-copy`, `cliphist`, `wallust`, `awww`, `hyprctl -j`) — external binaries, no Lua bindings
3. **File system operations** — Lua has `io` but sh is more ergonomic for multi-file ops
4. **Process management** (`pkill`, `killall`, `pgrep`) — no process API in Lua
5. **D-Bus / systemd interactions** (`systemctl`, `loginctl`) — no D-Bus API in Lua
6. **Network operations** (`curl`, `xdg-open`) — no networking API in Lua

### The 4 Lua-able Scripts

These scripts wrap a single `hl.dsp.*` call and could be inlined in `keybind.lua`:

| Script | Lua Equivalent | Status |
|---|---|---|
| `KillActiveProcess.sh` | `hl.dsp.window.kill({})` | Already inlined in keybind.lua (line 64) |
| `LockScreen.sh` | `hl.dsp.exec_cmd(deps.cmd("lock"))` | Already inlined in keybind.lua (line 66) |
| `Wlogout.sh` | `hl.dsp.exec_cmd(deps.cmd("logout_menu"))` | Already inlined in keybind.lua (line 67) |
| `desktop-overview.sh` | `hl.dsp.exec_cmd("qs -c overview")` | Stays as sh (has qs → ags fallback chain) |

**Design decision:** Keep the `.sh` files as fallback (resilience). The keybind.lua uses the Lua API directly; the sh scripts exist for manual invocation / debugging.

## Round 104 Fixes — Per-Category Summary

### A. `lib/common.sh` (foundation)

| Fix | Description |
|---|---|
| `dt_swaync_reload()` landmine removed | Was `pkill swaync; swaync &` — caused core dumps (Task 117 regression). Now `swaync-client --reload-config` (D-Bus live reload, no kill). |
| Fallback vars added | `$FILE_OPENER`, `$SCREENSHOT_EDITOR`, `$CALCULATOR`, `$MEDIA_PLAYER`, `$VIDEO_WALLPAPER`, `$IMAGE_MAGICK`, `$DIALOG`, `$CAVA`, `$HYPR_SEARCH_ENGINE` — scripts depending on these now work even if `.deps_cache.sh` is missing. |
| Capability-boundary doc | Added header comment explaining WHY these helpers exist (Lua cannot do hyprctl JSON queries, rofi, wl-copy, file ops). |

### B. Systemic "true # exit removed" Regression (40 instances fixed)

**Root cause:** Task 119 removed all `exit N` calls in scripts, replacing them with `true # exit removed: script exits naturally` no-ops. This was correct for trailing `exit 0` at end-of-script (where bash exits naturally), but WRONG for error paths.

**Symptoms fixed:**
- `Animations.sh`: error notify → fall-through → false success notify (lying to user)
- `RofiCalc.sh`: infinite loop on Escape (no `break`/`exit`)
- `RofiThemeSelector.sh`: infinite empty-rofi loop when themes dir missing
- `WallpaperAutoChange.sh`: missing `exit 1` after usage → `find ""` lists cwd → sets non-image files as wallpaper
- `WallustSwww.sh`: missing `exit 0` after empty-path guard → `ln -sf ""` (dangling symlink)
- `WaybarCava.sh`: missing `exit 1` on cava-missing → setup pidfile+trap, then `cava` fails
- `ZshChangeTheme.sh`: missing `exit 0` on NixOS path → continues past "NOT Supported" notify → `sed -i` corrupts NixOS-managed `~/.zshrc`
- `Tak0-Autodispatch.sh`: missing `exit 0` (success-on-match) → loops 29 extra times moving same window
- `desktop-overview.sh`: 4 missing `exit 0` on success → duplicate toggle attempts + spurious background spawns
- `validate_tags.sh`: missing `exit 2` on config error → reports "All 0 tags have rules" (masking config error)

**Fix rule applied:**
- Trailing no-op at end-of-script → `exit 0`
- Error path (missing dep, invalid arg, etc.) → `exit 1` (or `exit 2`/`exit N` if documented)
- `while true` loop exit on user-cancel → `break`
- Function error path → `return 1`

### C. Critical Bug Fixes

| Script | Bug | Fix |
|---|---|---|
| `RofiEmoji.sh` | `bash -n` fails (emoji data after `# # DATA # #` marker parsed as bash code) | Extracted emoji data to `lib/emoji-data.txt` (1849 lines). Script now `cat`s the file. |
| `Animations.sh` | Listed `.conf` files (none exist — presets are `.lua`); `hyprctl reload` didn't apply chosen preset | Now lists `.lua` files; writes chosen name to `.active_animation` state file; `lib/active_policy.lua` reads state on reload and `require()`s the chosen preset. |
| `Volume.sh` | `toggle_mic` had `-u --default-source u` (stray trailing `u` typo) | Changed to `--default-source -u` |
| `ScreenShot.sh` | Hardcoded `swappy`/`xdg-open`; dead code (lines 20-22, 108-113); unquoted `cd ${dir}` | Use `$SCREENSHOT_EDITOR`/`$FILE_OPENER` DI vars; removed dead code; quoted all paths; added `$RANDOM` to active_window_file |
| `DarkLight.sh` | `killall swaync` (Task 117 regression — swaync core-dumps on kill+restart) | Removed `$NOTIFICATION` from killall list; only `$BAR`/`$ROFI`/`ags`/`swaybg` killed |
| `ClipManager.sh` | `$CLIPBOARD` in single-quoted msg (literal text shown to user); infinite loop on Escape | Double-quoted msg; added `break` on case 1 (Escape) and after copy |
| `KeyBinds.sh` | jq used `.has_mod` (wrong field) and `.desc` (wrong field) | Changed to `.modmask` and `.description` (per Hyprland 0.55+ wiki) |
| `RofiBeats.sh` | `ps aux \| grep 'unique-wallpaper-process'` matched nothing → all mpv killed | Use `pgrep -x mpvpaper` + `pgrep -P` to find mpvpaper children; skip killing those |
| `Dropterminal.sh` | `grep -qF` (substring match) — `0x123` matches `0x1234` → false positive → drop-down never detected | Changed to `grep -qxF` (exact line match) |
| `Dropterminal.sh` | `validate_args` return code unchecked in `main()` | Added `\|\| return 1` |
| `WaybarStyles.sh` + `WaybarLayout.sh` | `$BAR` in single-quoted msg (literal `"$BAR"` shown to user) | Double-quoted msg |
| `Refresh.sh` + `RefreshNoWaybar.sh` | Looked for `${HYPR_CONFIG_DIR}/user/scripts/RainbowBorders.sh` (non-existent) — hook never fired | Changed to `${HYPR_SCRIPTS_DIR}/RainbowBorders.sh` (actual location) |
| `Quick_Settings.sh` | `edit="${EDITOR:-"$EDITOR"}"` — no-op tautology | Changed to `edit="${VISUAL:-$EDITOR}"` (respects $VISUAL → $EDITOR priority) |
| `SwitchKeyboardLayout.sh` + `Tak0-Per-Window-Switch.sh` | Read `sys/input.conf` (doesn't exist — only `sys/input.lua`); div-by-zero when layout count is 0 | Migrated to read from `sys/input.lua` (with sed parser for both quoted/unquoted forms); added `[ "$count" -gt 0 ] \|\| exit 1` guard |
| `Tak0-Autodispatch.sh` | `exit 0` (success-on-match) was removed → 29 redundant `window.move` calls per match | Restored `exit 0` |

### D. Architecture: Runtime-Switchable Animation Preset

**Problem:** `Animations.sh` couldn't apply a chosen preset because:
1. Animation presets are `.lua` files requiring `require()` — sh can't call Lua
2. `hyprctl reload` reloads the compiled config, not a chosen preset file
3. Lua's `package.loaded` caches modules — re-requiring doesn't re-execute

**Solution (Round 104):**
1. **`lib/active_policy.lua`** — Lua module that reads `$HYPR_CONFIG_DIR/.active_animation` state file and `require()`s the chosen preset
2. **`user/policy/default.lua`** — calls `require("lib.active_policy").apply()` instead of hardcoded `require("sys.policy.animations.default")`
3. **`Animations.sh`** — rofi picks preset name → writes to `.active_animation` → `hyprctl reload` → Lua reads state → applies preset

**Fallback:** If state file missing or preset name invalid, falls back to `default` (resilience design).

**Flow:**
```
SUPER+SHIFT+A → Animations.sh
  ├── rofi -dmenu (lists .lua preset files)
  ├── write chosen name → $HYPR_CONFIG_DIR/.active_animation
  └── hyprctl reload
        ↓
Hyprland reloads config
  ↓
user/policy/default.lua
  └── require("lib.active_policy").apply()
        ├── read .active_animation state file
        └── require("sys.policy.animations.<chosen>")
              └── applies curves + animations to Hyprland
```

## Per-Script Audit Status (keybind.lua order)

| Script | Round 104 Status | Key Fix |
|---|---|---|
| `desktop-overview.sh` | ✅ Fixed | 5× `exit 0`/`exit 1` restored |
| `KeyHints.sh` | ✅ OK | (cleanest of keybind/keyboard scripts) |
| `Refresh.sh` | ✅ Fixed | RainbowBorders path corrected |
| `RofiEmoji.sh` | ✅ Fixed | Data extracted to `lib/emoji-data.txt` |
| `RofiSearch.sh` | ✅ OK | (uses $HYPR_SEARCH_ENGINE — fallback added to common.sh) |
| `ChangeBlur.sh` | ✅ OK | (uses hyprctl keyword correctly) |
| `GameMode.sh` | ✅ OK | (Lua SM fallback — no changes needed) |
| `ChangeLayout.sh` | ✅ OK | (Lua SM fallback) |
| `ClipManager.sh` | ✅ Fixed | `$CLIPBOARD` literal + infinite loop |
| `RofiThemeSelector.sh` | ✅ Fixed | 4× `exit N` restored |
| `KeyBinds.sh` | ✅ Fixed | jq field names (`modmask`/`description`) |
| `Animations.sh` | ✅ Fixed | State-file architecture for runtime preset switch |
| `Hyprsunset.sh` | ✅ Fixed | `exit 0` at end |
| `Quick_Settings.sh` | ✅ Fixed | `$VISUAL`/`$EDITOR` tautology |
| `WaybarStyles.sh` | ✅ Fixed | `$BAR` literal in msg |
| `WaybarLayout.sh` | ✅ Fixed | `$BAR` literal in msg |
| `RofiBeats.sh` | ✅ Fixed | mpvpaper detection via `pgrep -P` |
| `WallpaperSelect.sh` | ✅ OK | (Task 117/118 already fixed — no daemon restart) |
| `WallpaperEffects.sh` | ✅ Fixed | `exit 1` on missing terminal |
| `WallpaperRandom.sh` | ✅ OK | (Task 117/118 already fixed) |
| `ZshChangeTheme.sh` | ✅ Fixed | `exit 0` on NixOS path (prevents `sed -i` corruption) |
| `RofiCalc.sh` | ✅ Fixed | `break` on Escape + `exit 0` at end |
| `Dropterminal.sh` | ✅ Fixed | `validate_args \|\| return 1` + `grep -qxF` |
| `Volume.sh` | ✅ Fixed | `toggle_mic` typo (`-u --default-source u` → `--default-source -u`) |
| `MediaCtrl.sh` | ✅ Fixed | `exit 0` at end |
| `ScreenShot.sh` | ✅ Fixed | Hardcoded `swappy`/`xdg-open` → DI vars + dead code removed |
| `SwitchKeyboardLayout.sh` | ✅ Fixed | Read from `sys/input.lua` + div-by-zero guard |
| `Tak0-Per-Window-Switch.sh` | ✅ Fixed | Same as above + `exit 1` on error paths |
| `Tak0-Autodispatch.sh` | ✅ Fixed | `exit 0` (success-on-match) restored |
| `AirplaneMode.sh` | ✅ OK | (rfkill — system hardware) |
| `RefreshNoWaybar.sh` | ✅ Fixed | RainbowBorders path + `exit 0` at end |
| `DarkLight.sh` | ✅ Fixed | `killall swaync` removed (Task 117 regression) |
| `WallustSwww.sh` | ✅ Fixed | `exit 1` on empty wallpaper path |
| `WallpaperAutoChange.sh` | ✅ Fixed | `exit 1` on usage error (prevents `find ""`) |
| `KeybindsLayoutInit.sh` | ⚠️ Deprecated | (called by startup.lua but duplicates ChangeLayout.sh — DRY violation, future cleanup) |
| `Hypridle.sh` | ✅ Fixed | `exit 1` on usage error |
| `LockScreen.sh` | ✅ OK | (Lua-able but kept as fallback) |
| `Wlogout.sh` | ✅ Fixed | `exit 0` on toggle-off (prevents immediate re-launch) |
| `KillActiveProcess.sh` | ✅ OK | (Lua-able but kept as fallback) |
| `Battery.sh` | ✅ OK | (/sys file read) |
| `Brightness.sh` / `BrightnessKbd.sh` | ✅ OK | (brightnessctl + notify) |
| `TouchPad.sh` | ✅ OK | (hyprctl + notify) |
| `Sounds.sh` | ✅ Fixed | 5× exit paths + `exit 1` on missing sound file |
| `Weather.sh` / `WeatherWrap.sh` | ✅ Fixed | `exit 0` on success paths |
| `UptimeNixOS.sh` | ✅ Fixed | `exit 1` on /proc/uptime read failure |
| `Distro_update.sh` | ✅ Fixed | `exit 1` on missing dep + `exit 0` on unsupported distro |
| `DotsUpdate.sh` | ✅ OK | (git + version check) |
| `Kitty_themes.sh` | ✅ Fixed | 5× `exit N` paths restored |
| `MonitorProfiles.sh` | ✅ OK | (rofi + hyprctl) |
| `Polkit.sh` / `Polkit-NixOS.sh` | ✅ Fixed | `exit 0` on success path |
| `PortalHyprland.sh` | ✅ OK | (systemctl D-Bus) |
| `RainbowBorders.sh` | ✅ OK | (random border colors) |
| `RofiThemeSelector-modified.sh` | ✅ Fixed | 3× `exit 1` + `exit 0` restored |
| `sddm_wallpaper.sh` | ✅ Fixed | `exit 0` on NixOS guard |
| `UserConfigsSwitcher.sh` | ✅ OK | (rofi + editor) |
| `WaybarCava.sh` | ✅ Fixed | `exit 1` on cava-missing |
| `WaybarScripts.sh` | ✅ OK | (file ops + notify) |
| `validate_tags.sh` | ✅ Fixed | `exit 2` on config error (matches documented exit-code legend) |

## Verification Matrix

| Check | Method | Result |
|---|---|---|
| Bash syntax | `bash -n *.sh` | 61/61 pass |
| Lua syntax | `luac -p *.lua` | 55/55 pass |
| "true # exit removed" count | `grep -cE 'true  # exit removed' *.sh` | 0 (was 40) |
| Hardcoded tool commands | `grep -vE '^\s*#' *.sh \| grep <tool>` | 0 in non-comment code |
| Hardcoded daemon kills | `grep -E '(pkill\|killall)\s+(swaync\|awww-daemon\|hypridle\|hyprlock)' *.sh` | 0 |
| Permissions (.lua) | `find . -name '*.lua' -exec stat -c '%a' {} \;` | All 644 |
| Permissions (.sh) | `find . -name '*.sh' -exec stat -c '%a' {} \;` | All 755 |
| Real Hyprland 0.56.2 verify | headless `Hyprland --config` | ✅ CONFIG_LOADED_OK |
| `lib/active_policy.lua` unit test | 3 assertions (no state / custom / empty) | ✅ ALL TESTS PASSED |

## Design Principles Applied

1. **Single Source of Truth (SSOT)**: `sys/const.lua` is the SSOT; `lib/common.sh` sources `.deps_cache.sh` (auto-generated). No hardcoded paths in scripts.

2. **Dependency Injection (DI)**: 26 tools declared in `lib/deps.lua`; scripts use `$HYPRCTL`/`$NOTIFY`/etc. variables, never hardcoded tool names.

3. **Capability Boundary**: Each script's header now documents WHY it stays in sh (not Lua). The 4 Lua-able scripts are inlined in `keybind.lua` with sh fallback for resilience.

4. **Resilience (Fail-Safe)**: `lib/active_policy.lua` falls back to `default` preset on any error. `common.sh` has fallback defaults if `.deps_cache.sh` is missing. State machines use `pcall` for module load.

5. **Single Responsibility**: `lib/emoji-data.txt` is data; `RofiEmoji.sh` is logic. `lib/active_policy.lua` is state resolution; `Animations.sh` is UI.

6. **Layered Architecture**:
   - Layer 1: `bootstrap/const.lua` (immutable paths)
   - Layer 2: `sys/const.lua` (system defaults, read-only)
   - Layer 3: `user/const.lua` (incremental overrides)
   - Shell layer: `lib/common.sh` (sources SSOT cache, provides helpers)

7. **No Backward Compatibility Hacks**: Removed dead code (`shotwin`, `--mic-inc`/`--mic-dec` unused args, duplicate `RofiThemeSelector-modified.sh` kept for now but flagged for future merge).

## References

- [Hyprland Wiki — Dispatchers](https://wiki.hypr.land/Configuring/Basics/Dispatchers/) — `hl.dsp.*` API
- [Hyprland Wiki — Binds](https://wiki.hypr.land/Configuring/Basics/Binds/) — `hl.bind()` + `hl.bindd()` (description-bearing binds)
- [Hyprland Wiki — Expanding Functionality](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Expanding-functionality/) — `hl.on()` events + convenience functions
- [Hyprland Wiki — Getting Binds](https://wiki.hypr.land/Configuring/Binds/#getting-binds) — `hyprctl binds -j` JSON schema (`modmask`, `key`, `description`)
