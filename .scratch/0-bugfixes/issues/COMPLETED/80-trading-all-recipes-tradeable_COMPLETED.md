# 80 — Trading: make all 14 recipes tradeable, not just 2

**What to build:** Guild and Collective trade lanes already loop generically over every priced consumable — the UI isn't hardcoded to time pearls. Only `timePearl` and `enhancementPowder` currently have a sale price, so the other 12 craftable recipes (`rewind`, `healingSalve`, `blast`, `shield`, `blackHole`, `prophetsBreath`, `beALady`, `pansPrank`, `healingBurst`, `failsafe`, `rejuvenation`, `wormhole`) are invisible to every trade lane. Give every craftable recipe a sale price so all 14 show up as sellable goods. No curation — combat consumables are tradeable the same as utility ones; it's the player's call whether to sell off combat stock.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] All 14 craftable recipes have a sale price entry.
- [ ] **Needs balance sign-off**: proposed prices for the 12 missing recipes, based on each recipe's existing crafting cost/XP reward for a defensible relative ordering — flag specific numbers for human review before/at completion (same convention as tickets 71/73).
- [ ] Any existing cross-reference validation between recipes and prices still passes (or is updated if it was asserting the old 2-recipe state).
- [ ] Guild marketplace test confirms all 14 recipes render as goods rows (Guild and Collective lanes).
