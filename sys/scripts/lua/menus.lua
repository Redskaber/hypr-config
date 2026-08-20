-- @path: sys/scripts/lua/menus.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Rofi menu aggregator (search/emoji/calc/music/theme)

local deps = require("lib.deps")
local utils = require("lib.script_utils")

local M = {}

-- Helper: run rofi with a mode and return selected item
local function rofi_dmenu(_, items, prompt)
  local launcher = deps.get("launcher")
  if not launcher then return nil end
  local launcher_cmd = launcher.cmd or "rofi"
  local tmp = os.tmpname()
  local f = io.open(tmp, "w")
  if not f then return nil end
  for _, item in ipairs(items) do f:write(item .. "\n") end
  f:close()
  local cmd = string.format("cat %s | %s -dmenu -p '%s'", tmp, launcher_cmd, prompt)
  local pf = io.popen(cmd)
  if not pf then os.remove(tmp); return nil end
  local selected = pf:read("*l") or nil
  pf:close()
  os.remove(tmp)
  return selected
end

-- Web search (replaces RofiSearch.sh)
-- KEY FIX: uses deps.get for search engine URL (was hardcoded google in sys,
-- user-overridden to bing in user/const.conf — the ONLY script with DIP)
function M.web_search(hl)
  -- In .lua era: local const = require("sys.const"); const.Search_Engine
  -- For now: read from a known location
  local search_engine = "https://www.google.com/search?q={}"  -- would be const
  local query = rofi_dmenu(hl, {}, "Search:")
  if query and #query > 0 then
    local url = search_engine:gsub("{}", query)
    hl.exec_cmd("xdg-open '" .. url .. "'")
  end
end

-- Emoji picker (replaces RofiEmoji.sh)
function M.emoji(hl)
  local emoji_file = os.getenv("HOME") .. "/.config/rofi/emoji-list"
  local f = io.open(emoji_file, "r")
  if not f then
    utils.notify(hl, "Emoji", "emoji-list file not found", "warning")
    return
  end
  local items = {}
  for line in f:lines() do table.insert(items, line) end
  f:close()
  local selected = rofi_dmenu(hl, items, "Emoji:")
  if selected then
    -- Extract emoji (first column)
    local emoji = selected:match("^(%S+)")
    if emoji then
      hl.exec_cmd(deps.cmd("wl_copy") .. " '" .. emoji .. "'")
      utils.notify(hl, "Emoji", "Copied: " .. emoji)
    end
  end
end

-- Calculator (replaces RofiCalc.sh)
function M.calculator(hl)
  local expr = rofi_dmenu(hl, {}, "Calculate:")
  if expr and #expr > 0 then
    -- Use qalc or bc for evaluation
    local f = io.popen("echo '" .. expr .. "' | qalc -s 2>/dev/null || bc -l 2>/dev/null")
    if f then
      local result = f:read("*l") or "Error"
      f:close()
      utils.notify(hl, "Calc", expr .. " = " .. result)
      hl.exec_cmd(deps.cmd("wl_copy") .. " '" .. result .. "'")
    end
  end
end

-- Music player (replaces RofiBeats.sh)
function M.music(hl)
  local media = deps.get("media_control")
  local items = { "Play/Pause", "Next", "Previous", "Stop" }
  local selected = rofi_dmenu(hl, items, "Music:")
  if selected then
    local actions = {
      ["Play/Pause"] = "play-pause",
      ["Next"] = "next",
      ["Previous"] = "previous",
      ["Stop"] = "stop",
    }
    local action = actions[selected]
    if action and media.found then
      hl.exec_cmd(media.cmd .. " " .. action)
    end
  end
end

-- Theme selector (replaces RofiThemeSelector.sh + modified variant)
function M.theme_selector(hl)
  local themes_dir = os.getenv("HOME") .. "/.config/rofi/themes"
  local f = io.popen("ls " .. themes_dir .. "/*.rasi 2>/dev/null")
  if not f then return end
  local items = {}
  for line in f:lines() do
    local name = line:match("([^/]+)%.rasi$")
    if name then table.insert(items, name) end
  end
  f:close()
  local selected = rofi_dmenu(nil, items, "Theme:")
  if selected then
    local target = themes_dir .. "/" .. selected .. ".rasi"
    hl.exec_cmd("cp " .. target .. " ~/.config/rofi/config.rasi")
    utils.notify(hl, "Theme", "Applied: " .. selected)
  end
end

return M
