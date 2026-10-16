# 11 — Prophet's Breath in the world: no ambushes

**What to build:** Prophet's Breath can be used from the Bag outside combat (same duration table as ticket 10). While active, the player cannot be ambushed — the ambush roll after a district action never fires. It shows in the active-effects chip row.

**Blocked by:** 10 — Active effects.

**Relevant files:** `systems/ambush.gd` (`maybe_trigger`), `systems/turf.gd` (`ambush_chance`), `systems/active_effects.gd`, `scenes/components/bag_drawer.gd`, `tests/test_ambush.gd`, `docs/REFERENCE.md` §3.1d

**Status:** ready-for-agent

- [ ] Bag Use on Prophet's Breath starts the effect
- [ ] No ambush triggers while active; ambushes resume after expiry
- [ ] Muggings unaffected
- [ ] REFERENCE.md updated; tests cover suppression and expiry
