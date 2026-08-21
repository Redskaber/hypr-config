-- @path: sys/hardware/laptop.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Laptop hardware — generic laptop keys (brightness/media/touchpad)
--
-- ARCHITECTURE: sys/ contains ONLY generic, vendor-agnostic laptop binds.
-- Vendor-specific binds (ASUS rog-control-center, asusctl, etc.) and
-- device-specific values (touchpad device name) go in user/hardware/laptop.lua.

local const = require("const")

-- Generic laptop brightness keys (work on all laptops with brightness buttons)
hl.bind("XF86Kbdbrightnessdown", hl.dsp.exec_cmd(const.dirs.scripts .. "/BrightnessKbd.sh --dec"), { repeating = true })
hl.bind("XF86Kbdbrightnessup", hl.dsp.exec_cmd(const.dirs.scripts .. "/BrightnessKbd.sh --inc"), { repeating = true })
hl.bind("XF86Monbrightnessdown", hl.dsp.exec_cmd(const.dirs.scripts .. "/Brightness.sh --dec"), { repeating = true })
hl.bind("XF86Monbrightnessup", hl.dsp.exec_cmd(const.dirs.scripts .. "/Brightness.sh --inc"), { repeating = true })

-- Touchpad toggle (generic — script detects device internally)
hl.bind("XF86Touchpadtoggle", hl.dsp.exec_cmd(const.dirs.scripts .. "/TouchPad.sh"))

-- Screenshot keys (laptop-specific F6 placement)
hl.bind(const.modifier .. " + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --now"))
hl.bind(const.modifier .. " + SHIFT + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --area"))
hl.bind(const.modifier .. " + CTRL + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --in5"))
hl.bind(const.modifier .. " + ALT + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --in10"))
hl.bind("ALT + F6", hl.dsp.exec_cmd(const.dirs.scripts .. "/ScreenShot.sh --active"))

require("sys.hardware.laptop-display")
