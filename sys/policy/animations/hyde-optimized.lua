-- @path: sys/policy/animations/hyde-optimized.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: hyde-optimized animation preset

hl.config({ animations = { enabled = true } })
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.85 }, { 0.03, 0.97 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.07, 0.88 }, { 0.04, 0.99 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.20, -0.15 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.80 }, { 0.10, 0.97 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.20, 0 }, { 0.80, 0.08 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.05, 0.82 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.20, 0 }, { 0.82, 0.10 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.48 }, { 0.38, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.10, 0.94 }, { 0.23, 0.98 } } })
hl.curve("OutBack", { type = "bezier", points = { { 0.28, 1.40 }, { 0.58, 1 } } })
hl.animation({ leaf = "border", enabled = "1", speed = "1.6", bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = "1", speed = "82", bezier = "liner", style = "once" })
hl.animation({ leaf = "windowsIn", enabled = "1", speed = "3.2", bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = "1", speed = "2.8", bezier = "easeOutCirc" })
hl.animation({ leaf = "windowsMove", enabled = "1", speed = "3", bezier = "wind", style = "slide" })
hl.animation({ leaf = "fade", enabled = "1", speed = "1.8", bezier = "md3_decel" })
hl.animation({ leaf = "layersIn", enabled = "1", speed = "1.8", bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = "1", speed = "1.5", bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn", enabled = "1", speed = "1.6", bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = "1", speed = "1.8", bezier = "menu_accel" })
hl.animation({ leaf = "workspaces", enabled = "1", speed = "4", bezier = "menu_decel", style = "slide" })
hl.animation({
	leaf = "specialWorkspace",
	enabled = "1",
	speed = "2.3",
	bezier = "md3_decel",
	style = "slidefadevert 15%",
})
