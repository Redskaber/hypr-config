# Hyprland Configuration

> **Pure `.lua` Hyprland window manager config** — native Lua API (Hyprland v0.55+).
> Tested on Hyprland 0.56.2. Historical `.conf` form is preserved in git history only.

Production-grade desktop environment that applies **compilation pipeline**, **design patterns**,
and **formal state machines** to a window manager configuration. Every architectural decision is
documented under [`docs/`](docs/).

---

## 🚀 Quick Start

### 5-Minute Install

```bash
# Clone into ~/.config/hypr
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr

# Edit user constants (terminal, search engine, etc.)
$EDITOR ~/.config/hypr/user/const.lua

# Verify the config loads cleanly
hyprland --verify-config

# Launch Hyprland — .lua files auto-reload on save (no `hyprctl reload` for edits)
Hyprland
```

> 💡 **Tip**: If `--verify-config` is unavailable, run `luacheck ~/.config/hypr --codes`
> (see `.luacheckrc`). A clean `hyprland --verify-config` is the gold standard.

### Where to Go Next

| If you want to… | Read |
| --- | --- |
| Understand the big picture | [docs/01-Getting-Started/README.md](docs/01-Getting-Started/README.md) |
| Install step-by-step | [docs/01-Getting-Started/QUICK_START.md](docs/01-Getting-Started/QUICK_START.md) |
| Do common customizations | [docs/01-Getting-Started/COMMON_TASKS.md](docs/01-Getting-Started/COMMON_TASKS.md) |
| Browse all docs | [docs/06-Meta/DOCUMENTATION_INDEX.md](docs/06-Meta/DOCUMENTATION_INDEX.md) |

---

## ✨ Key Features

### 🏗️ Professional Architecture
- **Layered pipeline** (bootstrap → sys → user) with last-write-wins merge on `_G.HYPR_CONST`
- **Three-layer constant system** — path infra / system defaults / user deltas
- **Incremental override pattern** — every `sys/X.lua` has a paired `user/X.lua`
- **Dependency inversion** via `lib/deps.lua` (25 external tools declared, 0 hard-coded)

### ⚙️ Advanced Runtime Systems
- **Tag-driven window management** — 26 tags in `sys/tags.lua` (categories + behaviors)
- **Formal state machines** — layout / game mode / night light, sharing `lib/sm.lua` base class
  (`pcall`-wrapped transitions + invariant assertions + transition log)
- **Strategy pattern policies** — swappable animation presets + wallust-generated colors
- **Dropdown terminal** — state machine + strategy + pipeline design (`sys/scripts/Dropterminal.sh`)

### 🎨 Customization
- Minimal user config — only specify deltas in `user/*.lua`
- Auto-reload on save (Hyprland watches `.lua` files)
- Profile switching via state machines (game mode, night light)
- Extensible tag system — add window rules in `user/tags.lua` + `user/rules.lua`

### 🚀 Performance
- Fast startup (config loads in a few ms)
- Batched `hl.config({...})` calls (single IPC round-trip per file)
- External tools resolved once at load time (no per-bind `os.execute`)

---

## 📁 Project Structure

```bash
~/.config/hypr/
├── hyprland.lua              # Entry point: require("bootstrap.default")
├── architecture.md           # Pointer to docs/02-Architecture/
├── icon.png                  # Notification icon (used by hypridle)
├── hypridle.conf → sys/hypridle.conf   # symlink (daemon needs .conf)
├── hyprlock.conf → sys/hyprlock.conf   # symlink (daemon needs .conf)
│
├── bootstrap/                # Layer 1 — path infrastructure (immutable)
│   ├── const.lua            # _G.HYPR_CONST.Hypr / .sys / .user / .lock_background
│   └── default.lua          # Pipeline orchestrator: const layers + sys/default
│
├── sys/                      # Layer 2 — system defaults (read-only, vendor)
│   ├── const.lua            # M, M_terminal, M_file_manager, S/H/P path prefixes…
│   ├── default.lua          # require chain (defines override priority)
│   ├── env.lua              # hl.env() calls
│   ├── input.lua            # input.* settings
│   ├── layout.lua           # layout engine defaults (dwindle/scrolling/master)
│   ├── decoration.lua       # decoration.* settings
│   ├── render.lua           # render.* settings
│   ├── misc.lua             # misc.* settings
│   ├── startup.lua          # hl.on("hyprland.start", fn) hook
│   ├── keybind.lua          # 132 hl.bind calls + SM-aware binds
│   ├── tags.lua             # Tag registry (26 tags, hl.window_rule)
│   ├── rules.lua            # Tag-driven behavior rules
│   ├── hardware/            # Hardware abstraction (monitors, laptop, workspaces)
│   ├── policy/              # Strategy pattern: animations/ + wallust/
│   ├── statemachine/        # Lua-native SMs: layout / gamemode / nightlight
│   └── scripts/             # 60 .sh runtime scripts (+ 3 .lua helpers)
│
├── user/                     # Layer 3 — user overrides (EDIT HERE)
│   ├── const.lua            # Delta overrides only
│   ├── env.lua  input.lua  layout.lua  decoration.lua  render.lua  misc.lua
│   ├── startup.lua  keybind.lua  tags.lua  rules.lua
│
├── lib/                      # Shared libraries
│   ├── sm.lua               # State machine base class (pcall + invariant + log)
│   ├── deps.lua             # 25-tool external dependency manifest (SSOT + DI)
│   ├── types.lua            # LuaLS type definitions (hl.* API surface)
│   └── script_utils.lua     # Helpers shared by shell scripts
│
├── wallpaper_effects/        # wallust output (gitignored)
└── docs/                     # Documentation (6 categories, see below)
```

**Key principle**: `sys/` is read-only. `user/X.lua` contains only the **deltas** you want to override.
Later requires win (last-write-wins on `_G.HYPR_CONST`).

---

## 📚 Documentation

Documentation is organized into 6 categories under [`docs/`](docs/):

| Category | What's inside | Start here |
| --- | --- | --- |
| **01-Getting-Started** | Project overview, quick start, common tasks | [README.md](docs/01-Getting-Started/README.md) |
| **02-Architecture** | Pipeline, design principles, three-layer constants | [ARCHITECTURE_OVERVIEW.md](docs/02-Architecture/ARCHITECTURE_OVERVIEW.md) |
| **03-Core-Systems** | Tag system, state machines | [TAG_SYSTEM.md](docs/03-Core-Systems/TAG_SYSTEM.md) |
| **05-Reference** | Troubleshooting, GPU verification | [TROUBLESHOOTING.md](docs/05-Reference/TROUBLESHOOTING.md) |
| **06-Meta** | Documentation index, changelog, completion report | [DOCUMENTATION_INDEX.md](docs/06-Meta/DOCUMENTATION_INDEX.md) |
| **07-Lua-Reference** | Legacy `.conf` ↔ `.lua` compatibility notes | [COMPATIBILITY.md](docs/07-Lua-Reference/COMPATIBILITY.md) |

> ℹ️ `docs/04-Implementation/` does not exist (deliberately skipped during restructuring).

---

## 🎓 Core Concepts

### 1. Three-Layer Constant System

Constants live in `_G.HYPR_CONST` — a single global table populated by three layered files.
Each layer writes to the same table; **last-write-wins** gives user overrides priority.

```lua
-- bootstrap/const.lua  (Layer 1 — paths, immutable)
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.Hypr  = "~/.config/hypr"
_G.HYPR_CONST.sys   = "~/.config/hypr/sys"
_G.HYPR_CONST.user  = "~/.config/hypr/user"

-- sys/const.lua  (Layer 2 — system defaults, read-only)
_G.HYPR_CONST.M          = "SUPER"
_G.HYPR_CONST.M_terminal = "kitty"
_G.HYPR_CONST.S          = "~/.config/hypr/sys/scripts"

-- user/const.lua  (Layer 3 — YOUR overrides, deltas only)
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.M_terminal = "ghostty"   -- ← wins (loaded last)
```

> ⚠️ There is no `deep_merge()` or `return { ... }` table form. Constants are plain
> `_G.HYPR_CONST.key = value` assignments — last-write-wins on the shared global table.

**Learn more**: [docs/02-Architecture/THREE_LAYER_CONSTANTS.md](docs/02-Architecture/THREE_LAYER_CONSTANTS.md)

### 2. Incremental Override Pattern

Every `sys/X.lua` file has a paired `user/X.lua`. Edit only the user file — it runs
*after* the sys file in the require chain, so its `hl.config({...})` calls win.

```lua
-- sys/input.lua  (system default — read-only)
hl.config({ input = { kb_layout = "us" } })

-- user/input.lua  (your delta — only the fields you want to change)
hl.config({ input = { kb_layout = "us,cn" } })   -- last-write-wins
```

> ⚠️ Note: `hl.config({...})` does a **table merge at the top-level keys you pass**, not a
> deep merge of every nested field. Pass the full sub-table you want to override.

**Learn more**: [docs/02-Architecture/DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md)

### 3. Tag-Driven Window Management

Two-step pattern decoupling "what an app is" from "how it behaves":

```lua
-- sys/tags.lua  — STEP 1: classify apps (WHAT they ARE)
hl.window_rule({
  match = { class = "^([Ff]irefox)$" },
  tag = "browser",
})

-- sys/rules.lua  — STEP 2: define behavior (HOW they act)
hl.window_rule({
  opacity = "1.00 0.85",
  match = { tag = "browser" },
})
```

**26 tags** defined in `sys/tags.lua`:

- **Category tags** (what an app is):
  `browser` `terminal` `im` `email` `projects` `notes` `file-manager`
  `multimedia` `multimedia-video` `screenshare` `games` `gamestore`
  `viewer` `text-editor` `utils` `calculator` `settings` `audio-mixer`
  `wallpaper` `notif`
- **Behavior tags** (how a window behaves):
  `pip` `auth-dialog` `file-dialog` `no-steal-focus` `suppress-activate`
- **Helper tags**: `keybindings` (and the `$H_Cheat` / `$H_Settings` constants)

**Learn more**: [docs/03-Core-Systems/TAG_SYSTEM.md](docs/03-Core-Systems/TAG_SYSTEM.md)

### 4. State Machine Runtime (Lua-native)

Three formal state machines in `sys/statemachine/`, all sharing the `lib/sm.lua` base class
(`pcall`-wrapped transitions, invariant assertions, transition log):

| State Machine | States | Trigger | Module |
| --- | --- | --- | --- |
| Layout | scrolling ↔ dwindle ↔ master | `SUPER + ALT + L` | `sys/statemachine/layout.lua` |
| GameMode | normal ↔ gaming | `SUPER + SHIFT + G` | `sys/statemachine/gamemode.lua` |
| NightLight | off ↔ on (4500K) | `SUPER + N` | `sys/statemachine/nightlight.lua` |

```lua
-- sys/keybind.lua — SM-aware bind (state machine is primary, .sh is fallback)
local layout_sm = require('sys.statemachine.layout').new(hl)

hl.bind("SUPER + ALT + L", function()
  layout_sm:fire("cycle")
end)
```

**Learn more**: [docs/03-Core-Systems/STATE_MACHINES.md](docs/03-Core-Systems/STATE_MACHINES.md)

---

## 🛠️ Common Tasks

### Change Terminal Emulator

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.M_terminal = "ghostty"   -- kitty, alacritty, foot, wezterm, ghostty…
```

Hyprland auto-reloads on save — no `hyprctl reload` needed.

### Add a Custom Keybind

```lua
-- user/keybind.lua
local const = _G.HYPR_CONST

hl.bind(const.M .. " + T", hl.dsp.exec_cmd("ghostty"))

-- Locked flag (fires on lock screen too)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Lua function dispatcher (impossible in .conf era)
hl.bind(const.M .. " + ALT + G", function()
  require('sys.statemachine.gamemode').new(hl):fire("toggle")
end)
```

### Add a New App (Tag + Rule)

```lua
-- user/tags.lua  (classify)
hl.window_rule({
  match = { class = "^([Mm]yapp)$" },
  tag = "myapp",
})

-- user/rules.lua  (behavior)
hl.window_rule({ float = true, match = { tag = "myapp" } })
hl.window_rule({ size = { 1200, 800 }, match = { tag = "myapp" } })
```

### Override Other Constants

```lua
-- user/const.lua
_G.HYPR_CONST = _G.HYPR_CONST or {}
_G.HYPR_CONST.M_terminal     = "ghostty"
_G.HYPR_CONST.M_file_manager = "thunar"
_G.HYPR_CONST.W              = "~/Pictures/my-wallpapers"
_G.HYPR_CONST.Search_Engine  = "https://google.com/search?q={}"   -- used by RofiSearch.sh
```

**More common tasks**: [docs/01-Getting-Started/COMMON_TASKS.md](docs/01-Getting-Started/COMMON_TASKS.md)

---

## 🔧 Pipeline

```
hyprland.lua
  └── bootstrap/default.lua
        ├── Stage 0: bootstrap/const.lua   (path infra)
        ├── Stage 0: sys/const.lua         (system defaults)
        ├── Stage 0: user/const.lua        (user deltas — wins)
        └── Stage 1: sys/default.lua       (pipeline entry)
              ├── sys/hardware/default → laptop + monitors + workspaces
              ├── sys/policy/default   → wallust colors + animation preset
              ├── sys/env          → user/env.lua
              ├── sys/misc         → user/misc.lua
              ├── sys/input        → user/input.lua
              ├── sys/layout       → user/layout.lua
              ├── sys/decoration   → user/decoration.lua
              ├── sys/render       → user/render.lua
              ├── sys/startup     → user/startup.lua
              ├── sys/keybind     → user/keybind.lua
              ├── sys/tags        → user/tags.lua
              └── sys/rules       → user/rules.lua
```

**require order = override priority**: later files win on `_G.HYPR_CONST` and on
`hl.config({...})` top-level keys.

**Learn more**: [docs/02-Architecture/PIPELINE_ARCHITECTURE.md](docs/02-Architecture/PIPELINE_ARCHITECTURE.md)

---

## 🎨 Layout System

Three layouts cycle at runtime via `SUPER + ALT + L` (driven by `sys/statemachine/layout.lua`):

```
scrolling  →  dwindle  →  master  →  scrolling  → …
```

| Layout | Description | `SUPER+J/K` | `SUPER+O` |
| --- | --- | --- | --- |
| `scrolling` | column-based scrolling layout (built-in since Hyprland v0.55) | built-in column nav | unbound |
| `dwindle` | binary space partitioning | focus down / up | togglesplit |
| `master` | master-stack | focus down / up | unbound |

Startup layout is set in `user/layout.lua` (default: `dwindle`).

> ℹ️ `scrolling` is built into Hyprland v0.55+ — no `hyprpm` plugin install needed.

**Learn more**: [docs/03-Core-Systems/STATE_MACHINES.md § Layout Engine](docs/03-Core-Systems/STATE_MACHINES.md)

---

## ⌨️ Keybinds (selected)

132 binds total in `sys/keybind.lua`. Press `SUPER + SHIFT + K` at runtime for a searchable list,
or `SUPER + H` for the cheat sheet.

| Key | Action |
| --- | --- |
| `SUPER + D` | App launcher (rofi) |
| `SUPER + Return` | Terminal |
| `SUPER + E` | File manager |
| `SUPER + Q` | Close window |
| `SUPER + H` | Cheat sheet |
| `SUPER + SHIFT + K` | Search keybinds |
| `SUPER + SHIFT + E` | Quick settings menu |
| `SUPER + S` | Web search (RofiSearch.sh) |
| `SUPER + W` | Wallpaper selector |
| `SUPER + ALT + L` | Cycle layout (SM) |
| `SUPER + SHIFT + G` | Toggle game mode (SM) |
| `SUPER + N` | Toggle night light (SM) |
| `SUPER + ALT + R` | Refresh waybar + swaync |
| `CTRL + ALT + L` | Lock screen |
| `CTRL + ALT + Del` | Exit Hyprland |

---

## 📜 Scripts

60 `.sh` scripts live in `sys/scripts/` (+ 3 `.lua` helpers in `sys/scripts/lua/`).
User-specific scripts go in `user/scripts/` (created on demand).

| Script | Trigger | Purpose |
| --- | --- | --- |
| `Dropterminal.sh` | bind / startup | Dropdown terminal — state machine + pipeline design |
| `ChangeLayout.sh` | `SUPER+ALT+L` fallback | Layout cycle (fallback for Lua SM) |
| `GameMode.sh` | `SUPER+SHIFT+G` fallback | Toggle game mode (fallback for Lua SM) |
| `Hyprsunset.sh` | `SUPER+N` fallback | Toggle night light (fallback for Lua SM, persists state) |
| `WallpaperSelect.sh` | `SUPER+W` | Pick wallpaper + apply wallust colors |
| `Animations.sh` | `SUPER+SHIFT+A` | Switch animation preset |
| `RofiSearch.sh` | `SUPER+S` | Web search via `$Search_Engine` |
| `DarkLight.sh` | Quick Settings | Toggle dark/light theme |
| `Refresh.sh` | `SUPER+ALT+R` | Restart waybar + swaync |
| `LockScreen.sh` | `CTRL+ALT+L` | Lock screen (hyprlock) |
| `Quick_Settings.sh` | `SUPER+SHIFT+E` | Open user config files in editor |
| `KeybindsLayoutInit.sh` | startup | Initialize layout-aware binds |
| `KeyHints.sh` | `SUPER+H` | Show keybind cheat sheet |
| `KeyBinds.sh` | `SUPER+SHIFT+K` | Searchable keybind list |

> ℹ️ The Lua state machine modules in `sys/statemachine/*.lua` are the **primary** implementations.
> The matching `.sh` scripts survive as `pcall`-protected fallbacks.

---

## 🎭 Policies (Strategy Pattern)

Swappable at runtime without reloading the full config:

- **Animations** — presets in `sys/policy/animations/`:
  `default` `disable` `end4` `hyde-optimized` `hyde-vertical` `ml4w-fast`
- **Colors** — generated by wallust into `sys/policy/wallust/wallust-hyprland.lua`
  on wallpaper change

**Design Pattern**: Strategy Pattern — policies are interchangeable algorithms.
See [docs/02-Architecture/DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md).

---

## 📦 Dependencies

External tools are declared once in [`lib/deps.lua`](lib/deps.lua) (SSOT + dependency injection).
All scripts and config files reference them via `deps.get("name").cmd` — **zero hard-coded tool names**.

**Required** (25 specs in `lib/deps.lua`, top-level ones):
`hyprland` `hyprlock` `hypridle` `hyprctl`
`awww` (wallpaper daemon) `waybar` (bar) `swaync` (notifications)
`rofi` (launcher) `wallust` (color generator) `cliphist` + `wl-clipboard`
`grim` + `slurp` (screenshots) `pamixer`/`pactl` (volume)
`brightnessctl` (brightness) `playerctl` (media)
`nm-applet` (network applet) `jq` (JSON) `notify-send`

**Optional**: `hyprsunset` (night light) `polkit agent` `fcitx5` (input method)
`wlogout` (logout menu) `mpvpaper` (live wallpapers) `qs` / `quickshell` (overview widget)

**Plugin note**: `scrolling` layout is **built into Hyprland v0.55+** — no `hyprpm` install needed.

---

## 🐛 Troubleshooting

### Config won't load
```bash
# Gold standard: Hyprland's own verifier
hyprland --verify-config

# Static analysis (catches undefined globals, unused vars)
luacheck ~/.config/hypr --codes    # see .luacheckrc; `hl` is a known global

# Runtime log
journalctl -u hyprland-session -f   # or check your session manager's log
```

### Colors not applied
Check pipeline order: `sys/policy/default.lua` must load **before** `sys/decoration.lua`
(it does, via `sys/default.lua`).
See [docs/02-Architecture/PIPELINE_ARCHITECTURE.md](docs/02-Architecture/PIPELINE_ARCHITECTURE.md).

### Keybinds not responding
```bash
# Re-initialize layout-aware binds (fallback path)
~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh

# Check for Lua errors
luacheck ~/.config/hypr --codes
```

### Service not starting
Check the `hl.on("hyprland.start", fn)` hook in [`sys/startup.lua`](sys/startup.lua).
Daemons are launched via `deps.cmd("name")` — if a tool is missing, install it or
override the spec in `user/` (extend `lib/deps.lua`).

**Full troubleshooting guide**: [docs/05-Reference/TROUBLESHOOTING.md](docs/05-Reference/TROUBLESHOOTING.md)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes — keep `luacheck` clean and verify with `hyprland --verify-config`
4. Preserve invariants: every tag should have rules; require order in `sys/default.lua` must be correct
5. Document changes in the relevant `.md` file
6. Submit a pull request

**Naming conventions**: `M_*` for apps, `H_*` for helper paths, `U_*` for user paths,
`S/H/P` for sys/scripts, sys/hardware, sys/policy.

See [docs/02-Architecture/DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md) for
architecture guidelines and [docs/06-Meta/DOCUMENTATION_INDEX.md](docs/06-Meta/DOCUMENTATION_INDEX.md)
for the full doc map.

---

## 📊 Project Statistics

| Metric | Value |
| --- | --- |
| Configuration files | 49 `.lua` (0 `.conf` in `sys/`/`user/`/`lib/`/`bootstrap/`) |
| Daemon configs | 2 `.conf` (`hypridle.conf`, `hyprlock.conf` — daemons don't support Lua) |
| Runtime scripts | 60 `.sh` + 3 `.lua` helpers |
| Shared libraries | 4 (`lib/sm.lua`, `lib/deps.lua`, `lib/types.lua`, `lib/script_utils.lua`) |
| Keybinds | 132 `hl.bind` calls in `sys/keybind.lua` |
| Window tags | 26 (20 category + 6 behavior/helper) in `sys/tags.lua` |
| State machines | 3 (`layout`, `gamemode`, `nightlight`) in `sys/statemachine/` |
| External deps declared | 25 (in `lib/deps.lua`) |
| Documentation | 18 `.md` files across 6 doc categories |

---

## 📜 License

This configuration is provided as-is for educational and practical use. Feel free to adapt the
architectural patterns to your own dotfiles.

---

## 🙏 Acknowledgments

- **Hyprland Team** — for the amazing Wayland compositor and v0.55 native Lua config
- **Community Contributors** — for scripts, ideas, and feedback
- **Architectural inspiration**:
  - Compiler design (Aho et al. — *Compilers: Principles, Techniques, and Tools*)
  - Design Patterns (Gamma, Helm, Johnson, Vlissides — *Design Patterns*)
  - Linux `config.d` convention
  - Hyprland community configs (end-4, prasanthrangan/hyprdots, mylinuxforwork)

---

**⭐ If you find this useful, please star the repository!**

**Last Updated**: 2026-08-20 · **Hyprland Version**: 0.56.2 · **Config Form**: Lua (native)

---

**🔝 [Back to Top](#hyprland-configuration)**
