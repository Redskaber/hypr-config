-- @path: sys/startup.lua
-- @author: redskaber
-- @date: 2026-08-22
-- @version: 2.0 (Round 107 — added shutdown cleanup handler + removed stale &)
-- @description: exec-once commands (hl.on hyprland.start/shutdown event hooks)
--
-- ARCHITECTURE (Round 107):
--   Per Hyprland wiki (Autostart): "hl.exec_cmd() will spawn an asynchronous
--   process, so there is no need for & disown at the end." Removed trailing `&`
--   from Dropterminal startup (was unnecessary, could cause double-fork).
--
--   Added hyprland.shutdown handler for cleanup (e.g. killing daemons that
--   don't auto-exit on Hyprland quit). Per wiki: "you can spawn processes on
--   exit by listening to hyprland.shutdown."

local const = require("const")
local deps = require("lib.deps")

-- ── STARTUP (hyprland.start event) ─────────────────────────────────────────
hl.on("hyprland.start", function()
	-- Regenerate .deps_cache.sh (in case config changed since bootstrap)
	require("sys.const").export_to_shell()

	-- Environment propagation (D-Bus + systemd)
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Wallpaper daemon (awww-daemon — no --format argb; that's for `awww img` only)
	hl.exec_cmd(deps.cmd("wallpaper_daemon"))

	-- Auth agent (polkit)
	local auth = deps.get("auth_agent")
	if auth and auth.found then
		hl.exec_cmd(const.dirs.scripts .. "/Polkit-NixOS.sh")
	end

	-- Keybind layout init
	hl.exec_cmd(const.dirs.scripts .. "/KeybindsLayoutInit.sh")

	-- Drop-down terminal (terminal from const.apps, not hardcoded)
	-- Round 107: removed trailing `&` — hl.exec_cmd is already async
	hl.exec_cmd(const.dirs.scripts .. "/Dropterminal.sh " .. const.apps.terminal)

	-- Network applet (DI: from deps, not hardcoded "nm-applet")
	local net = deps.get("network_applet")
	if net and net.found then
		hl.exec_cmd(net.cmd .. " --indicator")
	end

	-- Notification daemon
	local notif = deps.get("notification")
	if notif and notif.found then
		hl.exec_cmd(notif.cmd)
	end

	-- Status bar
	local bar = deps.get("bar")
	if bar and bar.found then
		hl.exec_cmd(bar.cmd)
	end

	-- Quickshell overview
	hl.exec_cmd("qs -c overview")

	-- Clipboard history (wl-paste watches clipboard → cliphist stores)
	local clip = deps.get("clipboard")
	local wl_paste = deps.get("wl_paste")
	if clip and clip.found and wl_paste and wl_paste.found then
		hl.exec_cmd(wl_paste.cmd .. " --type text --watch " .. clip.cmd .. " store")
		hl.exec_cmd(wl_paste.cmd .. " --type image --watch " .. clip.cmd .. " store")
	end

	-- Idle daemon (config path from deps, not hardcoded)
	local idle = deps.get("idle_daemon")
	if idle and idle.found and idle.config_path then
		hl.exec_cmd(idle.cmd .. " -c " .. idle.config_path)
	end

	-- Night light init (state machine)
	local nl = deps.get("nightlight")
	if nl and nl.found then
		hl.exec_cmd(const.dirs.scripts .. "/Hyprsunset.sh init")
	end
end)

-- ── SHUTDOWN (hyprland.shutdown event) ─────────────────────────────────────
-- Round 107: added cleanup handler for daemons that don't auto-exit.
-- Per Hyprland wiki: "you can spawn processes on exit by listening to
-- hyprland.shutdown."
hl.on("hyprland.shutdown", function()
	-- Kill daemons that may persist after Hyprland exits
	-- (waybar, swaync, awww-daemon, hypridle all should be cleaned up)
	-- Using `pkill` is safe here — Hyprland is already shutting down
	local bar = deps.get("bar")
	if bar and bar.cmd then
		hl.exec_cmd("pkill " .. bar.cmd)
	end

	local notif = deps.get("notification")
	if notif and notif.cmd then
		hl.exec_cmd("pkill " .. notif.cmd)
	end

	local idle = deps.get("idle_daemon")
	if idle and idle.cmd then
		hl.exec_cmd("pkill " .. idle.cmd)
	end

	local wp = deps.get("wallpaper_daemon")
	if wp and wp.cmd then
		hl.exec_cmd("pkill " .. wp.cmd)
	end
end)
