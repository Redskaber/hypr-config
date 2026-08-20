-- @path: sys/policy/animations/default.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Default animation preset (curves + animations)

hl.config({ animations = { enabled = true } })
hl.curve("wind", { type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}} })
hl.curve("winIn", { type = "bezier", points = {{0.1, 1.1}, {0.1, 1.1}} })
hl.curve("winOut", { type = "bezier", points = {{0.3, -0.3}, {0, 1}} })
hl.curve("liner", { type = "bezier", points = {{1, 1}, {1, 1}} })
hl.curve("overshot", { type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}} })
hl.curve("smoothOut", { type = "bezier", points = {{0.5, 0}, {0.99, 0.99}} })
hl.curve("smoothIn", { type = "bezier", points = {{0.5, -0.5}, {0.68, 1.5}} })
hl.animation({ leaf = "windows", enabled = true, speed = "6", curve = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = "5", curve = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = "3", curve = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = "5", curve = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = "1", curve = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = "100", curve = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = "3", curve = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = "5", curve = "overshot" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = "5", curve = "winIn", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = "5", curve = "winOut", style = "slide" })
