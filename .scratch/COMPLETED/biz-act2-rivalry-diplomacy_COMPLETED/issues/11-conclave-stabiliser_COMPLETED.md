# 11 — Conclave stabiliser

**What to build:** London's market steadies itself. When a good's price stays beyond ±X% of normal for N days, the Conclave counter-trades: it buys the crash or sells into the spike. The trade is bigger than plain arbitrage and accepts a loss, funded by the Conclave's non-calc income. It goes through Market recording with a Conclave annotation.

**Blocked by:** 03 — Pressure + relation drift.

**Relevant files:** `systems/faction_ai.gd` (Conclave step), `systems/faction_sim.gd` (`_arbitrage`, `_buy`, `_sell`), `systems/market.gd` (`price_series`, `record_*`), `systems/time_system.gd`, `data/constants.json`, `SaveManager` (run counters), `tests/test_faction_ai.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` story 63, §Conclave. REFERENCE.md §3.1, §3.13.

**Status:** ready-for-agent

- [ ] Rollover test: a price held above the band for N days triggers a Conclave sell, and the Conclave's cash/holdings show it traded at a loss against value.
- [ ] Rollover test: a crash triggers a Conclave buy. Short excursions trigger nothing.
- [ ] Run counters are saved. Thresholds in JSON. REFERENCE §3.1 step and CODEMAP updated.
