# 06 — Opportunity rows: expiring offers, demand spikes, favours

**What to build:** Opportunity tier rows for: pending Sales offers expiring within 1 day (action opens the offer); goods the player holds whose current demand modifier is ≥ the data threshold (default +25%), with a Sell button opening the Trade sheet; open faction favour requests (action opens the key member's thread). Rows drop off when the offer is taken/lapses, demand falls, stock is sold, or the favour is answered.

**Blocked by:** 01 — Tracer: DailyBrief projection + Today card.

**Relevant files:** `systems/offers.gd` (`pending_offers`, `is_expired`, expiry days), `data/offers.json`, `systems/market.gd` (`demand_modifiers`), `systems/barometer.gd` (item-demand multipliers), `systems/diplomacy.gd` (`pending_for`), `systems/phone_nav.gd` (`select_conversation`), `scenes/modals/modal_layer.gd` (sell_menu / Trade), `systems/daily_brief.gd`, `data/daily_brief.json`, `tests/test_daily_brief.gd`. REFERENCE.md §3.10 "Favours", §3.13 "London market".

**Status:** ready-for-agent

- [ ] Offer row only when expiry ≤ window (data, default 1 day)
- [ ] Demand row only for held goods at/above threshold (data, default +25%); boundary tested
- [ ] Favour row per open request
- [ ] Each action routes to the expected destination
- [ ] Opportunity rows excluded from `badge_count()`
