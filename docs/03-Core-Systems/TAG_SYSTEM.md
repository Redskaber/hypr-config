# Tag-Driven Window Management System

## Overview

This configuration implements a **tag-driven window management system** that decouples window classification (WHAT an app IS) from window behavior (HOW it should behave). This architecture applies the **Strategy design pattern** and **Single Responsibility Principle** to window rule management.

---

## Table of Contents

1. [Architecture Rationale](#architecture-rationale)
2. [Tag Taxonomy](#tag-taxonomy)
3. [Tag Registry](#tag-registry)
4. [Rule Application System](#rule-application-system)
5. [Compound Conditions](#compound-conditions)
6. [User Extension Pattern](#user-extension-pattern)
7. [Tag Completeness Invariant](#tag-completeness-invariant)
8. [Implementation Details](#implementation-details)
9. [Debugging & Validation](#debugging--validation)

---

## Architecture Rationale

### Problem: Traditional Window Rules

Traditional Hyprland configurations use direct class matching scattered across rules:

```bash
# BAD: Scattered, hard to maintain
windowrule = float on, match:class ^(firefox)$
windowrule = opacity 0.9, match:class ^(firefox)$
windowrule = float on, match:class ^(discord)$
windowrule = center on, match:class ^(discord)$
windowrule = size 800 600, match:class ^(discord)$
```

**Problems**:

- ❌ No single source of truth for app classifications
- ❌ Rules scattered by rule type (all floats together, all opacities together)
- ❌ Hard to audit completeness (which apps float? which are transparent?)
- ❌ Difficult to add new apps (must add rules in multiple places)
- ❌ Violates DRY principle (repeated patterns)

### Solution: Tag-Driven System

```bash
# STEP 1: Classify apps (WHAT they ARE)
# sys/tags.conf
windowrule = match:class ^(firefox)$, tag +browser
windowrule = match:class ^(discord)$, tag +im

# STEP 2: Define behaviors (HOW they act)
# sys/rules.conf
windowrule = opacity 0.9, match:tag browser
windowrule = float on, match:tag im
windowrule = center on, match:tag im
windowrule = size 800 600, match:tag im
```

**Benefits**:

- ✅ Single source of truth for classifications (`tags.conf`)
- ✅ Rules grouped by semantic category (easier auditing)
- ✅ Easy to add new apps (add tag + inherit all rules automatically)
- ✅ Clear separation of concerns (classification vs behavior)
- ✅ Follows Open/Closed Principle (extend without modifying)

### Design Patterns Applied

| Pattern                   | Application                                       | Example                            |
| ------------------------- | ------------------------------------------------- | ---------------------------------- |
| **Strategy**              | Tags define strategies for window behavior        | `browser` strategy: tiled + opaque |
| **Single Responsibility** | tags.conf classifies, rules.conf applies behavior | Separate files                     |
| **Template Method**       | All apps with same tag follow same rule template  | All `im` apps float + center       |
| **Registry**              | tags.conf is registry of all known app types      | 28 category tags registered        |

---

## Tag Taxonomy

Tags are organized into three orthogonal categories:

### 1. Category Tags (What an App IS)

Describe the **semantic type** of application. An app can have multiple category tags if it serves multiple purposes.

**Web Browsing**:

- `browser` — Web browsers (Firefox, Chrome, Edge, etc.)

**Productivity**:

- `terminal` — Terminal emulators (kitty, ghostty, alacritty)
- `projects` — IDEs and code editors (VSCode, JetBrains)
- `notes` — Knowledge base apps (Obsidian, Logseq)
- `email` — Email clients (Thunderbird, Evolution)
- `text-editor` — Lightweight editors (gedit, mousepad)

**Communication**:

- `im` — Instant messaging (Discord, Telegram, WhatsApp)

**File Management**:

- `file-manager` — File browsers (Thunar, Nautilus, nemo)

**Media**:

- `multimedia` — Audio players (Audacious, ncspot)
- `multimedia-video` — Video players (mpv, VLC)
- `screenshare` — Recording/streaming (OBS, easyeffects)

**Gaming**:

- `games` — Actual games (Steam games, Minecraft)
- `gamestore` — Game launchers (Steam, Lutris, Heroic)

**System Utilities**:

- `settings` — System config panels (nwg-displays, qt6ct)
- `audio-mixer` — Audio control (pavucontrol, pwvucontrol)
- `utils` — Power-user utilities (virt-manager, qbittorrent)
- `calculator` — Calculators (gnome-calculator)
- `viewer` — Document/image viewers (evince, eog)
- `wallpaper` — Wallpaper pickers (waypaper)
- `notif` — Notification centers (swaync)

### 2. Behavior Tags (How Windows Behave)

Orthogonal to category tags. Describe **interaction patterns** independent of app type.

- `pip` — Picture-in-picture windows (float, pinned, top-right)
- `auth-dialog` — Authentication prompts (polkit, sudo dialogs)
- `file-dialog` — Open/save file dialogs
- `no-steal-focus` — Prevent focus stealing on activation
- `suppress-activate` — Suppress spurious activation events

### 3. Helper Tags

Special-purpose tags for configuration UI elements:

- `$H_Cheat` — Quick cheat sheet window
- `$H_Settings` — Settings menu window
- `keybindings` — Keybind search results

**Design Principle**: Category tags describe WHAT, behavior tags describe HOW. They can be combined:

```bash
# Discord is both IM (category) and might steal focus (behavior)
windowrule = match:class ^(discord)$, tag +im
windowrule = match:class ^(discord)$, tag +no-steal-focus
```

---

## Tag Registry

### Complete Tag List

**Category Tags (28 total)**:

| Tag                | Apps                        | Float?     | Center? | Opacity     |
| ------------------ | --------------------------- | ---------- | ------- | ----------- |
| `browser`          | Firefox, Chrome, Edge       | No (main)  | No      | 1.0 / 0.85  |
| `terminal`         | kitty, ghostty, alacritty   | No         | No      | 0.9 / 0.8   |
| `im`               | Discord, Telegram, WhatsApp | Yes        | Yes     | 0.94 / 0.86 |
| `email`            | Thunderbird, Evolution      | No         | No      | 0.95 / 0.88 |
| `projects`         | VSCode, JetBrains IDEs      | No (main)  | No      | 0.98 / 0.9  |
| `notes`            | Obsidian, Logseq            | No (main)  | No      | 0.98 / 0.9  |
| `file-manager`     | Thunar, Nautilus, nemo      | Yes        | Yes     | 0.92 / 0.82 |
| `multimedia`       | Audacious, ncspot           | No         | No      | 0.94 / 0.86 |
| `multimedia-video` | mpv, VLC                    | Yes        | No      | 1.0 (full)  |
| `screenshare`      | OBS, easyeffects            | No (main)  | No      | 1.0 (full)  |
| `games`            | Steam games, Minecraft      | Fullscreen | N/A     | 1.0 (full)  |
| `gamestore`        | Steam, Lutris, Heroic       | Yes        | Yes     | Default     |
| `viewer`           | evince, eog, sysmonitor     | Yes        | Yes     | 0.85 / 0.75 |
| `text-editor`      | gedit, mousepad, xed        | Yes        | Yes     | 0.95 / 0.85 |
| `utils`            | virt-manager, qbittorrent   | Yes        | Yes     | 0.92 / 0.82 |
| `calculator`       | gnome-calculator            | Yes        | Yes     | Default     |
| `settings`         | nwg-displays, qt6ct         | Yes        | Yes     | 0.95 / 0.85 |
| `audio-mixer`      | pavucontrol, pwvucontrol    | Yes        | Yes     | 0.95 / 0.85 |
| `wallpaper`        | waypaper, waytrogen         | Yes        | Yes     | 0.95 / 0.85 |
| `notif`            | swaync                      | Yes        | No      | Default     |

**Behavior Tags (5 total)**:

| Tag                 | Effect                                   | Use Case                  |
| ------------------- | ---------------------------------------- | ------------------------- |
| `pip`               | Float, pin, top-right, keep aspect ratio | Browser PiP, video PiP    |
| `auth-dialog`       | Float, center, small size                | Polkit, sudo prompts      |
| `file-dialog`       | Float, center, medium size               | Open/save dialogs         |
| `no-steal-focus`    | no_initial_focus                         | WeChat, QQ, JetBrains     |
| `suppress-activate` | suppress_event activate                  | Vesktop (spurious events) |

### Tag Definition Syntax

```bash
# sys/tags.conf
windowrule = match:class ^(AppClassRegex)$, tag +tagname
```

**Examples**:

```bash
# Single class
windowrule = match:class ^(firefox)$, tag +browser

# Multiple classes (OR logic)
windowrule = match:class ^([Ff]irefox|chromium|brave)$, tag +browser

# Title-based (rare)
windowrule = match:title ^(Picture-in-Picture)$, tag +pip

# Negative title (compound — see below)
# NOT in tags.conf — goes in rules.conf
```

---

## Rule Application System

### Rule Groups by Tag

Rules are **grouped by tag**, not by rule type. This makes it easy to audit all rules for a specific app category.

#### Example: Browser Tag Rules

```bash
# sys/rules.conf — BROWSER section
################################################################################
# BROWSER
# Tiled main window. Opacity. Idle inhibit when fullscreen.
# Sub-windows (popups, dialogs) float via compound rule below.
################################################################################

windowrule = opacity 1.00 0.85,           match:tag browser
windowrule = idle_inhibit fullscreen,     match:tag browser

# browser sub-windows: float dialogs that are not the main browser window
# (compound condition — cannot be expressed via tag alone)
windowrule = float on, match:class ^([Ff]irefox)$, match:title negative:^(Mozilla Firefox)$
```

**Rule Order Within Tag Block**:

1. Float/tiling decision
2. Positioning (center, move)
3. Sizing
4. Opacity
5. Visual effects (blur, rounding)
6. Behavior (idle_inhibit, pin)

**Rationale**: Mirrors CSS specificity — layout → position → size → appearance → behavior.

### Rule Types

#### 1. Floating Behavior

```bash
windowrule = float on, match:tag im
windowrule = float off, match:tag browser  # explicit tiled
```

#### 2. Positioning

```bash
windowrule = center on, match:tag im
windowrule = move (monitor_w*0.72) (monitor_h*0.07), match:tag pip
```

#### 3. Sizing

```bash
# Relative to monitor
windowrule = size (monitor_w*0.60) (monitor_h*0.70), match:tag im

# Absolute pixels
windowrule = size 480 640, match:tag calculator
windowrule = size 900 600, match:tag audio-mixer
```

#### 4. Opacity

```bash
# active_opacity inactive_opacity
windowrule = opacity 0.94 0.86, match:tag im
windowrule = opacity 1.0, match:tag screenshare  # full opacity
```

#### 5. Visual Effects

```bash
windowrule = no_blur on, match:tag multimedia-video
windowrule = rounding 0, match:tag games
windowrule = dim_around on, match:tag pip
```

#### 6. Behavioral

```bash
windowrule = idle_inhibit always, match:tag screenshare
windowrule = idle_inhibit fullscreen, match:tag browser
windowrule = pin on, match:tag pip
windowrule = keep_aspect_ratio on, match:tag pip
```

#### 7. Fullscreen

```bash
windowrule = fullscreen 0, match:tag games  # borderless fullscreen
```

---

## Compound Conditions

Some scenarios require conditions beyond simple tag matching. These use **direct class/title matching** with logical operators.

### Pattern 1: Main Window vs Sub-Window

**Problem**: Distinguish main Firefox window from dialogs/popups.

**Solution**: Negative title matching.

```bash
# Main Firefox window has title "Mozilla Firefox"
# Dialogs have different titles (e.g., "Library", "About")
windowrule = float on, \
  match:class ^(firefox)$, \
  match:title negative:^(Mozilla Firefox)$
```

**Logic**: If class is firefox AND title is NOT "Mozilla Firefox" → it's a dialog → float it.

**Applied To**:

- Browsers (Firefox, Chrome, Edge)
- IDEs (VSCode, JetBrains)
- Notes apps (Obsidian, Logseq)
- File managers (Thunar, Nautilus)
- Game stores (Steam, Lutris)
- OBS

### Pattern 2: Multiple Conditions (AND Logic)

```bash
# Only match if BOTH conditions true
windowrule = float on, \
  match:class ^(jetbrains-.+)$, \
  match:title negative:^(.*(IDEA|PyCharm|WebStorm).*)$
```

### Pattern 3: OR Logic via Multiple Rules

```bash
# Match either condition
windowrule = float on, match:class ^(thunar)$, match:title negative:^(.*[Tt]hunar.*)$
windowrule = float on, match:class ^(org.gnome.Nautilus)$, match:title negative:^(Files)$
```

**Rule**: Each line is independent (OR). Multiple matches on same line are AND.

### When to Use Compound Conditions

**Use Tags When**:

- All windows of an app should behave the same
- Behavior is consistent across all instances

**Use Compound Conditions When**:

- Main window vs dialogs need different behavior
- Need to exclude specific titles
- Complex multi-condition logic

**Guideline**: Prefer tags. Use compounds only when tags are insufficient.

---

## User Extension Pattern

Adding custom apps follows a **two-step pattern**:

### Step 1: Add Tag Classification

```bash
# user/tags.conf
# Add Signal to IM category
windowrule = match:class ^(signal)$, tag +im

# Add custom app with new category
windowrule = match:class ^(myapp)$, tag +myapp
```

### Step 2: Add Behavior Rules

```bash
# user/rules.conf
# Signal inherits all IM rules automatically
# But we can add custom overrides:
windowrule = size (monitor_w*0.50) (monitor_h*0.60), match:tag signal

# Custom app needs full rule set
windowrule = float on, match:tag myapp
windowrule = center on, match:tag myapp
windowrule = size 800 600, match:tag myapp
windowrule = opacity 0.9 0.8, match:tag myapp
```

### Inheritance Benefits

When you tag Signal as `+im`, it **automatically inherits**:

- Float on
- Center on
- Size (monitor_w*0.60) (monitor_h*0.70)
- Opacity 0.94 0.86

You only override what differs (e.g., custom size).

### Adding New Category Tags

If your app doesn't fit existing categories:

```bash
# user/tags.conf
windowrule = match:class ^(davinci-resolve)$, tag +video-editing

# user/rules.conf
windowrule = opacity 1.0, match:tag video-editing
windowrule = no_blur on, match:tag video-editing
windowrule = idle_inhibit always, match:tag video-editing
```

**Naming Convention**: Use kebab-case for multi-word tags (`video-editing`, not `videoEditing`).

---

## Tag Completeness Invariant

### The Invariant

**Every tag defined in `tags.conf` MUST have at least one rule in `rules.conf`.**

**Violation Example**:

```bash
# tags.conf
windowrule = match:class ^(myapp)$, tag +mytag

# rules.conf — NO rules for +mytag!
# Result: Tag exists but does nothing (orphaned tag)
```

### Why It Matters

1. **Incomplete Configuration**: Orphaned tags indicate unfinished work
2. **Debugging Difficulty**: Hard to trace why an app behaves unexpectedly
3. **Maintenance Burden**: Accumulated orphaned tags clutter the system

### Validation Script

```bash
#!/usr/bin/env bash
# scripts/validate_tags.sh

TAGS_FILE="$HOME/.config/hypr/sys/tags.conf"
RULES_FILE="$HOME/.config/hypr/sys/rules.conf"

# Extract all defined tags
defined_tags=$(grep 'tag +' "$TAGS_FILE" | \
  sed 's/.*tag +//' | \
  sed 's/ .*//' | \
  sort -u)

# Extract all used tags
used_tags=$(grep 'match:tag' "$RULES_FILE" | \
  sed 's/.*match:tag //' | \
  sed 's/ .*//' | \
  sort -u)

# Find orphaned tags (defined but not used)
orphaned=$(comm -23 <(echo "$defined_tags") <(echo "$used_tags"))

if [[ -n "$orphaned" ]]; then
  echo "❌ Orphaned tags found (defined but not used):"
  echo "$orphaned"
  exit 1
else
  echo "✅ All tags have corresponding rules"
  exit 0
fi
```

### Automated Checking

Add to CI/CD or pre-commit hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash
~/.config/hypr/scripts/validate_tags.sh || exit 1
```

---

## Implementation Details

### Tag Application Order

Hyprland applies rules in **source order**:

```
1. sys/tags.conf    → Tags assigned to windows
2. user/tags.conf   → Additional tags
3. sys/rules.conf   → Rules applied based on tags
4. user/rules.conf  → User rule overrides/additions
```

**Implication**: User rules can override system rules (later wins).

### Multiple Tags Per Window

A window can have **multiple tags**:

```bash
# Discord is both IM and might steal focus
windowrule = match:class ^(discord)$, tag +im
windowrule = match:class ^(discord)$, tag +no-steal-focus
```

**Rule Application**: All rules for all tags apply. If conflicts occur, last rule wins.

### Tag Matching Performance

**Time Complexity**: O(n) where n = number of rules.

**Optimization**:

- Hyprland caches rule matches
- First match often sufficient (depends on rule specificity)
- ~200 rules → negligible overhead (<1ms per window)

### Debugging Tag Assignment

Check which tags a window has:

```bash
# Get active window info
hyprctl activewindow -j | jq '.tag'

# List all windows with tags
hyprctl clients -j | jq '.[] | {class: .class, title: .title, tag: .tag}'
```

---

## Debugging & Validation

### Symptom: App Not Following Expected Rules

**Diagnosis**:

```bash
# 1. Check if tag is assigned
hyprctl activewindow -j | jq '{class: .class, tag: .tag}'

# 2. Check if rules exist for that tag
grep 'match:tag tagname' sys/rules.conf

# 3. Check if user rules override system rules
grep 'match:tag tagname' user/rules.conf
```

**Common Causes**:

1. Tag not assigned (missing entry in tags.conf)
2. Typo in tag name (`+broswer` instead of `+browser`)
3. User rule overriding system rule unintentionally
4. Regex doesn't match app class (check exact class name)

### Symptom: Compound Condition Not Working

**Diagnosis**:

```bash
# Check exact window class and title
hyprctl activewindow -j | jq '{class: .class, title: .title}'

# Test regex manually
echo "Mozilla Firefox" | grep -P '^(Mozilla Firefox)$'
```

**Common Causes**:

1. Regex syntax error (escape special chars)
2. Title changes dynamically (use partial match)
3. Negative match logic inverted

### Validation Checklist

When adding a new app:

- [ ] Added tag in `user/tags.conf`
- [ ] Added rules in `user/rules.conf`
- [ ] Tested window appears correctly (float/tiling, position, size)
- [ ] Verified opacity settings
- [ ] Checked for conflicts with existing rules
- [ ] Ran tag completeness validation script

### Testing Procedure

1. **Launch App**:

   ```bash
   myapp &
   ```

2. **Check Tag Assignment**:

   ```bash
   hyprctl activewindow -j | jq '.tag'
   ```

3. **Verify Behavior**:
   - Does it float/tile as expected?
   - Is it centered (if applicable)?
   - Is size correct?
   - Is opacity correct?

4. **Test Edge Cases**:
   - Open dialogs/sub-windows
   - Resize manually
   - Move between workspaces

---

## Best Practices

### For Users

1. **Use Existing Tags First**: Before creating new tags, check if existing tags fit
2. **Minimal Overrides**: Only override rules that differ from tag defaults
3. **Comment Your Additions**: Explain WHY you chose specific rules
4. **Test Thoroughly**: Verify all window states (main, dialogs, popups)

### For Contributors

1. **Maintain Tag Completeness**: Every tag must have rules
2. **Group Rules by Tag**: Keep all rules for a tag together
3. **Document Compound Conditions**: Explain why tag alone is insufficient
4. **Follow Naming Conventions**: kebab-case for tags, descriptive names
5. **Update Documentation**: Add new tags to this document

### For Maintenance

1. **Regular Audits**: Run validation script monthly
2. **Remove Orphaned Tags**: Clean up unused tags
3. **Consolidate Similar Tags**: Merge tags with identical rules
4. **Performance Monitoring**: Watch for rule application slowdowns

---

## Comparison with Alternatives

### Approach 1: Direct Class Matching (Traditional)

```bash
windowrule = float on, match:class ^(firefox)$
windowrule = float on, match:class ^(discord)$
windowrule = float on, match:class ^(thunar)$
```

**Pros**: Simple, straightforward
**Cons**: Repetitive, hard to maintain, no abstraction

### Approach 2: This Tag-Driven System

```bash
# Classify once
windowrule = match:class ^(firefox)$, tag +browser
windowrule = match:class ^(discord)$, tag +im
windowrule = match:class ^(thunar)$, tag +file-manager

# Apply rules by category
windowrule = float on, match:tag im
windowrule = float on, match:tag file-manager
```

**Pros**: DRY, maintainable, extensible, auditable
**Cons**: Slightly more complex initial setup

### Approach 3: Hybrid (This System)

Use tags for common cases, compounds for edge cases:

```bash
# Tags for 90% of cases
windowrule = match:class ^(firefox)$, tag +browser

# Compounds for 10% edge cases
windowrule = float on, match:class ^(firefox)$, match:title negative:^(Mozilla Firefox)$
```

**Pros**: Best of both worlds
**Cons**: Requires understanding when to use each

---

## Future Enhancements

### Proposed Features

1. **Tag Hierarchy**: Parent/child tag relationships

   ```bash
   tag +productivity includes +projects, +notes, +email
   ```

2. **Tag Profiles**: Switch between tag rule sets

   ```bash
   hyprctl tag-profile load gaming
   hyprctl tag-profile load productivity
   ```

3. **Dynamic Tagging**: Auto-tag based on behavior patterns

   ```bash
   # Auto-tag windows that stay small as dialogs
   windowrule = auto_tag +file-dialog, maxsize 400 300
   ```

4. **Tag Statistics**: Track tag usage

   ```bash
   hyprctl tag-stats
   # Output: browser: 3 windows, im: 2 windows, terminal: 1 window
   ```

5. **Visual Tag Indicator**: Show tags in window borders
   ```bash
   decoration {
       tag_indicator = true  # Color-coded borders by tag
   }
   ```

---

## References

- [Hyprland Window Rules Documentation](https://wiki.hyprland.org/Configuring/Window-Rules/)
- [Strategy Design Pattern](https://refactoring.guru/design-patterns/strategy)
- [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single-responsibility_principle)
- [DRY Principle (Don't Repeat Yourself)](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
- [Open/Closed Principle](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle)
