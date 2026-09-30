# 22 — Raid bias to specialist ores + Firm shortfall steal

**What to build:** Factions bias raid targets toward veins of their specialist ores. The Firm, predatory by nature, raids to steal an ore it consumes when its holdings of that ore stay under target for a run of days. The steal is open at any stance except Partner, prefers veins of that ore, and counts as a hostile act.

**Blocked by:** 04 — Escalation framework + raid rung.

**Relevant files:** `systems/faction_ai.gd`, `systems/factions.gd` (`_pick_target_vein`), `systems/raiding.gd`, `systems/faction_sim.gd` (`ore_reserve`, holdings), `data/constants.json`, `tests/test_faction_ai.gd`, `tests/test_raiding.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 33–34. REFERENCE.md §3.12.

**Status:** ready-for-agent

- [ ] Test (seeded): among equal candidates, the raid pick prefers the attacker's primary/secondary ore.
- [ ] Rollover test: the Firm short on an ore for N days queues a steal on a vein of that ore at Neutral, but never at Partner.
- [ ] Constants in JSON. REFERENCE and CODEMAP updated.
