-- @path: bootstrap/default.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Pipeline orchestrator — Stage 0 const merge + Stage 1+ sys pipeline
--
-- bootstrap/default.lua — Pipeline orchestrator (Stage 0 + Stage 1+)
--
-- Stage 0: three-layer const merge (bootstrap → sys → user, last-wins)
-- Stage 1+: delegate to sys.default for full pipeline
--
-- Note: Hyprland's require() has special scope behavior.
-- We use a global table `_G.HYPR_CONST` that const files write to,
-- rather than relying on require() return values.

-- Initialize global const table
_G.HYPR_CONST = _G.HYPR_CONST or {}

-- Stage 0: load three const layers (each writes to _G.HYPR_CONST)
require("bootstrap.const")
require("sys.const")
require("user.const")

-- Make const available as require("const") for downstream modules
package.loaded["const"] = _G.HYPR_CONST

-- Stage 1+: load the system pipeline
require("sys.default")
