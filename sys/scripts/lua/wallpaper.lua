-- @path: sys/scripts/lua/wallpaper.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Wallpaper subsystem module (select/random/set/regenerate)

local deps = require("lib.deps")
local utils = require("lib.script_utils")
local const = require("const")

local M = {}

-- Select wallpaper via rofi menu (replaces WallpaperSelect.sh)
function M.select(hl)
  local launcher = deps.get("launcher")
  if not launcher then return end
  local launcher_cmd = launcher.cmd or "rofi"
  local wp_dir = const.wallpaper_dir
  local cmd = string.format(
    "ls %s/*.{jpg,png} 2>/dev/null | %s -dmenu -p 'Wallpaper:'",
    wp_dir, launcher_cmd
  )
  local f = io.popen(cmd)
  if not f then return nil end
  local selected = f:read("*l")
  f:close()
  if selected and #selected > 0 then
    M.set(hl, selected)
  end
end

-- Set wallpaper (replaces the core of WallpaperEffects.sh + swww_wallpaper.sh)
function M.set(hl, wallpaper_path)
  local wp_daemon = deps.get("wallpaper_daemon")
  if not wp_daemon then return end
  local cmd = (wp_daemon.cmd or "awww-daemon") .. " img '" .. wallpaper_path .. "'"
  if wp_daemon.default_args and wp_daemon.default_args.format then
    cmd = (wp_daemon.cmd or "awww-daemon") .. " --format " .. wp_daemon.default_args.format
    cmd = cmd .. " img '" .. wallpaper_path .. "'"
  end
  hl.exec_cmd(cmd)
  -- Update current wallpaper symlink
  hl.exec_cmd("ln -sfn '" .. wallpaper_path .. "' " .. const.dirs.lock_background)
  -- Trigger color regeneration
  M.regenerate_colors(hl)
end

-- Regenerate colors from current wallpaper (replaces WallustSwww.sh)
function M.regenerate_colors(hl)
  local color_gen = deps.get("color_gen")
  if not color_gen then return end
  local color_cmd = color_gen.cmd or "wallust"
  hl.exec_cmd(color_cmd .. " 2>/dev/null || true")
  local bar = deps.get("bar")
  if bar then
    local bar_cmd = bar.cmd or "waybar"
    utils.kill_existing(hl, bar_cmd)
    hl.exec_cmd(bar_cmd .. " &")
  end
  local notif = deps.get("notification")
  if notif then
    local notif_cmd = notif.cmd or "swaync"
    hl.exec_cmd(notif_cmd .. "-client --reload-config 2>/dev/null || true")
  end
end

-- Random wallpaper (replaces WallpaperRandom.sh)
function M.random(hl)
  local wp_dir = const.wallpaper_dir
  local cmd = string.format("ls %s/*.{jpg,png} 2>/dev/null | shuf -n 1", wp_dir)
  local f = io.popen(cmd)
  if not f then return nil end
  local random_wp = f:read("*l") or ""
  f:close()
  if random_wp and #random_wp > 0 then
    M.set(hl, random_wp)
  end
end

-- Auto-change wallpaper on interval (replaces WallpaperAutoChange.sh)
function M.auto_change_start(hl, interval_minutes)
  interval_minutes = interval_minutes or 30
  local hyprctl_cmd = deps.cmd("hyprctl") or "hyprctl"
  hl.exec_cmd(string.format(
    "while true; do sleep %d; %s; done &",
    interval_minutes * 60,
    hyprctl_cmd .. " dispatch exec 'lua -e \"require(\\\"sys.scripts.wallpaper\\\").random()\"'"
  ))
end

-- Apply wallpaper effects (replaces WallpaperEffects.sh)
function M.apply_effects(hl, effect)
  local wp = const.dirs.lock_background
  local effects = {
    blur = "50",
    dim = "0.3",
    grayscale = "100",
    none = "0",
  }
  local amount = effects[effect] or "0"
  hl.exec_cmd(string.format("magick %s -blur 0x%s %s_effect.png", wp, amount, wp))
  M.set(hl, wp .. "_effect.png")
end

-- Set SDDM wallpaper (replaces sddm_wallpaper.sh)
function M.set_sddm(hl, wallpaper_path)
  local sddm_conf = "/usr/share/sddm/themes/default/theme.conf"
  hl.exec_cmd(string.format(
    "echo '[Wallpaper]\\n Wallpaper=%s' | sudo tee %s",
    wallpaper_path, sddm_conf
  ))
end

return M
