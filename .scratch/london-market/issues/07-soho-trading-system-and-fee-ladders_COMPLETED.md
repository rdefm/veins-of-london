# 07 — Soho trading system and fee ladders

**What to build:** A new Soho system lets the player buy and sell ore and items by tier against London stock. Separate sell and buy fee ladders live in data, set by order value across the whole cart, and a rung's rate applies to the whole order. The first sell rung is Archie's current fee plus a small margin, and high rungs can fall below it, down to a floor. The system gives pure rows for the current order: rung and % rate, £ fee, net result, next rung's threshold and rate, £ and units still needed, the full ladder, and Archie's comparable fee. The business Act 1 closing event sets a new unlock flag, and loading a save past that event backfills it.

Spec: `.scratch/london-market/spec.md`, "Soho Marketplace", "Trading screen", delivery step 6. Stories 46, 50-58, 59-61, 63-65, 69-70, 94.

**Blocked by:** 02

**Relevant files:** new `systems/soho.gd`, new `tests/test_soho.gd`, `systems/market.gd`, `systems/economy.gd`, `systems/stash.gd`, `systems/crafting.gd`, `data/market.json`, `data/events/biz_a1_closing.json`, `autoload/SaveManager.gd`, `autoload/GameState.gd`, `CODEMAP.md`, `CONTEXT.md`, REFERENCE.md §3.6 Selling (Archie lane), §3.13 London market, §2 STATE SCHEMA

**Status:** ready-for-agent

- [ ] Buying is limited by availability and cash; selling is limited to the shared pool
- [ ] Purchases reach the shared pool at the tier bought; stashed goods cannot be sold
- [ ] Sold items enter stock at their own tier; better tiers earn more
- [ ] Soho never sells multi-target items
- [ ] No mugging, relation gain or Archie cut applies
- [ ] Rung thresholds count the whole cart, across goods and tiers
- [ ] The fee rows match exactly what is charged
- [ ] First-rung sell fee is above Archie's; top rungs can beat it, and never pass the floor
- [ ] Rows give next-rung data, and show the top rung as the best rate
- [ ] Buying then reselling loses money at every rung and tier, proved by test
- [ ] Soho sales count as player supply in `Market.sold_this_week`
- [ ] The unlock flag is set by the closing event and backfilled on load where that event is complete
- [ ] Fee values are data-driven placeholders
- [ ] `CODEMAP.md`, `CONTEXT.md` (Soho Marketplace) and REFERENCE.md are updated
