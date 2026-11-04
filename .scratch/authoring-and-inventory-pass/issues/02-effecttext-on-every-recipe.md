# 02 — `effectText` on every recipe

**What to build:** Every recipe has a plain one-line statement of what it does, so sellers and the Bag can both show it. 35 of 43 recipes lack one today. Numbers in each sentence must match the item's real behaviour.

**Blocked by:** None — can start immediately

**Relevant files:** `data/recipes.json`, `systems/active_effects.gd` (existing reader), `data/lab.json`, `data/vein_growth.json`, `docs/CONTENT-GUIDE.md`, `docs/writing-guide.md`, `tests/test_gamedata.gd`

**Status:** ready-for-agent

- [ ] All 43 recipes have non-empty `effectText`
- [ ] A data test fails if any recipe lacks it
- [ ] Existing effect text still renders where it did
- [ ] Copy follows CONTENT-GUIDE.md and writing-guide.md, with vein cultivation language and no gardening vocabulary
- [ ] Task report flags the file with `PROSE-REVIEW:`
