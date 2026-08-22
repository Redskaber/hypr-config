-- @path: sys/statemachine/nightlight.lua
-- @author: redskaber
-- @date: 2026-08-22
-- @version: 1.2 (Round 109 — use const.cache_dir instead of hardcoded $HOME/.cache)
-- @description: NightLight state machine (off↔on toggle, DI via deps.cmd)

local SM = require("lib.sm")
local deps = require("lib.deps")
local const = require("const")
local M = {}

-- State persistence file
-- Round 109: use const.cache_dir (XDG-aware) instead of hardcoded $HOME/.cache
local STATE_FILE = const.cache_dir .. "/.hypr_nightlight_state"
local TARGET_TEMP = 4500

function M.new(hl)
  local initial = "off"
  local f = io.open(STATE_FILE, "r")
  if f then
    local state = f:read("*l")
    f:close()
    if state == "on" then initial = "on" end
  end

  local function persist(state)
    local pf = io.open(STATE_FILE, "w")
    if pf then pf:write(state); pf:close() end
  end

  -- DI: resolve nightlight command via deps (not hard-coded "hyprsunset")
  local nightlight_cmd = deps.get("nightlight").cmd or "hyprsunset"

  local function apply(state)
    if state == "on" then
      hl.exec_cmd(nightlight_cmd .. " -t " .. TARGET_TEMP .. " &")
    else
      hl.exec_cmd("pkill -x " .. nightlight_cmd .. " 2>/dev/null")
    end
    persist(state)
  end

  return SM.new{
    states = {"off", "on"},
    initial = initial,
    invariant = function(sm)
      return sm.current == "off" or sm.current == "on"
    end,
    transitions = {
      {from="off", on="toggle", to="on",
       action=function(_, _, to) apply(to) end},
      {from="on",  on="toggle", to="off",
       action=function(_, _, to) apply(to) end},
    },
  }
end

return M
