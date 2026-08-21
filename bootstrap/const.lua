-- @path: bootstrap/const.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @version: 3.0
-- @description: Layer 1: path infrastructure constants (immutable, XDG-aware)
--
-- REFACTOR (Task 85): Pure module — no _G.HYPR_CONST legacy.
--   Consumers use: local paths = require("bootstrap.const")
--   paths.config_root, paths.sys, paths.user, etc.

local M = {}

-- Resolve config root: XDG_CONFIG_HOME/hypr or ~/.config/hypr
M.config_root = os.getenv("XDG_CONFIG_HOME") and (os.getenv("XDG_CONFIG_HOME") .. "/hypr") or
                (os.getenv("HOME") .. "/.config/hypr")

-- Layer directories (derived from config_root, never hard-coded)
M.bootstrap = M.config_root .. "/bootstrap"
M.sys       = M.config_root .. "/sys"
M.user      = M.config_root .. "/user"

-- Runtime paths
M.wallust_effects = M.config_root .. "/wallust_effects"
M.lock_background  = M.wallust_effects .. "/.wallpaper_current"

-- Default icon
M.icon = M.config_root .. "/icon.png"

return M
