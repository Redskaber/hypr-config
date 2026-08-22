-- @path: sys/keybind.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Canonical keybind table (140+ binds, layout-specific, SM)

-- State machine loading with pcall fallback (resilience design).
-- If a Lua SM module fails to load (deleted file, syntax error), the bind
-- falls back to the legacy .sh script instead of crashing Hyprland.
local const = require("const")
local deps = require("lib.deps")

local ok_layout, layout_mod = pcall(require, 'sys.statemachine.layout')
local ok_gamemode, gamemode_mod = pcall(require, 'sys.statemachine.gamemode')
local ok_nightlight, nightlight_mod = pcall(require, 'sys.statemachine.nightlight')

local layout_sm = ok_layout and layout_mod.new(hl) or nil
local gamemode_sm = ok_gamemode and gamemode_mod.new(hl) or nil
local nightlight_sm = ok_nightlight and nightlight_mod.new(hl) or nil

-- Pre-resolve deps (at file load, not in bind callbacks)
local launcher_cmd = deps.get("launcher").cmd or "rofi"
local terminal_cmd = deps.get("terminal").cmd or "kitty"
local file_manager_cmd = deps.get("file_manager").cmd or "nemo"
local notification_cmd = deps.get("notification").cmd or "swaync"
local bar_cmd = deps.get("bar").cmd or "waybar"


-- Note: get_current_layout uses hl.exec_cmd (non-blocking, but no return value)
-- Users can configure layout-specific keybinds

-- ── STANDARD — launchers & apps ────────────────────────────────────
-- Round 108: use deps.get("file_opener") (DI) instead of hardcoded xdg-open
local file_opener = deps.get("file_opener")
local file_opener_cmd = (file_opener and file_opener.cmd) or "xdg-open"
hl.bind(const.modifier .. " + D", hl.dsp.exec_cmd("pkill " .. launcher_cmd .. " || true && " .. launcher_cmd .. " -show drun -modi drun filebrowser run window"))
hl.bind(const.modifier .. " + B", hl.dsp.exec_cmd(file_opener_cmd .. " \"https://\""))
hl.bind(const.modifier .. " + Return", hl.dsp.exec_cmd(terminal_cmd))
hl.bind(const.modifier .. " + E", hl.dsp.exec_cmd(file_manager_cmd))
hl.bind(const.modifier .. " + A", hl.dsp.exec_cmd(const.dirs.scripts .. "/desktop-overview.sh"))

-- ── SYSTEM ──────────────────────────────────────────────────────────
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
hl.bind(const.modifier .. " + Q", hl.dsp.window.close())
hl.bind(const.modifier .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(deps.cmd("lock")))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(deps.cmd("logout_menu")))
hl.bind(const.modifier .. " + SHIFT + N", hl.dsp.exec_cmd(notification_cmd .. "-client -t -sw"))

-- ── FEATURES / EXTRAS ──────────────────────────────────────────────
hl.bind(const.modifier .. " + H", hl.dsp.exec_cmd(const.dirs.scripts .. "/KeyHints.sh"))
hl.bind(const.modifier .. " + ALT + R", hl.dsp.exec_cmd(const.dirs.scripts .. "/Refresh.sh"))
hl.bind(const.modifier .. " + ALT + E", hl.dsp.exec_cmd(const.dirs.scripts .. "/RofiEmoji.sh"))
hl.bind(const.modifier .. " + S", hl.dsp.exec_cmd(const.dirs.scripts .. "/RofiSearch.sh"))
hl.bind(const.modifier .. " + CTRL + S", hl.dsp.exec_cmd(launcher_cmd .. " -show window"))
hl.bind(const.modifier .. " + ALT + O", hl.dsp.exec_cmd(const.dirs.scripts .. "/ChangeBlur.sh"))

-- State machines (with .sh fallback if Lua SM failed to load)
hl.bind(const.modifier .. " + SHIFT + G", function()
  if gamemode_sm then gamemode_sm:fire("toggle")
  else hl.exec_cmd(const.dirs.scripts .. "/GameMode.sh") end
end)
hl.bind(const.modifier .. " + ALT + L", function()
  if layout_sm then layout_sm:fire("cycle")
  else hl.exec_cmd(const.dirs.scripts .. "/ChangeLayout.sh") end
end)
hl.bind(const.modifier .. " + ALT + V", hl.dsp.exec_cmd(const.dirs.scripts .. "/ClipManager.sh"))
hl.bind(const.modifier .. " + CTRL + R", hl.dsp.exec_cmd(const.dirs.scripts .. "/RofiThemeSelector.sh"))
hl.bind(const.modifier .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("pkill " .. launcher_cmd .. " || true && " .. const.dirs.scripts .. "/RofiThemeSelector-modified.sh"))
hl.bind(const.modifier .. " + SHIFT + K", hl.dsp.exec_cmd(const.dirs.scripts .. "/KeyBinds.sh"))
hl.bind(const.modifier .. " + SHIFT + A", hl.dsp.exec_cmd(const.dirs.scripts .. "/Animations.sh"))
hl.bind(const.modifier .. " + N", function()
  if nightlight_sm then nightlight_sm:fire("toggle")
  else hl.exec_cmd(const.dirs.scripts .. "/Hyprsunset.sh") end
end)
hl.bind(const.modifier .. " + SHIFT + E", hl.dsp.exec_cmd(const.dirs.scripts .. "/Quick_Settings.sh"))

-- Waybar
hl.bind(const.modifier .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 " .. bar_cmd))
hl.bind(const.modifier .. " + CTRL + B", hl.dsp.exec_cmd(const.dirs.scripts .. "/WaybarStyles.sh"))
hl.bind(const.modifier .. " + ALT + B", hl.dsp.exec_cmd(const.dirs.scripts .. "/WaybarLayout.sh"))

-- Sound/Music
hl.bind(const.modifier .. " + SHIFT + M", hl.dsp.exec_cmd(const.dirs.scripts .. "/RofiBeats.sh"))

-- Wallpaper
hl.bind(const.modifier .. " + W", hl.dsp.exec_cmd(const.dirs.scripts .. "/WallpaperSelect.sh"))
hl.bind(const.modifier .. " + SHIFT + W", hl.dsp.exec_cmd(const.dirs.scripts .. "/WallpaperEffects.sh"))
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(const.dirs.scripts .. "/WallpaperRandom.sh"))

-- Misc
hl.bind(const.modifier .. " + SHIFT + O", hl.dsp.exec_cmd(const.dirs.scripts .. "/ZshChangeTheme.sh"))
hl.bind(const.modifier .. " + ALT + C", hl.dsp.exec_cmd(const.dirs.scripts .. "/RofiCalc.sh"))

-- ── WINDOW MANAGEMENT ──────────────────────────────────────────────
hl.bind(const.modifier .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(const.modifier .. " + CTRL + F", hl.dsp.window.fullscreen({mode="maximized"}))
hl.bind(const.modifier .. " + SPACE", hl.dsp.window.float({action="toggle"}))
hl.bind(const.modifier .. " + ALT + SPACE", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(const.modifier .. " + SHIFT + Return", hl.dsp.exec_cmd(const.dirs.scripts .. "/Dropterminal.sh " .. const.apps.terminal))

-- Cursor zoom (Round 107: migrated from sh pipeline to pure Lua via lib/cursor.lua)
-- Was: hyprctl keyword cursor:zoom_factor $(hyprctl getoption ... | jq | awk ...)
-- Now: hl.get_config("cursor.zoom_factor") + hl.config({cursor={zoom_factor=v}})
-- Benefits: no process fork, no jq/awk dependency, uses Lua SSOT
local cursor = require("lib.cursor")
hl.bind(const.modifier .. " + ALT + mouse_down", function() cursor.zoom_in(2.0) end)
hl.bind(const.modifier .. " + ALT + mouse_up", function() cursor.zoom_out(2.0) end)

-- Resize (works in all layouts)
hl.bind(const.modifier .. " + SHIFT + left", hl.dsp.window.resize({x=-50, y=0, relative=true}), { repeating = true })
hl.bind(const.modifier .. " + SHIFT + right", hl.dsp.window.resize({x=50, y=0, relative=true}), { repeating = true })
hl.bind(const.modifier .. " + SHIFT + up", hl.dsp.window.resize({x=0, y=-50, relative=true}), { repeating = true })
hl.bind(const.modifier .. " + SHIFT + down", hl.dsp.window.resize({x=0, y=50, relative=true}), { repeating = true })

-- Move window (works in all layouts)
hl.bind(const.modifier .. " + CTRL + left", hl.dsp.window.move({direction="l"}))
hl.bind(const.modifier .. " + CTRL + right", hl.dsp.window.move({direction="r"}))
hl.bind(const.modifier .. " + CTRL + up", hl.dsp.window.move({direction="u"}))
hl.bind(const.modifier .. " + CTRL + down", hl.dsp.window.move({direction="d"}))

-- Swap window (works in all layouts)
hl.bind(const.modifier .. " + ALT + left", hl.dsp.window.swap({direction="l"}))
hl.bind(const.modifier .. " + ALT + right", hl.dsp.window.swap({direction="r"}))
hl.bind(const.modifier .. " + ALT + up", hl.dsp.window.swap({direction="u"}))
hl.bind(const.modifier .. " + ALT + down", hl.dsp.window.swap({direction="d"}))

-- Focus (works in all layouts)
hl.bind(const.modifier .. " + left", hl.dsp.focus({direction="l"}))
hl.bind(const.modifier .. " + right", hl.dsp.focus({direction="r"}))
hl.bind(const.modifier .. " + up", hl.dsp.focus({direction="u"}))
hl.bind(const.modifier .. " + down", hl.dsp.focus({direction="d"}))

-- Cycle
hl.bind("ALT + tab", hl.dsp.window.cycle_next())

-- Group management
hl.bind(const.modifier .. " + G", hl.dsp.group.toggle())
hl.bind(const.modifier .. " + Tab", hl.dsp.group.next())
hl.bind(const.modifier .. " + SHIFT + Tab", hl.dsp.group.prev())
hl.bind(const.modifier .. " + CTRL + tab", hl.dsp.group.next())
hl.bind(const.modifier .. " + CTRL + K", hl.dsp.window.move({into_group="l"}))
hl.bind(const.modifier .. " + CTRL + L", hl.dsp.window.move({into_group="r"}))
hl.bind(const.modifier .. " + CTRL + H", hl.dsp.window.move({out_of_group=true}))

-- Window properties
hl.bind(const.modifier .. " + CTRL + O", hl.dsp.window.set_prop({prop="opaque", value="toggle"}))

-- ── LAYOUT-SPECIFIC KEYBINDS ───────────────────────────────────────
-- master-only
hl.bind(const.modifier .. " + CTRL + D", hl.dsp.layout("removemaster"))
hl.bind(const.modifier .. " + I", hl.dsp.layout("addmaster"))
hl.bind(const.modifier .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"))
-- dwindle-only
hl.bind(const.modifier .. " + SHIFT + I", hl.dsp.layout("togglesplit"))
hl.bind(const.modifier .. " + P", hl.dsp.window.pseudo())
hl.bind(const.modifier .. " + M", hl.dsp.layout("splitratio 0.3"))
-- scrolling-only
hl.bind(const.modifier .. " + period", hl.dsp.layout("move +col"))
hl.bind(const.modifier .. " + comma", hl.dsp.layout("move -col"))
hl.bind(const.modifier .. " + bracketright", hl.dsp.layout("colresize +0.1"))
hl.bind(const.modifier .. " + bracketleft", hl.dsp.layout("colresize -0.1"))
hl.bind(const.modifier .. " + CTRL + bracketright", hl.dsp.layout("colresize +conf"))
hl.bind(const.modifier .. " + CTRL + bracketleft", hl.dsp.layout("colresize -conf"))
hl.bind(const.modifier .. " + ALT + F", hl.dsp.layout("fit active"))
hl.bind(const.modifier .. " + ALT + SHIFT + F", hl.dsp.layout("fit visible"))
hl.bind(const.modifier .. " + CTRL + comma", hl.dsp.layout("swapcol l"))
hl.bind(const.modifier .. " + CTRL + period", hl.dsp.layout("swapcol r"))
hl.bind(const.modifier .. " + apostrophe", hl.dsp.layout("promote"))
hl.bind(const.modifier .. " + CTRL + T", hl.dsp.layout("fit into_view"))

-- ── WORKSPACE ──────────────────────────────────────────────────────
hl.bind(const.modifier .. " + 1", hl.dsp.focus({workspace=1}))
hl.bind(const.modifier .. " + 2", hl.dsp.focus({workspace=2}))
hl.bind(const.modifier .. " + 3", hl.dsp.focus({workspace=3}))
hl.bind(const.modifier .. " + 4", hl.dsp.focus({workspace=4}))
hl.bind(const.modifier .. " + 5", hl.dsp.focus({workspace=5}))
hl.bind(const.modifier .. " + 6", hl.dsp.focus({workspace=6}))
hl.bind(const.modifier .. " + 7", hl.dsp.focus({workspace=7}))
hl.bind(const.modifier .. " + 8", hl.dsp.focus({workspace=8}))
hl.bind(const.modifier .. " + 9", hl.dsp.focus({workspace=9}))
hl.bind(const.modifier .. " + 0", hl.dsp.focus({workspace=10}))

hl.bind(const.modifier .. " + SHIFT + 1", hl.dsp.window.move({workspace=1}))
hl.bind(const.modifier .. " + SHIFT + 2", hl.dsp.window.move({workspace=2}))
hl.bind(const.modifier .. " + SHIFT + 3", hl.dsp.window.move({workspace=3}))
hl.bind(const.modifier .. " + SHIFT + 4", hl.dsp.window.move({workspace=4}))
hl.bind(const.modifier .. " + SHIFT + 5", hl.dsp.window.move({workspace=5}))
hl.bind(const.modifier .. " + SHIFT + 6", hl.dsp.window.move({workspace=6}))
hl.bind(const.modifier .. " + SHIFT + 7", hl.dsp.window.move({workspace=7}))
hl.bind(const.modifier .. " + SHIFT + 8", hl.dsp.window.move({workspace=8}))
hl.bind(const.modifier .. " + SHIFT + 9", hl.dsp.window.move({workspace=9}))
hl.bind(const.modifier .. " + SHIFT + 0", hl.dsp.window.move({workspace=10}))

hl.bind(const.modifier .. " + mouse_down", hl.dsp.focus({workspace="e+1"}))
hl.bind(const.modifier .. " + mouse_up", hl.dsp.focus({workspace="e-1"}))

-- Special workspace
hl.bind(const.modifier .. " + minus", hl.dsp.workspace.toggle_special("magic"))
hl.bind(const.modifier .. " + SHIFT + minus", hl.dsp.window.move({workspace="special:magic", follow=false}))

-- Move workspace to monitor
hl.bind(const.modifier .. " + CTRL + F9", hl.dsp.workspace.move({monitor="l"}))
hl.bind(const.modifier .. " + CTRL + F10", hl.dsp.workspace.move({monitor="r"}))
hl.bind(const.modifier .. " + CTRL + F11", hl.dsp.workspace.move({monitor="u"}))
hl.bind(const.modifier .. " + CTRL + F12", hl.dsp.workspace.move({monitor="d"}))

-- ── MEDIA KEYS (locked) ────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(const.dirs.scripts .. "/Volume.sh --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(const.dirs.scripts .. "/Volume.sh --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(const.dirs.scripts .. "/Volume.sh --toggle-mic"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(const.dirs.scripts .. "/Volume.sh --toggle"), { locked = true })
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("XF86WLAN", hl.dsp.exec_cmd(const.dirs.scripts .. "/AirplaneMode.sh"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(const.dirs.scripts .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(const.dirs.scripts .. "/MediaCtrl.sh --nxt"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(const.dirs.scripts .. "/MediaCtrl.sh --prv"), { locked = true })

-- ── SCREENSHOTS ────────────────────────────────────────────────────
hl.bind(const.modifier .. " + Print", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --now"))
hl.bind(const.modifier .. " + SHIFT + Print", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --area"))
hl.bind(const.modifier .. " + CTRL + Print", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --in5"))
hl.bind(const.modifier .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --in10"))
hl.bind("ALT + Print", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --active"))
hl.bind(const.modifier .. " + SHIFT + S", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --swappy"))

-- ── KEYBOARD LAYOUT SWITCH ─────────────────────────────────────────
hl.bind("ALT_L + SHIFT_L", hl.dsp.exec_cmd(const.dirs.scripts .. "/SwitchKeyboardLayout.sh"), { locked = true, non_consumed = true })
hl.bind("SHIFT_L + ALT_L", hl.dsp.exec_cmd(const.dirs.scripts .. "/Tak0-Per-Window-Switch.sh"), { locked = true, non_consumed = true })

-- ── MOUSE BINDS ────────────────────────────────────────────────────
hl.bind(const.modifier .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(const.modifier .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
