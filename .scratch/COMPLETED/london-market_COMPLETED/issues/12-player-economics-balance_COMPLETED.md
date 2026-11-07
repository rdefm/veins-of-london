# 12 — Player economics balance

**What to build:** Check and tune the market from the player's side. Income through Archie stays comparable at a similar stage. Soho's ladders keep small sales with Archie and bulk with Soho, and flipping loses money everywhere. Root Feed supply can meet faction demand. Report before and after tables for human sign-off.

There is no daily buy cap. If depth and fees do not limit flipping, report it rather than adding a cap.

Spec: `.scratch/london-market/spec.md`, "Balance outcomes", "Soho Marketplace", delivery step 9. Stories 15, 59-61, 79, 93-94.

**Blocked by:** 07, 11

**Relevant files:** `data/market.json`, `systems/soho.gd`, `tests/test_soho.gd`, `scripts/sim_faction_economy.gd`, `scripts/sim_faction_economy_impl.gd`, `.scratch/london-market/baseline.md`, `.scratch/london-market/balance-report.md`, REFERENCE.md §3.6 Selling (Archie lane), §3.13 London market

**Status:** ready-for-agent

- [ ] Player income through Archie stays comparable at a similar stage, against baseline
- [ ] Buying then reselling in Soho loses money at every rung and tier with final values
- [ ] Soho costs more than Archie at small volumes, and top rungs can beat him
- [ ] A sustained player corner moves a price materially
- [ ] Root Feed supply can meet faction demand
- [ ] Before and after tables are added to `.scratch/london-market/balance-report.md` for human sign-off
- [ ] Final fee values are written into REFERENCE.md
