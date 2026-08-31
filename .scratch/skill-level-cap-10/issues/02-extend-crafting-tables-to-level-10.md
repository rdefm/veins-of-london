# 02 — Extend crafting's effectPower/price tables to level 10

**What to build:** Crafting recipes' `effectPower` arrays (`data/recipes.json`, one per recipe, 28 recipes total) currently have exactly 6 entries (index 0–5, matching the skill 0–5 range). With the level-10 cap from ticket 01, `effectPower(r) = r.effectPower[skill]` will index out of range for skill 6–10 — this must not crash or silently misbehave.

Extend every recipe's `effectPower` array from 6 to 11 entries (index 0–10), with placeholder/extrapolated values for levels 6–10 continuing that recipe's existing growth pattern, clearly flagged **TBD, needs a human balance pass**.

`qualityTier()`'s refine-tier path (`refineStep`) is uncapped already (REFERENCE.md: "Not capped — a refine tier can climb past 5") and needs no change. `qualityPriceMultiplier(tier) = 1.0 + 0.25*(tier-1)` is also an uncapped linear formula and needs no code change — but document in this ticket's report that it now naturally produces 3.25× at tier 10 (previously 2.0× was "the top skill tier"), flagged for balance sign-off since no one has confirmed that's an intended price ceiling.

**Blocked by:** 01 — Extend XP curves for all four skills to level 10 (players must be able to reach skill 6–10 for this to matter).

**Status:** ready-for-agent

- [ ] Every recipe in `data/recipes.json` has an 11-entry `effectPower` array (index 0–10), with levels 6–10 flagged TBD/placeholder in a comment.
- [ ] Crafting at skill levels 6–10 succeeds and applies the extended `effectPower` value, verified by a test.
- [ ] `qualityPriceMultiplier`'s derived tier-10 value (3.25×) is called out explicitly in the ticket's completion report for balance sign-off — no code change to the formula itself unless directed.
- [ ] No index-out-of-range or crash when crafting at any skill level 1–10.
