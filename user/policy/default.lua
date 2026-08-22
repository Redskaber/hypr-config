-- @path: user/policy/default.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: User policy aggregator — loads after sys/policy/default.lua
--
-- ARCHITECTURE (Round 104): Runtime-switchable animation preset.
--   The active preset name is stored in $HYPR_CONFIG_DIR/.active_animation
--   (written by Animations.sh). On Hyprland reload, this file reads that
--   state and requires the chosen preset.
--
--   To set a default at install time, edit lib/active_policy.lua:M.default_preset.
--   To switch at runtime: SUPER+SHIFT+A → Animations.sh → hyprctl reload.

-- Wallust colors (system default; user can override in user/policy/wallust/)
require("sys.policy.wallust.wallust-hyprland")

-- Animation preset (runtime-switchable via Animations.sh + state file)
require("lib.active_policy").apply()
