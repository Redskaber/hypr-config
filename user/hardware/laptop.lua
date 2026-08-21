-- @path: user/hardware/laptop.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: User laptop hardware overrides — vendor-specific binds + device config
--
-- ARCHITECTURE: This file contains VENDOR-SPECIFIC and DEVICE-SPECIFIC configs.
-- sys/hardware/laptop.lua has only generic, vendor-agnostic laptop binds.
-- Edit this file to match your laptop vendor and model.
--
-- Usage: Edit Touchpad_Device to match your touchpad name (find via `hyprctl devices`).
--        Uncomment/add vendor-specific launch keys as needed.

local const = require("const")

-- ── Device-specific: touchpad name (find via `hyprctl devices -j | jq '.keyboards[].name'`) ──
local Touchpad_Device = "asue1209:00-04f3:319f-touchpad"

-- Enable touchpad
hl.device({ name = Touchpad_Device, enabled = true })

-- ── ASUS-specific launch keys (uncomment if you have an ASUS laptop) ──────
hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"))
hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"))
hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"))

-- ── Other vendor launch keys (uncomment as needed) ─────────────────────────
-- Dell: hl.bind("XF86Launch1", hl.dsp.exec_cmd("ddcutil setvcp 10 50"))
-- Lenovo: hl.bind("XF86Launch1", hl.dsp.exec_cmd("lenovo-utility"))
