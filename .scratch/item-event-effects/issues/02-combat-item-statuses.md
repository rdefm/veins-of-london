# 02 — Combat items: Near Miss, Sod's Law, Ricochet, Navvy's Draught

**What to build:** Four new combat items work in a fight, each as one new case in the round-combat item table, shaped like the existing statuses (brainstorm §3.1, §3.4, §4). Near Miss: the next N attacks on you miss. Sod's Law: on one enemy, its next N attack rolls land at the bottom of its damage range. Ricochet: the next hit you take returns X damage to the attacker. Navvy's Draught: +X max and current HP for one fight, usable from the Bag before combat. Tier scales N/X via effectPower. Loadout and guard-kit allowlists are updated as brainstorm §6 says.

**Blocked by:** 01

**Relevant files:** `systems/combat_rounds.gd`, `systems/combat.gd`, `systems/combat_prep.gd`, `systems/loadout.gd`, `systems/guard_kit.gd`, `systems/bag.gd`, `data/combat_rounds.json`, `data/constants.json` (loadout/guardKit), `tests/test_combat_rounds.gd`; REFERENCE §3.7b Open/Guarded round combat.

**Status:** ready-for-agent

- [ ] Each item's effect is tested through the combat public API at a low and a high tier
- [ ] Item spent on use; tooltip/strings in data (PROSE-REVIEW)
- [ ] Loadout and guard-kit lists include the items where the brainstorm says
