# 02 — Conserved tiered stock

**What to build:** London's stock becomes real. Item stock is held per tier, 1 to 5, and ore stays untiered. Stock changes only through recorded and nameless flows: fixed reversion and the Independents buy cover are gone. Nameless demand falls as price rises, down to a floor. Independents supply rises as price rises, up to a cap, and enters across tiers by a data-driven mix. A new public availability read gives what can be traded per good and tier today. Existing saves move across once with no price jump. Archie's sell lane and the sell-at-market event op put goods into stock at their own tier.

Prices and shortfalls may run rough on `main` until ticket 11. Faction trades can enter at a simple default tier until ticket 04.

Spec: `.scratch/london-market/spec.md`, "Market module", "Schema", delivery step 2. Stories 1-6, 8-11, 16-19, 21, 25, 43, 84-86.

**Blocked by:** 01

**Relevant files:** `systems/market.gd`, `data/market.json`, `systems/shares.gd`, `systems/economy.gd`, `systems/events.gd`, `systems/barometer.gd`, `autoload/SaveManager.gd`, `autoload/GameState.gd`, `scripts/sim_faction_economy_impl.gd`, `tests/test_market.gd`, `tests/test_savemanager.gd`, `tests/test_rewind.gd`, `tests/test_shares.gd`, `CONTEXT.md`, REFERENCE.md §3.13 London market, §3.14 Shares

**Status:** ready-for-agent

- [ ] Each good keeps one quote; the price curve reads total stock across tiers
- [ ] A tier's price is the quote × the existing quality multiplier
- [ ] Stock is conserved: with no flows it does not move, and with flows the change equals their sum
- [ ] Nameless demand falls as price rises, with a floor; it draws across tiers in proportion to stock, in deterministic whole units
- [ ] Independents supply rises as price rises, stops at its cap, and enters by the data-driven tier mix
- [ ] `independentsShare` stays 0.3 and `independentsOreShare` stays 0.4; `normalStock` rises to about 14 days of civilian demand
- [ ] Availability per good and tier = stock + today's supply − today's demand, floored at 0
- [ ] Items with no tier enter as tier 1; multi-target items enter as their base item at their tier
- [ ] Ticker effects, story rises and derived ore demand still move prices
- [ ] Shares credits Independents with what they actually supplied
- [ ] Old saves are migrated once, rescaled to the new `normalStock` and split by the tier mix, with prices steady
- [ ] One tiered stock change round-trips through save and Rewind; results repeat under the same seed
- [ ] All new state is pure data; all new numbers are data-driven placeholders
- [ ] REFERENCE.md §3.13 and §3.14 are updated; `CONTEXT.md` defines London market and Guild Marketplace
