-- @path: lib/types.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: EmmyLua type annotations (16 @class schemas for IDE)

---@class Const
---@field Hypr string Root config path
---@field sys string System directory
---@field user string User directory
---@field M string Modifier key (e.g. "SUPER")
---@field M_terminal string Terminal command
---@field M_file_manager string File manager command
---@field M_editor string Editor command
---@field S string Scripts directory
---@field H string Hardware directory
---@field P string Policy directory
---@field I_notify string Notification icon path
---@field Search_Engine string Search engine URL

---@class Dep
---@field name string Dependency name
---@field cmd string Resolved command
---@field found boolean Whether command exists
---@field owned boolean Whether hypr-config manages this tool's config
---@field config_path string|nil Config file path for owned tools
---@field default_args table|nil Default command arguments
---@field desc string Description

---@class Deps
---@field specs table<string, table> Raw dependency specifications
---@field get fun(name: string): Dep|nil Resolve a dependency by name
---@field check_all fun(): boolean, string[] Verify all required deps, return missing list
---@field owned_tools fun(): string[] List tools whose config we manage
---@field cmd fun(name: string): string|nil Get full command string with default args

---@class WindowRule
---@field opacity string|nil Opacity value (e.g. "0.90 0.80")
---@field float boolean|nil Whether window floats
---@field center boolean|nil Whether window is centered
---@field size string|nil Window size (e.g. "800 600")
---@field pin boolean|nil Whether window is pinned
---@field idle_inhibit string|nil Idle inhibit mode
---@field match table Match conditions (class, tag, title, etc.)
---@field tag string|nil Tag to register/use

---@class Tag
---@field name string Tag name
---@field category string Tag category (web/productivity/media/etc.)
---@field classes string[] Class patterns that map to this tag

---@class StateMachine
---@field states string[] Valid states
---@field current string Current state
---@field initial string Initial state
---@field transitions table[] Transition definitions
---@field fire fun(event: string): boolean, string|nil Fire an event, return success + error

---@class SMTransition
---@field from string Source state
---@field on string Event name
---@field to string Target state
---@field action fun(sm: StateMachine, from: string, to: string)|nil Transition action

---@class ScriptUtils
---@field NOTIF_ICON string Notification icon path (SSOT)
---@field SCRIPTSDIR string Scripts directory (SSOT)
---@field focused_monitor fun(): string|nil Get focused monitor name
---@field kill_existing fun(proc_name: string): nil Kill process by name
---@field notify fun(hl: table, summary: string, body: string, urgency: string): nil Send notification
---@field bg fun(cmd: string): nil Run command in background
---@field wait_for fun(check_fn: fun(): boolean, max_retries: integer, delay: number): boolean Wait with retry

return {}
