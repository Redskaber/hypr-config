-- @path: user/startup.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: User exec-once overrides
--
-- user/startup.lua — User exec-once commands

local deps = require("lib.deps")

hl.on("hyprland.start", function()
	local im = deps.get("input_method")
	if im.found then
		hl.exec_cmd(im.cmd .. " -d -r")
	end
end)
