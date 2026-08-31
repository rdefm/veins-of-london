# 01 — Extend XP curves for all four skills to level 10

**What to build:** Crafting, cultivating, combat, and stealth skills currently cap at level 5. Raise the cap to level 10 for all four by extending each skill's XP-threshold table, so a player can actually grind and see the skill climb past 5 in play.

The level-up mechanism (`systems/progression.gd`'s `Progression.award_xp()`) already derives its cap from `levels.size() - 1` rather than a hardcoded `5` — no code change is needed to raise the cap itself. This ticket is a data-only change: extend the four XP curve arrays from 6 entries (index 0–5) to 11 entries (index 0–10):
- `CULTIVATING_XP_LEVELS` (`data/vein_growth.json`'s `cultivatingXpLevels`)
- `CRAFTING_XP_LEVELS` (`data/recipes.json`'s `craftingXpLevels`)
- `COMBAT_XP_LEVELS` (`data/enemies.json`'s `combatXpLevels`)
- `STEALTH_XP_LEVELS` (`data/stealth.json`'s `stealthXpLevels`)

The new thresholds for levels 6–10 are placeholder values (continue the existing curve's growth pattern) — mark them clearly as **TBD, needs a human balance pass** in a code comment. This ticket unblocks players reaching levels 6–10 at all; it does not need to make those levels mechanically meaningful yet (tickets 02/03 in this feature and the stealth formula handle that).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `CULTIVATING_XP_LEVELS`, `CRAFTING_XP_LEVELS`, `COMBAT_XP_LEVELS`, `STEALTH_XP_LEVELS` each have 11 entries (index 0–10), with levels 6–10's thresholds flagged TBD/placeholder in a comment near the data.
- [ ] A player who grinds enough XP in each of the four skills actually reaches level 10, verified by a test (extending the existing pattern in the relevant `tests/test_*.gd` files).
- [ ] No other code changes required to raise the cap — `Progression.award_xp()` is untouched.
- [ ] Stealth's success-chance formula (`Raiding.stealth_success_chance()`, a continuous formula, not a table) is confirmed to behave sanely (clamped 0.0–1.0) at skill 10 — no table needed there, just a sanity check.
