-- .luacheckrc for hypr-config (pure .lua config repo)
-- Run: luacheck ~/.config/hypr --codes
-- Should output: 0 errors (warnings about 'hl' are expected — it's Hyprland runtime global)
std = "lua54"
globals = { "hl" }  -- hl is provided by Hyprland v0.55+ runtime
ignore = { "21" }   -- unused variable (translated locals)
max_line_length = 200
