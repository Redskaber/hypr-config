-- @path: lib/colors.lua
-- @author: redskaber
-- @date: 2026-08-22
-- @version: 1.0 (Round 105 — break sys→user layer cycle)
-- @description: Wallust color resolver (SSOT for merged colors).
--
-- ARCHITECTURE (Round 105 fix):
--   Previously `sys/decoration.lua` required `user.policy.wallust.wallust-hyprland`
--   directly — a sys→user layer violation that creates a dependency cycle.
--
--   Now this module (in lib/, neutral layer) resolves the merged colors:
--     1. Load sys/policy/wallust/wallust-hyprland.lua (sys defaults)
--     2. Load user/policy/wallust/wallust-hyprland.lua (which itself merges sys)
--     3. Cache the result; expose via M.get()
--
--   Both sys and user decoration.lua use M.get() — no sys→user dependency.

local M = {}
local _cached = nil

-- Resolve and cache the merged wallust colors.
-- Returns: table of color name → "#hex" string
function M.resolve()
	if _cached then
		return _cached
	end

	-- User colors module already merges sys defaults + user overrides.
	-- pcall for resilience: if user module fails to load, fall back to sys only.
	local ok, user_colors = pcall(require, "user.policy.wallust.wallust-hyprland")
	if ok and type(user_colors) == "table" then
		_cached = user_colors
		return _cached
	end

	-- Fallback: sys colors only (resilience design)
	local sys_colors = require("sys.policy.wallust.wallust-hyprland")
	_cached = sys_colors
	return _cached
end

-- Get a specific color by name (e.g. "color12").
-- Falls back to "#444444" if color is missing.
function M.get(name)
	local colors = M.resolve()
	return colors[name] or "#444444"
end

return M
