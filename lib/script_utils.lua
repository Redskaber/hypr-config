-- @path: lib/script_utils.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Shared script utilities (NOTIF_ICON/SCRIPTSDIR/focused_monitor)
--
-- wiki WARNING: "Keybind handlers must not block. Avoid io.popen, network I/O"
-- These functions are ONLY for use in startup (file load time) or .sh scripts,
-- NEVER in hl.bind() callback functions.

local const = _G.HYPR_CONST
local M = {}

M.NOTIF_ICON = const.I_notify
M.SCRIPTSDIR = const.S

-- Get focused monitor (ONLY at startup, not in bind callbacks)
function M.focused_monitor()
	local f = io.popen("hyprctl monitors -j 2>/dev/null")
	if not f then
		return nil
	end
	local json = f:read("*a")
	f:close()
	local match = json:match('"name":"([^"]+)"[^}]*"focused":true')
	if match then
		return match
	end
	return json:match('"name":"([^"]+)"')
end

-- Kill existing process (use hl.exec_cmd in bind callbacks, this is for startup only)
function M.kill_existing(hl, proc_name)
	hl.exec_cmd("pkill " .. proc_name .. " 2>/dev/null || true")
end

-- Notify (use hl.exec_cmd in bind callbacks, this is for startup only)
function M.notify(hl, summary, body, urgency)
	urgency = urgency or "low"
	hl.exec_cmd(string.format("notify-send -e -u %s -i %s '%s' '%s'", urgency, M.NOTIF_ICON, summary, body or ""))
end

-- Run in background (use hl.exec_cmd in bind callbacks, this is for startup only)
function M.bg(hl, cmd)
	hl.exec_cmd(cmd .. " &")
end

return M
