-- @path: sys/statemachine/gamemode.lua
-- @author: redskaber
-- @date: 2026-08-22
-- @version: 1.2 (Round 109 — use const.cache_dir instead of hardcoded $HOME/.cache)
-- @description: GameMode state machine (NORMAL↔GAMING toggle, with state persistence)

local SM = require("lib.sm")
local const = require("const")
local M = {}

-- State persistence file (T79: persist across Hyprland restarts)
-- Round 109: use const.cache_dir (XDG-aware) instead of hardcoded $HOME/.cache
local STATE_FILE = const.cache_dir .. "/.hypr_gamemode_state"

function M.new(hl)
	-- Read persisted state on startup (default to NORMAL if no file)
	local initial = "NORMAL"
	local f = io.open(STATE_FILE, "r")
	if f then
		local state = f:read("*l")
		f:close()
		if state == "GAMING" then
			initial = "GAMING"
		end
	end

	local function persist(state)
		local pf = io.open(STATE_FILE, "w")
		if pf then
			pf:write(state)
			pf:close()
		end
	end

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
			-- Restore sys/layout.lua + sys/decoration.lua original values
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
		persist(state)
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
