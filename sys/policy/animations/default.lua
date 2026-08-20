-- @path: sys/policy/animations/default.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Default animation preset (curves + animations)

hl.config({ animations = { enabled = true } })
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.5, 0 }, { 0.99, 0.99 } } })
hl.curve("smoothIn", { type = "bezier", points = { { 0.5, -0.5 }, { 0.68, 1.5 } } })
hl.animation({ leaf = "windows", enabled = "1", speed = "6", bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = "1", speed = "5", bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = "1", speed = "3", bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = "1", speed = "5", bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = "1", speed = "1", bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = "1", speed = "100", bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = "1", speed = "3", bezier = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = "1", speed = "5", bezier = "overshot" })
hl.animation({ leaf = "workspacesIn", enabled = "1", speed = "5", bezier = "winIn", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = "1", speed = "5", bezier = "winOut", style = "slide" })
