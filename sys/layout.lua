-- @path: sys/layout.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Window layout engines (dwindle/master/scrolling + binds)
--
-- sys/layout.lua — Window layout engines
-- Three layouts: scrolling (default via user/layout.lua), dwindle, master
-- Runtime cycle: scrolling → dwindle → master → scrolling (via SM module)
--
-- Note: Since Hyprland v0.55, scrolling is a BUILT-IN layout (not a plugin).
-- Config category: `scrolling` (not `plugin:hyprscrolling`).
-- Ref: https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/

hl.config({
	general = {
		layout = "dwindle",
		border_size = 2,
		gaps_in = 2,
		gaps_out = 4,
		resize_on_border = true,
	},
	dwindle = {
		preserve_split = true,
		special_scale_factor = 0.8,
	},
	master = {
		new_status = "master",
		new_on_top = 1,
		mfact = 0.5,
	},
	binds = {
		workspace_back_and_forth = true,
		allow_workspace_cycles = true,
		pass_mouse_when_bound = false,
	},
	scrolling = {
		column_width = 0.5,
		fullscreen_on_one_column = false,
		explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
		focus_fit_method = 0,
		follow_focus = true,
		-- follow_debounce_ms removed in v0.55+ (not in wiki)
	},
})
