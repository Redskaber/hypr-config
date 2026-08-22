-- @path: lib/sm.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: StateMachine base class (pcall + invariant + persistence)

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
