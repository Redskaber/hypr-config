# 真实 GPU 运行时验证清单

> **目的**: 在真实 Hyprland 环境中验证配置功能（headless --verify-config 无法覆盖）
> **前置**: `hyprland --verify-config` 输出 `config ok`
> **方法**: 逐条执行，记录结果

---

## 1. 窗口规则验证

| # | 操作 | 期望 | 命令 |
|---|---|---|---|
| 1 | 打开 Firefox | opacity 0.9 (active) / 0.85 (inactive) | `firefox` |
| 2 | 打开 Discord | float + center + size 800x600 | `discord` |
| 3 | 打开 Steam | tiled, opacity 1.0 override | `steam` |
| 4 | 打开 kitty | opacity 0.90 0.80 | `kitty` |
| 5 | 全屏 Firefox | idle_inhibit fullscreen | SUPER+SHIFT+F |

## 2. Keybind 触发验证

| # | Keybind | 期望 |
|---|---|---|
| 6 | SUPER+Return | 打开终端 (kitty) |
| 7 | SUPER+D | 打开 rofi launcher |
| 8 | SUPER+Q | 关闭当前窗口 |
| 9 | SUPER+SHIFT+G | GameMode toggle (animations off/on) |
| 10 | SUPER+ALT+L | Layout 切换 (scrolling→dwindle→master) |
| 11 | SUPER+N | NightLight toggle (hyprsunset) |
| 12 | SUPER+1-0 | 切换 workspace 1-10 |
| 13 | SUPER+SHIFT+1-0 | 移动窗口到 workspace |
| 14 | SUPER+left/right/up/down | 焦点移动 |
| 15 | SUPER+CTRL+left/right/up/down | 移动窗口 |
| 16 | SUPER+SHIFT+left/right/up/down | 调整窗口大小 (repeat) |
| 17 | SUPER+SPACE | 切换浮动 |
| 18 | SUPER+F | 全屏 |
| 19 | SUPER+G | 切换 group |
| 20 | ALT+Tab | 循环窗口 |
| 21 | SUPER+minus | 切换 special workspace |
| 22 | SUPER+SHIFT+minus | 移动窗口到 special workspace |
| 23 | XF86AudioMute | 静音 (locked) |
| 24 | XF86AudioPlay | 播放/暂停 (locked) |
| 25 | SUPER+Print | 截图 |
| 26 | SUPER+mouse:272 | 拖拽窗口 |
| 27 | SUPER+mouse:273 | 调整窗口大小 |

## 3. 状态机验证

| # | 操作 | 期望 |
|---|---|---|
| 28 | SUPER+SHIFT+G (第一次) | GameMode ON: animations off, blur off, gaps 0 |
| 29 | SUPER+SHIFT+G (第二次) | GameMode OFF: animations on, blur on, gaps 2/4 |
| 30 | SUPER+ALT+L (第一次) | Layout → dwindle (J/K 绑定, O 绑定 togglesplit) |
| 31 | SUPER+ALT+L (第二次) | Layout → master (J/K 绑定, O unbind) |
| 32 | SUPER+ALT+L (第三次) | Layout → scrolling (J/K/O unbind) |
| 33 | SUPER+N (第一次) | NightLight ON: hyprsunset -t 4500 |
| 34 | SUPER+N (第二次) | NightLight OFF: pkill hyprsunset |

## 4. 动画验证

| # | 操作 | 期望 |
|---|---|---|
| 35 | 切换 workspace | 动画播放 |
| 36 | 打开/关闭窗口 | 窗口动画 |
| 37 | 焦点切换 | 边框动画 |

## 5. Startup 验证

| # | 检查 | 期望 |
|---|---|---|
| 38 | waybar 运行 | `pgrep waybar` |
| 39 | swaync 运行 | `pgrep swaync` |
| 40 | awww-daemon 运行 | `pgrep awww` |
| 41 | hypridle 运行 | `pgrep hypridle` |
| 42 | wl-paste --watch 运行 | `pgrep -f "wl-paste.*cliphist"` |
| 43 | cliphist 运行 | `pgrep cliphist` |

## 6. Layout-specific 验证

| # | Layout | 操作 | 期望 |
|---|---|---|---|
| 44 | scrolling | SUPER+period | 移动列右 |
| 45 | scrolling | SUPER+comma | 移动列左 |
| 46 | scrolling | SUPER+bracketright | 列加宽 |
| 47 | scrolling | SUPER+bracketleft | 列变窄 |
| 48 | scrolling | SUPER+CTRL+comma | 交换列左 |
| 49 | scrolling | SUPER+apostrophe | promote 窗口 |
| 50 | dwindle | SUPER+SHIFT+I | togglesplit |
| 51 | dwindle | SUPER+M | splitratio 0.3 |
| 52 | master | SUPER+I | addmaster |
| 53 | master | SUPER+CTRL+D | removemaster |
| 54 | master | SUPER+CTRL+Return | swapwithmaster |

## 7. 脚本触发验证

| # | Keybind | 脚本 | 期望 |
|---|---|---|---|
| 55 | SUPER+S | RofiSearch.sh | rofi 搜索框 |
| 56 | SUPER+ALT+E | RofiEmoji.sh | emoji 选择器 |
| 57 | SUPER+ALT+C | RofiCalc.sh | 计算器 |
| 58 | SUPER+W | WallpaperSelect.sh | 壁纸选择器 |
| 59 | SUPER+SHIFT+K | KeyBinds.sh | keybind 列表 (hyprctl binds -j) |
| 60 | SUPER+ALT+R | Refresh.sh | 重启 waybar/swaync |

---

**结果**: 逐条执行, 记录 Pass/Fail. 任何 Fail 需调查根因并修复.
