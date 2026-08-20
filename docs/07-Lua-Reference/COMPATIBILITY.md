# 配置语法参考 — .lua 与历史 .conf 对照

> 本文档是 .lua 配置的**语法参考**，对照说明每个配置构造。
> .conf 形式已弃用（Hyprland v0.55+），仅作历史参考。
>
> **本仓库的当前形态是 .lua**。如果你想了解迁移历史，查看 git log。

---

## 1. 基本结构

### 1.1 入口文件

| 历史形式 (.conf) | 当前形式 (.lua) | 说明 |
|---|---|---|
| `hyprland.conf` | `hyprland.lua` | 入口文件 |
| `source = ./bootstrap/default.conf` | `require("bootstrap.default")` | 加载子模块 |

### 1.2 注释

| .conf | .lua |
|---|---|
| `# comment` | `-- comment` |

### 1.3 变量（常量系统）

.lua 时代没有 `$var` 系统——常量在 const 文件中以 table 返回，翻译时已解析为字面值。

| .conf | .lua (const 文件) | 使用处 |
|---|---|---|
| `$M = SUPER` | `return { ['M = "SUPER" }` | `hl.bind("SUPER + ...", ...)` |
| `$M_terminal = kitty` | `return { ['M_terminal = "kitty" }` | `hl.dsp.exec_cmd("kitty")` |

详见 [../02-Architecture/THREE_LAYER_CONSTANTS.md](../02-Architecture/THREE_LAYER_CONSTANTS.md)。

---

## 2. 配置块 (sections)

### 2.1 标量配置

```lua
-- .lua 当前形式
hl.config({ general = { layout = "dwindle" } })
hl.config({ input = { kb_layout = "us" } })
hl.config({ decoration = { rounding = 10 } })
```

### 2.2 嵌套 section

```lua
hl.config({ decoration = { shadow = { enabled = true } } })
hl.config({ group = { groupbar = { col = { active = "rgb(404143)" } } } })
```

### 2.3 plugin section

```lua
-- scrolling (built-in since v0.55) { column_width = 0.5 }
hl.config({ plugin = { scrolling layout = { column_width = 0.5 } } })
```

### 2.4 值类型

| .lua 值 | 类型 | 示例 |
|---|---|---|
| `true` / `false` | boolean | `enabled = true` |
| `10` | integer | `rounding = 10` |
| `1.0` | float | `active_opacity = 1.0` |
| `"dwindle"` | string | `layout = "dwindle"` |
| `"rgb(70717F)"` | color | `color = "rgb(70717F)"` |

---

## 3. bind 指令

### 3.1 语法

```lua
hl.bind(keystring, dispatcher, flags?)
```

- `keystring`: `"MODS + KEY"` 格式（每个 mod 用 ` + ` 连接）
- `dispatcher`: `hl.dsp.exec_cmd("cmd")` 或 `function() ... end`
- `flags`: 可选 table，如 `{locked=true, repeating=true}`

### 3.2 flags 对照

| .conf 变体 | .lua flags | 说明 |
|---|---|---|
| `bindd` | (无) | 描述 |
| `bindld` | `{locked=true}` | 锁定时激活 |
| `binded` | `{repeating=true}` | 按住重复 |
| `bindeld` | `{locked=true, repeating=true}` | 组合 |
| `bindlnd` | `{locked=true, non_consuming=true}` | 组合 |
| `bindmd` | `{mouse=true}` | 鼠标 |

### 3.3 dispatcher 类型

```lua
-- exec dispatcher → hl.dsp.exec_cmd
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))

-- 无参 dispatcher → function 包装
hl.bind("SUPER + Q", function() hl.dispatch("killactive") end)

-- 带参 dispatcher
hl.bind("SUPER + SHIFT + left", function() hl.dispatch("resizeactive", "-50 0") end, {repeating=true})
```

### 3.4 完整示例

```lua
-- 启动器
hl.bind("SUPER + D", hl.dsp.exec_cmd("rofi -show drun"))

-- 关闭窗口
hl.bind("SUPER + Q", function() hl.dispatch("killactive") end)

-- 调整大小（按住重复）
hl.bind("SUPER + SHIFT + left", function() hl.dispatch("resizeactive", "-50 0") end, {repeating=true})

-- 媒体键（锁定时激活）
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("Volume.sh --toggle"), {locked=true})

-- 鼠标拖拽
hl.bind("SUPER + mouse:272", hl.dsp.window.move(), {mouse=true})
```

### 3.5 XF86 keysym 规范

.lua 要求 CamelCase keysym（.conf 时代小写也接受）：

| keysym | .lua 写法 |
|---|---|
| 静音 | `XF86AudioMute` |
| 音量+ | `XF86AudioRaiseVolume` |
| 音量- | `XF86AudioLowerVolume` |
| 麦克风静音 | `XF86AudioMicMute` |
| 播放 | `XF86AudioPlay` |
| 下一首 | `XF86AudioNext` |
| 上一首 | `XF86AudioPrev` |
| 睡眠 | `XF86Sleep` |

---

## 4. windowrule 指令

### 4.1 标签注册

```lua
-- sys/tags.lua
hl.window_rule({
  match = { class = "^(firefox)$" },
  tag = "browser",
})
```

### 4.2 行为规则

```lua
-- sys/rules.lua
hl.window_rule({
  opacity = "0.90 0.80",
  match = { tag = "terminal" },
})

hl.window_rule({
  float = true,
  match = { tag = "im" },
})

hl.window_rule({
  size = "800 600",
  match = { tag = "im" },
})
```

### 4.3 规则关键字 → Lua 字段

| 规则 | .lua 字段 | 值类型 |
|---|---|---|
| `opacity X Y` | `opacity = "X Y"` | string |
| `float on/off` | `float = true/false` | boolean |
| `center on/off` | `center = true/false` | boolean |
| `size W H` | `size = "W H"` | string |
| `pin on/off` | `pin = true/false` | boolean |
| `idle_inhibit fullscreen` | `idle_inhibit = "fullscreen"` | string |

### 4.4 compound 规则

```lua
-- class + negative:title（标签系统无法表达的复合条件）
hl.window_rule({
  float = true,
  match = {
    class = "^([Tt]hunar)$",
    title_negative = "^(.*[Tt]hunar.*)$",
  },
})
```

---

## 5. env 指令

```lua
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
```

---

## 6. exec / exec-once

### 6.1 立即执行

```lua
hl.exec_cmd("notify-send 'Hello'")
```

### 6.2 启动时执行（exec-once 替代）

.lua 时代用 `hl.on` 事件钩子：

```lua
-- sys/startup.lua
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh")
end)

-- 新能力：关闭时清理（.conf 时代不可能）
hl.on("hyprland.shutdown", function()
  hl.exec_cmd("pkill swaync 2>/dev/null")
end)
```

---

## 7. monitor 指令

```lua
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "1",
})
```

---

## 8. animation / bezier

### 8.1 bezier 曲线

```lua
hl.curve("wind", { type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}} })
```

### 8.2 animation

```lua
hl.animation({
  leaf = "windows",
  enabled = true,
  speed = 6,
  bezier = "wind",
  style = "slide",
})
```

**注意**：`speed` 必须在 `[0, 100]` 范围内。

---

## 9. layerrule 指令

```lua
hl.layer_rule({ rule = "blur on, match:namespace ^(rofi)$" })
```

---

## 10. hyprlock / hypridle 独立配置

`hyprlock` 和 `hypridle` 是独立守护进程，有各自的配置文件（不被 Hyprland 加载）：

```bash
# 加载方式
hyprlock --config ~/.config/hypr/sys/hyprlock.lua
hypridle --config ~/.config/hypr/sys/hypridle.lua
```

它们的 `source` 指令在 .lua 时代变为 `require`，路径解析方式相同。

---

## 相关文档

- [README.md](README.md) — .lua 配置架构
- [../02-Architecture/ARCHITECTURE_OVERVIEW.md](../02-Architecture/ARCHITECTURE_OVERVIEW.md) — 架构总览
- [../02-Architecture/THREE_LAYER_CONSTANTS.md](../02-Architecture/THREE_LAYER_CONSTANTS.md) — 三层常量系统
- [../03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) — 标签系统
- [../03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) — 状态机

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
