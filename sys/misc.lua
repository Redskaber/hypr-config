-- @path: sys/misc.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Miscellaneous options (vrr/swallow/ANR/session lock)

const = require("const")

hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = 2,
		mouse_move_enables_dpms = true,
		enable_swallow = false,
		swallow_regex = "^(" .. const.apps.terminal .. ")$",
		focus_on_activate = false,
		initial_workspace_tracking = 0,
		middle_click_paste = false,
		enable_anr_dialog = true,
		anr_missed_pings = 15,
		allow_session_lock_restore = true,
	},
	debug = {
		vfr = true,
	},
})
