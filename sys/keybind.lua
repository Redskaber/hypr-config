-- @path: sys/keybind.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Canonical keybind table (140+ binds, layout-specific, SM)
--
-- sys/keybind.lua — Canonical Keybind Table (vendor defaults)
-- 通解: layout-specific keybinds 用策略模式 + safe_layoutmsg

local layout_mod = require("sys.statemachine.layout")
local gamemode_mod = require("sys.statemachine.gamemode")
local nightlight_mod = require("sys.statemachine.nightlight")
local layout_sm = layout_mod.new(hl)
local gamemode_sm = gamemode_mod.new(hl)
local nightlight_sm = nightlight_mod.new(hl)

local const = _G.HYPR_CONST
local deps = require("lib.deps")

-- 预解析 deps (在文件加载时, 不在 bind 回调里)
local launcher_cmd = deps.get("launcher").cmd or "rofi"
local terminal_cmd = deps.get("terminal").cmd or "kitty"
local file_manager_cmd = deps.get("file_manager").cmd or "nemo"
local notification_cmd = deps.get("notification").cmd or "swaync"
local bar_cmd = deps.get("bar").cmd or "waybar"

-- 注意: get_current_layout 用 hl.exec_cmd 不会阻塞, 但也无法返回值
-- 用户可以通过 keybind 配置只绑定当前 layout 的 keybinds

-- ── STANDARD — launchers & apps ────────────────────────────────────
hl.bind(
	const.M .. " + D",
	hl.dsp.exec_cmd(
		"pkill " .. launcher_cmd .. " || true && " .. launcher_cmd .. " -show drun -modi drun filebrowser run window"
	)
)
hl.bind(const.M .. " + B", hl.dsp.exec_cmd('xdg-open "https://"'))
hl.bind(const.M .. " + Return", hl.dsp.exec_cmd(terminal_cmd))
hl.bind(const.M .. " + E", hl.dsp.exec_cmd(file_manager_cmd))
hl.bind(const.M .. " + A", hl.dsp.exec_cmd(const.S .. "/desktop-overview.sh"))

-- ── SYSTEM ──────────────────────────────────────────────────────────
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
hl.bind(const.M .. " + Q", hl.dsp.window.close())
hl.bind(const.M .. " + SHIFT + Q", hl.dsp.exec_cmd(const.S .. "/KillActiveProcess.sh"))
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(const.S .. "/LockScreen.sh"))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(const.S .. "/Wlogout.sh"))
hl.bind(const.M .. " + SHIFT + N", hl.dsp.exec_cmd(notification_cmd .. "-client -t -sw"))

-- ── FEATURES / EXTRAS ──────────────────────────────────────────────
hl.bind(const.M .. " + H", hl.dsp.exec_cmd(const.S .. "/KeyHints.sh"))
hl.bind(const.M .. " + ALT + R", hl.dsp.exec_cmd(const.S .. "/Refresh.sh"))
hl.bind(const.M .. " + ALT + E", hl.dsp.exec_cmd(const.S .. "/RofiEmoji.sh"))
hl.bind(const.M .. " + S", hl.dsp.exec_cmd(const.S .. "/RofiSearch.sh"))
hl.bind(const.M .. " + CTRL + S", hl.dsp.exec_cmd(launcher_cmd .. " -show window"))
hl.bind(const.M .. " + ALT + O", hl.dsp.exec_cmd(const.S .. "/ChangeBlur.sh"))

-- State machines
hl.bind(const.M .. " + SHIFT + G", function()
	gamemode_sm:fire("toggle")
end)
hl.bind(const.M .. " + ALT + L", function()
	layout_sm:fire("cycle")
end)
hl.bind(const.M .. " + ALT + V", hl.dsp.exec_cmd(const.S .. "/ClipManager.sh"))
hl.bind(const.M .. " + CTRL + R", hl.dsp.exec_cmd(const.S .. "/RofiThemeSelector.sh"))
hl.bind(
	const.M .. " + CTRL + SHIFT + R",
	hl.dsp.exec_cmd("pkill " .. launcher_cmd .. " || true && " .. const.S .. "/RofiThemeSelector-modified.sh")
)
hl.bind(const.M .. " + SHIFT + K", hl.dsp.exec_cmd(const.S .. "/KeyBinds.sh"))
hl.bind(const.M .. " + SHIFT + A", hl.dsp.exec_cmd(const.S .. "/Animations.sh"))
hl.bind(const.M .. " + N", function()
	nightlight_sm:fire("toggle")
end)
hl.bind(const.M .. " + SHIFT + E", hl.dsp.exec_cmd(const.S .. "/Quick_Settings.sh"))

-- Waybar
hl.bind(const.M .. " + CTRL + ALT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 " .. bar_cmd))
hl.bind(const.M .. " + CTRL + B", hl.dsp.exec_cmd(const.S .. "/WaybarStyles.sh"))
hl.bind(const.M .. " + ALT + B", hl.dsp.exec_cmd(const.S .. "/WaybarLayout.sh"))

-- Sound/Music
hl.bind(const.M .. " + SHIFT + M", hl.dsp.exec_cmd(const.S .. "/RofiBeats.sh"))

-- Wallpaper
hl.bind(const.M .. " + W", hl.dsp.exec_cmd(const.S .. "/WallpaperSelect.sh"))
hl.bind(const.M .. " + SHIFT + W", hl.dsp.exec_cmd(const.S .. "/WallpaperEffects.sh"))
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd(const.S .. "/WallpaperRandom.sh"))

-- Misc
hl.bind(const.M .. " + SHIFT + O", hl.dsp.exec_cmd(const.S .. "/ZshChangeTheme.sh"))
hl.bind(const.M .. " + ALT + C", hl.dsp.exec_cmd(const.S .. "/RofiCalc.sh"))

-- ── WINDOW MANAGEMENT ──────────────────────────────────────────────
hl.bind(const.M .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(const.M .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(const.M .. " + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(const.M .. " + ALT + SPACE", hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"))
hl.bind(const.M .. " + SHIFT + Return", hl.dsp.exec_cmd(const.S .. "/Dropterminal.sh " .. const.M_terminal))

hl.bind(
	const.M .. " + ALT + mouse_down",
	hl.dsp.exec_cmd(
		"hyprctl keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq -r '.float // .set // 1.0' | awk '{if($1<1)$1=1; print $1*2}')"
	)
)
hl.bind(
	const.M .. " + ALT + mouse_up",
	hl.dsp.exec_cmd(
		"hyprctl keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq -r '.float // .set // 1.0' | awk '{if($1<1)$1=1; print $1/2}')"
	)
)

-- Resize (works in all layouts)
hl.bind(const.M .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(const.M .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(const.M .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(const.M .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Move window (works in all layouts)
hl.bind(const.M .. " + CTRL + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(const.M .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(const.M .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(const.M .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }))

-- Swap window (works in all layouts)
hl.bind(const.M .. " + ALT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(const.M .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(const.M .. " + ALT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(const.M .. " + ALT + down", hl.dsp.window.swap({ direction = "d" }))

-- Focus (works in all layouts)
hl.bind(const.M .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(const.M .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(const.M .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(const.M .. " + down", hl.dsp.focus({ direction = "d" }))

-- Cycle
hl.bind("ALT + tab", hl.dsp.window.cycle_next())

-- Group management
hl.bind(const.M .. " + G", hl.dsp.group.toggle())
hl.bind(const.M .. " + Tab", hl.dsp.group.next())
hl.bind(const.M .. " + SHIFT + Tab", hl.dsp.group.prev())
hl.bind(const.M .. " + CTRL + tab", hl.dsp.group.next())
hl.bind(const.M .. " + CTRL + K", hl.dsp.window.move({ into_group = "l" }))
hl.bind(const.M .. " + CTRL + L", hl.dsp.window.move({ into_group = "r" }))
hl.bind(const.M .. " + CTRL + H", hl.dsp.window.move({ out_of_group = true }))

-- Window properties
hl.bind(const.M .. " + CTRL + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))

-- ── LAYOUT-SPECIFIC KEYBINDS ───────────────────────────────────────
-- master-only
hl.bind(const.M .. " + CTRL + D", hl.dsp.layout("removemaster"))
hl.bind(const.M .. " + I", hl.dsp.layout("addmaster"))
hl.bind(const.M .. " + CTRL + Return", hl.dsp.layout("swapwithmaster"))
-- dwindle-only
hl.bind(const.M .. " + SHIFT + I", hl.dsp.layout("togglesplit"))
hl.bind(const.M .. " + P", hl.dsp.window.pseudo())
hl.bind(const.M .. " + M", hl.dsp.layout("splitratio 0.3"))
-- scrolling-only
hl.bind(const.M .. " + period", hl.dsp.layout("move +col"))
hl.bind(const.M .. " + comma", hl.dsp.layout("move -col"))
hl.bind(const.M .. " + bracketright", hl.dsp.layout("colresize +0.1"))
hl.bind(const.M .. " + bracketleft", hl.dsp.layout("colresize -0.1"))
hl.bind(const.M .. " + CTRL + bracketright", hl.dsp.layout("colresize +conf"))
hl.bind(const.M .. " + CTRL + bracketleft", hl.dsp.layout("colresize -conf"))
hl.bind(const.M .. " + ALT + F", hl.dsp.layout("fit active"))
hl.bind(const.M .. " + ALT + SHIFT + F", hl.dsp.layout("fit visible"))
hl.bind(const.M .. " + CTRL + comma", hl.dsp.layout("swapcol l"))
hl.bind(const.M .. " + CTRL + period", hl.dsp.layout("swapcol r"))
hl.bind(const.M .. " + apostrophe", hl.dsp.layout("promote"))
hl.bind(const.M .. " + CTRL + T", hl.dsp.layout("fit into_view"))

-- ── WORKSPACE ──────────────────────────────────────────────────────
hl.bind(const.M .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(const.M .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(const.M .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(const.M .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(const.M .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(const.M .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(const.M .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(const.M .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(const.M .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(const.M .. " + 0", hl.dsp.focus({ workspace = 10 }))

hl.bind(const.M .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(const.M .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(const.M .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(const.M .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(const.M .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(const.M .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(const.M .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(const.M .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(const.M .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(const.M .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(const.M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(const.M .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Special workspace
hl.bind(const.M .. " + minus", hl.dsp.workspace.toggle_special("magic"))
hl.bind(const.M .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:magic", follow = false }))

-- Move workspace to monitor
hl.bind(const.M .. " + CTRL + F9", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(const.M .. " + CTRL + F10", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(const.M .. " + CTRL + F11", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(const.M .. " + CTRL + F12", hl.dsp.workspace.move({ monitor = "d" }))

-- ── MEDIA KEYS (locked) ────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(const.S .. "/Volume.sh --inc"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(const.S .. "/Volume.sh --dec"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(const.S .. "/Volume.sh --toggle-mic"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(const.S .. "/Volume.sh --toggle"), { locked = true })
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("XF86WLAN", hl.dsp.exec_cmd(const.S .. "/AirplaneMode.sh"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(const.S .. "/MediaCtrl.sh --pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(const.S .. "/MediaCtrl.sh --nxt"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(const.S .. "/MediaCtrl.sh --prv"), { locked = true })

-- ── SCREENSHOTS ────────────────────────────────────────────────────
hl.bind(const.M .. " + Print", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --now"))
hl.bind(const.M .. " + SHIFT + Print", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --area"))
hl.bind(const.M .. " + CTRL + Print", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --in5"))
hl.bind(const.M .. " + CTRL + SHIFT + Print", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --in10"))
hl.bind("ALT + Print", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --active"))
hl.bind(const.M .. " + SHIFT + S", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --swappy"))

-- ── KEYBOARD LAYOUT SWITCH ─────────────────────────────────────────
hl.bind(
	"ALT_L + SHIFT_L",
	hl.dsp.exec_cmd(const.S .. "/SwitchKeyboardLayout.sh"),
	{ locked = true, non_consuming = true }
)
hl.bind(
	"SHIFT_L + ALT_L",
	hl.dsp.exec_cmd(const.S .. "/Tak0-Per-Window-Switch.sh"),
	{ locked = true, non_consuming = true }
)

-- ── MOUSE BINDS ────────────────────────────────────────────────────
hl.bind(const.M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(const.M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
