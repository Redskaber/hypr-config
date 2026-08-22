-- @path: lib/cursor.lua
-- @author: redskaber
-- @date: 2026-08-22
-- @version: 1.0 (Round 107 — migrate cursor zoom from sh pipeline to pure Lua)
-- @description: Cursor utility functions (zoom factor get/set via hl.get_config/hl.config)
--
-- ARCHITECTURE (Round 107 — capability boundary):
--   Previously, cursor zoom keybinds used a sh pipeline:
--     hyprctl keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq -r '.float // .set // 1.0' | awk '{if($1<1)$1=1; print $1*2}')
--
--   This is fragile (depends on jq + awk), slow (forks 3 processes), and
--   violates the "充分使用lua 单一可信数据源" principle.
--
--   Now uses the native Lua API:
--     - hl.get_config("cursor.zoom_factor") — read current value (no fork)
--     - hl.config({ cursor = { zoom_factor = v } }) — set new value (no fork)
--
--   Per Hyprland wiki (Expanding Functionality → Dynamically changing a config option):
--     "You can use hl.get_config() to get the current value of a config option."
--     "You can change the value of a config option with a keybind with a script like..."
--
--   Note: hl.get_config may return a table representation for complex types
--   (e.g. gaps_in returns {top, left, right, bottom}). For a simple number
--   like zoom_factor, it returns a number directly. We handle both cases.

local M = {}

-- Default zoom factor (used if get_config returns nil/0)
M.DEFAULT_ZOOM = 1.0

-- Read the current cursor zoom factor.
-- Returns: number (the current zoom factor, ≥ 1.0)
function M.get_zoom()
	local config = hl.get_config("cursor.zoom_factor")
	-- Handle table representation (defensive — zoom_factor should be a number)
	if type(config) == "table" then
		config = config.float or config.set or config.value or M.DEFAULT_ZOOM
	end
	-- Ensure numeric and ≥ 1.0
	local zoom = tonumber(config) or M.DEFAULT_ZOOM
	if zoom < 1.0 then
		zoom = 1.0
	end
	return zoom
end

-- Set the cursor zoom factor.
-- @param zoom number: the new zoom factor (will be clamped to ≥ 1.0)
function M.set_zoom(zoom)
	zoom = tonumber(zoom) or M.DEFAULT_ZOOM
	if zoom < 1.0 then
		zoom = 1.0
	end
	hl.config({ cursor = { zoom_factor = zoom } })
end

-- Zoom in (multiply current zoom by factor, default 2x).
-- Called from keybind: hl.bind("SUPER + ALT + mouse_down", function() require("lib.cursor").zoom_in() end)
function M.zoom_in(factor)
	factor = factor or 2.0
	M.set_zoom(M.get_zoom() * factor)
end

-- Zoom out (divide current zoom by factor, default 2x).
-- Called from keybind: hl.bind("SUPER + ALT + mouse_up", function() require("lib.cursor").zoom_out() end)
function M.zoom_out(factor)
	factor = factor or 2.0
	M.set_zoom(M.get_zoom() / factor)
end

return M
