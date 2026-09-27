# 25 — Split Lab into Crafting and Experimenting sections

**What to build:** "Lab" is currently split across two disconnected places: HQ's inline "Recipes"/"Workbench" cards (crafting known recipes via `Crafting.attempt_craft`) and the separate `LabScreen` (`scenes/screens/lab.gd`, `state.benchNav`-driven calc-discovery/"experimenting" flow), reached only via a Lab card's "Open" button. Make Lab a single screen with two clear sections — "Crafting" (today's HQ Recipes/Workbench functionality) and "Experimenting" (today's existing `lab.gd` flow) — so both live under one Lab entry point instead of being split between HQ and a separate screen.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Lab screen has two distinct, navigable sections: Crafting and Experimenting.
- [ ] Crafting section carries over the existing Recipes/Workbench functionality (`Crafting.attempt_craft` and related HQ cards), moved out of `hq.gd` into the Lab screen.
- [ ] Experimenting section is the existing `lab.gd` discovery flow (`benchNav` states), unchanged in behavior, just reframed as a section of the combined screen.
- [ ] HQ screen's Lab card opens directly to this combined screen (default section: whichever the human prefers — flag if unspecified).
- [ ] `hq` and `lab` tests updated to reflect the moved/combined functionality.
