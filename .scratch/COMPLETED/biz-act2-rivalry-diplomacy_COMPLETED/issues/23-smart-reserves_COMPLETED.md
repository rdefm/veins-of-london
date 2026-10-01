# 23 — Smart reserves

**What to build:** Faction stock becomes a weapon. Reserve targets are dynamic. A faction stockpiles ahead of a planned flood or raid, hoards on Ticker hints, and withholds supply to squeeze a target.

**Blocked by:** 05 — Producer market moves.

**Relevant files:** `systems/faction_sim.gd` (`ore_reserve`, `item_reserve`, `reserve`, `_sell_surplus`), `systems/faction_ai.gd` (planned moves), `systems/barometer.gd` (hints), `data/constants.json`, `tests/test_faction_sim.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` story 35, §FactionSim.

**Status:** ready-for-agent

- [ ] Rollover test: a planned flood raises the flooder's reserve of that ore in the days before.
- [ ] Rollover test: a Ticker hint on a good raises reserves of it.
- [ ] Existing faction_sim tests still pass. Constants in JSON. CODEMAP updated.
