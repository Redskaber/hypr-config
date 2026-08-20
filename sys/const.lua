-- @path: sys/const.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Layer 2: system default constants (vendor, never edit)
--
-- sys/const.lua — Layer 2: system defaults (vendor, never edit)
-- Writes to global _G.HYPR_CONST (Hyprland require scope-safe pattern)
-- Note: M_editor resolved from EDITOR env var (was ${EDITOR:-nano} in .conf)

_G.HYPR_CONST = _G.HYPR_CONST or {}

_G.HYPR_CONST.M = "SUPER"
_G.HYPR_CONST.M_terminal = "kitty"
_G.HYPR_CONST.M_file_manager = "nemo"
_G.HYPR_CONST.M_editor = os.getenv("EDITOR") or "nano"

_G.HYPR_CONST.S = "~/.config/hypr/sys/scripts"
_G.HYPR_CONST.H = "~/.config/hypr/sys/hardware"
_G.HYPR_CONST.P = "~/.config/hypr/sys/policy"
_G.HYPR_CONST.P_w = "~/.config/hypr/sys/policy/wallust"
_G.HYPR_CONST.P_a = "~/.config/hypr/sys/policy/animations"

_G.HYPR_CONST.H_Cheat = "Help_Cheat"
_G.HYPR_CONST.H_Settings = "Help_Settings"

_G.HYPR_CONST.U = "~/.config/hypr/user"
_G.HYPR_CONST.U_s = "~/.config/hypr/user/scripts"
_G.HYPR_CONST.U_h = "~/.config/hypr/user/hardware"
_G.HYPR_CONST.U_p = "~/.config/hypr/user/policy"
_G.HYPR_CONST.U_pw = "~/.config/hypr/user/policy/wallust"
_G.HYPR_CONST.U_pa = "~/.config/hypr/user/policy/animations"

_G.HYPR_CONST.W = "~/.config/hypr/Pictures/wallpapers"
_G.HYPR_CONST.W_l = ""
_G.HYPR_CONST.I_notify = "~/.config/hypr/icon.png"

_G.HYPR_CONST.Search_Engine = "https://www.google.com/search?q={}"
