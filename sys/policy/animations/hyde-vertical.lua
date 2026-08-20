-- @path: sys/policy/animations/hyde-vertical.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: hyde-vertical animation preset

hl.config({ animations = { enabled = true } })
hl.curve("fluent_decel", { type = "bezier", points = { { 0, 0.2 }, { 0.4, 1 } } })
hl.curve("easeOutCirc", { type = "bezier", points = { { 0, 0.55 }, { 0.45, 1 } } })
hl.curve("easeOutCubic", { type = "bezier", points = { { 0.33, 1 }, { 0.68, 1 } } })
hl.curve("easeinoutsine", { type = "bezier", points = { { 0.37, 0 }, { 0.63, 1 } } })
hl.animation({ leaf = "windowsIn", enabled = "1", speed = "1.5", bezier = "easeinoutsine", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = "1", speed = "1.5", bezier = "easeOutCubic", style = "popin 60%" })
hl.animation({ leaf = "windowsMove", enabled = "1", speed = "1.5", bezier = "easeinoutsine", style = "slide" })
hl.animation({ leaf = "fade", enabled = "1", speed = "2.5", bezier = "fluent_decel" })
hl.animation({ leaf = "fadeLayersIn", enabled = "0" })
hl.animation({ leaf = "border", enabled = "0" })
hl.animation({ leaf = "layers", enabled = "1", speed = "1.5", bezier = "easeinoutsine", style = "popin" })
hl.animation({ leaf = "workspaces", enabled = "1", speed = "3", bezier = "fluent_decel", style = "slidefadevert 30%" })
hl.animation({ leaf = "specialWorkspace", enabled = "1", speed = "2", bezier = "fluent_decel", style = "slidefade 10%" })
