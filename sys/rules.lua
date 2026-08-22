-- @path: sys/rules.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Window & layer rules — tag-driven, structured fields

-- DRY helper: generate the common float+center+size+opacity 4-tuple pattern.
-- Eliminates ~24 lines of repetition (8 tags × 3 saved lines each).
-- Usage: floating_panel("im", { "monitor_w * 0.60", "monitor_h * 0.70" }, "0.94 0.86")
local function floating_panel(tag, size_expr, opacity_str)
	hl.window_rule({ float = true, match = { tag = tag } })
	hl.window_rule({ center = true, match = { tag = tag } })
	hl.window_rule({ size = size_expr, match = { tag = tag } })
	if opacity_str then
		hl.window_rule({ opacity = opacity_str, match = { tag = tag } })
	end
end

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
floating_panel("im", { "monitor_w * 0.60", "monitor_h * 0.70" }, "0.94 0.86")
hl.window_rule({
	opacity = "0.95 0.88",
	match = { tag = "email" },
})
hl.window_rule({
	opacity = "0.98 0.90",
	match = { tag = "projects" },
})
floating_panel("notes", { "monitor_w * 0.55", "monitor_h * 0.80" }, "0.98 0.90")
floating_panel("file-manager", { "monitor_w * 0.70", "monitor_h * 0.75" }, "0.92 0.82")
hl.window_rule({
	float = true,
	match = { class = "^([Tt]hunar)$" },
})
hl.window_rule({
	float = true,
	match = { class = "^(org.gnome.Nautilus)$" },
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
	size = { "monitor_w * 0.65", "monitor_h * 0.80" },
	match = { tag = "gamestore" },
})
hl.window_rule({
	float = true,
	match = { class = "^([Ss]team)$" },
})
hl.window_rule({
	float = true,
	match = { class = "^(lutris)$" },
})
hl.window_rule({
	float = true,
	match = { class = "^(com.heroicgameslauncher.hgl)$" },
})
floating_panel("viewer", { "monitor_w * 0.70", "monitor_h * 0.75" }, "0.85 0.75")
floating_panel("text-editor", { "monitor_w * 0.65", "monitor_h * 0.75" }, "0.95 0.85")
floating_panel("utils", { "monitor_w * 0.65", "monitor_h * 0.75" }, "0.92 0.82")
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
floating_panel("settings", { "monitor_w * 0.60", "monitor_h * 0.70" }, "0.95 0.85")
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
floating_panel("wallpaper", { "monitor_w * 0.70", "monitor_h * 0.70" }, "0.95 0.85")
hl.window_rule({
	float = true,
	match = { tag = "notif" },
})
hl.window_rule({
	float = true,
	match = { tag = "pip" },
})
hl.window_rule({
	move = { "monitor_w * 0.72", "monitor_h * 0.07" },
	match = { tag = "pip" },
})
hl.window_rule({
	pin = true,
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
	size = { "monitor_w * 0.35", "monitor_h * 0.25" },
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
	size = { "monitor_w * 0.65", "monitor_h * 0.65" },
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
	size = { "monitor_w * 0.65", "monitor_h * 0.90" },
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
	size = { "monitor_w * 0.65", "monitor_h * 0.80" },
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
	size = { "monitor_w * 0.65", "monitor_h * 0.80" },
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
hl.layer_rule({ ignore_alpha = 0.5, match = { namespace = "quickshell:overview" } })
hl.layer_rule({ dim_around = true, match = { namespace = "^(rofi|wlogout)$" } })
hl.layer_rule({ above_lock = 1, match = { namespace = "notifications" } })

-- =============================================================================
-- Event-Driven Compound Conditions (per wiki "Static effects cannot match on
-- dynamically-changing titles" — use hl.on("window.title", fn) + hl.dispatch)
-- =============================================================================
-- These handle the "main window vs sub-window" cases that static window_rule
-- cannot express (e.g. Firefox main window vs Library dialog).
-- Pattern: on title/class change, check if it's a known sub-window pattern
-- and dispatch float action dynamically.

hl.on("window.title", function(w)
	if w == nil then
		return
	end
	-- Firefox: main window has title "Mozilla Firefox" (or appends " - Mozilla Firefox")
	-- Sub-windows (Library, About, Preferences) have different titles → float them
	if w.class and w.class:match("^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr)$") then
		if w.title and not w.title:match("Mozilla Firefox$") then
			hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))
		end
	end
	-- Thunar: main window title is "Thunar" or folder name
	-- Dialogs (Open, Properties) have different titles → float them
	if w.class and w.class:match("^([Tt]hunar)$") then
		if w.title and w.title ~= "Thunar" and not w.title:match(" — Thunar$") then
			hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))
		end
	end
	-- Nautilus (GNOME Files): main window title is folder name
	-- Dialogs have "Open" / "Save" / "Properties" → float them
	if w.class and w.class:match("^(org.gnome.Nautilus|Nautilus)$") then
		if w.title and w.title:match("^(Open|Save|Select|Properties)") then
			hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))
		end
	end
	-- Steam: main window title is "Steam" or "Friends List"
	-- Dialogs (Settings, Downloads) → float them
	if w.class and w.class:match("^([Ss]team)$") then
		if w.title and w.title ~= "Steam" and w.title ~= "Friends List" then
			hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))
		end
	end
end)

-- Also listen on window.open (fires once when window is fully initialized)
-- to catch dialogs that don't change title after creation
hl.on("window.open", function(w)
	if w == nil then
		return
	end
	-- JetBrains: modal dialogs (e.g. "Confirm", "Find in Path") → float + no_steal_focus
	if w.class and w.class:match("^(jetbrains-.+)$") then
		if w.title and (w.title:match("^(Confirm|Find|Replace|Settings)") or w.initial_class ~= w.class) then
			hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))
		end
	end
end)
