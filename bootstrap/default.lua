-- @path: bootstrap/default.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @version: 3.1
-- @description: Pipeline orchestrator — Stage 0 const merge + Stage 1+ sys pipeline
--
-- REFACTOR (Task 85): Pure module const system (no _G.HYPR_CONST).
--   Stage 0: merge three const layers into a single module
--   - bootstrap/const.lua → paths (immutable)
--   - sys/const.lua       → apps, modifier, dirs, helpers, search (vendor)
--   - user/const.lua      → deltas (override)
--
--   The merged const is registered as "const" in package.loaded,
--   so all downstream modules can: local const = require("const")

local paths = require("bootstrap.const")
local sys_const = require("sys.const")
local user_const = require("user.const")

-- Merge: start with sys defaults, override with user deltas
local const = {}

-- Paths (from bootstrap, immutable)
const.config_root    = paths.config_root
const.bootstrap       = paths.bootstrap
const.sys             = paths.sys
const.user            = paths.user
const.wallust_effects = paths.wallust_effects
const.lock_background = paths.lock_background
const.icon            = paths.icon

-- Apps (sys defaults + user overrides)
const.apps = {}
for k, v in pairs(sys_const.apps) do const.apps[k] = v end
if user_const.apps then
  for k, v in pairs(user_const.apps) do const.apps[k] = v end
end

-- Modifier (sys default + user override)
const.modifier = user_const.modifier or sys_const.modifier

-- Dirs (from sys, derived from paths)
const.dirs = sys_const.dirs

-- Helpers (from sys)
const.helpers = sys_const.helpers

-- Search engine (sys default + user override)
const.search_engine = user_const.search_engine or sys_const.search_engine

-- Wallpaper dir (sys default + user override)
const.wallpaper_dir = user_const.wallpaper_dir or sys_const.wallpaper_dir

-- Notify icon (from sys)
const.notify_icon = sys_const.notify_icon

-- Register merged const as "const" module (so downstream require("const") gets it)
package.loaded["const"] = const

-- Stage 1+: load the system pipeline
require("sys.default")

return const
