# Lua Configuration Architecture

> **本目录的 .lua 配置是 hypr-config 的当前形态**（Hyprland v0.55+ 原生 Lua）。
> 历史的 .conf 形式保留在 git 历史中（v0.55 之前的 commit）。
>
> 本文档解释 .lua 配置的架构、组织、设计原则——**不是迁移指南**。
> 如果你想了解 .conf → .lua 的转换细节，查看 git log 中迁移 commit 的说明。

---

## 1. 为什么是 Lua？

Hyprland 自 v0.55（2026-05-09）弃用 hyprlang（.conf DSL），改为原生 Lua 配置：
- v0.55–v0.56：.conf 仍兼容（fallback），.lua 是推荐
- v0.57/v0.58：硬删除 hyprlang，.lua 是唯一选择

本配置库的 `.lua` 文件是面向未来的形态。它们使用 Hyprland 的 `hl.*` API：

```lua
-- hyprland.lua（入口）
require("bootstrap").run()
```

```lua
-- 典型配置模式
hl.config({ general = { layout = "dwindle" } })
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))
hl.window_rule({ opacity = "0.9", match = { tag = "browser" } })
hl.on("hyprland.start", function() hl.exec_cmd("waybar") end)
```

---

## 2. 目录组织

```
~/.config/hypr/
├── hyprland.lua              # 单一入口（require bootstrap）
├── bootstrap/
│   ├── const.lua             # Layer 1: 路径常量（返回 table）
│   └── default.lua           # 管道编排器（Stage 0 + Stage 1）
├── sys/                      # Layer 2: 系统默认（只读）
│   ├── const.lua             # 系统常量（返回 table）
│   ├── default.lua           # 系统管道
│   ├── env.lua               # 环境变量
│   ├── input.lua             # 输入设备
│   ├── layout.lua            # 布局引擎
│   ├── decoration.lua        # 视觉装饰
│   ├── render.lua            # 渲染
│   ├── misc.lua              # 杂项
│   ├── startup.lua           # exec-once（hl.on 事件钩子）
│   ├── keybind.lua           # 快捷键（hl.bind）
│   ├── tags.lua              # 标签注册表
│   ├── rules.lua             # 窗口规则
│   ├── hardware/             # 硬件抽象
│   │   ├── default.lua
│   │   ├── laptop.lua
│   │   ├── monitors.lua
│   │   └── workspaces.lua
│   └── policy/               # 策略层（颜色 + 动画预设）
│       ├── default.lua
│       ├── wallust/
│       └── animations/
├── user/                     # Layer 3: 用户覆盖（编辑这里）
│   ├── const.lua             # 常量覆盖
│   ├── env.lua               # 环境变量覆盖
│   ├── input.lua             # 输入覆盖
│   └── ...
├── sys/scripts/              # 运行时脚本（.sh，调外部进程）
└── docs/                     # 本文档
```

**核心原则**：`sys/` 只读，`user/` 是你编辑的地方。`user/X.lua` 只含与 `sys/X.lua` 的**差异**（增量覆盖）。

---

## 3. 三层常量系统

```lua
-- bootstrap/const.lua — Layer 1: 路径基础设施（不可覆盖）
return {
  ['Hypr = "~/.config/hypr",
  ['sys  = "~/.config/hypr/sys",
  ['user = "~/.config/hypr/user",
}

-- sys/const.lua — Layer 2: 系统默认
return {
  ['M          = "SUPER",
  ['M_terminal = "kitty",
  ['S          = "~/.config/hypr/sys/scripts",
}

-- user/const.lua — Layer 3: 用户覆盖（仅差异）
return {
  ['M_terminal = "ghostty",  -- 覆盖 kitty
}
```

`bootstrap/default.lua` 按顺序 `require` 三层，用 `deep_merge` 合并（last-write-wins）。这让用户改一个常量，全链路生效。

---

## 4. 标签驱动窗口规则

**单一可信数据源**：`sys/tags.lua` 注册所有标签，`sys/rules.lua` 消费标签。

```lua
-- sys/tags.lua — 标签注册
hl.window_rule({
  match = { class = "^(firefox)$" },
  tag = "browser",
})

-- sys/rules.lua — 行为规则（引用标签）
hl.window_rule({
  opacity = "0.9",
  match = { tag = "browser" },
})
```

**对称性**：每个标签至少有一条规则，每条规则引用已定义的标签。

---

## 5. 状态机

3 个运行时状态机，原本是外部 .sh 脚本，在 .lua 时代可移入配置（用 `hl.bind(key, fn)` + `hl.on(event, fn)`）：

| 状态机 | 状态 | 触发 | 当前形态 |
|---|---|---|---|
| Layout | scrolling ↔ dwindle ↔ master | SUPER+ALT+L | .sh 脚本（可移入 .lua）|
| GameMode | NORMAL ↔ GAMING | SUPER+SHIFT+G | .sh 脚本（可移入 .lua）|
| NightLight | off ↔ on | SUPER+N | .sh 脚本（可移入 .lua）|

详见 [../03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md)。

---

## 6. 策略层（颜色 + 动画）

```lua
-- sys/policy/default.lua — 聚合 wallust 颜色 + 动画预设
require("sys.policy.wallust.wallust-hyprland")  -- $colorN 变量
require("sys.policy.animations.default")        -- 动画预设
```

6 个动画预设在 `sys/policy/animations/`，运行时可用 `Animations.sh` 切换（Strategy 模式）。

---

## 7. 事件驱动

.lua 时代用 `hl.on` 替代 .conf 的 `exec-once`：

```lua
-- sys/startup.lua — 替代 exec-once
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh")
end)
```

**新能力**：`hl.on("hyprland.shutdown", fn)` 提供 .conf 时代不可能的清理钩子。

---

## 8. bind 变体 → Lua flags

.lua 的 `hl.bind` 第三参数是 flags table：

```lua
-- 普通 bind
hl.bind("SUPER + Q", function() hl.dispatch("killactive") end)

-- locked（锁定时也激活）
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("Volume.sh --toggle"), {locked=true})

-- repeating（按住重复）
hl.bind("SUPER + SHIFT + left", function() hl.dispatch("resizeactive", "-50 0") end, {repeating=true})

-- mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.move(), {mouse=true})
```

| .conf 变体 | .lua flags |
|---|---|
| bindd | (无) |
| bindld | `{locked=true}` |
| binded | `{repeating=true}` |
| bindeld | `{locked=true, repeating=true}` |
| bindlnd | `{locked=true, non_consuming=true}` |
| bindmd | `{mouse=true}` |

---

## 9. 配置校验

```bash
# 静态检查
luacheck ~/.config/hypr --codes

# 真实 Hyprland 验证（headless，无需 GPU）
WLR_BACKENDS=headless hyprland --config ~/.config/hypr/hyprland.lua --i-am-really-stupid
# 应输出 "Welcome to Hyprland!" 且无 Lua error
```

---

## 10. 历史参考

如果你想对比 .conf 与 .lua 的语法差异，查看：
- git log 中的迁移 commit（记录了转换细节）
- [../06-Meta/DOC_RESTRUCTURING_NOTICE.md](../06-Meta/DOC_RESTRUCTURING_NOTICE.md) — 文档目录重组历史

**注意**：本配置库**不维护** .conf → .lua 转换工具。转换是一次性历史事件，转换工具不进本仓库。

---

## 相关文档

- [../02-Architecture/ARCHITECTURE_OVERVIEW.md](../02-Architecture/ARCHITECTURE_OVERVIEW.md) — 架构总览
- [../02-Architecture/DESIGN_PRINCIPLES.md](../02-Architecture/DESIGN_PRINCIPLES.md) — 设计原则
- [../03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) — 标签系统
- [../03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) — 状态机

---

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)
