# 01 — Guard kit core: data, state, stock/unstock

**What to build:** A player can move allowlisted combat consumables, by tier, from their inventory onto a guarded vein's guard kit and back again. The mechanics are complete and tested headless, with no UI yet: the JSON config, the `vein.guardKit` state, old-save backfill, capacity and the active-unit rules. The capacity and active-unit helpers work on a kit dict plus a guard count and a slots-per-guard value, so the HQ kit (ticket 09) reuses them without a refactor.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/constants.json` (new `guardKit` block next to `guardRepel`), `systems/guard_kit.gd` (new, static), `systems/cultivating.gd` (`vein_guard_count`, `find_vein`), `systems/crafting.gd` (`inventory_add`, `inventory_remove_from_tier`, tier-bucket shape), SaveManager (inventory migration precedent), GameData constant loading, `tests/test_guard_kit.gd` (new), `CODEMAP.md`. Spec: `.scratch/guard-kit/spec.md` §Eligible items, §State, §Capacity, §Stocking system, §Data. REFERENCE.md §1.6, §2.

**Status:** ready-for-agent

- [ ] `constants.json` has `guardKit` with `items`, `slotsPerGuard` (2), `hqSlotsPerGuard` (3), `repelBonus`, `repelTier`, `repelCap` (0.90) and `guardAlly`, all marked *placeholder* in REFERENCE.md, with no numbers in code.
- [ ] New player veins carry `guardKit: {}`. An old save loads with `{}` on every player vein, and the kit round-trips through save/load.
- [ ] `GuardKit.stock` moves units of one tier from inventory to the kit. It's refused with no state change for: an item not on the allowlist (incl. `healingSalve`, `wormhole`), fewer held than `qty`, a vein that isn't the player's, 0 guards, or an over-capacity result.
- [ ] `GuardKit.unstock` returns units to inventory at their tier. It works even over capacity or with 0 guards, and is refused when the kit holds fewer than `qty`.
- [ ] `active_units` returns the first `capacity` units in allowlist order, then highest tier first. Dropping a guard keeps the kit intact but makes the excess inactive, and stocking is refused while at or over capacity.
- [ ] Both calls emit `EventBus.state_changed`. REFERENCE §1.6/§2 and CODEMAP are updated.
