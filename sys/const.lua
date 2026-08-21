-- @path: sys/const.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @version: 3.0
-- @description: Layer 2: system default constants (vendor, read-only)
--
-- REFACTOR (Task 85): Pure module — no _G.HYPR_CONST legacy.
--   Consumers use: local const = require("sys.const")
--   const.apps.terminal, const.modifier, const.dirs.scripts, etc.

local paths = require("bootstrap.const")

local M = {}

-- ── Application commands (DI: resolved via deps.lua at use site) ──────────
M.apps = {
  terminal     = "kitty",
  file_manager = "nemo",
  editor       = os.getenv("EDITOR") or "nano",
}

-- ── Main modifier key ──────────────────────────────────────────────────────
M.modifier = "SUPER"

-- ── Directory paths (derived, never hard-coded) ────────────────────────────
M.dirs = {
  scripts    = paths.sys .. "/scripts",
  hardware   = paths.sys .. "/hardware",
  policy     = paths.sys .. "/policy",
  wallust    = paths.sys .. "/policy/wallust",
  animations = paths.sys .. "/policy/animations",
  -- User-side equivalents
  user_scripts    = paths.user .. "/scripts",
  user_hardware   = paths.user .. "/hardware",
  user_policy     = paths.user .. "/policy",
  user_wallust    = paths.user .. "/policy/wallust",
  user_animations = paths.user .. "/policy/animations",
}

-- ── Helper tags (window tag names for help/config UI) ──────────────────────
M.helpers = {
  cheat    = "Help_Cheat",
  settings = "Help_Settings",
}

-- ── Search engine URL template ({}) is replaced by query) ──────────────────
M.search_engine = "https://www.google.com/search?q={}"

-- ── Wallpaper directory (user home, not config dir) ────────────────────────
M.wallpaper_dir = os.getenv("HOME") .. "/Pictures/wallpapers"

-- ── Notification icon ──────────────────────────────────────────────────────
M.notify_icon = paths.icon

-- ── Config root (for scripts that need the base path) ──────────────────────
M.config_root = paths.config_root

return M
