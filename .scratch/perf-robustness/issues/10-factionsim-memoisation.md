# 10 — FactionSim memoisation (byte-identical sim)

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** Daily-tick faction trade/craft does less repeated work: cached `calc_cost` by recipe+skill, a withholding set built once per `trade()`, traded goods computed once per faction per pass. `held()`/`reserve()` values that trades mutate are NOT cached. No formula changes.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/faction_sim.gd` (`trade`, `craft`, `reserve`, `ore_reserve`, `traded_goods`), `systems/faction_ai.gd` (`is_withholding`), `systems/crafting.gd` (`calc_cost`), `scripts/sim_faction_economy.gd`, `scripts/profile_block_end.gd`; review §2.5

**Status:** ready-for-agent

- [ ] Baseline `JSON.stringify(GameState.state).hash()` from a fixed-seed `sim_faction_economy.gd` run recorded BEFORE changes; identical after
- [ ] Daily-tick time before/after reported
- [ ] Existing faction tests pass
