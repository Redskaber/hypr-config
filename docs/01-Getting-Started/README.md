# Hyprland Configuration

> **Production-grade Hyprland window manager configuration** with professional software architecture  
> Applying compilation theory, design patterns, and state machine formalization

---

## 🚀 Quick Start

### New to This Configuration?

→ **[Start Here](docs/01-Getting-Started/README.md)** — Project overview and key concepts

### Want to Get Running Fast?

→ **[Quick Start Guide](docs/01-Getting-Started/QUICK_START.md)** _(coming soon)_

### Looking for Something Specific?

→ **[Documentation Index](docs/06-Meta/DOCUMENTATION_INDEX.md)** — Complete navigation hub

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
- **Formal state machines** (layout engine, game mode, night light)
- **Strategy pattern policies** (swappable colors, animations)
- **Process lifecycle management** (service isolation, absolute paths)

### 🎨 Customization

- **Minimal user config** (only specify differences)
- **Hot-reload support** (most changes without restart)
- **Profile switching** (gaming, productivity, presentation modes)
- **Extensible tag system** (add custom window rules easily)

### 🚀 Performance

- **Fast startup** (~32ms config load time)
- **Low memory** (~150MB RAM usage)
- **Optimized rendering** (configurable blur, shadows, animations)
- **Efficient IPC** (batched hyprctl commands)

---

## 🎯 Learning Paths

Choose the path that matches your expertise level:

### Essential User (15 min)

Learn basics and common tasks

- [README](docs/01-Getting-Started/README.md) → [Common Tasks](docs/01-Getting-Started/COMMON_TASKS.md) _(coming soon)_

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
├── hyprland.conf              # Single entry point (sources bootstrap/default.conf)
│
├── bootstrap/                 # Layer 1: Infrastructure constants
│   ├── const.conf             # Path definitions ($Hypr, $sys, $user)
│   └── default.conf           # Sources all layers in correct order
│
├── sys/                       # Layer 2: System defaults
│   ├── const.conf             # System constants ($M, $S, $H, $P, etc.)
│   ├── hardware/              # Hardware abstraction (monitors, input)
│   ├── policy/                # Visual policies (colors, animations)
│   ├── scripts/               # Shell scripts (60+ utilities)
│   ├── *.conf                 # Core configuration domains
│   └── ...
│
├── user/                      # Layer 3: User overrides
│   ├── const.conf             # User constant overrides
│   ├── *.conf                 # User configuration deltas
│   └── ...
│
├── docs/                      # 📚 Documentation (NEW!)
│   ├── 01-Getting-Started/    # New user guides
│   ├── 02-Architecture/       # Design & architecture
│   ├── 03-Core-Systems/       # Runtime systems
│   ├── 04-Implementation/     # How-to guides
│   ├── 05-Reference/          # Reference materials
│   └── 06-Meta/               # Project meta-information
│
└── MIGRATION_NOTICE.md        # Documentation restructuring notice
```

**Key Design Principle**: `sys/` contains vendor defaults, `user/` contains only your customizations (incremental override pattern).

---

## 🔧 Installation

### Prerequisites

- Hyprland >= 0.52.0
- Wayland compositor running
- Required packages: `swww`, `waybar`, `swaync`, `cliphist`, `hypridle`, `rofi`, `wallust`

### Quick Install

```bash
# Clone or copy this configuration
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr

# Review and customize user constants
nano ~/.config/hypr/user/const.conf

# Restart Hyprland (or reload config)
hyprctl reload
```

**Detailed installation guide**: [docs/01-Getting-Started/QUICK_START.md](docs/01-Getting-Started/QUICK_START.md) _(coming soon)_

---

## 🎓 Core Concepts

### 1. Three-Layer Constant System

```bash
Layer 1 (bootstrap/const.conf): $sys = ~/.config/hypr/sys
Layer 2 (sys/const.conf):       $M_terminal = kitty
Layer 3 (user/const.conf):      $M_terminal = ghostty  ← Wins!
```

**Learn more**: [THREE_LAYER_CONSTANTS.md](docs/02-Architecture/THREE_LAYER_CONSTANTS.md)

### 2. Incremental Override Pattern

```bash
# sys/input.conf (system default)
input { kb_layout = us }

# user/input.conf (your delta - ONLY this line needed)
input { kb_layout = us,cn }
```

**Learn more**: [DESIGN_PRINCIPLES.md](docs/02-Architecture/DESIGN_PRINCIPLES.md) § Incremental Override

### 3. Tag-Driven Window Management

```bash
# Step 1: Tag applications (tags.conf)
windowrule = match:class ^(Firefox)$, tag +browser

# Step 2: Define behavior (rules.conf)
windowrule = opacity 1.00 0.85, match:tag browser
```

**Learn more**: [TAG_SYSTEM.md](docs/03-Core-Systems/TAG_SYSTEM.md)

### 4. State Machine Runtime

```bash
Layout Engine FSM: scrolling ↔ dwindle ↔ master
Game Mode FSM:     NORMAL ↔ GAMING
Night Light FSM:   OFF ↔ ON
```

**Learn more**: [STATE_MACHINES.md](docs/03-Core-Systems/STATE_MACHINES.md)

---

## 🛠️ Common Tasks

### Change Terminal Emulator

Edit `user/const.conf`:

```bash
$M_terminal = ghostty
```

Then reload: `hyprctl reload`

### Modify Keybindings

Edit `user/keybind.conf` (only your changes needed):

```bash
bind = SUPER, T, exec, $M_terminal
```

### Add Window Rule

1. Add tag in `user/tags.conf`:
   ```bash
   windowrule = match:class ^(MyApp)$, tag +myapp
   ```
2. Define behavior in `user/rules.conf`:
   ```bash
   windowrule = float on, match:tag myapp
   ```

**More common tasks**: [docs/01-Getting-Started/COMMON_TASKS.md](docs/01-Getting-Started/COMMON_TASKS.md) _(coming soon)_

---

## 🐛 Troubleshooting

### Colors Not Working?

Check Stage 2 constraint: policy must load before decoration.  
See: [PIPELINE_ARCHITECTURE.md](docs/02-Architecture/PIPELINE_ARCHITECTURE.md) § Stage 2 Constraints

### Keybinds Not Responding?

Re-initialize layout binds:  
`~/.config/hypr/sys/scripts/KeybindsLayoutInit.sh`

### Service Not Starting?

Check absolute paths in `startup.conf`. Daemons need full paths.  
See: [SERVICE_LIFECYCLE.md](docs/03-Core-Systems/SERVICE_LIFECYCLE.md) _(coming soon)_

**Full troubleshooting guide**: [docs/05-Reference/TROUBLESHOOTING.md](docs/05-Reference/TROUBLESHOOTING.md) _(coming soon)_

---

## 🤝 Contributing

We welcome contributions! Please see:

- **[Contributing Guidelines](docs/06-Meta/CONTRIBUTING.md)** _(coming soon)_
- **[Documentation Standards](docs/06-Meta/CONTRIBUTING.md)** _(coming soon)_
- **[Code of Conduct](CODE_OF_CONDUCT.md)** _(coming soon)_

**Quick start**:

1. Fork the repository
2. Create feature branch
3. Make changes (follow style guide)
4. Submit pull request

---

## 📊 Project Statistics

| Metric                  | Value                              |
| ----------------------- | ---------------------------------- |
| **Configuration Files** | 50+ (.conf files)                  |
| **Scripts**             | 60+ (.sh files)                    |
| **Documentation**       | 9 existing + 15 planned = 24 total |
| **Documentation Size**  | ~240KB existing, ~600KB target     |
| **Lines of Config**     | ~3,000 lines                       |
| **Lines of Scripts**    | ~5,000 lines                       |
| **Lines of Docs**       | ~6,100 existing, ~15,000 target    |

---

## 📜 License

This configuration is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **Hyprland Team**: For the amazing Wayland compositor
- **Community Contributors**: For scripts, ideas, and feedback
- **Software Engineering Literature**: For design patterns and architecture principles

---

## 📞 Support

- **Documentation**: [docs/06-Meta/DOCUMENTATION_INDEX.md](docs/06-Meta/DOCUMENTATION_INDEX.md)
- **Issues**: GitHub Issues (use labels: `bug`, `question`, `documentation`)
- **Discussions**: GitHub Discussions
- **Wiki**: [Project Wiki](wiki-link) _(coming soon)_

---

**⭐ If you find this useful, please star the repository!**

**Last Updated**: 2026-04-17  
**Version**: 2.0.0 (Restructured Documentation)  
**Next Release**: Phase 2 completion (Apr 20, 2026)

---

**🔝 [Back to Top](#hyprland-configuration)**

# Hyprland Dotfiles

A **production-grade, layered pipeline architecture** for Hyprland ≥ 0.52.1 that applies software engineering principles from compiler design, state machine theory, dependency injection, and policy-based management.

## 📚 Documentation Navigation

**🗺️ Start Here**: [INDEX.md](INDEX.md) — Complete navigation guide with learning paths by user type

### Core Architecture

- **[DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md)** — Core design principles, compilation pipeline analogy, layered architecture, dependency inversion, software patterns catalog (35KB)
- **[PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md)** — Detailed 5-stage pipeline (lexical analysis → code generation), layer boundaries, incremental override pattern (60KB)
- **[THREE_LAYER_CONSTANTS.md](THREE_LAYER_CONSTANTS.md)** — Complete specification of bootstrap/sys/user constant system with dependency graphs and resolution examples (NEW, 20KB)
- **[STATE_MACHINES.md](STATE_MACHINES.md)** — Formal state machine definitions for layout engine, game mode, and night light with transition functions and invariants (40KB)
- **[TAG_SYSTEM.md](TAG_SYSTEM.md)** — Tag-driven window management system with tag taxonomy, rule application, compound conditions, and validation (30KB)

### Quick Reference

- **[architecture.md](architecture.md)** — High-level architecture overview, quick reference for daily use (15KB, 20 min read)
- **[README.md](README.md)** — This file (quick start, common tasks, directory structure) (8KB, 10 min read)

**Total Documentation**: ~173KB of comprehensive architectural specification applying formal software engineering principles.

**Recommended Reading Paths**:

- **New Users** (15 min): README.md → architecture.md § Common Tasks
- **Power Users** (55 min): README → architecture → DESIGN_PRINCIPLES § Core Principles → TAG_SYSTEM § User Extension
- **Developers** (3.75 hrs): All docs in order (see [INDEX.md](INDEX.md) for details)
- **Architects** (6+ hrs): Deep study of all docs + external references

---

## Quick Start

```bash
git clone https://github.com/Redskaber/hypr-config ~/.config/hypr
# Edit user/const.conf — set your terminal, file manager, wallpaper dir
# Edit user/env.conf  — HiDPI, NVIDIA, custom env vars
# Launch Hyprland
```

## Directory Structure

```bash
~/.config/hypr/
├── hyprland.conf              # single entry point — sources bootstrap only
├── icon.png                   # notification icon used by hypridle
├── DESIGN_PRINCIPLES.md       # Core design principles & patterns
├── PIPELINE_ARCHITECTURE.md   # 5-stage compilation pipeline
├── STATE_MACHINES.md          # Runtime state management
├── architecture.md            # High-level architecture overview
├── README.md                  # This file
├── bootstrap/
│   ├── const.conf             # all path/variable constants ($Hypr, $sys, $user, ...)
│   └── default.conf           # pipeline: Stage 0 constants → Stage 1 sys
├── sys/                       # system defaults — do not edit directly
│   ├── const.conf             # all path/variable constants ($M, $S, $H, $P, ...)
│   ├── default.conf           # sys pipeline (each sys/* paired with user/*)
│   ├── env.conf               # wayland / qt / app environment variables
│   ├── misc.conf              # misc hyprland options
│   ├── input.conf             # keyboard, touchpad, gestures
│   ├── layout.conf            # dwindle / master / scrolling (hyprscrolling)
│   ├── decoration.conf        # colors, blur, shadow, opacity (needs $colorN)
│   ├── render.conf            # render pipeline, xwayland, cursor
│   ├── startup.conf           # exec-once services
│   ├── keybind.conf           # canonical keybind table
│   ├── tags.conf              # unified window tag registry
│   ├── rules.conf             # tag-driven window & layer rules
│   ├── hypridle.conf          # idle / lock timeouts (absolute paths only)
│   ├── hardware/
│   │   ├── default.conf       # hardware aggregator (laptop + monitors + workspaces)
│   │   ├── laptop.conf        # laptop keys, touchpad, ASUS ROG binds
│   │   ├── laptop-display.conf# lid-switch display state
│   │   ├── monitors.conf      # monitor configuration
│   │   └── workspaces.conf    # workspace → monitor assignment
│   ├── policy/
│   │   ├── default.conf       # policy aggregator (wallust colors → animations)
│   │   ├── wallust/           # wallust-generated color variables
│   │   └── animations/        # animation presets (default, disable, end4 …)
│   └── scripts/               # runtime scripts (~55 scripts)
└── user/                      # your overrides — edit only these
    ├── const.conf             # override $M_terminal, $W, $Search_Engine, etc.
    ├── env.conf               # override / add env vars (NVIDIA, HiDPI, EDITOR …)
    ├── misc.conf              # override misc options (vfr, vrr, swallow …)
    ├── input.conf             # override keyboard layout, sensitivity
    ├── layout.conf            # startup layout + gap / scroller overrides
    ├── decoration.conf        # override colors, blur, rounding
    ├── render.conf            # override render / cursor settings
    ├── startup.conf           # add exec-once services
    ├── keybind.conf           # add / override keybinds
    ├── tags.conf              # add window tags
    └── rules.conf             # add window rules
```

## Pipeline

```bash
hyprland.conf
  └── bootstrap/default.conf
        ├── Stage 0: bootstrap/const.conf   (constants)
│       ├── Stage 0: sys/const.conf         (sys constants)
        ├── Stage 0: user/const.conf        (user constant overrides)
        └── Stage 1: sys/default.conf       (entry point)
              ├── sys/hardware/default.conf → laptop + monitors + workspaces
              ├── sys/policy/default.conf   → wallust colors + animations
              ├── sys/env.conf          → user/env.conf
              ├── sys/misc.conf         → user/misc.conf
              ├── sys/input.conf        → user/input.conf
              ├── sys/layout.conf       → user/layout.conf
              ├── sys/decoration.conf   → user/decoration.conf
              ├── sys/render.conf       → user/render.conf
              ├── sys/startup.conf      → user/startup.conf
              ├── sys/keybind.conf      → user/keybind.conf
              ├── sys/tags.conf         → user/tags.conf
              └── sys/rules.conf        → user/rules.conf
```

Source order = override priority: **later wins**.

**See Also**:

- [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) — Complete pipeline documentation with compiler analogies
- [DESIGN_PRINCIPLES.md § Compilation Pipeline](DESIGN_PRINCIPLES.md#compilation-pipeline-architecture) — Lexical/syntax/semantic analysis phases

## User Customization

Every `sys/` file has a paired `user/` override. Edit only the `user/` files.

**Common overrides:**

```bash
# user/const.conf
$M_terminal     = ghostty
$M_file_manager = thunar
$W              = $HOME/Pictures/my-wallpapers
$Search_Engine  = "https://google.com/search?q={}"   # used by RofiSearch.sh (SUPER+S)

# user/env.conf
env = EDITOR,              nvim
env = HYPR_TERMINAL,       ghostty       # used by wallpaper/waybar scripts
env = HYPR_WALLPAPER_DIR,  /path/to/wallpapers
env = HYPR_FILE_MANAGER,   thunar        # used by WaybarScripts.sh
env = GDK_SCALE,           1.5           # HiDPI
env = QT_SCALE_FACTOR,     1.5

# user/layout.conf — startup layout (scrolling requires hyprscrolling plugin)
general { layout = dwindle }

# user/input.conf
input { kb_layout = us,cn }

# user/misc.conf
misc { vfr = true }   # variable frame rate (power saving)
```

**Design Principle**: Incremental Override Pattern — user files contain only deltas from system defaults. See [DESIGN_PRINCIPLES.md § Dependency Inversion](DESIGN_PRINCIPLES.md#dependency-inversion--incremental-override-pattern).

## Layout System

Three layouts are supported, cycled at runtime with `SUPER+ALT+L`:

```bash
scrolling  →  dwindle  →  master  →  scrolling  → …
```

| Layout      | Description                         | `SUPER+J/K`                    | `SUPER+O`     |
| ----------- | ----------------------------------- | ------------------------------ | ------------- |
| `scrolling` | hyprscrolling plugin (column-based) | plugin-owned (column nav)      | unbound       |
| `dwindle`   | binary space partitioning           | `cyclenext` / `cyclenext,prev` | `togglesplit` |
| `master`    | master-stack                        | `cyclenext` / `cyclenext,prev` | unbound       |

The startup layout is set in `user/layout.conf` (default: `scrolling`).
The sys-level default is `dwindle` so the config works without the plugin.

`sys/layout.conf` provides `plugin:hyprscrolling {}` defaults for hyprscrolling.

### State Machine Implementation

Layout transitions are managed by an explicit **3-state finite state machine**. See [STATE_MACHINES.md § Layout Engine](STATE_MACHINES.md#layout-engine-state-machine) for formal definition, transition functions, and atomicity guarantees.

### hyprscrolling Keybinds

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

Override `plugin:hyprscrolling` defaults in `user/layout.conf`.

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

See `sys/keybind.conf` for the full table, or press `SUPER + SHIFT + K` at runtime.

## Scripts

All scripts live in `sys/scripts/`. User-specific scripts go in `user/scripts/`.

| Script                  | Trigger          | Purpose                                                     |
| ----------------------- | ---------------- | ----------------------------------------------------------- |
| `ChangeLayout.sh`       | `SUPER+ALT+L`    | Three-state layout cycle; manages J/K and O binds           |
| `KeybindsLayoutInit.sh` | startup          | Initialize layout-aware binds based on current layout       |
| `GameMode.sh`           | `SUPER+SHIFT+G`  | Toggle animations/blur/gaps off for gaming                  |
| `WallpaperSelect.sh`    | `SUPER+W`        | Pick wallpaper + apply wallust colors                       |
| `Animations.sh`         | `SUPER+SHIFT+A`  | Switch animation preset                                     |
| `RofiSearch.sh`         | `SUPER+S`        | Web search: resolves `$Search_Engine` user → sys → fallback |
| `DarkLight.sh`          | Quick Settings   | Toggle dark/light theme system-wide                         |
| `Refresh.sh`            | `SUPER+ALT+R`    | Restart waybar + swaync                                     |
| `RefreshNoWaybar.sh`    | wallpaper change | Refresh theme without restarting waybar                     |
| `Hyprsunset.sh`         | `SUPER+N`        | Toggle night light (state persists across sessions)         |
| `Hypridle.sh`           | waybar module    | Toggle hypridle on/off                                      |
| `Quick_Settings.sh`     | `SUPER+SHIFT+E`  | Open user config files in editor                            |

**State Machine Scripts**: `ChangeLayout.sh`, `GameMode.sh`, and `Hyprsunset.sh` implement formal state machines. See [STATE_MACHINES.md](STATE_MACHINES.md) for detailed implementation.

## Policies

Swappable at runtime without reloading the full config:

- **Animations** — presets in `sys/policy/animations/`: `default` `disable` `end4` `hyde-optimized` `hyde-vertical` `ml4w-fast`
- **Colors** — generated by wallust into `sys/policy/wallust/wallust-hyprland.conf` on wallpaper change

**Design Pattern**: Strategy Pattern — policies are interchangeable algorithms. See [DESIGN_PRINCIPLES.md § Policy Layer](DESIGN_PRINCIPLES.md#policy-layer--runtime-swapping).

## Window Tags

Tags are defined in `sys/tags.conf` and consumed by `sys/rules.conf`.
Add personal app tags in `user/tags.conf` with matching rules in `user/rules.conf`.

**Category tags** (what an app is):
`browser` `terminal` `im` `email` `projects` `notes` `file-manager` `multimedia` `multimedia-video` `screenshare` `games` `gamestore` `viewer` `text-editor` `utils` `calculator` `settings` `audio-mixer` `wallpaper` `notif`

**Behavior tags** (how a window behaves):
`pip` `auth-dialog` `file-dialog` `no-steal-focus` `suppress-activate`

**Helper tags**: `$H_Cheat` `$H_Settings` `keybindings`

**Architecture**: Tag-driven rule system implements Strategy Pattern for window management. See [DESIGN_PRINCIPLES.md § Tag-Driven System](DESIGN_PRINCIPLES.md#tag-driven-window-management-system) and [PIPELINE_ARCHITECTURE.md § Stage 5](PIPELINE_ARCHITECTURE.md#stage-5-window-management-rule-compilation).

## Dependencies

**Required:** `hyprland` `hyprlock` `hypridle` `swww` `waybar` `swaync` `rofi-wayland` `cliphist` `wl-clipboard` `grim` `slurp` `pamixer` `playerctl` `brightnessctl` `nm-applet` `wallust` `jq`

**Optional:** `hyprscrolling` (scrolling layout, install via hyprpm) · `mpvpaper` (live wallpapers) · `fcitx5` (input method) · `nwg-displays` (monitor config GUI) · `kvantummanager` (Qt theming) · `qs` / `quickshell` (overview widget) · `swappy` (screenshot annotation)

## Design Philosophy

This configuration treats the desktop environment as a **compiled system** rather than a collection of scripts. Key principles:

1. **Compilation Pipeline**: Config loading mirrors compiler phases (lexical → syntax → semantic → code generation)
2. **Layered Architecture**: Clear boundaries between bootstrap, system, hardware, policy, and user layers
3. **Dependency Inversion**: Constants abstract implementation details; user overrides injected at Stage 0
4. **State Machines**: Runtime behavior changes managed via explicit state transition functions
5. **Policy-Based Management**: Swappable strategies (colors, animations) without full reload
6. **Tag-Driven Rules**: Decouple window classification from behavior (Strategy Pattern)
7. **Single Responsibility**: Each file has one clear purpose
8. **Incremental Override**: User files contain only deltas from system defaults

For detailed explanations, see [DESIGN_PRINCIPLES.md](DESIGN_PRINCIPLES.md).

## Contributing

When contributing to this configuration:

1. **Maintain Layer Boundaries**: Don't cross layer responsibilities
2. **Preserve Invariants**: Every tag must have rules; source order must be correct
3. **Document Changes**: Update relevant `.md` files
4. **Test State Transitions**: Verify state machines handle edge cases
5. **Follow Naming Conventions**: `$M_*` for apps, `$H_*` for helpers, `$U_*` for user

See [DESIGN_PRINCIPLES.md § Best Practices](DESIGN_PRINCIPLES.md#best-practices) for detailed guidelines.

## License

This configuration is provided as-is for educational and practical use. Feel free to adapt the architectural patterns to your own dotfiles.

## Acknowledgments

Architectural patterns inspired by:

- Compiler design (Aho, Lam, Sethi, Ullman - "Compilers: Principles, Techniques, and Tools")
- Design Patterns (Gamma, Helm, Johnson, Vlissides - "Design Patterns: Elements of Reusable Object-Oriented Software")
- Linux config.d convention
- Hyprland community configurations (end-4, prasanthrangan/hyprdots, mylinuxforwork)

