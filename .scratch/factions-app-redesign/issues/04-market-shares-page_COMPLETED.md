# 04 — Market shares page

**What to build:** The Register's home gains a separate Market shares route. The player chooses Ore or Crafting and one ore glyph, then sees London's producer shares as readable oxide-orange percentage bars.

**Blocked by:** 01 — Branded directory and dossier route.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `systems/shares.gd`, `data/ore_types.json`, `tests/test_shares.gd`, `tests/test_phone_nav.gd`, `docs/REFERENCE.md` §3.14 “Shares”, `CODEMAP.md`.

- [ ] Market shares is a secondary route from the five-row home, with Back to that home. Its Ore/Crafting toggle and five glyph-and-name ore choices select presentation only.
- [ ] For the selected tally and ore, show each producer returned by the existing Shares overview, including You and Independents when present, with exact percentage text and an oxide-orange bar filled to that percentage. The existing window, calculations and producer visibility are unchanged.
- [ ] Switching tally/ore or receiving a state refresh updates the bars without losing the current selection, duplicating controls or touching gameplay state. No share table remains on the home page.
- [ ] Headless checks cover both tallies, all five ore choices, producer visibility, displayed values and navigation. Syntax checks and full Godot 4.7 suite pass. Report phone-width bar/glyph/contrast QA and new copy as `PROSE-REVIEW:`.
