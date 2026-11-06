# 29 — Item art: brief + implement final icons

**What to build:** First, an art brief listing every placeholder asset the new items use: 24 item icons plus any card or combat art the mechanic tickets added. Each entry has the id, name, symbol, the brainstorm's description line, its size/format to match the existing `assets/combat/icons/` set, and the target path. The human supplies the assets. Once they arrive, they're placed, imported, and every placeholder reference is replaced.

**Blocked by:** 01 (brief); asset placement waits on the human supplying files.

**Relevant files:** `assets/combat/icons/`, `data/recipes.json` (icon paths), `docs/brainstorm.md`, `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Art brief written to `.scratch/item-event-effects/art-brief.md` and handed to the human (status → ready-for-human until assets arrive)
- [ ] With assets supplied: all icons placed at their target paths and referenced; no placeholder references remain
- [ ] Boot validation and tests pass; on-device icon check list in the report
