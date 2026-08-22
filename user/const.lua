-- @path: user/const.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @version: 4.1
-- @description: Layer 3: user constant overrides (minimal delta)
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ARCHITECTURE: Single Source of Truth (SSOT)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- sys/const.lua is the SSOT for ALL constants.
-- This file (user/const.lua) overrides ONLY what differs from sys defaults.
--
-- The merged const (sys + user) flows to two consumers:
--   1. Lua config: require("const") → all .lua modules
--   2. Shell scripts: M.export_to_shell() → .deps_cache.sh → common.sh → .sh scripts
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SHELL EXPORT NAMING RULES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- When M.export_to_shell() generates .deps_cache.sh, it converts Lua keys
-- to UPPER_SNAKE_CASE shell variables. Here is the complete mapping:
--
-- ── Config paths (from bootstrap/const.lua + sys/const.lua M.dirs) ──────────
--   const.config_hypr       → HYPR_CONFIG_DIR        ($HOME/.config/hypr)
--   const.dirs.scripts      → HYPR_SCRIPTS_DIR       ($HYPR_CONFIG_DIR/sys/scripts)
--   const.dirs.hardware     → HYPR_HARDWARE_DIR      ($HYPR_CONFIG_DIR/sys/hardware)
--   const.dirs.policy       → HYPR_POLICY_DIR        ($HYPR_CONFIG_DIR/sys/policy)
--   const.dirs.wallust      → (internal, not exported)
--   const.dirs.animations   → (internal, not exported)
--   const.dirs.wallust_effects → HYPR_WALLUST_DIR    ($HYPR_CONFIG_DIR/wallust_effects)
--   const.dirs.lock_background → HYPR_LOCK_BG        ($HYPR_WALLUST_DIR/.wallpaper_current)
--   const.notify_icon       → HYPR_NOTIFY_ICON       ($HYPR_CONFIG_DIR/icon.png)
--   const.wallpaper_dir     → HYPR_WALLPAPER_DIR     ($HOME/Pictures/wallpapers)
--
-- ── External tool config paths (from sys/const.lua M.external) ────────────
--   const.external.swaync_dir     → SWAYNC_DIR       ($HOME/.config/swaync)
--   const.external.swaync_icons  → SWAYNC_ICONS      ($SWAYNC_DIR/icons)
--   const.external.swaync_images → SWAYNC_IMAGES     ($SWAYNC_DIR/images)
--   const.external.rofi_dir      → ROFI_DIR          ($HOME/.config/rofi)
--   const.external.waybar_dir    → WAYBAR_DIR        ($HOME/.config/waybar)
--   const.external.wallust_dir   → WALLUST_DIR       ($HOME/.config/wallust)
--   const.external.kitty_dir     → KITTY_DIR         ($HOME/.config/kitty)
--   const.external.qt_dir        → QT_DIR            ($HOME/.config/qt)
--
-- ── Tool commands (from lib/deps.lua M.specs, resolved at load) ─────────────
--   deps.get("hyprctl").cmd     → HYPRCTL            (hyprctl)
--   deps.get("notify").cmd      → NOTIFY             (notify-send)
--   deps.get("rofi").cmd        → ROFI               (rofi)
--   deps.get("bar").cmd         → BAR                (waybar)
--   deps.get("notification").cmd → NOTIFICATION      (swaync)
--   deps.get("jq").cmd          → JQ                 (jq)
--   deps.get("terminal").cmd    → TERMINAL           (kitty)
--   deps.get("file_manager").cmd → FILE_MANAGER      (nemo)
--   deps.get("launcher").cmd    → LAUNCHER           (rofi)
--   deps.get("brightness_control").cmd → BRIGHTNESS_CONTROL (brightnessctl)
--   deps.get("volume_control").cmd → VOLUME_CONTROL  (pamixer)
--   deps.get("media_control").cmd → MEDIA_CONTROL    (playerctl)
--   deps.get("clipboard").cmd   → CLIPBOARD          (cliphist)
--   deps.get("wl_paste").cmd    → WL_PASTE           (wl-paste)
--   deps.get("wl_copy").cmd     → WL_COPY            (wl-copy)
--   deps.get("screenshot").cmd  → SCREENSHOT         (grim)
--   deps.get("slurp").cmd       → SLURP              (slurp)
--   deps.get("wallpaper_daemon").cmd → WALLPAPER_DAEMON (awww-daemon)
--   deps.get("color_gen").cmd   → COLOR_GEN          (wallust)
--   deps.get("lock").cmd        → LOCK               (hyprlock)
--   deps.get("idle_daemon").cmd → IDLE_DAEMON        (hypridle)
--   deps.get("nightlight").cmd  → NIGHTLIGHT         (hyprsunset)
--   deps.get("logout_menu").cmd → LOGOUT_MENU        (wlogout)
--   deps.get("editor").cmd     → EDITOR              (nano / $EDITOR)
--
-- ── Env var overrides ────────────────────────────────────────────────────────
--   Users can override any tool command via env var (checked by deps.get):
--     HYPR_TERMINAL=alacritty  → deps.get("terminal").cmd resolves to "alacritty"
--     HYPR_FILE_MANAGER=thunar → deps.get("file_manager").cmd resolves to "thunar"
--
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HOW TO OVERRIDE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--
-- Uncomment a line and change the value. The override automatically flows
-- to both Lua config and shell scripts (.deps_cache.sh).
--
-- For shell-only overrides (without editing Lua), use env vars:
--   export SWAYNC_DIR=/custom/swaync
--   export ROFI_DIR=/custom/rofi
-- These are checked by common.sh as fallback defaults.

local M = {}

-- ── Application overrides ──────────────────────────────────────────────────
M.apps = {
	terminal = "kitty", -- was "ghostty" in sys/const.lua
	file_manager = "nemo", -- "thunar"
	editor = "nvim",
}

-- ── External tool config directory overrides ──────────────────────────────
M.external = {
	-- swaync_dir  = "/custom/swaync",    -- → SWAYNC_DIR in shell
	-- rofi_dir    = "/custom/rofi",      -- → ROFI_DIR in shell
	-- waybar_dir  = "/custom/waybar",    -- → WAYBAR_DIR in shell
	-- wallust_dir = "/custom/wallust",   -- → WALLUST_DIR in shell
	-- kitty_dir   = "/custom/kitty",     -- → KITTY_DIR in shell
	-- qt_dir      = "/custom/qt",        -- → QT_DIR in shell
}

-- ── Search engine ──────────────────────────────────────────────────────────
M.search_engine = "https://www.bing.com/search?q={}"

-- ── Wallpaper directory ────────────────────────────────────────────────────
-- M.wallpaper_dir = os.getenv("HOME") .. "/Pictures/my-wallpapers"
-- → HYPR_WALLPAPER_DIR in shell

-- ── Main modifier ──────────────────────────────────────────────────────────
-- M.modifier = "ALT"
-- (used in Lua only, not exported to shell)

return M
