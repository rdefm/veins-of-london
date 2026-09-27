# 145 — Sliders for trade and Production

**What to build:** The quantity slider from 144 replaces the +/− steppers in trade and Production:
- Sell menu, both directions: selling maxes at what the player holds; buying maxes at the lower of what the player can afford and the lane's stock. Rows that start unselected today keep a "not chosen" (0) position; otherwise default 1.
- Guild marketplace quantity: same buy rule.
- BizBrief Production targets: the ±5 buttons become a slider 0..50 (cap 50 lives in data, set via the rooms system; existing saves above 50 clamp on load).

**Blocked by:** 144 — Quantity slider, used for crafting.

**Relevant files:** `scenes/modals/sell_menu_view.gd` (~L241-263 stepper, ~L346 buy max), `scenes/screens/guild_marketplace.gd` (~L80), `scenes/phone_apps/bizbrief_app.gd` (~L282 target row), `systems/economy.gd` (`adjust_sell_qty`, `adjust_marketplace_qty`, `get_faction_buy_max_qty`), `systems/rooms.gd` (`adjust_lab_threshold`), `autoload/SaveManager.gd`; REFERENCE.md §3.6 "Selling", §3.10 (Production targets).

**Status:** ready-for-agent

- [ ] Sell slider max = held qty; buy slider max = min(affordable, lane stock); tested
- [ ] Marketplace slider uses the same buy max; tested
- [ ] Production target clamps 0..50; old saves above 50 clamp on load; tested
- [ ] Human on-device: sell menu buy + sell rows, guild marketplace, BizBrief Production target — drag each to max and check the limit
