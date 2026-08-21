-- @path: sys/scripts/lua/system.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: System action module (screenshot/logout/lock/kill)

local deps = require("lib.deps")
local utils = require("lib.script_utils")

local M = {}

-- Screenshot (replaces ScreenShot.sh)
-- Uses deps.get("screenshot") + deps.get("slurp") — not hardcoded grim/slurp
function M.screenshot(hl, mode)
  mode = mode or "region"  -- region | full | window
  local shot = deps.get("screenshot")
  local slurp = deps.get("slurp")
  local timestamp = os.date("%Y%m%d_%H%M%S")
  local outfile = os.getenv("HOME") .. "/Pictures/Screenshots/screenshot_" .. timestamp .. ".png"

  if not shot or not shot.cmd then
    utils.notify(hl, "Screenshot", "screenshot tool not found", "critical")
    return
  end

  local cmd
  if mode == "full" then
    cmd = shot.cmd .. " '" .. outfile .. "'"
  elseif mode == "region" and slurp and slurp.found then
    cmd = shot.cmd .. ' -g "$(' .. slurp.cmd .. ')" "' .. outfile .. '"'
  else
    cmd = shot.cmd .. " '" .. outfile .. "'"
  end
  hl.exec_cmd(cmd)
  utils.notify(hl, "Screenshot", "Saved: " .. outfile)
end

-- Logout menu (replaces Wlogout.sh)
function M.logout_menu(hl)
  local menu = deps.get("logout_menu")
  if menu and menu.found then
    hl.exec_cmd(menu.cmd)
    return
  end
  -- Fallback: rofi-based menu
  local items = { "Lock", "Logout", "Suspend", "Reboot", "Shutdown" }
  local launcher = deps.get("launcher")
  if not launcher or not launcher.cmd then return end
  local cmd = "echo '" .. table.concat(items, "\\n") .. "' | " .. launcher.cmd .. " -dmenu -p 'Power:'"
  local f = io.popen(cmd)
  if not f then return end
  local selected = f:read("*l")
  f:close()
  if selected then
    local actions = {
      Lock = "hyprlock", Logout = "hyprctl dispatch exit",
      Suspend = "systemctl suspend", Reboot = "systemctl reboot",
      Shutdown = "systemctl poweroff",
    }
    local action = actions[selected]
    if action then hl.exec_cmd(action) end
  end
end

-- Lock screen (replaces LockScreen.sh)
function M.lock(hl)
  local lock = deps.get("lock")
  if lock and lock.cmd then
    hl.exec_cmd(lock.cmd)
  end
end

-- Portal setup (replaces PortalHyprland.sh)
function M.setup_portal(hl)
  hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland")
  hl.exec_cmd("systemctl --user start xdg-desktop-portal-gtk 2>/dev/null || true")
end

-- Kill active process (replaces KillActiveProcess.sh)
function M.kill_active(hl)
  hl.dsp.window.kill({})
  utils.notify(hl, "Kill", "Active window killed")
end

return M
