-- @path: sys/statemachine/nightlight.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: NightLight state machine (off↔on toggle, hyprsunset daemon)
--
-- sys/statemachine/nightlight.lua — Night Light SM
-- 通解: toggle on/off with hyprsunset daemon (not hyprctl reload)

local SM = require("lib.sm")
local M = {}

local STATE_FILE = os.getenv("HOME") .. "/.cache/.hyprsunset_state"
local TARGET_TEMP = 4500

function M.new(hl)
	local initial = "off"
	local f = io.open(STATE_FILE, "r")
	if f then
		local state = f:read("*l")
		f:close()
		if state == "on" then
			initial = "on"
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
		if state == "on" then
			hl.exec_cmd("hyprsunset -t " .. TARGET_TEMP .. " &")
		else
			hl.exec_cmd("pkill -x hyprsunset 2>/dev/null")
		end
		persist(state)
	end

	return SM.new({
		states = { "off", "on" },
		initial = initial,
		invariant = function(sm)
			return sm.current == "off" or sm.current == "on"
		end,
		transitions = {
			{
				from = "off",
				on = "toggle",
				to = "on",
				action = function(_, _, to)
					apply(to)
				end,
			},
			{
				from = "on",
				on = "toggle",
				to = "off",
				action = function(_, _, to)
					apply(to)
				end,
			},
		},
	})
end

return M
