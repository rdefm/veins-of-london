# 04 — Faction trade uses real stock

**What to build:** Factions trade through London's real shelves. The daily trade has two passes: every faction sells, then every faction buys, so one faction's surplus can reach another the same day. Factions sell at the tiers they hold and are paid each tier's price. They buy the lowest available tier first, receive goods at that tier, and pay only for what they received. On a short shelf the first faction served rotates by day. An empty shelf leaves a faction short through the existing shortfall path. Every market move is limited by availability. No new AI and no war rule are added.

Spec: `.scratch/london-market/spec.md`, "Faction trade", delivery step 4. Stories 7, 12-14, 22-24, 26-35, 38-40.

**Blocked by:** 02

**Relevant files:** `systems/faction_sim.gd`, `systems/time_system.gd`, `systems/market.gd`, `systems/faction_ai.gd`, `systems/shares.gd`, `tests/test_faction_sim.gd`, `tests/test_faction_ai.gd`, `tests/test_market.gd`, REFERENCE.md §1.8 `data/factions.json`, §3.13 London market, §3.14 Shares, §3.1 Time, rest, daily tick (daily_tick order)

**Status:** ready-for-agent

- [ ] A faction's sale can be bought by another faction on the same day
- [ ] Sellers enter stock at held tiers and are paid per tier
- [ ] Buyers take the lowest available tier first; goods reach holdings at that tier
- [ ] Wallets are charged only for goods actually received
- [ ] The first faction served rotates by day, seeded stably for Rewind
- [ ] Daily buys, deny, stabiliser, stock-up, arbitrage and positions cannot exceed availability
- [ ] Flood, undercut and deny act on real stock
- [ ] An empty shelf produces the existing shortfall behaviour
- [ ] A faction runs short when the only crafter of a good stops selling it
- [ ] A faction reselling goods the player sold it adds them to London stock; a faction fed directly buys less
- [ ] Factions at war still trade in London
- [ ] Results repeat under the same seed
- [ ] REFERENCE.md §1.8, §3.13, §3.14 and the daily order are updated
