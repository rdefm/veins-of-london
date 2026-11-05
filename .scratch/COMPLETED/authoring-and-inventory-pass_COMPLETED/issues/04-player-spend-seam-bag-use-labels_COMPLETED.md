# 04 — Player spend seam, Bag use and labels

**What to build:** A single player spend seam checks, counts and spends ore and items across shared then stash, preserving tiers. Lowest-tier-first rules stay with each caller. Using items from the Bag and applying vein items by hand go through it, so stashed units work for the player. Player-facing labels become Shared and Stash. Moves stay on the HQ ore slip.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/stash.gd`, `systems/crafting.gd`, `systems/consumables.gd`, `systems/cultivating.gd`, `systems/active_effects.gd`, `systems/grudges.gd`, `systems/contacts.gd`, `scenes/components/bag_drawer.gd`, `scenes/modals/hq_ore_readout_modal.gd`, `tests/test_stash.gd`, REFERENCE.md stash section, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Shared stock is spent before stash, with tiers preserved
- [ ] A stashed-only item can be used from the Bag and applied to a vein by hand
- [ ] Totals include stashed units
- [ ] Contracts, Sales, Production, Procurement, cultivators, manual selling, gifting and guard-kit stocking stay shared-only
- [ ] Raids still cannot reach the stash
- [ ] Automated systems leave the stash untouched even when shared stock is empty
- [ ] Player-facing pools read Shared and Stash; new strings are flagged `PROSE-REVIEW:`
- [ ] REFERENCE.md stash section is updated
