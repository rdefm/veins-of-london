# 04 — Posts tab: place cards with slots and score bar

**What to build:** the Posts tab rebuilt around places.

- Each HQ / vein card: place name (vein: ore-colour dot, ore + district, "most valuable" on the top vein), score number + band word in the band's colour (Exposed gets a warning glyph), and a split score bar — hardware part and guard part — with a small legend "hardware a/40 · guards b/60" (max points from `muscle.score` data).
- Slots shown as tiles up to the post cap: filled tile = avatar, short name, wage, level badge (tap → guard detail; "→ Reserve" stays reachable from the detail sheet); empty tile = dashed "+" (tap → the existing Assign picker for that place).
- Footer: "n/cap · £wage/wk" and a "Kit a/b ›" link only when guards are posted; with no guards, one muted line (e.g. no lock, no guards).
- Veins ordered by `value_order`, most valuable first. Veins with no guards that aren't in the top slot fold to a one-line row (ore dot, name, n/cap, score + band); tapping expands to the full card.
- Reserve stays as a card at the bottom for now (ticket 05 moves it to a tray).

Mockup: https://claude.ai/artifact/3F5zB6ctS4FBERj2k4SqDx (Posts artboard).

**Blocked by:** 01 — Muscle readouts; 03 — Guards tab rows and shared guard widgets.

**Relevant files:** `scenes/screens/security.gd` (`_build_posts`, `place_ids`, `place_header`, `place_cost_text`, `place_kit_text`), `systems/cultivating.gd` (`value_order`), `systems/guard_kit.gd` (`status_text`, capacity), `systems/muscle.gd` (score split from 01), `data/palette.json` (band colours, ore colours), `data/constants.json` (`muscle.score`), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Split bar parts match the score; band colour from palette data
- [ ] Slot tiles = post cap; empty tile opens Assign for that place; disabled without the office
- [ ] Veins sorted by value; empty non-top veins fold and expand on tap (expansion screen-local)
- [ ] Kit link hidden at 0 guards
- [ ] check_all clean; full suite green
- [ ] PROSE-REVIEW: empty-place line, legend text
- [ ] On-device checklist in the report
