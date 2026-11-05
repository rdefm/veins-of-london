# 11 — Market balance pass

**What to build:** Tune the new market until the sim proves its central promise: one sale barely moves a price, and sustained control of a good moves it a lot. This includes resolving the supply gap estimated in the spec, where sinks reach about 2,700/day against about 2,330/day of supply, either through more harvest or lower sinks. Report before and after tables for human sign-off.

Faction wallet growth is reported only. Do not fix it unless the human asks.

Spec: `.scratch/london-market/spec.md`, "Balance outcomes", "Further Notes", delivery step 9. Stories 10, 12, 87-92, 95.

**Blocked by:** 03, 04, 05, 06

**Relevant files:** `data/market.json`, `data/factions.json`, `data/vein_growth.json`, `scripts/sim_faction_economy.gd`, `scripts/sim_faction_economy_impl.gd`, `scripts/sim_ai_guard.gd`, `.scratch/london-market/baseline.md`, REFERENCE.md §3.13 London market "Pinned values"

**Status:** ready-for-agent

- [ ] Named producers are 65-75% of item supply at rest, across at least 3 seeds
- [ ] Ore named share stays close to baseline
- [ ] No good is pinned at minimum or maximum price at rest
- [ ] No faction is in permanent shortfall of something it needs
- [ ] Sim runs show that withholding moves a price materially and a single sale does not
- [ ] Turf, rivalry and diplomacy stay healthy against baseline
- [ ] Faction wallet growth is reported
- [ ] Before and after tables are saved in `.scratch/london-market/balance-report.md` for human sign-off
- [ ] Final values are written into REFERENCE.md
