# Hyprland Configuration

> **⚠️ 本文档以 .lua（Hyprland v0.55+ 原生）为准**。历史 .conf 形式见文末 [Historical .conf form](#historical-conf-form) 节，亦见 git history。
> 语法对照见 [../../07-Lua-Reference/COMPATIBILITY.md](../../07-Lua-Reference/COMPATIBILITY.md)。

> **Production-grade Hyprland window manager configuration** with professional software architecture
> Applying compilation theory, design patterns, and state machine formalization
>
> **Config Form**: Lua (native, Hyprland v0.55+) · **Tested**: Hyprland 0.56.2
> **Historical .conf form**: preserved in git history (pre-v0.55 commits)

---

## 🚀 Quick Start

### New to This Configuration?

**[Start Here](docs/01-Getting-Started/README.md)** — Project overview and key concepts

### Want to Get Running Fast?

**[Quick Start Guide](docs/01-Getting-Started/QUICK_START.md)** — 5-minute setup

### Looking for Something Specific?

**[Documentation Index](docs/06-Meta/DOCUMENTATION_INDEX.md)** — Complete navigation hub

### 5-Minute Install

```bash
# Clone the .lua config (no .conf files in this repo)
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr

# Edit user/const.lua — set your terminal / file manager / wallpaper dir
nano ~/.config/hypr/user/const.lua

# Launch Hyprland (no hyprctl reload needed — .lua auto-reloads on save)
Hyprland
```

---

## 📚 Documentation

This project features a **comprehensive documentation set** organized into 6 categories:

| Category                | Purpose             | Documents                         |
| ----------------------- | ------------------- | --------------------------------- |
| **01. Getting Started** | New user guides     | README, Quick Start, Common Tasks |
| **02. Architecture**    | Design & principles | Pipeline, Constants, Layers       |
| **03. Core Systems**    | Runtime behavior    | Tags, State Machines, Policies    |
| **04. Implementation**  | How-to guides       | Config, Scripts, Extensions       |
| **05. Reference**       | Lookup materials    | Constants, API, Troubleshooting   |
| **06. Meta**            | Project info        | Index, Contributing, Changelog    |

**📖 Browse all documentation**: [docs/06-Meta/DOCUMENTATION_INDEX.md](docs/06-Meta/DOCUMENTATION_INDEX.md)

---

## ✨ Key Features

### 🏗️ Professional Architecture

- **5-stage compilation pipeline** (lexical analysis → code generation)
- **Three-layer constant system** (bootstrap/sys/user)
- **Incremental override pattern** (user deltas over system defaults)
- **Dependency inversion** throughout

### ⚙️ Advanced Runtime Systems

- **Tag-driven window management** (28 category tags + 5 behavior tags)
- **Formal state machines** (layout engine, game mode, night light) — now in `.lua` modules
- **Strategy pattern policies** (swappable colors, animations)
- **Process lifecycle management** (service isolation, absolute paths)

### 🎨 Customization

- **Minimal user config** (only specify differences — return-table style)
- **Auto-reload** (Hyprland detects `.lua` file changes, no `hyprctl reload` for most edits)
- **Profile switching** (gaming, productivity, presentation modes)
- **Extensible tag system** (add custom window rules easily)

### 🚀 Performance

- **Fast startup** (~32ms config load time)
- **Low memory** (~150MB RAM usage)
- **Optimized rendering** (configurable blur, shadows, animations)
- **Efficient IPC** (batched `hl.config({...})` calls)

---

## 🎯 Learning Paths

Choose the path that matches your expertise level:

### Essential User (15 min)

Learn basics and common tasks

- [README](docs/01-Getting-Started/README.md) → [Common Tasks](docs/01-Getting-Started/COMMON_TASKS.md)

### Power User (90 min)

Understand architecture and customize effectively

- Architecture Overview → Three-Layer Constants → Configuration Guide

### Developer (3.5 hours)

Deep understanding for advanced customization

- All Power User content + Design Principles + Tag System + State Machines

### Architect (8+ hours)

Complete mastery for architectural decisions

- Full documentation suite including pipeline architecture, layer boundaries, performance tuning

**See all learning paths**: [DOCUMENTATION_INDEX.md](docs/06-Meta/DOCUMENTATION_INDEX.md) § Learning Paths

---

## 📁 Project Structure

```bash
~/.config/hypr/
├── hyprland.lua              # Single entry point (requires bootstrap.default)
├── icon.png                   # notification icon used by hypridle
│
├── bootstrap/                 # Layer 1: Infrastructure constants
│   ├── const.lua             # Path constants (return-table form)
│   └── default.lua           # Pipeline orchestrator (requires all layers)
│
├── sys/                       # Layer 2: System defaults (read-only)
│   ├── const.lua             # System constants ($M, $S, $H, $P, etc.)
│   ├── default.lua           # System pipeline
│   ├── env.lua               # hl.env calls
│   ├── input.lua             # hl.config input settings
│   ├── layout.lua            # hl.config layout engines
│   ├── decoration.lua       # hl.config visual decoration
│   ├── render.lua            # hl.config render pipeline
│   ├── misc.lua              # hl.config misc options
│   ├── startup.lua           # hl.on("hyprland.start", fn) hooks
│   ├── keybind.lua           # hl.bind calls + SM-aware binds
│   ├── tags.lua              # Tag registry (hl.window_rule)
│   ├── rules.lua             # Tag-driven window rules (hl.window_rule)
│   ├── hardware/             # Hardware abstraction (monitors, input)
│   │   ├── default.lua
│   │   ├── laptop.lua
│   │   └── monitors.lua
│   ├── policy/               # Strategy pattern (colors + animations)
│   │   ├── default.lua
│   │   ├── wallust/
│   │   └── animations/
│   ├── statemachine/         # F3 backport: in-config Lua SMs
│   │   ├── layout.lua        # 3-state layout cycle
│   │   ├── gamemode.lua      # 2-state game mode toggle
│   │   └── nightlight.lua    # 2-state night light toggle
│   └── scripts/              # Runtime scripts (~60 .sh files, fallback targets)
│
├── user/                      # Layer 3: User overrides (edit here)
│   ├── const.lua             # Constant overrides (return-table)
│   ├── env.lua               # Environment variable overrides
│   ├── input.lua             # Input overrides
│   ├── keybind.lua           # Additional keybinds
│   ├── tags.lua              # Additional tag registrations
│   ├── rules.lua             # Additional window rules
│   └── ...                   # Other overrides
│
├── lib/                       # Shared libraries
│   └── sm.lua                # State machine base class (pcall + invariants)
│
└── docs/                      # Documentation
    ├── 01-Getting-Started/
    ├── 02-Architecture/
    ├── 03-Core-Systems/
    ├── 04-Implementation/
    ├── 05-Reference/
    ├── 06-Meta/
    └── 07-Lua-Reference/
```

**Key Design Principle**: `sys/` is read-only (vendor defaults), `user/` is where you edit. `user/X.lua` contains only the **deltas** from `sys/X.lua` (incremental override pattern).

---

## 🔧 Installation

### Prerequisites

- Hyprland >= 0.55.0 (Lua config native; tested on 0.56.2)
- Wayland compositor running
- Required packages: `awww`, `waybar`, `swaync`, `cliphist`, `hypridle`, `rofi`, `wallust`

### Quick Install

```bash
# Clone or copy this configuration (now .lua-first)
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr

# Review and customize user constants (Lua return-table style)
nano ~/.config/hypr/user/const.lua

# Launch Hyprland — no hyprctl reload needed (.lua auto-reloads on save)
Hyprland
```

### Static Check (Recommended)

```bash
# Install luacheck if missing
sudo luarocks install luacheck

# Run static check — should be 0 warnings/errors
luacheck ~/.config/hypr --codes
```

**Detailed installation guide**: [docs/01-Getting-Started/QUICK_START.md](docs/01-Getting-Started/QUICK_START.md)

---

## 🎓 Core Concepts

### 1. Three-Layer Constant System

Constants are returned as **Lua tables** from three layered files. Bootstrap merges them via `deep_merge(C, require(...))` so that user overrides win:

```lua
-- bootstrap/const.lua (Layer 1: paths, not overridable)
return {
  ['Hypr = "~/.config/hypr",
  ['sys   = "~/.config/hypr/sys",
  ['user  = "~/.config/hypr/user",
}

-- sys/const.lua (Layer 2: system defaults)
return {
  ['M          = "SUPER",
  ['M_terminal = "kitty",
  ['S          = "~/.config/hypr/sys/scripts",
}

-- user/const.lua (Layer 3: your overrides — only the deltas)
return {
  ['M_terminal = "ghostty",  -- ← Wins! (deep_merge last-write-wins)
}
```

**Learn more**: [THREE_LAYER_CONSTANTS.md](docs/02-Architecture/THREE_LAYER_CONSTANTS.md)

### 2. Incremental Override Pattern

```lua
-- sys/input.lua (system default)
hl.config({ input = { kb_layout = "us" } })

-- user/input.lua (your delta — ONLY this line needed)
hl.config({ input = { kb_layout = "us,cn" } })  -- last-write-wins
```

**Learn more**: [DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md) § Incremental Override

### 3. Tag-Driven Window Management

```lua
-- sys/tags.lua — STEP 1: classify apps (WHAT they ARE)
hl.window_rule({
  match = { class = "^([Ff]irefox)$" },
  tag = "browser",
})

-- sys/rules.lua — STEP 2: define behavior (HOW they act)
hl.window_rule({
  opacity = "1.00 0.85",
  match = { tag = "browser" },
})
```

**Learn more**: [TAG_SYSTEM.md](docs/03-Core-Systems/TAG_SYSTEM.md)

### 4. State Machine Runtime (Lua-native)

The config ships three formal state machines **as Lua modules** under `sys/statemachine/`, sharing the base class `lib/sm.lua`:

```lua
-- sys/keybind.lua — SM-aware bind (pcall + .sh fallback)
local ok_sm, layout_sm = pcall(require, 'sys.statemachine.layout')

hl.bind("SUPER + ALT + L", function()
  if ok_sm then layout_sm.new(hl):fire("cycle")
  else hl.dsp.exec_cmd("~/.config/hypr/sys/scripts/ChangeLayout.sh") end
end)
```

| State Machine | States                         | Trigger        | Module                            |
| ------------- | ------------------------------ | -------------- | --------------------------------- |
| Layout        | scrolling ↔ dwindle ↔ master | SUPER+ALT+L    | `sys/statemachine/layout.lua`     |
| GameMode      | NORMAL ↔ GAMING               | SUPER+SHIFT+G  | `sys/statemachine/gamemode.lua`   |
| NightLight    | off ↔ on (4500K)              | SUPER+N        | `sys/statemachine/nightlight.lua` |

**Learn more**: [STATE_MACHINES.md](docs/03-Core-Systems/STATE_MACHINES.md)

---

## 🛠️ Common Tasks

### Change Terminal Emulator

Edit `user/const.lua` (return-table style):

```lua
-- user/const.lua
return {
  ['M_terminal = "ghostty",  -- options: kitty, alacritty, foot, wezterm, ghostty
}
```

Hyprland auto-reloads on save — no `hyprctl reload` needed.

### Modify Keybindings

Edit `user/keybind.lua` (Lua form):

```lua
-- user/keybind.lua
hl.bind("SUPER + T", hl.dsp.exec_cmd("ghostty"))

-- With locked flag (active on lock screen)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Lua function dispatcher (impossible in .conf era)
hl.bind("SUPER + ALT + G", function()
  require('sys.statemachine.gamemode').new(hl):fire("toggle")
end)
```

### Add a New App (Tag + Rule)

1. Add tag in `user/tags.lua`:

   ```lua
   -- user/tags.lua
   hl.window_rule({
     match = { class = "^([Mm]yapp)$" },
     tag = "myapp",
   })
   ```

2. Define behavior in `user/rules.lua`:

   ```lua
   -- user/rules.lua
   hl.window_rule({
     float = true,
     match = { tag = "myapp" },
   })
   hl.window_rule({
     size = "1200 800",
     match = { tag = "myapp" },
   })
   ```

### Override Other Constants

```lua
-- user/const.lua
return {
  ['M_terminal     = "ghostty",                    -- terminal emulator
  ['M_file_manager = "thunar",                     -- file manager
  ['W              = "~/Pictures/my-wallpapers",   -- wallpaper directory
  ['Search_Engine  = "\"https://google.com/search?q={}\"",  -- used by RofiSearch.sh
}
```

**More common tasks**: [docs/01-Getting-Started/COMMON_TASKS.md](docs/01-Getting-Started/COMMON_TASKS.md)

---

## 🐛 Troubleshooting

### Colors Not Working?

Check Stage 2 constraint: policy must load before decoration.
See: [PIPELINE_ARCHITECTURE.md](docs/02-Architecture/PIPELINE_ARCHITECTURE.md) § Stage 2 Constraints

### Keybinds Not Responding?

Re-initialize layout binds (fallback path):

```bash
~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh
```

Or check for Lua errors:

```bash
luacheck ~/.config/hypr --codes
journalctl -u hyprland-session -f
```

### Service Not Starting?

Check the `hl.on("hyprland.start", fn)` hook in `sys/startup.lua`:

```lua
-- sys/startup.lua
hl.on("hyprland.start", function()
  hl.exec_cmd("awww-daemon --format xrgb")
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  -- ...
end)
```

Daemons need absolute paths. See  _(coming soon)_

**Full troubleshooting guide**: [docs/05-Reference/TROUBLESHOOTING.md](docs/05-Reference/TROUBLESHOOTING.md)

---

## 🤝 Contributing

We welcome contributions! Please see:

- **[Contributing Guidelines](docs/06-Meta/CONTRIBUTING.md)** _(coming soon)_
- **[Documentation Standards](docs/06-Meta/CONTRIBUTING.md)** _(coming soon)_
- **[Code of Conduct](CODE_OF_CONDUCT.md)** _(coming soon)_

**Quick start**:

1. Fork the repository
2. Create feature branch
3. Make changes (follow style guide — `luacheck` clean)
4. Submit pull request

---

## 📊 Project Statistics

| Metric                  | Value                              |
| ----------------------- | ---------------------------------- |
| **Configuration Files** | 45 `.lua` files (0 `.conf`)        |
| **Scripts**             | 60 `.sh` files (runtime + SM fallback) |
| **Libraries**           | 1 (`lib/sm.lua` — SM base class)   |
| **Documentation**       | 17 docs across 7 categories         |
| **Lines of Config**     | ~3,000 lines                       |
| **Lines of Scripts**    | ~5,000 lines                       |
| **Lines of Docs**       | ~15,000 lines                      |

---

## 📜 License

This configuration is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **Hyprland Team**: For the amazing Wayland compositor and v0.55 native Lua config
- **Community Contributors**: For scripts, ideas, and feedback
- **Software Engineering Literature**: For design patterns and architecture principles

---

## 📞 Support

- **Documentation**: [docs/06-Meta/DOCUMENTATION_INDEX.md](docs/06-Meta/DOCUMENTATION_INDEX.md)
- **Issues**: GitHub Issues (use labels: `bug`, `question`, `documentation`)
- **Discussions**: GitHub Discussions
- **Wiki**: [Project Wiki](wiki-link) _(coming soon)_

---

## Pipeline

```
hyprland.lua
  └── bootstrap/default.lua
        ├── Stage 0: bootstrap/const.lua   (constants)
        ├── Stage 0: sys/const.lua         (sys constants)
        ├── Stage 0: user/const.lua        (user constant overrides)
        └── Stage 1: sys/default.lua       (entry point)
              ├── sys/hardware/default.lua → laptop + monitors + workspaces
              ├── sys/policy/default.lua   → wallust colors + animations
              ├── sys/env.lua          → user/env.lua
              ├── sys/misc.lua         → user/misc.lua
              ├── sys/input.lua        → user/input.lua
              ├── sys/layout.lua       → user/layout.lua
              ├── sys/decoration.lua   → user/decoration.lua
              ├── sys/render.lua       → user/render.lua
              ├── sys/startup.lua      → user/startup.lua
              ├── sys/keybind.lua      → user/keybind.lua
              ├── sys/tags.lua         → user/tags.lua
              └── sys/rules.lua        → user/rules.lua
```

require order = override priority: **later wins** (`deep_merge(C, require(...))`).

**See Also**:

- [PIPELINE_ARCHITECTURE.md](docs/02-Architecture/PIPELINE_ARCHITECTURE.md) — Complete pipeline documentation with compiler analogies
- [DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md) § Compilation Pipeline — Lexical/syntax/semantic analysis phases

## User Customization

Every `sys/` file has a paired `user/` override. Edit only the `user/` files.

**Common overrides:**

```lua
-- user/const.lua
return {
  ['M_terminal     = "ghostty",
  ['M_file_manager = "thunar",
  ['W              = "~/Pictures/my-wallpapers",
  ['Search_Engine  = "\"https://google.com/search?q={}\"",  -- used by RofiSearch.sh (SUPER+S)
}

-- user/env.lua
hl.env("EDITOR",              "nvim")
hl.env("HYPR_TERMINAL",       "ghostty")        -- used by wallpaper/waybar scripts
hl.env("HYPR_WALLPAPER_DIR",  "/path/to/wallpapers")
hl.env("HYPR_FILE_MANAGER",   "thunar")         -- used by WaybarScripts.sh
hl.env("GDK_SCALE",           "1.5")             -- HiDPI
hl.env("QT_SCALE_FACTOR",     "1.5")

-- user/layout.lua — startup layout (scrolling requires scrolling layout (built-in since v0.55))
hl.config({ general = { layout = "dwindle" } })

-- user/input.lua
hl.config({ input = { kb_layout = "us,cn" } })

-- user/misc.lua
hl.config({ misc = { vfr = true } })  -- variable frame rate (power saving)
```

**Design Principle**: Incremental Override Pattern — user files contain only deltas from system defaults. See [DESIGN_PRINCIPLES.md § Dependency Inversion](docs/02-Architecture/DESIGN_PRINCIPLES.md).

## Layout System

Three layouts are supported, cycled at runtime with `SUPER+ALT+L` (driven by `sys/statemachine/layout.lua`):

```
scrolling  →  dwindle  →  master  →  scrolling  → …
```

| Layout      | Description                         | `SUPER+J/K`                    | `SUPER+O`     |
| ----------- | ----------------------------------- | ------------------------------ | ------------- |
| `scrolling` | scrolling layout (built-in since v0.55) (column-based) | built-in (column nav)      | unbound       |
| `dwindle`   | binary space partitioning           | `cyclenext` / `cyclenext,prev` | `togglesplit` |
| `master`    | master-stack                        | `cyclenext` / `cyclenext,prev` | unbound       |

The startup layout is set in `user/layout.lua` (default: `dwindle`).
`sys/layout.lua` provides `scrolling (built-in since v0.55) {}` defaults for scrolling layout.

### State Machine Implementation

Layout transitions are managed by an explicit **3-state finite state machine** in `sys/statemachine/layout.lua` (using the base class `lib/sm.lua`). See [STATE_MACHINES.md § Layout Engine](docs/03-Core-Systems/STATE_MACHINES.md) for formal definition, transition functions, and atomicity guarantees.

### scrolling layout Keybinds

| Key                       | Action                            |
| ------------------------- | --------------------------------- |
| `SUPER + .`               | Move column right                 |
| `SUPER + ,`               | Move column left                  |
| `SUPER + SHIFT + .`       | Move window to right column       |
| `SUPER + SHIFT + ,`       | Move window to left column        |
| `SUPER + SHIFT + ↑/↓`     | Move window up/down               |
| `SUPER + ]`               | Resize column wider (+0.1)        |
| `SUPER + [`               | Resize column narrower (-0.1)     |
| `SUPER + CTRL + ]`        | Cycle column width up (`+conf`)   |
| `SUPER + CTRL + [`        | Cycle column width down (`-conf`) |
| `SUPER + ALT + F`         | Fit active column into view       |
| `SUPER + ALT + SHIFT + F` | Fit all visible columns           |
| `SUPER + CTRL + ,`        | Swap column left                  |
| `SUPER + CTRL + .`        | Swap column right                 |
| `SUPER + '`               | Promote window to its own column  |
| `SUPER + CTRL + T`        | Toggle fit method (center ↔ fit)  |

Override `scrolling (built-in since v0.55)` defaults in `user/layout.lua`.

## Keybinds

| Key                 | Action                                                  |
| ------------------- | ------------------------------------------------------- |
| `SUPER + H`         | Cheat sheet                                             |
| `SUPER + SHIFT + K` | Search keybinds                                         |
| `SUPER + SHIFT + E` | Quick settings menu                                     |
| `SUPER + D`         | App launcher (rofi)                                     |
| `SUPER + Return`    | Terminal                                                |
| `SUPER + W`         | Wallpaper selector                                      |
| `SUPER + ALT + L`   | Cycle layout (scrolling → dwindle → master → scrolling) |
| `SUPER + J / K`     | Cycle windows (dwindle/master) · column nav (scrolling) |
| `SUPER + O`         | Toggle split (dwindle only)                             |
| `SUPER + SHIFT + G` | Toggle game mode                                        |
| `SUPER + N`         | Toggle night light                                      |
| `SUPER + ALT + R`   | Refresh waybar + swaync                                 |

See `sys/keybind.lua` for the full table, or press `SUPER + SHIFT + K` at runtime.

## Scripts

All scripts live in `sys/scripts/`. User-specific scripts go in `user/scripts/`.

| Script                  | Trigger          | Purpose                                                     |
| ----------------------- | ---------------- | ----------------------------------------------------------- |
| `ChangeLayout.sh`       | `SUPER+ALT+L`    | Three-state layout cycle (fallback for Lua SM)              |
| `KeybindsLayoutInit.sh` | startup          | Initialize layout-aware binds based on current layout       |
| `GameMode.sh`           | `SUPER+SHIFT+G`  | Toggle animations/blur/gaps off for gaming (fallback for Lua SM) |
| `WallpaperSelect.sh`    | `SUPER+W`        | Pick wallpaper + apply wallust colors                       |
| `Animations.sh`         | `SUPER+SHIFT+A`  | Switch animation preset                                     |
| `RofiSearch.sh`         | `SUPER+S`        | Web search: resolves `$Search_Engine` user → sys → fallback |
| `DarkLight.sh`          | Quick Settings   | Toggle dark/light theme system-wide                         |
| `Refresh.sh`            | `SUPER+ALT+R`    | Restart waybar + swaync                                     |
| `RefreshNoWaybar.sh`    | wallpaper change | Refresh theme without restarting waybar                     |
| `Hyprsunset.sh`         | `SUPER+N`        | Toggle night light (fallback for Lua SM, state persists)   |
| `Hypridle.sh`           | waybar module    | Toggle hypridle on/off                                      |
| `Quick_Settings.sh`     | `SUPER+SHIFT+E`  | Open user config files in editor                            |

**State Machine Modules**: `sys/statemachine/{layout,gamemode,nightlight}.lua` are the **primary** implementations, replacing the `.sh` scripts above. The `.sh` scripts survive as `pcall`-protected fallback targets. See [STATE_MACHINES.md](docs/03-Core-Systems/STATE_MACHINES.md) for the Lua implementation details.

## Policies

Swappable at runtime without reloading the full config:

- **Animations** — presets in `sys/policy/animations/`: `default` `disable` `end4` `hyde-optimized` `hyde-vertical` `ml4w-fast`
- **Colors** — generated by wallust into `sys/policy/wallust/wallust-hyprland.lua` on wallpaper change

**Design Pattern**: Strategy Pattern — policies are interchangeable algorithms. See [DESIGN_PRINCIPLES.md § Policy Layer](docs/02-Architecture/DESIGN_PRINCIPLES.md).

## Window Tags

Tags are defined in `sys/tags.lua` and consumed by `sys/rules.lua`.
Add personal app tags in `user/tags.lua` with matching rules in `user/rules.lua`.

**Category tags** (what an app is):
`browser` `terminal` `im` `email` `projects` `notes` `file-manager` `multimedia` `multimedia-video` `screenshare` `games` `gamestore` `viewer` `text-editor` `utils` `calculator` `settings` `audio-mixer` `wallpaper` `notif`

**Behavior tags** (how a window behaves):
`pip` `auth-dialog` `file-dialog` `no-steal-focus` `suppress-activate`

**Helper tags**: `$H_Cheat` `$H_Settings` `keybindings`

**Architecture**: Tag-driven rule system implements Strategy Pattern for window management. See [DESIGN_PRINCIPLES.md § Tag-Driven System](docs/02-Architecture/DESIGN_PRINCIPLES.md) and [PIPELINE_ARCHITECTURE.md § Stage 5](docs/02-Architecture/PIPELINE_ARCHITECTURE.md).

## Dependencies

**Required:** `hyprland` `hyprlock` `hypridle` `awww` `waybar` `swaync` `rofi-wayland` `cliphist` `wl-clipboard` `grim` `slurp` `pamixer` `playerctl` `brightnessctl` `nm-applet` `wallust` `jq`

**Optional:** `scrolling layout` (scrolling layout, install via -- hyprpm (not needed for scrolling, built-in since v0.55) (for other plugins, not needed for scrolling)) · `mpvpaper` (live wallpapers) · `fcitx5` (input method) · `nwg-displays` (monitor config GUI) · `kvantummanager` (Qt theming) · `qs` / `quickshell` (overview widget) · `swappy` (screenshot annotation)

> scrolling layout -> departed to in builtins

## Design Philosophy

This configuration treats the desktop environment as a **compiled system** rather than a collection of scripts. Key principles:

1. **Compilation Pipeline**: Config loading mirrors compiler phases (lexical → syntax → semantic → code generation)
2. **Layered Architecture**: Clear boundaries between bootstrap, system, hardware, policy, and user layers
3. **Dependency Inversion**: Constants abstract implementation details; user overrides injected at Stage 0
4. **State Machines**: Runtime behavior changes managed via explicit state transition functions (now in `.lua`)
5. **Policy-Based Management**: Swappable strategies (colors, animations) without full reload
6. **Tag-Driven Rules**: Decouple window classification from behavior (Strategy Pattern)
7. **Single Responsibility**: Each file has one clear purpose
8. **Incremental Override**: User files contain only deltas from system defaults

For detailed explanations, see [DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md).

## Contributing

When contributing to this configuration:

1. **Maintain Layer Boundaries**: Don't cross layer responsibilities
2. **Preserve Invariants**: Every tag must have rules; require order must be correct
3. **Document Changes**: Update relevant `.md` files
4. **Test State Transitions**: Verify state machines handle edge cases (use `lib/sm.lua`'s `:fire_n()` helper)
5. **Follow Naming Conventions**: `M_*` for apps, `H_*` for helpers, `U_*` for user

See [DESIGN_PRINCIPLES.md § Best Practices](docs/02-Architecture/DESIGN_PRINCIPLES.md) for detailed guidelines.

## License

This configuration is provided as-is for educational and practical use. Feel free to adapt the architectural patterns to your own dotfiles.

## Acknowledgments

Architectural patterns inspired by:

- Compiler design (Aho, Lam, Sethi, Ullman - "Compilers: Principles, Techniques, and Tools")
- Design Patterns (Gamma, Helm, Johnson, Vlissides - "Design Patterns: Elements of Reusable Object-Oriented Software")
- Linux config.d convention
- Hyprland community configurations (end-4, prasanthrangan/hyprdots, mylinuxforwork)

---

## Historical .conf form

> The following examples show the **legacy `.conf` syntax** preserved here for historical context only. The current repo no longer contains `.conf` files — see git history for the migration commits.

### Example 1: const file + bind (LEGACY `.conf`)

```conf
# user/const.conf  (LEGACY — not in current repo)
$M_terminal     = ghostty
$M_file_manager = thunar
$W              = $HOME/Pictures/my-wallpapers

# user/keybind.conf  (LEGACY)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("$M_terminal"))
bindl = , XF86AudioMute, exec, $S/Volume.sh --toggle
```

**Equivalence**: In `.lua`, the `$var = value` assignments become `return { ['var = "value" }` table keys in `user/const.lua`. The `bind = MOD, KEY, exec, CMD` directive becomes `hl.bind("MOD + KEY", hl.dsp.exec_cmd("CMD"))` — the modifiers and key are joined into a single ` + `-separated string, and the `bindl` "locked" variant moves to a third-arg flags table `{ locked = true }`.

### Example 2: windowrule + exec-once (LEGACY `.conf`)

```conf
# user/rules.conf  (LEGACY)
hl.window_rule({ match = { class = "^(Firefox)$" }, tag = "browser" })
hl.window_rule({ opacity = "1.00 0.85", match = { tag = "browser" } })

# sys/startup.conf  (LEGACY)
exec-once = awww-daemon --format xrgb
exec-once = waybar
exec-once = $S/Hyprsunset.sh init
```

**Equivalence**: In `.lua`, `windowrule = match:class ^X$, tag +Y` becomes `hl.window_rule({ match = { class = "^X$" }, tag = "Y" })` — the rule keyword becomes a table field name. `windowrule = opacity V, match:tag X` becomes `hl.window_rule({ opacity = "V", match = { tag = "X" } })`. `exec-once = cmd` becomes `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` — event-driven, with the bonus of `hl.on("hyprland.shutdown", fn)` cleanup hooks that were impossible in the `.conf` era.

---

**⭐ If you find this useful, please star the repository!**

**Last Updated**: 2026-08-19 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)

---

**🔝 [Back to Top](#hyprland-configuration)**
