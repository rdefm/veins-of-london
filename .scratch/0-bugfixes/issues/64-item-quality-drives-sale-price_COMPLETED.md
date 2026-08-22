# 64 — Item quality drives sale price

**What to build:** No "quality" concept exists anywhere in the data model today — crafted items are tracked as flat per-recipe counts, `player["inventory"][recipe_key] = player["inventory"].get(recipe_key, 0) + 1` (`systems/crafting.gd:67`), with no memory of the crafting skill/effect-power tier an individual crafted batch was made at. Per the human: quality should be derived from the same thing that already varies a consumable's effect — `effect_power(recipe_key, skill)` (`crafting.gd:29-36`, indexes each recipe's `effectPower` array by skill 0-5, or a Bench-refined value where applicable). Sale price (`Economy.execute_sale()`, `systems/economy.gd:18-74`, consumable branch `:49`, currently `round(GameData.CONSUMABLE_PRICES.get(item_type, 30) * (1.0 + price_mod))` with no skill/quality input at all) should scale with that same tier.

This is a genuine inventory-schema change, not just a formula tweak — flagged as the riskiest ticket in this batch. Flat `inventory[recipe_key] = count` must become tier-bucketed (e.g. `inventory[recipe_key] = { tier: count }`) so quality survives from craft-time to sale-time. Existing saves have the old flat-int shape; the load path must handle that gracefully (e.g. treat a bare int as an untiered/legacy bucket) rather than crashing on old saves.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `player["inventory"][recipe_key]` restructured to track quantity per quality tier (tier = the `effect_power` skill-index/refined-tier at craft time), rather than a flat count.
- [ ] `Crafting.attempt_craft()` records the tier achieved on each successful craft into the correct bucket.
- [ ] `Economy.execute_sale()`'s consumable price path scales `CONSUMABLE_PRICES` by the sold item's tier (higher tier = higher price), on top of existing `price_mod`/ticker logic.
- [ ] Every other reader of `player["inventory"][recipe_key]` (bag/inventory UI, crafting-availability checks, event effects, etc.) updated for the new tier-bucketed shape — audit all call sites, don't just patch crafting/economy.
- [ ] `SaveManager` load path handles pre-existing saves where `inventory[recipe_key]` is a bare int (legacy shape) without crashing — migrate it into the new shape (e.g. as an untiered/tier-0 bucket) on load.
- [ ] `docs/REFERENCE.md` inventory schema (§2) and sale-price formula (§3.5-ish) updated to document the new tier-bucketed shape and price-by-tier rule.
- [ ] New tests: crafting at different skill levels produces different tiers in inventory; selling different tiers of the same item yields different prices; loading a legacy flat-int save doesn't crash and migrates correctly.
- [ ] Manual check noted for the human: craft the same consumable at low and high crafting skill, confirm both are tracked distinctly and sell for different prices; load an old pre-this-ticket save and confirm inventory isn't lost/corrupted.
