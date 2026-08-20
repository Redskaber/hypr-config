-- @path: sys/policy/animations/hyde-vertical.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: hyde-vertical animation preset

hl.config({ animations = { enabled = true } })
hl.curve("fluent_decel", { type = "bezier", points = {{0, 0.2}, {0.4, 1}} })
hl.curve("easeOutCirc", { type = "bezier", points = {{0, 0.55}, {0.45, 1}} })
hl.curve("easeOutCubic", { type = "bezier", points = {{0.33, 1}, {0.68, 1}} })
hl.curve("easeinoutsine", { type = "bezier", points = {{0.37, 0}, {0.63, 1}} })
hl.animation({ leaf = "windowsIn", enabled = true, speed = "1.5", curve = "easeinoutsine", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = "1.5", curve = "easeOutCubic", style = "popin 60%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = "1.5", curve = "easeinoutsine", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = "2.5", curve = "fluent_decel" })
hl.animation({ leaf = "fadeLayersIn", enabled = false })
hl.animation({ leaf = "border", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = "1.5", curve = "easeinoutsine", style = "popin" })
hl.animation({ leaf = "workspaces", enabled = true, speed = "3", curve = "fluent_decel", style = "slidefadevert 30%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = "2", curve = "fluent_decel", style = "slidefade 10%" })
