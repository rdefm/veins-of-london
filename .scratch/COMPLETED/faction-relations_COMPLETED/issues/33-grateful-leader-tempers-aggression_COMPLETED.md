# 33 — Grateful leader tempers faction aggression, cooling over time

**What to build:** When an instigator the player has accepted secret offers from becomes their faction's leader, that faction's aggression toward the player is scaled down. The multiplier is fixed (TBD, ~×0.5), separate from the leader's `aggressionMult`, and stacks with the number of handovers accepted from that member. It decays daily, and hostile acts by the player against that faction cancel it.

**Blocked by:** 31 — Secret offers rework.

**Relevant files:** `systems/faction_ai.gd` (`personality`), `systems/key_members.gd` (`aggression_scale`, `daily_tick`, accept hook), `autoload/SaveManager.gd` (old-save backfill), `data/faction_incidents.json`, `tests/test_key_members.gd`, `CODEMAP.md`. REFERENCE.md key members § "Standing and succession" (effective aggressionPersonality).

**Status:** ready-for-agent

- [ ] Accepted offers are counted per instigator
- [ ] Faction aggression toward the player is tempered only while a helped instigator leads it
- [ ] Tempering stacks with handover count and decays daily
- [ ] Hostile acts against the faction cancel it
- [ ] Old saves load; tests, REFERENCE and CODEMAP updated
