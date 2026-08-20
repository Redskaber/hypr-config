-- @path: sys/input.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Input devices & gestures (keyboard/touchpad/tablet/gestures)

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		repeat_rate = 50,
		repeat_delay = 300,
		sensitivity = 0,
		numlock_by_default = true,
		left_handed = false,
		follow_mouse = 1,
		float_switch_override_focus = false,
		touchpad = {
			disable_while_typing = true,
			natural_scroll = true,
			clickfinger_behavior = false,
			middle_button_emulation = false,
			tap_to_click = true, -- wiki: tap_to_click (not tap-to-click)
			drag_lock = false,
		},
		touchdevice = { enabled = true },
		tablet = { transform = 0, left_handed = 0 },
	},
	gestures = {
		workspace_swipe_distance = 500,
		workspace_swipe_invert = true,
		workspace_swipe_min_speed_to_force = 30,
		workspace_swipe_cancel_ratio = 0.5,
		workspace_swipe_create_new = true,
		workspace_swipe_forever = true,
	},
})

-- Gestures via hl.gesture (NOT hl.config gestures)
-- 3-finger horizontal: workspace switch
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- 4-finger up: zoom in
hl.gesture({ fingers = 4, direction = "up", action = "close" })
