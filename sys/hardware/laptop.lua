-- @path: sys/hardware/laptop.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Laptop hardware (brightness/media keys/touchpad device)

-- Const module (merged by bootstrap/default.lua: paths + apps + modifier + dirs)
local const = require("const")

local Touchpad_Device = "asue1209:00-04f3:319f-touchpad"

hl.bind("XF86Kbdbrightnessdown", hl.dsp.exec_cmd(const.dirs.scripts .. "/BrightnessKbd.sh --dec"), { repeating = true })
hl.bind("XF86Kbdbrightnessup", hl.dsp.exec_cmd(const.dirs.scripts .. "/BrightnessKbd.sh --inc"), { repeating = true })
hl.bind("XF86Monbrightnessdown", hl.dsp.exec_cmd(const.dirs.scripts .. "/Brightness.sh --dec"), { repeating = true })
hl.bind("XF86Monbrightnessup", hl.dsp.exec_cmd(const.dirs.scripts .. "/Brightness.sh --inc"), { repeating = true })
hl.bind("XF86Launch1", hl.dsp.exec_cmd("rog-control-center"))
hl.bind("XF86Launch3", hl.dsp.exec_cmd("asusctl led-mode -n"))
hl.bind("XF86Launch4", hl.dsp.exec_cmd("asusctl profile -n"))
hl.bind("XF86Touchpadtoggle", hl.dsp.exec_cmd(const.dirs.scripts .. "/TouchPad.sh"))
hl.bind(const.modifier .. " + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --now"))
hl.bind(const.modifier .. " + SHIFT + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --area"))
hl.bind(const.modifier .. " + CTRL + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --in5"))
hl.bind(const.modifier .. " + ALT + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --in10"))
hl.bind("ALT + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --active"))

-- Per-device config via hl.device (enabled is bool, not string)
hl.device({ name = Touchpad_Device, enabled = true })

require("sys.hardware.laptop-display")
