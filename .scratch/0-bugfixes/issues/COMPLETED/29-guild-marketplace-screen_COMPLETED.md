# 29 — Guild marketplace screen, membership-gated

**What to build:** A new screen where the player can buy and sell calc (and related goods) through the Guild, using the buy/sell pricing system from ticket 28. Gated behind Guild membership (`state.factions.guild.joined`, set via the existing `Factions.join()`/`can_join()` mechanic — the dedicated questline gate from ticket 33 will refine this later, but this ticket ships against the existing generic relation-threshold join so it isn't blocked on the questline). Non-members see the screen is locked/unavailable rather than the trading UI.

**Blocked by:** 28 — needs the buy mechanic and spread pricing system.

**Status:** ready-for-agent

- [ ] New marketplace screen lists tradeable goods (calc/ore types + related consumables — confirm exact catalog with the human if not obvious from existing sellable items) with live buy/sell prices from ticket 28's system.
- [ ] Screen is only reachable/usable when `state.factions.guild.joined` is true; non-members get a locked/"become a Guild member" state instead of the trading UI.
- [ ] Buying and selling from the screen correctly updates `cash` and inventory, and reflects ticker/relation-driven price changes live.
- [ ] New screen tests cover: locked state for non-members, successful buy/sell updating state, price display reflecting the ticket 28 formula.
