-- @path: lib/deps.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: External dependency manifest (SSOT + DI, 26 tools)

local M = {}

M.specs = {
  hyprctl = { cmd = "hyprctl", required = true, owned = false, desc = "Hyprland IPC client" },
  terminal = { cmd = "kitty", fallback = "alacritty", required = true, owned = false, env_var = "HYPR_TERMINAL", desc = "Terminal emulator" },
  launcher = { cmd = "rofi", fallback = "wofi", required = true, owned = true, config_path = "~/.config/rofi/", desc = "Application launcher" },
  bar = { cmd = "waybar", fallback = "yambar", required = true, owned = true, config_path = "~/.config/waybar/", desc = "Wayland status bar" },
  wallpaper_daemon = { cmd = "awww-daemon", fallback = "swww-daemon", required = true, owned = false, desc = "Wallpaper daemon" },
  color_gen = { cmd = "wallust", fallback = "pywal", required = true, owned = true, config_path = "~/.config/wallust/", desc = "Color scheme generator" },
  notification = { cmd = "swaync", fallback = "mako", required = true, owned = true, config_path = "~/.config/swaync/", desc = "Notification daemon" },
  idle_daemon = { cmd = "hypridle", fallback = "swayidle", required = true, owned = true, config_path = "~/.config/hypr/sys/hypridle.conf", desc = "Idle daemon" },
  lock = { cmd = "hyprlock", fallback = "swaylock", required = true, owned = true, config_path = "~/.config/hypr/sys/hyprlock.conf", desc = "Screen locker" },
  nightlight = { cmd = "hyprsunset", fallback = "gammastep", required = false, owned = false, desc = "Blue light filter" },
  clipboard = { cmd = "cliphist", fallback = "clipman", required = true, owned = false, desc = "Clipboard history" },
  wl_paste = { cmd = "wl-paste", required = true, owned = false, desc = "Wayland clipboard paste" },
  wl_copy = { cmd = "wl-copy", required = true, owned = false, desc = "Wayland clipboard copy" },
  screenshot = { cmd = "grim", fallback = "hyprshot", required = true, owned = false, desc = "Screenshot" },
  slurp = { cmd = "slurp", required = false, owned = false, desc = "Region selector" },
  logout_menu = { cmd = "wlogout", fallback = "wleave", required = false, owned = true, config_path = "~/.config/wlogout/", desc = "Logout menu" },
  media_control = { cmd = "playerctl", required = false, owned = false, desc = "Media control" },
  volume_control = { cmd = "pamixer", fallback = "pactl", required = true, owned = false, desc = "Volume control" },
  brightness_control = { cmd = "brightnessctl", fallback = "light", required = false, owned = false, desc = "Brightness" },
  auth_agent = { cmd = "/usr/libexec/polkit-gnome-authentication-agent-1", fallback = "lxpolkit", required = true, owned = false, desc = "Polkit agent" },
  input_method = { cmd = "fcitx5", fallback = "ibus-daemon", required = false, owned = false, desc = "Input method" },
  network_applet = { cmd = "nm-applet", fallback = "nm-tray", required = false, owned = false, desc = "Network applet" },
  file_manager = { cmd = "nemo", fallback = "thunar", required = true, owned = false, env_var = "HYPR_FILE_MANAGER", desc = "File manager" },
  editor = { cmd = os.getenv("EDITOR") or "nano", fallback = "vim", required = true, owned = false, desc = "Editor" },
  jq = { cmd = "jq", required = true, owned = false, desc = "JSON processor" },
  notify = { cmd = "notify-send", required = true, owned = false, desc = "Notification sender" },
}

M._resolved = {}

function M.get(name)
  local spec = M.specs[name]
  if not spec then return nil end
  if M._resolved[name] then return M._resolved[name] end

  -- No os.execute check (may block). Return spec directly.
  -- env_var override takes precedence over spec.cmd.
  local cmd = spec.cmd or ""
  if spec.env_var and os.getenv(spec.env_var) then
    cmd = os.getenv(spec.env_var) or cmd
  end

  local result = {
    name = name,
    cmd = cmd,
    found = true,  -- assumed present; user must ensure tools are installed
    owned = spec.owned,
    config_path = spec.config_path,
    default_args = spec.default_args,
    desc = spec.desc,
  }
  M._resolved[name] = result
  return result
end

function M.check_all()
  return true, {}
end

function M.owned_tools()
  local out = {}
  for name, spec in pairs(M.specs) do
    if spec.owned then table.insert(out, name) end
  end
  table.sort(out)
  return out
end

function M.cmd(name)
  local dep = M.get(name)
  if not dep then return nil end
  local cmd = dep.cmd or ""
  if dep.default_args then
    for k, v in pairs(dep.default_args) do
      cmd = cmd .. " --" .. k .. " " .. tostring(v)
    end
  end
  return cmd
end

-- NOTE: export_to_shell() has been moved to sys/const.lua M.export_to_shell().
--       That function exports BOTH deps (tool commands) AND const (paths).
--       lib/deps.lua is now ONLY the dependency manifest (specs + get/cmd).

return M
