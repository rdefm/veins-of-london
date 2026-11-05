# 14 — Ore supply: targeted faction veins and Independents ore share

**What to build:** Close the ore and item gaps left by ticket 11 without the global `factionYieldMult`. Give factions more veins where their crafting is short of ore, mainly Life for Guild and Conclave (so Rejuvenation, Failsafe, Good Year, Healing Burst can be made), plus a few Physics/Fate where seeds pin those ores. Raise the Independents ore share so factions lean on Independents for ore while still dominating item crafting. Remove `factionYieldMult` (or set it to 1.0) once veins carry the load. Re-run the 3-seed sim and report before/after against the ticket 11 report.

Decisions already made with the human:
- Prefer more veins over a harvest multiplier; targeted by ore, not global.
- Factions may rely on Independents for a larger share of ore. The "ore named share close to baseline" target is relaxed on purpose. Item named share target stays 65-75%.
- Open for the agent to confirm with the human before building: the day-one roster is a code constant; adding veins means adding sites/districts data, which touches turf, presence and claim weights. If the roster should move to data, ask first (CLAUDE.md: no numbers in code).

Spec: `.scratch/london-market/spec.md` "Balance outcomes", "Further Notes". Report: `.scratch/london-market/balance-report.md` ("Open" list).

**Blocked by:** 11 (done).

**Relevant files:** `.scratch/london-market/balance-report.md`, `data/vein_growth.json` (`factionYieldMult`, `factionPruneThreshold`), `data/market.json` (`independentsOreShare`, ore `civilianDemand`), `data/sites.json`, `data/districts.json`, `systems/factions.gd` (`DAY_ONE_ROSTER`, `seed_day_one_veins`), `systems/faction_sim.gd` (`_prune`, crafting, trade), `scripts/sim_faction_economy.gd` and `_impl.gd`, `tests/test_faction_sim.gd` (prune yield test reads `factionYieldMult`), REFERENCE.md §1.8 Day-one roster and fieldwork, §3.13 London market "Pinned values".

**Status:** ready-for-agent

- [ ] Guild and Conclave hold Life veins; Conclave is no longer in permanent shortfall of Rejuvenation or Failsafe across 3 seeds
- [ ] No good pinned at min or max price at rest across 3 seeds
- [ ] Item named share is 65-75% across 3 seeds
- [ ] Ore named share reported against baseline; the lower, relaxed figure is stated for human sign-off
- [ ] `factionYieldMult` is removed or 1.0, and REFERENCE.md is updated
- [ ] Turf, rivalry and diplomacy stay healthy against baseline (no zero-turf faction, no runaway leader)
- [ ] Faction wallet growth is reported (not fixed)
- [ ] Before and after tables are appended to `.scratch/london-market/balance-report.md`
- [ ] CODEMAP.md updated if any file's responsibility changes
