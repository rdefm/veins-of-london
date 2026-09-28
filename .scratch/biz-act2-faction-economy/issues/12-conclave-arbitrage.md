# 12 — Conclave arbitrage

**What to build:** The Conclave buys goods quoted under `arbBuyMult` × base and sells what it holds over `arbSellMult` × base, capped by its cash and a daily volume limit, recorded as demand/supply with source `conclave`. No other faction arbitrages. Stability / anti-aggressor goals stay 4a.

Placeholders: 0.7×, 1.3×, volume cap — JSON.

Spec: §Buying and selling (Conclave arbitrage).

**Blocked by:** 11 — Faction buying/selling + real cash.

**Relevant files:**
- `systems/faction_sim.gd`, `data/factions.json`, `systems/market.gd`
- Tests: `tests/test_faction_sim.gd`
- REFERENCE.md §1.8, §3.13

**Status:** ready-for-agent

- [ ] Conclave buys a crashed good and sells a spiked one
- [ ] Capped by cash and daily volume
- [ ] No other faction arbitrages
- [ ] REFERENCE.md updated
