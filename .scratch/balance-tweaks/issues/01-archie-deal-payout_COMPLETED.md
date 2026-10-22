# 01 — Archie tag-along deals pay more (20–100 ore base)

**What to build:** Archie's occasional tag-along deals pay far too little. Raise the deal size's base range from 5–25 units to **20–100 units** of ore. Keep the rest of the shape: size doubles per £5,000 of player cash up to the existing tier cap, sold at Archie's price, player gets 50% of gross, same offer-chance curve. Move the deal constants (chance curve, tier step/cap, quantity range, cut share) out of code into data.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/archie_deals.gd` (`QTY_BASE_MIN/MAX`, `TIER_*`, `CHANCE_*`, `roll_deal`, 50% cut)
- `data/constants.json` (or a suitable data home) for the moved constants
- `autoload/GameData.gd` (load + validation)
- `systems/economy.gd` (`get_archie_ore_price`)
- `tests/test_archie_deals*.gd`
- `.scratch/0-bugfixes/issues/95-archie-tag-along-deal-offers.md` (current mechanics)
- REFERENCE (add the deal constants where Archie's deals are documented, or §3 economy)

**Status:** ready-for-agent

- [ ] Tier-0 deal rolls 20–100 units; tier n rolls (20–100) × 2^n (tests)
- [ ] No deal number left in code; all in data
- [ ] REFERENCE documents the numbers
- [ ] Report a small table: cash level → typical player cut, before vs after
