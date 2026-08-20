# Documentation Restructuring Notice

> This notice records the documentation restructuring history.
> The docs are now organized into 6 categories under `docs/`.

## Current Structure (2026-08-20)

```
docs/
├── 01-Getting-Started/    ← install + daily operations
│   ├── README.md          (also the root README via symlink)
│   ├── QUICK_START.md
│   └── COMMON_TASKS.md
├── 02-Architecture/        ← design + pipeline
│   ├── ARCHITECTURE_OVERVIEW.md
│   ├── PIPELINE_ARCHITECTURE.md
│   ├── DESIGN_PRINCIPLES.md
│   └── THREE_LAYER_CONSTANTS.md
├── 03-Core-Systems/        ← runtime systems
│   ├── TAG_SYSTEM.md
│   └── STATE_MACHINES.md
├── 05-Reference/           ← troubleshooting + checklists
│   ├── TROUBLESHOOTING.md
│   └── GPU_VERIFICATION_CHECKLIST.md
├── 06-Meta/                ← project info
│   ├── DOCUMENTATION_INDEX.md
│   ├── CHANGELOG.md
│   ├── COMPLETION_REPORT.md
│   ├── REVIEW_DEEP_AUDIT.md
│   └── DOC_RESTRUCTURING_NOTICE.md  (this file)
└── 07-Lua-Reference/       ← API reference + migration
    ├── README.md
    └── COMPATIBILITY.md
```

> Note: `docs/04-Implementation/` was planned but deliberately skipped —
> implementation details live in `02-Architecture/` and `03-Core-Systems/`.

## What Changed (Task 67-71, 2026-08-20)

### Rewritten (all `.conf`-era leftovers removed)
- 15 docs files had `.conf` syntax leftovers (tag +X, match:tag, .strip(), tags.conf, rule = "...")
- All 15 rewritten to use accurate `.lua` syntax verified against actual code
- 7 P1 docs (107 leftovers → 0)
- 4 P2 docs (37 leftovers → 0)
- 3 P3 docs (6 leftovers → 0)
- Plus TAG_SYSTEM.md (already rewritten in Task 68)

### Added
- `docs/06-Meta/REVIEW_DEEP_AUDIT.md` — Task 69 deep audit report
- `hypr-sim.py` — runtime config simulator (in repo root)

### Stats (verified)
- 18 docs files across 6 categories
- 52 Lua code blocks in docs, all syntax-validated with `lupa load()`
- All internal links validated (0 missing targets)

## Why the Restructuring

### Problem (before)
- Old docs mixed `.conf` and `.lua` syntax freely
- Code examples had syntax errors (`return { ['M = "SUPER" }` — invalid Lua)
- Referenced non-existent files (`docs/04-Implementation/`)
- Outdated statistics ("45 .lua files" when actual is 49)
- Missing API whitelisting (recommended `keep_aspect_ratio` as effect, but it's a dispatcher param)

### Solution
- Each doc rewritten from scratch based on actual code (not design docs)
- Every statistic verified with `grep`/`wc`/`find`
- Every Lua code block validated with `lupa load()` (Lua 5.4)
- Every internal link validated with `[ -e file ]`
- Every API claim verified against [Hyprland wiki](https://wiki.hypr.land/)

### Principle
> "docs must be based on code reality, not impressions" (教训 12)
>
> Old docs were written "per design docs"; new docs are "per code as-is".
> The two are qualitatively different.

## Validation Methodology

```bash
# 1. Static analysis
luacheck ~/.config/hypr --codes

# 2. Runtime simulator (catches errors luacheck misses)
python3 hypr-sim.py

# 3. Real Hyprland (gold standard)
hyprland --verify-config

# 4. Docs link check
find docs -name '*.md' | while read f; do
  grep -oE '\]\(([^)]+)\)' "$f" | sed 's/](//; s/)//' | grep -v '^http' | while read link; do
    resolved=$(realpath -m "$(dirname $f)/$link")
    [ -e "$resolved" ] || echo "MISSING: $f → $link"
  done
done

# 5. Lua code block syntax check
python3 -c "
import lupa, re
for f in [...]:  # iterate docs
    blocks = re.findall(r'\`\`\`lua\n(.*?)\`\`\`', open(f).read(), re.S)
    for blk in blocks:
        # use lupa to load() each block
"
```

## References

- [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) — full file listing
- [CHANGELOG.md](CHANGELOG.md) — version history
- [REVIEW_DEEP_AUDIT.md](REVIEW_DEEP_AUDIT.md) — Task 69 audit report
