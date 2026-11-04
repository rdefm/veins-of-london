# 06 — Loadout and Lab draw on the stash

**What to build:** Equipping a loadout and hand-crafting at the Lab can draw on the stash through the player spend seam, so everything the player does by hand reaches the reserve. Selling and guard-kit stocking remain shared-only.

**Blocked by:** 04

**Relevant files:** `systems/loadout.gd`, `systems/lab.gd`, `systems/crafting.gd`, `scenes/screens/hq_lab_bench.gd`, `tests/test_lab.gd`, `tests/test_stash.gd`, REFERENCE.md Lab section

**Status:** ready-for-agent

- [ ] Equip works from stashed-only stock, keeping the tier
- [ ] Hand-crafting can spend stashed ore and items, shared first
- [ ] Lab availability counts show what the player can really spend
- [ ] Selling and guard-kit stocking still ignore the stash
- [ ] Rewind restores spent stock to the pools it came from
- [ ] REFERENCE.md Lab section is updated
