-- @path: sys/statemachine/gamemode.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: GameMode state machine (NORMAL↔GAMING toggle)

local SM = require("lib.sm")
local M = {}

function M.new(hl)
	local initial = "NORMAL"

	local function apply(state)
		if state == "GAMING" then
			hl.config({
				animations = { enabled = false },
				decoration = {
					shadow = { enabled = false },
					blur = { enabled = false },
					rounding = 0,
				},
				general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
			})
		else
			-- 恢复 sys/layout.lua + sys/decoration.lua 的原始值
			hl.config({
				animations = { enabled = true },
				decoration = {
					shadow = { enabled = true },
					blur = { enabled = true },
					rounding = 10,
				},
				general = { gaps_in = 2, gaps_out = 4, border_size = 2 },
			})
		end
	end

	return SM.new({
		states = { "NORMAL", "GAMING" },
		initial = initial,
		invariant = function(sm)
			return sm.current == "NORMAL" or sm.current == "GAMING"
		end,
		transitions = {
			{
				from = "NORMAL",
				on = "toggle",
				to = "GAMING",
				action = function(_, _, to)
					apply(to)
				end,
			},
			{
				from = "GAMING",
				on = "toggle",
				to = "NORMAL",
				action = function(_, _, to)
					apply(to)
				end,
			},
		},
	})
end

return M
