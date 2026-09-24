# 15g — Wire remaining combat items (Prophet's Breath, Wormhole) into the prototype

**What to build:** Extend ticket 14b's approved item budget to cover the two production combat items it left out, so the full `COMBAT_COMPLICATION_RECIPES` roster (`systems/combat.gd:97`) is exercisable in the squad/wave prototype, not just the six 14b already resolved.

**Raised by:** 15e's on-device QA pass — flagged that the prototype's debug scenarios don't exercise every combat item a human might reasonably expect to test.

**Blocked by:** None — independent pickup, same shape as 15f. Only in scope if the human wants Prophet's Breath/Wormhole exercised in this prototype; ticket 15 itself never required full item coverage.

- [ ] Use the `grilling` skill on the human for Wormhole specifically — its production effect (`systems/combat.gd:1209` `use_wormhole()`) is an instant-flee-from-combat, and the prototype's committed-round engine (`_advance_round()`, `systems/combat_prototype.gd`) has no existing "abandon a round already in progress" contract. Resolve: can it be committed mid-round like every other action, does it end the fight outright bypassing `_current_wave_defs()`'s wave progression, and what's its `outcome` value on a multi-wave (`gauntlet`-shaped) fight.
- [ ] Prophet's Breath is lower-risk (a straight evade-turns buff, same shape as already-wired effects) — confirm it slots into the existing effect-application path (`Dial.cast_complication()` / direct-use) with no new round-structure question, then wire it the same way 14b's six items were wired.
- [ ] Both draw from real inventory (`Crafting.inventory_remove`), same "no synthetic pool" precedent as every other item in this prototype (ticket 15's Approved rule).
- [ ] Resolve Rewind interaction for both, consistent with ticket 15's existing item-restoration contract (stock/charge restored, the Rewind resource itself never refunded).
- [ ] Update ticket 15's own "Approved rule" section (or append a dated amendment) once resolved, same as 14b did — don't silently redefine it in code without a written record.
- [ ] Add both to a debug scenario's exercisable item set once wired; re-run device QA on the affected scenario(s).

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. Run required GDScript syntax checks and the full headless suite after any code change.
