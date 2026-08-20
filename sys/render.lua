-- @path: sys/render.lua
-- @author: redskaber
-- @date: 2026-08-20
-- @description: Render pipeline + cursor + xwayland

hl.config({
  render = {
    direct_scanout = 0,
  },
  cursor = {
    sync_gsettings_theme = true,
    no_hardware_cursors = 2,
    enable_hyprcursor = true,
    warp_on_change_workspace = 2,
    no_warps = true,
  },
  xwayland = {
    enabled = true,
    force_zero_scaling = true,
  },
})
