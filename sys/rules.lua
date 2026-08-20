-- @path: sys/rules.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Window & layer rules — tag-driven, structured fields

hl.window_rule({
	opacity = "1.00 0.85",
	match = { tag = "browser" },
})
hl.window_rule({
	idle_inhibit = "fullscreen",
	match = { tag = "browser" },
})
hl.window_rule({
	opacity = "0.90 0.80",
	match = { tag = "terminal" },
})
hl.window_rule({
	float = true,
	match = { tag = "im" },
})
hl.window_rule({
	center = true,
	match = { tag = "im" },
})
hl.window_rule({
	size = "(monitor_w*0.60) (monitor_h*0.70)",
	match = { tag = "im" },
})
hl.window_rule({
	opacity = "0.94 0.86",
	match = { tag = "im" },
})
hl.window_rule({
	opacity = "0.95 0.88",
	match = { tag = "email" },
})
hl.window_rule({
	opacity = "0.98 0.90",
	match = { tag = "projects" },
})
hl.window_rule({
	float = true,
	match = { tag = "notes" },
})
hl.window_rule({
	center = true,
	match = { tag = "notes" },
})
hl.window_rule({
	size = "(monitor_w*0.55) (monitor_h*0.80)",
	match = { tag = "notes" },
})
hl.window_rule({
	opacity = "0.98 0.90",
	match = { tag = "notes" },
})
hl.window_rule({
	float = true,
	match = { tag = "file-manager" },
})
hl.window_rule({
	center = true,
	match = { tag = "file-manager" },
})
hl.window_rule({
	size = "(monitor_w*0.70) (monitor_h*0.75)",
	match = { tag = "file-manager" },
})
hl.window_rule({
	opacity = "0.92 0.82",
	match = { tag = "file-manager" },
})
hl.window_rule({
	float = true,
	match = {
		class = "^([Tt]hunar)$,",
		-- title was negative:^(.*[Tt]hunar.*)$ — compound rule, tag system cannot express
	},
})
hl.window_rule({
	float = true,
	match = {
		class = "^(org.gnome.Nautilus)$,",
		-- title was negative:^(Files)$ — compound rule
	},
})
hl.window_rule({
	opacity = "0.94 0.86",
	match = { tag = "multimedia" },
})
hl.window_rule({
	float = true,
	match = { tag = "multimedia-video" },
})
hl.window_rule({
	opacity = "1.0",
	match = { tag = "multimedia-video" },
})
hl.window_rule({
	no_blur = true,
	match = { tag = "multimedia-video" },
})
hl.window_rule({
	idle_inhibit = "always",
	match = { tag = "multimedia-video" },
})
hl.window_rule({
	float = true,
	match = { tag = "screenshare" },
})
hl.window_rule({
	opacity = "1.0",
	match = { tag = "screenshare" },
})
hl.window_rule({
	no_blur = true,
	match = { tag = "screenshare" },
})
hl.window_rule({
	idle_inhibit = "always",
	match = { tag = "screenshare" },
})
hl.window_rule({
	fullscreen = "0",
	match = { tag = "games" },
})
hl.window_rule({
	no_blur = true,
	match = { tag = "games" },
})
hl.window_rule({
	rounding = 0,
	match = { tag = "games" },
})
hl.window_rule({
	idle_inhibit = "always",
	match = { tag = "games" },
})
hl.window_rule({
	float = true,
	match = { tag = "gamestore" },
})
hl.window_rule({
	center = true,
	match = { tag = "gamestore" },
})
hl.window_rule({
	size = "(monitor_w*0.65) (monitor_h*0.80)",
	match = { tag = "gamestore" },
})
hl.window_rule({
	float = true,
	match = {
		class = "^([Ss]team)$,",
		-- title was negative:^([Ss]team)$ — compound rule
	},
})
hl.window_rule({
	float = true,
	match = {
		class = "^(lutris)$,",
		-- title was negative:^(Lutris)$ — compound rule
	},
})
hl.window_rule({
	float = true,
	match = {
		class = "^(com.heroicgameslauncher.hgl)$,",
		-- title was negative:(Heroic... — compound rule",
	},
})
hl.window_rule({
	float = true,
	match = { tag = "viewer" },
})
hl.window_rule({
	center = true,
	match = { tag = "viewer" },
})
hl.window_rule({
	size = "(monitor_w*0.70) (monitor_h*0.75)",
	match = { tag = "viewer" },
})
hl.window_rule({
	opacity = "0.85 0.75",
	match = { tag = "viewer" },
})
hl.window_rule({
	float = true,
	match = { tag = "text-editor" },
})
hl.window_rule({
	center = true,
	match = { tag = "text-editor" },
})
hl.window_rule({
	size = "(monitor_w*0.65) (monitor_h*0.75)",
	match = { tag = "text-editor" },
})
hl.window_rule({
	opacity = "0.95 0.85",
	match = { tag = "text-editor" },
})
hl.window_rule({
	float = true,
	match = { tag = "utils" },
})
hl.window_rule({
	center = true,
	match = { tag = "utils" },
})
hl.window_rule({
	size = "(monitor_w*0.65) (monitor_h*0.75)",
	match = { tag = "utils" },
})
hl.window_rule({
	opacity = "0.92 0.82",
	match = { tag = "utils" },
})
hl.window_rule({
	float = true,
	match = { tag = "calculator" },
})
hl.window_rule({
	center = true,
	match = { tag = "calculator" },
})
hl.window_rule({
	size = "480 640",
	match = { tag = "calculator" },
})
hl.window_rule({
	float = true,
	match = { tag = "settings" },
})
hl.window_rule({
	center = true,
	match = { tag = "settings" },
})
hl.window_rule({
	size = "(monitor_w*0.60) (monitor_h*0.70)",
	match = { tag = "settings" },
})
hl.window_rule({
	opacity = "0.95 0.85",
	match = { tag = "settings" },
})
hl.window_rule({
	float = true,
	match = { tag = "audio-mixer" },
})
hl.window_rule({
	center = true,
	match = { tag = "audio-mixer" },
})
hl.window_rule({
	size = "900 600",
	match = { tag = "audio-mixer" },
})
hl.window_rule({
	opacity = "0.95 0.85",
	match = { tag = "audio-mixer" },
})
hl.window_rule({
	float = true,
	match = { tag = "wallpaper" },
})
hl.window_rule({
	center = true,
	match = { tag = "wallpaper" },
})
hl.window_rule({
	size = "(monitor_w*0.70) (monitor_h*0.70)",
	match = { tag = "wallpaper" },
})
hl.window_rule({
	opacity = "0.95 0.85",
	match = { tag = "wallpaper" },
})
hl.window_rule({
	float = true,
	match = { tag = "notif" },
})
hl.window_rule({
	float = true,
	match = { tag = "pip" },
})
hl.window_rule({
	move = "(monitor_w*0.72) (monitor_h*0.07)",
	match = { tag = "pip" },
})
hl.window_rule({
	pin = true,
	match = { tag = "pip" },
})
hl.window_rule({
	keep_aspect_ratio = true,
	match = { tag = "pip" },
})
hl.window_rule({
	opacity = "0.95 0.75",
	match = { tag = "pip" },
})
hl.window_rule({
	dim_around = true,
	match = { tag = "pip" },
})
hl.window_rule({
	float = true,
	match = { tag = "auth-dialog" },
})
hl.window_rule({
	center = true,
	match = { tag = "auth-dialog" },
})
hl.window_rule({
	size = "(monitor_w*0.35) (monitor_h*0.25)",
	match = { tag = "auth-dialog" },
})
hl.window_rule({
	float = true,
	match = { tag = "file-dialog" },
})
hl.window_rule({
	center = true,
	match = { tag = "file-dialog" },
})
hl.window_rule({
	size = "(monitor_w*0.65) (monitor_h*0.65)",
	match = { tag = "file-dialog" },
})
hl.window_rule({
	float = true,
	match = { tag = "Help_Cheat" },
})
hl.window_rule({
	center = true,
	match = { tag = "Help_Cheat" },
})
hl.window_rule({
	opacity = "0.85 0.85",
	match = { tag = "Help_Cheat" },
})
hl.window_rule({
	size = "(monitor_w*0.65) (monitor_h*0.90)",
	match = { tag = "Help_Cheat" },
})
hl.window_rule({
	float = true,
	match = { tag = "Help_Settings" },
})
hl.window_rule({
	center = true,
	match = { tag = "Help_Settings" },
})
hl.window_rule({
	size = "(monitor_w*0.65) (monitor_h*0.80)",
	match = { tag = "Help_Settings" },
})
hl.window_rule({
	float = true,
	match = { tag = "keybindings" },
})
hl.window_rule({
	center = true,
	match = { tag = "keybindings" },
})
hl.window_rule({
	size = "(monitor_w*0.65) (monitor_h*0.80)",
	match = { tag = "keybindings" },
})
hl.window_rule({
	no_initial_focus = true,
	match = { tag = "no-steal-focus" },
})
hl.window_rule({
	suppress_event = "activate",
	match = { tag = "suppress-activate" },
})
hl.window_rule({
	idle_inhibit = "fullscreen",
	match = { fullscreen = true },
})
hl.layer_rule({ blur = true, match = { namespace = "^(rofi|wlogout|quickshell:overview)$" } })
hl.layer_rule({ blur = true, match = { namespace = "^(notifications|swaync)$" } })
hl.layer_rule({ ignore_alpha = "0.5", match = { namespace = "quickshell:overview" } })
hl.layer_rule({ dim_around = true, match = { namespace = "^(rofi|wlogout)$" } })
hl.layer_rule({ above_lock = 1, match = { namespace = "notifications" } })
