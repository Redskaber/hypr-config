-- @path: bootstrap/const.lua
-- @author: redskaber
-- @date: 2026-08-22
-- @version: 3.1 (Round 109 — added cache_dir for state persistence SSOT)
-- @description: Layer 1: path infrastructure constants (immutable, XDG-aware)

local M = {}

M.home_dir = os.getenv("HOME")
M.cache_dir = os.getenv("XDG_CACHE_HOME") or (M.home_dir .. "/.cache")
M.wallpaper_dir = M.home_dir .. "/Pictures/wallpapers"

M.xdg_config = os.getenv("XDG_CONFIG_HOME") or (M.home_dir .. "/.config")
M.config_hypr = M.xdg_config .. "/hypr"

M.bootstrap = M.config_hypr .. "/bootstrap"
M.sys = M.config_hypr .. "/sys"
M.user = M.config_hypr .. "/user"

-- Runtime paths
M.wallust_effects = M.config_hypr .. "/wallust_effects"
M.lock_background = M.wallust_effects .. "/.wallpaper_current"

M.notify_icon = M.config_hypr .. "/icon.png"
M.search_engine = "https://www.google.com/search?q={}"

return M
