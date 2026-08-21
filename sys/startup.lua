-- @path: sys/startup.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: exec-once commands (hl.on hyprland.start event hook)

local const = require("const")
local deps = require("lib.deps")

hl.on("hyprland.start", function()
  -- Regenerate .deps_cache.sh (in case config changed since bootstrap)
  require("sys.const").export_to_shell()

  -- Environment propagation
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

  -- Wallpaper daemon (uses deps.cmd for --format argb SSOT)
  hl.exec_cmd(deps.cmd("wallpaper_daemon"))

  -- Auth agent
  local auth = deps.get("auth_agent")
  if auth and auth.found then hl.exec_cmd(const.dirs.scripts .. "/Polkit-NixOS.sh") end

  -- Keybind layout init
  hl.exec_cmd(const.dirs.scripts .. "/KeybindsLayoutInit.sh")

  -- Drop-down terminal (uses const.apps.terminal — terminal from const, not hardcoded)
  hl.exec_cmd(const.dirs.scripts .. "/Dropterminal.sh " .. const.apps.terminal .. " &")

  -- Network applet (DI: from deps, not hardcoded "nm-applet")
  local net = deps.get("network_applet")
  if net and net.found then hl.exec_cmd(net.cmd .. " --indicator") end

  -- Notification daemon
  local notif = deps.get("notification")
  if notif and notif.found then hl.exec_cmd(notif.cmd) end

  -- Status bar
  local bar = deps.get("bar")
  if bar and bar.found then hl.exec_cmd(bar.cmd) end

  -- Quickshell overview
  hl.exec_cmd("qs -c overview")

  -- Clipboard (DI: from deps)
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
