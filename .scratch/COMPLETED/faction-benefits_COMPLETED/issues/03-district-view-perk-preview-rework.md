# 03 — Rework district-view perk preview

**What to build:** Replace the confusing flat-list perk preview in the district panel with a district-scoped tier ladder. Separate "Here (turf)" perks from "Everywhere (global)". Each perk shows active here / active at reduced strength (foothold) / inactive, and what unlocks it. Tighten wording, drop jargon. Same ladder visual as ticket 02 (share the widget, don't duplicate; whichever lands first owns it).

**Blocked by:** 01 — Benefit rows read.

**Visual reference:** `mockups/district.png` (source `district.html`). Layout, grouping and content only — colours are illustrative. Keep the Map tab's existing theme (`map_palette.json` light/dark tokens via MapCardStyle, incl. Dark map), not the mockup colours.

**Relevant files:** `scenes/screens/map.gd` (`_add_perk_preview`, `_toggle_perk_preview`, ~line 295-320), `scenes/screens/map_card_style.gd`, `systems/turf_panel.gd` (`faction_preview`), `tests/test_turf_panel.gd`, `docs/ui-vision.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Turf and global perks shown in separate groups
- [ ] Each perk states active-here status and unlock requirement
- [ ] Old flat list removed; wording plain
- [ ] Ladder visual consistent with Factions app (02)
- [ ] check_all + tests pass; human on-device check: panel readable, active vs locked obvious at a glance
