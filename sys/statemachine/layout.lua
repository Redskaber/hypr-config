-- @path: sys/statemachine/layout.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Layout state machine (scrolling↔dwindle↔master cycle)

local SM = require("lib.sm")
local M = {}

function M.new(hl)
  -- No hl.getoption in wiki API → default to dwindle
  local initial = "dwindle"

  local function apply_layout(to)
    -- Switch layout via hl.config (wiki confirmed: general.layout config)
    hl.config({ general = { layout = to } })

    -- Rebind J/K/O based on layout (wiki: hl.bind + hl.unbind confirmed)
    if to == "dwindle" then
      hl.bind("SUPER + J", hl.dsp.focus({direction="d"}))
      hl.bind("SUPER + K", hl.dsp.focus({direction="u"}))
      hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))
    elseif to == "master" then
      hl.bind("SUPER + J", hl.dsp.focus({direction="d"}))
      hl.bind("SUPER + K", hl.dsp.focus({direction="u"}))
      hl.unbind("SUPER + O")
    else  -- scrolling: unbind J/K/O (plugin owns column nav)
      hl.unbind("SUPER + J")
      hl.unbind("SUPER + K")
      hl.unbind("SUPER + O")
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
