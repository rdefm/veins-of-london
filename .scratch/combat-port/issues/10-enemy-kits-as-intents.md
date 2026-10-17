# 10 — Enemy, guard and raider kits as planned intents

**What to build:** Enemies carrying items (enemy capabilities, faction raider kits) and guard allies carrying guard kits use them as actions in their committed round plans, per §3.7b. Enemy kit actions show on the strip as intents, subject to fog like any other enemy action. Kit capacity, consumption and refill rules are unchanged.

**An ally's own Failsafe (R§3.7b Rewind).** "An ally's own `failsafe` keeps it on 1 hp on its own lethal hit (one unit per save)." Round fights don't have this yet: the old reactive save in `_enemy_attack_ally` isn't ported, and ticket 15 only says failsafe is never planned. This ticket builds it for both guard allies (shared `combat.guardKit` pool) and recruits (their own slot `failsafe`; recruit failsafes aren't round-loadout items today, see `_round_loadout`). It's reactive and never planned. It fires inside the round core at the moment of the lethal hit, so the ally stays standing for the rest of the round. The spent unit settles like any spent kit/slot unit (guard kit `used` → vein/HQ refill, recruit `slotsUsed` → `Loadout.settle_allies`). It's an ordinary spent item, not a Rewind payment, so a later Rewind/Failsafe/ally rewind restoring a snapshot from before it returns it (ticket 08's `_restore_round_snapshot()` keeps only rewind payments spent).

**Blocked by:** 05, 06

**Relevant files:** `systems/combat.gd` (`_enemy_capabilities_from_template`, `_enemy_try_item`, `_guard_try_item`, `_guard_pool_has`, `_spend_guard_item`); `systems/combat_prototype.gd` (plan rolling); `systems/raiding.gd`; `data/factions.json`; `data/enemies.json`; `tests/test_combat.gd`; `tests/test_raiding.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] An enemy with a kit item commits it in its plan and it resolves at its slot
- [ ] Unread kit intents show `?` until they resolve
- [ ] Guard kits spend and refill as today
- [ ] A guard ally with a kit `failsafe` takes a lethal hit and stays on 1 hp, spending one unit; with none left it's KO'd (seeded test)
- [ ] A recruit with a `failsafe` in a slot does the same from its own slot, and the slot settles as used
- [ ] A Rewind to a snapshot from before an ally's Failsafe save returns that unit
