# 57 — Crafting quantity +/- batch UI

**What to build:** The crafting screen (`scenes/screens/lab.gd:149`) currently offers only a single-shot "Craft one" button calling `Crafting.attempt_craft(recipe_key)` (`systems/crafting.gd:51`), which takes no quantity param and crafts exactly one item per call (one ingredient deduction, one success roll, one inventory increment). Add +/- controls to pick a quantity, then a single craft action that calls `attempt_craft()` that many times in a row, each attempt rolled and reported individually (not one pooled success chance) — matching the human's explicit request. Naturally capped by available ingredients: if a mid-batch attempt can't afford its ingredients, the batch stops there rather than erroring.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Crafting UI (`lab.gd`) gains +/- controls to select a quantity before crafting.
- [ ] A single "Craft" action loops `Crafting.attempt_craft(recipe_key)` the selected number of times, each call independently rolled per existing logic — no change needed to `attempt_craft()` itself.
- [ ] Batch stops early (rather than erroring) if `can_craft()` returns false partway through, and the UI reports how many of the requested quantity actually completed.
- [ ] Result display shows a per-attempt breakdown (success/fail for each), not just an aggregate count.
- [ ] New test covering a multi-item batch, including a batch that runs out of ingredients partway through.
- [ ] Manual check noted for the human: craft a batch of e.g. 5 at once, confirm each is rolled individually and results are legible.
