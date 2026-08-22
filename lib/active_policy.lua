-- @path: lib/active_policy.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Runtime-switchable animation preset resolver
--
-- DESIGN (Round 104 — capability boundary):
--   Animations.sh cannot directly require() a Lua module from sh (no Lua
--   bridge in sh). Instead, sh writes the chosen preset name to a state file
--   (.active_animation), and this Lua module reads it on Hyprland reload.
--
--   Flow:
--     1. Animations.sh: rofi picks preset name → writes .active_animation
--     2. Animations.sh: calls `hyprctl reload`
--     3. Hyprland reloads → user/policy/default.lua → require("lib.active_policy")
--     4. This module reads .active_animation → requires the chosen preset
--
--   Fallback: if state file missing or preset name invalid, falls back to
--   sys.policy.animations.default (resilience design).

local const = require("const")
local M = {}

-- Path to the state file (under config root, dot-prefixed)
M.state_file = const.config_root .. "/.active_animation"
M.default_preset = "default"

-- Read the active preset name from the state file.
-- Returns the preset name string, or M.default_preset on any error.
function M.read_active()
	local f = io.open(M.state_file, "r")
	if not f then
		return M.default_preset
	end
	local line = f:read("*l") or ""
	f:close()
	-- Trim whitespace
	line = line:gsub("^%s+", ""):gsub("%s+$", "")
	if line == "" then
		return M.default_preset
	end
	return line
end

-- Resolve and require the active animation preset.
-- Called by user/policy/default.lua.
function M.apply()
	local preset = M.read_active()
	local ok, err = pcall(require, "sys.policy.animations." .. preset)
	if not ok then
		-- Fallback to default on any error (resilience design)
		require("sys.policy.animations.default")
	end
end

return M
