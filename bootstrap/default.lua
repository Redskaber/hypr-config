-- @path: bootstrap/default.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Pipeline orchestrator — Stage 0 const load + Stage 1+ sys pipeline

-- Stage 0: load three const layers (each writes to _G.HYPR_CONST, last-wins)
_G.HYPR_CONST = _G.HYPR_CONST or {}
require("bootstrap.const")
require("sys.const")
require("user.const")

-- Stage 1+: load the system pipeline
require("sys.default")
