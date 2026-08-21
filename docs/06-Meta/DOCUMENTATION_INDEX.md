# Documentation Index

> Complete navigation hub for the hypr-config documentation set.
> Pure `.lua` (Hyprland v0.55+). 18 `.md` files across 6 categories.

## Quick Navigation

| If you want to… | Read |
| --- | --- |
| Install & configure | [01-Getting-Started/QUICK_START.md](../01-Getting-Started/QUICK_START.md) |
| Do common tasks | [01-Getting-Started/COMMON_TASKS.md](../01-Getting-Started/COMMON_TASKS.md) |
| Understand architecture | [02-Architecture/ARCHITECTURE_OVERVIEW.md](../02-Architecture/ARCHITECTURE_OVERVIEW.md) |
| Understand the pipeline | [02-Architecture/PIPELINE_ARCHITECTURE.md](../02-Architecture/PIPELINE_ARCHITECTURE.md) |
| Design principles | [02-Architecture/DESIGN_PRINCIPLES.md](../02-Architecture/DESIGN_PRINCIPLES.md) |
| Constants system | [02-Architecture/THREE_LAYER_CONSTANTS.md](../02-Architecture/THREE_LAYER_CONSTANTS.md) |
| Tag system | [03-Core-Systems/TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) |
| State machines | [03-Core-Systems/STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) |
| Troubleshoot | [05-Reference/TROUBLESHOOTING.md](../05-Reference/TROUBLESHOOTING.md) |
| `.conf` ↔ `.lua` migration | [07-Lua-Reference/COMPATIBILITY.md](../07-Lua-Reference/COMPATIBILITY.md) |
| Lua API quick card | [07-Lua-Reference/README.md](../07-Lua-Reference/README.md) |

## Complete File Listing

### 01-Getting-Started (3 files)
- [README.md](../01-Getting-Started/README.md) — project overview (also root README)
- [QUICK_START.md](../01-Getting-Started/QUICK_START.md) — 5-minute install
- [COMMON_TASKS.md](../01-Getting-Started/COMMON_TASKS.md) — cheat sheet

### 02-Architecture (4 files)
- [ARCHITECTURE_OVERVIEW.md](../02-Architecture/ARCHITECTURE_OVERVIEW.md) — quick reference
- [PIPELINE_ARCHITECTURE.md](../02-Architecture/PIPELINE_ARCHITECTURE.md) — require chain spec
- [DESIGN_PRINCIPLES.md](../02-Architecture/DESIGN_PRINCIPLES.md) — 10 principles + patterns
- [THREE_LAYER_CONSTANTS.md](../02-Architecture/THREE_LAYER_CONSTANTS.md) — `_G.HYPR_CONST` spec

### 03-Core-Systems (2 files)
- [TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) — tag-driven window management
- [STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) — 3 FSMs + base class

### 05-Reference (2 files)
- [TROUBLESHOOTING.md](../05-Reference/TROUBLESHOOTING.md) — 8 common issues
- [GPU_VERIFICATION_CHECKLIST.md](../05-Reference/GPU_VERIFICATION_CHECKLIST.md) — GPU/NVIDIA setup

### 06-Meta (5 files)
- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) — this file
- [CHANGELOG.md](CHANGELOG.md) — version history
- [COMPLETION_REPORT.md](COMPLETION_REPORT.md) — project completion status
- [REVIEW_DEEP_AUDIT.md](REVIEW_DEEP_AUDIT.md) — Task 69 deep audit report
- [DOC_RESTRUCTURING_NOTICE.md](DOC_RESTRUCTURING_NOTICE.md) — restructuring notes

### 07-Lua-Reference (2 files)
- [COMPATIBILITY.md](../07-Lua-Reference/COMPATIBILITY.md) — `.conf` ↔ `.lua` translation
- [README.md](../07-Lua-Reference/README.md) — Lua API quick card

## Learning Paths

### Beginner (15 min)
1. [QUICK_START.md](../01-Getting-Started/QUICK_START.md) — install
2. [COMMON_TASKS.md](../01-Getting-Started/COMMON_TASKS.md) — daily operations
3. [TROUBLESHOOTING.md](../05-Reference/TROUBLESHOOTING.md) — diagnose issues

### Intermediate (1 hour)
4. [ARCHITECTURE_OVERVIEW.md](../02-Architecture/ARCHITECTURE_OVERVIEW.md) — design
5. [THREE_LAYER_CONSTANTS.md](../02-Architecture/THREE_LAYER_CONSTANTS.md) — constants
6. [TAG_SYSTEM.md](../03-Core-Systems/TAG_SYSTEM.md) — window classification
7. [STATE_MACHINES.md](../03-Core-Systems/STATE_MACHINES.md) — runtime behavior

### Advanced (2+ hours)
8. [PIPELINE_ARCHITECTURE.md](../02-Architecture/PIPELINE_ARCHITECTURE.md) — require chain
9. [DESIGN_PRINCIPLES.md](../02-Architecture/DESIGN_PRINCIPLES.md) — 10 principles
10. [COMPATIBILITY.md](../07-Lua-Reference/COMPATIBILITY.md) — migration from `.conf`
11. Source code: `lib/sm.lua`, `lib/deps.lua`, `sys/statemachine/*.lua`

## Validation Tools

| Tool | Command | What it catches |
| --- | --- | --- |
| `luacheck` | `luacheck ~/.config/hypr --codes` | Static syntax + undefined globals |
| `hyprland --verify-config` | Real Hyprland config loader | `hyprland --verify-config` | Runtime errors (require chain, nil calls) + API whitelist |
| `hyprctl` | `hyprland --verify-config` | Real Hyprland config loader (needs nix store) |

## Project Statistics (verified 2026-08-20)

| Metric | Value |
| --- | --- |
| Lua config files | 49 |
| Shell scripts | 60 (+ 3 lua helpers) |
| Shared libraries | 4 (`lib/`) |
| Keybinds | 132 |
| Window tags | 26 |
| State machines | 3 |
| External deps | 25 (in `lib/deps.lua`) |
| Documentation files | 18 |
