-- @path: bootstrap/default.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @version: 4.0
-- @description: Pipeline orchestrator — Stage 0 const merge + shell export + Stage 1+ sys pipeline
--
-- ARCHITECTURE (Task 90): SSOT const → two consumers:
--   1. Lua config: downstream modules use require("const")
--   2. Shell scripts: sys/const.lua M.export_to_shell() generates .deps_cache.sh
--
--   The merged const (sys defaults + user overrides) is the SINGLE SOURCE OF TRUTH.
--   Shell scripts source .deps_cache.sh to get all paths + DI variables.

local paths = require("bootstrap.const")
local sys_const = require("sys.const")
local user_const = require("user.const")

-- ── Deep merge helper (recursively merges tables) ─────────────────────────
local function deep_merge(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

-- ── Merge: start with sys defaults, override with user deltas ──────────────
local const = {}

-- Paths (from bootstrap, immutable)
const.config_root    = paths.config_root
const.bootstrap       = paths.bootstrap
const.sys             = paths.sys
const.user            = paths.user
const.wallust_effects = paths.wallust_effects
const.lock_background = paths.lock_background
const.icon            = paths.icon

-- Apps (sys defaults + user overrides via deep merge)
const.apps = {}
deep_merge(const.apps, sys_const.apps)
if user_const.apps then deep_merge(const.apps, user_const.apps) end

-- Modifier
const.modifier = user_const.modifier or sys_const.modifier

-- Dirs (from sys, derived from paths)
const.dirs = sys_const.dirs

-- External tool paths (sys defaults + user overrides via deep merge)
const.external = {}
deep_merge(const.external, sys_const.external)
if user_const.external then deep_merge(const.external, user_const.external) end

-- Helpers
const.helpers = sys_const.helpers

-- Search engine
const.search_engine = user_const.search_engine or sys_const.search_engine

-- Wallpaper dir
const.wallpaper_dir = user_const.wallpaper_dir or sys_const.wallpaper_dir

-- Notify icon
const.notify_icon = sys_const.notify_icon

-- Config root
const.config_root = paths.config_root

-- ── Register merged const as "const" module ────────────────────────────────
package.loaded["const"] = const

-- ── Export to shell: generate .deps_cache.sh (SSOT → shell) ────────────────
-- Called here (after merge) so user overrides are reflected in shell scripts.
-- Also called by sys/startup.lua on hyprland.start event.
sys_const.export_to_shell()

-- ── Stage 1+: load the system pipeline ─────────────────────────────────────
require("sys.default")

return const
