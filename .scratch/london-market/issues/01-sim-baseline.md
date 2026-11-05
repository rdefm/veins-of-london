# 01 — Sim baseline

**What to build:** The headless faction economy sim reports what the current market actually does with items, so later balance work has a real before picture. It reports item flows, stock by good, and named-producer share of item and ore supply, then records a baseline across at least 3 seeds. No market behaviour changes.

Spec: `.scratch/london-market/spec.md`, delivery step 1 and "Further Notes" (baseline, scale of change).

**Blocked by:** None — can start immediately

**Relevant files:** `scripts/sim_faction_economy.gd`, `scripts/sim_faction_economy_impl.gd`, `systems/market.gd`, `systems/shares.gd`, `systems/faction_sim.gd`, `.scratch/london-market/spec.md`, REFERENCE.md §3.13 London market, §3.14 Shares

**Status:** ready-for-agent

- [ ] Sim output reports daily item flows by source: faction sales, faction buys, Independents, nameless demand, player
- [ ] Sim output reports named share of item supply and of ore supply, plus days at minimum or maximum price per good
- [ ] Sim output reports faction shortfalls and wallet growth
- [ ] Reporting can show stock by tier once tiered stock exists, without a further rewrite
- [ ] Sim runs use an isolated user data folder, so autosaves do not touch real saves
- [ ] Baseline tables for at least 3 seeds are saved in `.scratch/london-market/baseline.md`
- [ ] No market, faction or price behaviour changes
