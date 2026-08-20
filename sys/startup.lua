-- @path: sys/startup.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: exec-once commands (hl.on hyprland.start event hook)
--
-- exec-once commands (emitted via hyprland.start event)
-- 通解: all daemon names from lib.deps (DI), no hardcoded literals

local const = _G.HYPR_CONST
local deps = require("lib.deps")

hl.on("hyprland.start", function()
	-- Environment propagation
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Wallpaper daemon (uses deps.cmd for --format argb SSOT)
	hl.exec_cmd(deps.cmd("wallpaper_daemon"))

	-- Auth agent
	local auth = deps.get("auth_agent")
	if auth.found then
		hl.exec_cmd(const.S .. "/Polkit-NixOS.sh")
	end

	-- Keybind layout init
	hl.exec_cmd(const.S .. "/KeybindsLayoutInit.sh")

	-- Drop-down terminal (uses const.M_terminal — terminal from const, not hardcoded)
	hl.exec_cmd(const.S .. "/Dropterminal.sh " .. const.M_terminal .. " &")

	-- Network applet (DI: from deps, not hardcoded "nm-applet")
	local net = deps.get("network_applet")
	if net.found then
		hl.exec_cmd(net.cmd .. " --indicator")
	end

	-- Notification daemon
	local notif = deps.get("notification")
	if notif.found then
		hl.exec_cmd(notif.cmd)
	end

	-- Status bar
	local bar = deps.get("bar")
	if bar.found then
		hl.exec_cmd(bar.cmd)
	end

	-- Quickshell overview
	hl.exec_cmd("qs -c overview")

	-- Clipboard (DI: from deps)
	local clip = deps.get("clipboard")
	local wl_paste = deps.get("wl_paste")
	if clip.found and wl_paste.found then
		hl.exec_cmd(wl_paste.cmd .. " --type text --watch " .. clip.cmd .. " store")
		hl.exec_cmd(wl_paste.cmd .. " --type image --watch " .. clip.cmd .. " store")
	end

	-- Idle daemon (config path from deps, not hardcoded)
	local idle = deps.get("idle_daemon")
	if idle.found and idle.config_path then
		hl.exec_cmd(idle.cmd .. " -c " .. idle.config_path)
	end

	-- Night light init (state machine)
	local nl = deps.get("nightlight")
	if nl.found then
		hl.exec_cmd(const.S .. "/Hyprsunset.sh init")
	end
end)
