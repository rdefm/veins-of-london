# 15 — Ally AI for every combat item

**What to build:** Recruits (Archie, James) can equip every loadout item the player can, and the round-fight ally AI plans each one sensibly from its own slots. Today allies can't equip Wormhole or Be a Lady (`loadout.allyExcluded`). The prototype ally AI (`_ally_item_action`) plans only heals (patient below `allyHealBelow`) and Time Pearl / Black Hole (vs `allyCrowdEnemies`+ enemies, none already losing actions). An ally holding Blast, Shield, Enhancement Powder, Prophet's Breath, Be a Lady or any table-4 item never uses it.

Review the ally AI for every item and give each one a plan-time trigger rule, target rule and once-per-round/once-per-fight limit. Then empty `allyExcluded`, or keep only what the human decides stays player-only (see Open decisions).

**Blocked by:** 07, 08, 10 (07 and 08 define the Pan family / Wormhole / Failsafe / Rewind in the action model; 10 settles the guard-kit rule order allies share)

**Relevant files:** `systems/combat_prototype.gd` (`_plan_allies`, `_ally_item_action`, `_ally_heal_patient`, `_ally_action`, `_use_item`); `systems/combat.gd` (`_round_loadout`, `_round_ally_combatant`, `_sync_round_allies`, `_guard_try_item` for the old guard-kit rule order); `systems/loadout.gd` (`is_equippable`); `data/constants.json` (`loadout.allyExcluded`, `loadout.items`); `data/combat_prototype.json` (`allyHealBelow`, `allyCrowdEnemies`); `scenes/phone_apps/profile_app.gd` (recruit loadout picker); `tests/test_combat_rounds.gd`; `tests/test_combat_prototype.gd`; `tests/test_loadout.gd`; REFERENCE §3.7 (Recruit loadout), §3.7b (Items, Table 4, Table 5)

**Status:** needs-info

## Draft ally rules (for human sign-off, not decided)

Plan-time, evaluated in this order on the round-start state. Each unit is reserved at commit and spent on resolution (Table 5 rule):

| Item | Proposed trigger | Target |
|---|---|---|
| healingBurst | lowest-fraction friendly below `allyHealBelow` (existing) | that friendly; multi → team |
| prophetsBreath | player has no sight and 1+ enemy action is unread | player gets sight (Table 5) |
| shield | ally (or, multi, any friendly) targeted by a read enemy strike, own pool 0 | self / team |
| timePearl / blackHole | `allyCrowdEnemies`+ enemies, none losing actions (existing) | all enemies |
| blast | a living enemy at or below `power` hp, else the lowest-hp enemy | that enemy; multi → all |
| enhancementPowder | first action of a round with no powder running, once per fight | self |
| beALady | first action of round 1 (or first round with 2+ enemies), once per fight | self |
| panic / pansRapture / panger / pandemonium | per 07's table-4 rows: the unstatused enemy with most read offensive actions | that enemy; multi → all unstatused |
| wormhole | see Open decisions | — |
| failsafe / rewind | stay automatic, never planned (Table 5) | — |

## Open decisions (human)

1. **Wormhole on an ally.** REFERENCE Table 4 and ticket 07 say "player only, allies refuse". Options: (a) keep it player-only, the one exception to "all items"; (b) an ally's Wormhole ends the fight `fled` for everyone, used only when the player is KO'd or below some hp fraction; (c) it pulls just that ally out (it leaves the fight, no KO cooldown).
2. **Be a Lady on an ally.** In-fight only (max rolls + 1/3 crit for `power` rounds on the ally), with no carry-in for allies. Confirm.
3. **Thresholds** in the draft table (Blast kill check, Shield trigger, Powder/Lady timing) need sign-off or replacement. Any new numbers go in `data/combat_prototype.json`, not code.
4. Whether guard-kit allies (ticket 10) use the same rules as recruits, or keep Table 5's own order.

Once decided, update REFERENCE §3.7 (Recruit loadout `allyExcluded`) and §3.7b (ally item rules) before implementation, then set `Status: ready-for-agent`.

- [ ] Every loadout item is equippable by a recruit, except any the human keeps player-only
- [ ] Each item has an ally plan rule; a seeded test per item shows an ally committing it as an intent and resolving it at its tier's power
- [ ] Ally item intents always read; a removed or fizzled action returns the unit
- [ ] Spent ally units settle and refill as today (`Loadout.settle_allies`)
