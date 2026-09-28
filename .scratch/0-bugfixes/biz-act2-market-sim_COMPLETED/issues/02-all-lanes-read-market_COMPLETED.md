# 02 — Every lane reads the London price

**What to build:** Every player-facing money figure reads Market instead of base price + Barometer ore price. Archie lane consumables price at quote (then quality, district mod, cut) and record supply. Faction buy/sell lanes price at quote (+ district mod where configured) with spread/relation on top; player sells record supply, player buys record demand. Contract "buy missing calc" purchases record demand. Offers' per-unit value and James's craft-job `payPerItem` use quote. Archie tag-along deals price at quote and record nothing. Vein sale / buyout valuation uses the 2-day average quote. Faction AI vein scoring and raid strength stay on `basePrice`. Nothing calls Barometer's ore-price functions afterwards (their deletion happens in 03).

Known interim gap: between this ticket and 03, the Ticker doesn't move prices. Accepted.

**Blocked by:** 01 — Market core + Archie ore lane.

**Relevant files:**
- `systems/economy.gd` (~lines 95, 265–275: Archie consumables, faction lane pricing)
- `systems/contracts.gd` (~line 345, buyCalc via `Economy.get_faction_buy_price`)
- `systems/offers.gd` (`unit_value`, ~lines 135–145), `systems/jobs.gd` (`payPerItem`), `systems/archie_deals.gd` (~line 77), `systems/vein_trade.gd` (~line 18, `quote`)
- Leave alone: `systems/factions.gd`, `systems/raiding.gd` (basePrice scoring)
- Tests: `tests/test_economy.gd`, `test_contracts.gd`, `test_offers.gd`, `test_jobs.gd`, `test_archie_deals.gd`, `test_vein_trade.gd`
- `docs/REFERENCE.md` §3.6 Selling (Archie lane), plus faction-lane pricing and vein-sale valuation wherever they live

**Status:** ready-for-agent

- [ ] Archie consumable sale and faction lane sell/buy prices equal the quote-derived price; supply/demand recorded with the player as source
- [ ] buyCalc purchase records demand
- [ ] Archie deal priced at quote; market tallies unchanged by it
- [ ] Offer unit value and job pay follow quote after a reprice
- [ ] Vein sale uses 2-day average
- [ ] No remaining caller of `Barometer.get_effective_ore_price` / `get_ore_price_modifier` (grep clean)
- [ ] REFERENCE.md §3.6 and related sections updated
