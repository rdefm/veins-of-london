# 15 — Craft loop skips uncoverable recipes

**What to build:** A faction's daily craft pass no longer stops at the first recipe it cannot afford. When ore cannot cover one recipe, the faction moves on to the next recipe in its list, so one expensive or starved recipe cannot block the rest of its output.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/faction_sim.gd` (`craft`, `_craft_toward_target`, `_can_cover`), `tests/test_faction_sim.gd`, REFERENCE.md §3.1.

**Status:** ready-for-agent

- [ ] With a faction holding ore for recipe B but not recipe A (A first in its list), B is still crafted
- [ ] Ore spent per attempt, success chance and crafting-share bookkeeping are unchanged
- [ ] Test covers the starved-first-recipe case
- [ ] 3-seed sim run once and the change in item named share and shortfall days reported (before/after, appended to `.scratch/london-market/balance-report.md`)
