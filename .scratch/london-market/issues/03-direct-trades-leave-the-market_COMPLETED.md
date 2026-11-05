# 03 — Direct trades leave the market

**What to build:** Trades between the player and a faction stop touching London. Faction lanes and business calc purchases move goods and money between the two parties and record nothing in Market tallies. Tag-along deals and contract deliveries stay outside the market as they are. Their price effect now comes only from what the faction does next.

Decided: FactionAI's undercut targeting keeps reading the player's sales from `Market.sold_this_week`. A player who sells only through faction lanes can therefore not be targeted. This is accepted, because those goods never reached London. Archie and Soho sales still count.

Spec: `.scratch/london-market/spec.md`, "Routes" table, delivery step 3. Stories 36-41.

**Blocked by:** 01

**Relevant files:** `systems/economy.gd`, `systems/contracts.gd`, `systems/faction_ai.gd`, `systems/market.gd`, `tests/test_economy.gd`, `tests/test_market.gd`, `tests/test_faction_ai.gd`, REFERENCE.md §3.6a Faction shops, §3.13 London market

**Status:** ready-for-agent

- [ ] Selling to or buying from a faction leaves Market tallies unchanged
- [ ] Business calc purchases leave Market tallies unchanged
- [ ] Goods and money still move correctly between player and faction
- [ ] Archie sales and the sell-at-market event op still record to the market
- [ ] Tag-along deals and contract deliveries still record nothing
- [ ] `sold_this_week` covers market routes only, and undercut targeting works from it with no special case
- [ ] Authored tests and comments that assumed a price effect from direct trades are updated
- [ ] REFERENCE.md §3.6a and §3.13 are updated
