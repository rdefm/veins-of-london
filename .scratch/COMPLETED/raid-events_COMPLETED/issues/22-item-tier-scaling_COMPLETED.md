# 22 — Item tier scaling in events

**What to build:** A rolled event item effect gets stronger with the tier of the item spent, so max-level items can reach the raid calibration targets (proposal §1.4–1.5: max skill + full max-tier kit ≈ 90% clean run). Scaled: `bonus` amount, `bypass` base chance, and an item's cover-roll odds. No-roll effects don't scale (they already succeed). The toggle spends the highest tier held, with no new UI; the odds breakdown shows the scaled value. Item-boosted checks clamp at 0.97 instead of the default 0.95; ordinary checks keep 0.95. Multipliers are placeholders in data (e.g. Powder T1 +0.15 → max tier ≈ +0.33).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`apply_item_effect()` ~L808, `active_toggles()`, `choose()` consume ~L359–411, `check_odds()`), `systems/crafting.gd` (tier-bucketed inventory, `use_one`), `data/constants.json` (`eventChecks`), `tests/test_event_items.gd`, `.scratch/raid-events/raid-variants-proposal.md` §1.4–1.5, REFERENCE.md §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] Scaling table and the item-boosted clamp documented in R§3.9a
- [ ] Tests: holding T1 and T3 spends T3 and applies the T3 value; bonus, bypass base and cover odds scale; no-roll effects identical at every tier; an item-boosted check can reach 0.97, a plain check caps at 0.95; existing item tests pass
