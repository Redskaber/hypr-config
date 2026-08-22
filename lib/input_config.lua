-- @path: lib/input_config.lua
-- @author: redskaber
-- @date: 2026-08-22
-- @version: 1.0 (Round 105 — proper kb_layout parser for sh scripts)
-- @description: Read kb_layouts from sys/input.lua (SSOT) for sh scripts.
--
-- PROBLEM (Round 105 audit):
--   SwitchKeyboardLayout.sh and Tak0-Per-Window-Switch.sh used a sed/grep
--   parser that broke on actual Lua syntax:
--     `kb_layout = "us,cn",` → produced `us,cn,` (trailing comma → empty
--     array element) and `us,` (single-layout case → div-by-zero from
--     trailing comma creating empty entry).
--
-- SOLUTION:
--   Lua can require() the actual config module? No — sys/input.lua calls
--   hl.config() at load time (side effects). Instead, this module reads
--   the file as text and parses with a proper Lua-aware regex.
--
--   Sh scripts call: lua /path/to/lib/input_config.lua layouts
--   Output: space-separated layout names, e.g. "us cn"

local M = {}

-- Path to the input config (Lua source file, NOT required — parsed as text)
M.input_lua_path = nil -- set by main()

-- Extract kb_layout value from a Lua source file.
-- Returns: array of layout name strings (e.g. {"us", "cn"})
function M.parse_kb_layouts(file_path)
	local f = io.open(file_path, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()

	-- Match: kb_layout = "us,cn" OR kb_layout = us,cn (unquoted)
	-- Captures the value between quotes (if present), or after = up to comma/comment
	local line = content:match("kb_layout%s*=%s*(.-)\n")
	if not line then
		return {}
	end

	-- Strip Lua line comment
	line = line:gsub("%-%-.*$", "")

	-- Try quoted form first: kb_layout = "us,cn",
	local quoted = line:match('^"([^"]*)"')
	if quoted then
		local layouts = {}
		for layout in quoted:gmatch("[^,]+") do
			layout = layout:match("^%s*(.-)%s*$") -- trim
			if layout ~= "" then
				table.insert(layouts, layout)
			end
		end
		return layouts
	end

	-- Unquoted form: kb_layout = us,cn (no quotes around value)
	-- The line is already comment-stripped; take rest of line, split on comma.
	-- Strip trailing Lua separators (comma, semicolon) and whitespace.
	local raw = line:gsub("[,;]%s*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if raw ~= "" and not raw:match('^"') then
		local layouts = {}
		for layout in raw:gmatch("[^,]+") do
			layout = layout:match("^%s*(.-)%s*$") -- trim
			if layout ~= "" then
				table.insert(layouts, layout)
			end
		end
		if #layouts > 0 then
			return layouts
		end
	end

	return {}
end

-- CLI entry point: lua input_config.lua layouts <path>
-- Prints space-separated layouts to stdout.
if arg and arg[1] then
	local cmd = arg[1]
	if cmd == "layouts" and arg[2] then
		local layouts = M.parse_kb_layouts(arg[2])
		io.write(table.concat(layouts, " "))
		io.write("\n")
	elseif cmd == "default" and arg[2] then
		local layouts = M.parse_kb_layouts(arg[2])
		io.write(layouts[1] or "us")
		io.write("\n")
	else
		io.stderr:write("Usage: lua input_config.lua [layouts|default] <input.lua.path>\n")
		os.exit(1)
	end
end

return M
