# 19 — Factions buy from the Collective

**What to build:** A daily step lets other factions buy Root Feed from the Collective's for-sale stock at market quote, paying from their resources. It is blocked while at war with the Collective. Limits are data-driven placeholders.

**Blocked by:** 18

**Relevant files:** `systems/faction_sim.gd`, `systems/market.gd`, `systems/factions.gd`, `systems/time_system.gd`, `data/factions.json`, `tests/test_faction_sim.gd`, REFERENCE.md §1.8 `data/factions.json`, daily order

**Status:** ready-for-agent

- [ ] Stock moves to the buyer and resources are paid at market quote
- [ ] The Collective is paid
- [ ] Factions at war with the Collective cannot buy
- [ ] The Collective's reserved stock and the stock limit are respected
- [ ] REFERENCE.md daily order is updated
