# 06 — District panel Turf section

**What to build:** Tapping a district shows a Turf section listing each contender's share of its veins (%), the control tier (Control / Foothold / Contested), the vein margin needed to flip it, and the turf modifiers the player currently gets there, each tagged with its source faction. A pure, headless-testable decision layer (like the district bubble layer) backs it.

**Blocked by:** 04 — Turf district modifiers

**Relevant files:** `scenes/screens/map.gd` (`_build_district_panel`, ~line 249), `systems/district_bubble.gd` (prior art), `systems/districts.gd` (`ownership_summary`), `systems/turf.gd`, `scenes/components/map_card_style.gd`, `tests/test_district_bubble.gd`, new turf-panel test. `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Pure decision layer returns rows: contender shares, tier, flip margin, active modifiers with source faction
- [ ] Panel renders them; the screen does no logic or mutation
- [ ] Headless tests on the decision layer
- [ ] Row slots ready for later benefit/harassment rows (07, 14) without restructure
- [ ] UI strings flagged `PROSE-REVIEW`; on-device QA list in the report
