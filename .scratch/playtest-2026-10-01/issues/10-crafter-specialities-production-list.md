# 10 — Crafter specialities; production lists all eligible unlocked recipes

**What to build:** BizBrief Production only offers 3 items because `Rooms.RECIPE_UNLOCK_FLAGS` is a hardcoded 3-recipe table. Give each crafter a list of speciality ore types (data, per contact); James = time + life. A crafter can produce any recipe that is unlocked for the player AND whose ore inputs are all within their specialities (time-only, life-only, time+life for James). Existing skill-level gates still apply. Replace the hardcoded table with the general unlock rule.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/rooms.gd` (RECIPE_UNLOCK_FLAGS, producer crafting step), `scenes/phone_apps/bizbrief_app.gd` (~L336 production recipe rows), `systems/contacts.gd`, `systems/crafting.gd`, `systems/bench.gd` (recipe unlock state), `data/constants.json` (contacts), `data/recipes.json`, `autoload/SaveManager.gd` (backfill), REFERENCE.md R§3.10 lab/production.

**Status:** ready-for-agent

- [ ] Speciality data per crafter; James time+life; save backfill
- [ ] Production list = unlocked recipes whose inputs are all within specialities; tested with mixed recipes
- [ ] Rooms step crafts newly listed recipes
- [ ] CODEMAP + REFERENCE updated
- [ ] Human check: Production shows all James's eligible unlocked recipes
