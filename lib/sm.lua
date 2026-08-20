-- @path: lib/sm.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: StateMachine base class (pcall + invariant + persistence)
--
-- phase-c/lib/sm.lua  — StateMachine base class (pcall + invariant assertions)
-- Replaces ad-hoc bash `case` logic in ChangeLayout.sh / GameMode.sh / Hyprsunset.sh.
-- REVIEW_REPORT §2 root-cause B fix: pcall makes atomicity a framework property.
--
-- Formal 5-tuple: (Q, Σ, δ, q₀, F)
--   Q (states)      = opts.states
--   Σ (events)      = derived from transitions' `on` field
--   δ (transition)  = opts.transitions[i].{from,on,to,action}
--   q₀ (initial)    = opts.initial
--   F (final)       = N/A (continuous system)
--
-- Persistence strategy field (fixes REVIEW gap A: asymmetric persistence):
--   opts.persistence = "none"      -- stateless (Layout/GameMode via Hyprland option)
--   opts.persistence = "file:path" -- file-based (Hyprsunset via ~/.cache/...)
--   opts.persistence = "hypr:option_name"  -- read from hyprctl getoption

local M = {}
M.__index = M

function M.new(opts)
	assert(opts.states and opts.initial and opts.transitions, "states, initial, transitions required")
	return setmetatable({
		states = opts.states,
		initial = opts.initial,
		current = opts.initial,
		transitions = opts.transitions,
		invariant = opts.invariant or function(_)
			return true
		end,
		persistence = opts.persistence or "none",
		log = {}, -- transition log for debugging/property tests
	}, M)
end

function M:fire(event)
	for _, t in ipairs(self.transitions) do
		if t.from == self.current and t.on == event then
			-- ATOMIC: pcall ensures action failures don't leave half-state
			-- (fixes REVIEW gap: ChangeLayout.sh's `|| true` silently swallows)
			local ok, err = pcall(t.action, self, self.current, t.to)
			if not ok then
				return false, ("transition action failed: %s"):format(err)
			end
			local prev = self.current
			self.current = t.to
			-- INVARIANT assertion (catches logic errors at dev time, not runtime)
			assert(self.invariant(self), ("invariant violated after %s -> %s"):format(prev, self.current))
			self.log[#self.log + 1] = { from = prev, on = event, to = self.current }
			return true
		end
	end
	return false, ("no transition from %s on %s"):format(self.current, event)
end

-- Property-based testing helpers (fixes REVIEW gap E: SM lacks property tests)
function M:fire_n(n, event)
	for _ = 1, n do
		local ok, err = self:fire(event)
		if not ok then
			return false, err
		end
	end
	return true
end

function M:reset()
	self.current = self.initial
	self.log = {}
end

return M
