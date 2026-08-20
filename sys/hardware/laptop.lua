-- @path: sys/hardware/laptop.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Laptop hardware (brightness/media keys/touchpad device)
--
-- sys/hardware/laptop.lua — Laptop hardware config
-- Uses hl.device (per-device config), NOT hl.config({ device = ... })

local const = require("const")

local Touchpad_Device = "asue1209:00-04f3:319f-touchpad"
local TOUCHPAD_ENABLED = "true"

hl.bind("XF86Kbdbrightnessdown", hl.dsp.exec_cmd(const.S .. "/BrightnessKbd.sh --dec"), { repeating = true })
hl.bind("XF86Kbdbrightnessup", hl.dsp.exec_cmd(const.S .. "/BrightnessKbd.sh --inc"), { repeating = true })
hl.bind("XF86Monbrightnessdown", hl.dsp.exec_cmd(const.S .. "/Brightness.sh --dec"), { repeating = true })
hl.bind("XF86Monbrightnessup", hl.dsp.exec_cmd(const.S .. "/Brightness.sh --inc"), { repeating = true })
hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"))
hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"))
hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"))
hl.bind("XF86Touchpadtoggle", hl.dsp.exec_cmd(const.S .. "/TouchPad.sh"))
hl.bind(const.M .. " + F6", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --now"))
hl.bind(const.M .. " + SHIFT + F6", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --area"))
hl.bind(const.M .. " + CTRL + F6", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --in5"))
hl.bind(const.M .. " + ALT + F6", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --in10"))
hl.bind("ALT + F6", hl.dsp.exec_cmd(const.S .. "/ScreenShot.sh --active"))

-- Per-device config via hl.device (enabled is bool, not string)
hl.device({ name = Touchpad_Device, enabled = true })

require("sys.hardware.laptop-display")
