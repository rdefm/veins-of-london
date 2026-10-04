# 02 — Retire tier 0; consumables use stored tier; save migration scaffold

**What to build:** Tier 0 no longer exists. Existing tier-0 units in every store (player inventory, stash, guard kits, faction holdings, loaded Dial Complications) become tier 1 on load, and anything that formerly granted tier 0 grants tier 1. Direct personal consumable use takes its effect power from the unit's stored tier, not the player's crafting skill; direct item effects receive no Dial amplification. Introduce a versioned save-migration step that keeps previously supported saves readable and that later tickets in this feature extend (weapons, loadouts, James's Dial, HQ kit capacity).

**Blocked by:** None — can start immediately.

**Relevant files:** `autoload/SaveManager.gd`, `autoload/GameState.gd`, `systems/consumables.gd`, `systems/combat.gd`, `systems/crafting.gd`, `systems/faction_sim.gd`, `systems/guard_kit.gd`, `systems/dial.gd`, `systems/event_items.gd`, `data/factions.json` (`startingHoldings`), `tests/test_savemanager.gd`, `tests/test_consumables.gd`, `tests/test_combat.gd`. Update REFERENCE §2 (state schema), §3.5, §3.7 with the change.

**Status:** ready-for-agent

- [ ] Loading an old save converts all tier-0 units in all stores to tier 1, counts conserved (merged into existing tier-1 buckets)
- [ ] No code path grants tier 0 any more
- [ ] Direct item power reads the unit's tier; tier 1 vs tier 3 differ in tests
- [ ] Save version bumped; migration step is a reusable, ordered hook; older saves still load
- [ ] REFERENCE updated
