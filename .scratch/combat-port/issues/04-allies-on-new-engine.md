# 04 — Allies on the new engine

**What to build:** Allies fight under the new rules in contexts already on the new engine. Recruited contacts use their own combat skill, falling back to the authored level in their combat kit. Hired guards and hired muscle use their flat authored level from data (§3.7b). Allies plan after enemy plans are rolled, reading the fogged view (guard incoming strikes, strike enemies who will be Open, feint ahead of a teammate's strike), and their plans always read for the player. Each ally uses its real two-slot loadout by the prototype's simple rules (consumed and refilled like today). The prep sheet's recruit selection and order set the ally roster.

**Blocked by:** 03

**Relevant files:** `systems/combat.gd` (`_gather_raid_allies`, `_gather_defend_allies`, `_add_guard_allies`, `_add_hired_muscle`, `build_guard_ally`); `systems/combat_prototype.gd` (ally AI); `systems/contacts.gd`; `systems/loadout.gd`; `systems/combat_prep.gd`; `data/hiring.json`; `data/combat_prototype.json`; `tests/test_combat_prep.gd`; `tests/test_contacts.gd`; `tests/test_loadout.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] A contact ally fights at its own level; guards and muscle at their authored level
- [ ] Ally plans are visible before the player's pick and react to read intents only
- [ ] Ally loadout units are consumed from real stock and refill at settlement as today
- [ ] Prep recruit order is the ally order in the fight
