-- @path: user/const.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @version: 3.0
-- @description: Layer 3: user constant overrides (minimal delta)
--
-- REFACTOR (Task 85): Pure module — no _G.HYPR_CONST legacy.
--   Override only what differs from sys/const.lua defaults.

local M = {}

-- Override applications (delta from sys defaults)
M.apps = {
	terminal = "kitty", -- was "ghostty"
	-- file_manager = "thunar",    -- uncomment to override
	-- editor = "nvim",            -- uncomment to override
}

-- Override search engine (delta)
M.search_engine = "https://www.bing.com/search?q={}"

-- Override wallpaper directory (delta)
-- M.wallpaper_dir = os.getenv("HOME") .. "/Pictures/my-wallpapers"

-- Override main modifier (delta)
-- M.modifier = "ALT"

return M
