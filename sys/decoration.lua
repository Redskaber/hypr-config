-- @path: sys/decoration.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Visual decoration (colors from wallust, shadow/blur/group)
--
-- sys/decoration.lua — Visual decoration
-- Colors from wallust module (wallust 端负责格式, 直接给 "rgb(...)" 或 "#hex")

local colors = require("sys.policy.wallust.wallust-hyprland")

hl.config({
	general = {
		col = {
			active_border = colors.color12,
			inactive_border = colors.color10,
		},
	},
	decoration = {
		rounding = 10,
		active_opacity = 1.0,
		inactive_opacity = 0.9,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.1,
		dim_special = 0.8,
		shadow = {
			enabled = true,
			range = 3,
			render_power = 1,
			color = colors.color12,
			color_inactive = colors.color10,
		},
		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			ignore_opacity = true,
			new_optimizations = true,
			special = true,
			popups = true,
		},
	},
	group = {
		col = {
			border_active = colors.color15,
		},
		groupbar = {
			col = {
				active = colors.color0,
			},
		},
	},
})
