-- @path: sys/policy/animations/ml4w-fast.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: ml4w-fast animation preset

hl.config({ animations = { enabled = true } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.animation({ leaf = "windows", enabled = "1", speed = "3", bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "border", enabled = "1", speed = "10", bezier = "default" })
hl.animation({ leaf = "fade", enabled = "1", speed = "2.5", bezier = "md3_decel" })
hl.animation({ leaf = "workspaces", enabled = "1", speed = "3.5", bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = "1", speed = "3", bezier = "md3_decel", style = "slidevert" })
