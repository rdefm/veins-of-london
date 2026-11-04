# 07 — Bag projection and new drawer

**What to build:** The Bag becomes a filtered, collapsible list driven by a pure projection, which returns filter options, categories and rows. Layout order: raw ore row, ore filter, collapsible ore categories, active effect lines, Dial summary, Close. Each row shows image, name and `?` on the left, and quantity and Use on the right, with a small "in stash" line when relevant. `?` opens a modal with name, `effectText` and `description`. One row per item, with a tier picker on Use when several tiers are held. Combat has filters and `?` but no Use. Target-picking items keep their existing block until ticket 08.

**Blocked by:** 01, 02, 04

**Relevant files:** `systems/bag.gd`, `scenes/components/bag_drawer.gd`, `scenes/components/item_icons.gd`, `systems/stash.gd`, `tests/test_bag.gd`, `tests/test_bag_drawer.gd`, `docs/adr/0007-use-item-on-a-place.md`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Rows carry item key, total, stash quantity, usability and use action
- [ ] Only held items are listed and empty categories are hidden
- [ ] Items use the Lab grouping for multi-ore recipes; multi-target variants keep their own row
- [ ] Use shows only when the action is available in management mode
- [ ] Combat shows no Use and allows no loadout change
- [ ] Raw ore row and Dial summary are kept
- [ ] Pure tests cover rows and filters with no Nodes
- [ ] New strings are flagged `PROSE-REVIEW:`
- [ ] Human QA block lists collapse, modal and row layout
