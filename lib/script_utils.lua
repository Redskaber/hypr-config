-- @path: lib/script_utils.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Shared script utilities (NOTIF_ICON/SCRIPTSDIR/focused_monitor)

local const = require("const")
local deps = require("lib.deps")
local M = {}

M.NOTIF_ICON = const.notify_icon
M.SCRIPTSDIR = const.dirs.scripts

-- Get focused monitor (ONLY at startup, not in bind callbacks)
-- DI: uses deps.get("hyprctl").cmd instead of hard-coded "hyprctl"
function M.focused_monitor()
	local hyprctl_cmd = deps.cmd("hyprctl") or "hyprctl"
	local f = io.popen(hyprctl_cmd .. " monitors -j 2>/dev/null")
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
-- DI: notify-send command resolved via deps, not hard-coded
function M.notify(hl, summary, body, urgency)
	urgency = urgency or "low"
	local notify_cmd = deps.cmd("notify") or "notify-send"
	hl.exec_cmd(string.format("%s -e -u %s -i %s '%s' '%s'", notify_cmd, urgency, M.NOTIF_ICON, summary, body or ""))
end

-- Run in background (use hl.exec_cmd in bind callbacks, this is for startup only)
function M.bg(hl, cmd)
	hl.exec_cmd(cmd .. " &")
end

return M
