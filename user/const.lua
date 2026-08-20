-- @path: user/const.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Layer 3: user constant overrides (minimal delta)
--
-- user/const.lua — Layer 3: user overrides (minimal delta)
-- Writes to global _G.HYPR_CONST (overwrites sys defaults, last-wins)

_G.HYPR_CONST = _G.HYPR_CONST or {}

_G.HYPR_CONST.M_terminal = "kitty"
_G.HYPR_CONST.Search_Engine = "https://www.bing.com/search?q={}"
-- M_editor, M_file_manager, W, I_notify inherit from sys/const.lua
