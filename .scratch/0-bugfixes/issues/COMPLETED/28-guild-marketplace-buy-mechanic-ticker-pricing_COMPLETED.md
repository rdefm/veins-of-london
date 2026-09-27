# 28 — Marketplace buy mechanic + ticker-driven spread pricing

**What to build:** No "buy" mechanic exists anywhere today — only `Economy.execute_sale()` (`systems/economy.gd`, the Archie lane) exists, which already reads `Barometer.get_effective_ore_price()` (`systems/barometer.gd`) for ticker-driven base prices. Add a general buy mechanic for calc/related goods that computes price as `effective_base_price * (1 + spread)`, where `spread` is +15% on buy / -15% on sell at zero Guild relationship, narrowing toward 0% as Guild relationship increases (formula/curve is new — no existing precedent narrows a multiplier by relation; closest analog is the flat 0.7× `securityContactUnlocked` discount in `hq.gd`, not reusable directly). This ticket is the pricing/transaction system only — the marketplace UI and membership gate are ticket 29.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A buy function exists (e.g. in `systems/economy.gd`) mirroring `execute_sale()`'s shape, deducting `cash` and adding inventory on success.
- [ ] Both buy and sell prices for the marketplace read `Barometer.get_effective_ore_price()`/equivalent ticker-effective base price.
- [ ] A relation-to-spread curve is implemented: spread = ±15% at `state.factions.guild.relation` == join threshold, narrowing toward 0% as relation increases (exact curve shape/cap — get human sign-off if not specified, don't invent silently).
- [ ] `economy` tests cover: buy price above ticker base, sell price below ticker base, spread narrowing as relation increases, insufficient-cash rejection on buy.
