-- @path: sys/statemachine/layout.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Layout state machine (scrolling↔dwindle↔master cycle)

local SM = require("lib.sm")
local const = require("const")
local M = {}

function M.new(hl)
  -- No hl.getoption in wiki API → default to dwindle
  local initial = "dwindle"

  local function apply_layout(to)
    -- Switch layout via hl.config (wiki confirmed: general.layout config)
    hl.config({ general = { layout = to } })

    -- Rebind J/K/O based on layout (wiki: hl.bind + hl.unbind confirmed)
    -- Uses const.modifier for DI (not hard-coded "SUPER")
    local mod = const.modifier
    if to == "dwindle" then
      hl.bind(mod .. " + J", hl.dsp.focus({direction="d"}))
      hl.bind(mod .. " + K", hl.dsp.focus({direction="u"}))
      hl.bind(mod .. " + O", hl.dsp.layout("togglesplit"))
    elseif to == "master" then
      hl.bind(mod .. " + J", hl.dsp.focus({direction="d"}))
      hl.bind(mod .. " + K", hl.dsp.focus({direction="u"}))
      hl.unbind(mod .. " + O")
    else  -- scrolling: unbind J/K/O (built-in owns column nav)
      hl.unbind(mod .. " + J")
      hl.unbind(mod .. " + K")
      hl.unbind(mod .. " + O")
    end
  end

  return SM.new{
    states = {"scrolling", "dwindle", "master"},
    initial = initial,
    invariant = function(sm)
      for _, s in ipairs(sm.states) do
        if s == sm.current then return true end
      end
      return false
    end,
    transitions = {
      {from="scrolling", on="cycle", to="dwindle",
       action=function(_, _, to) apply_layout(to) end},
      {from="dwindle",   on="cycle", to="master",
       action=function(_, _, to) apply_layout(to) end},
      {from="master",    on="cycle", to="scrolling",
       action=function(_, _, to) apply_layout(to) end},
    },
  }
end

return M
