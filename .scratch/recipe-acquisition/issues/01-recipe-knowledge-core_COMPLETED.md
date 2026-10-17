# 01 — RecipeKnowledge core: rungs, ceilings, grant op, collision fallback

**What to build:** A new `RecipeKnowledge` system that owns recipe acquisition on top of the ported Lab's knowledge. For each recipe it reports which knowledge-ladder rungs the player holds (`base`, `hint1`, `hint2`, `master`), each hint/master rung as unknown / vague / exact, and the rank ceiling that knowledge allows. Events and quests grant a rung through it, and also through a new event op `grant_recipe_rung { recipe, rung, specificity }` (specificity defaults to exact). Granting knowledge the player already holds is never a silent dud; it falls back (see criteria). A per-recipe master-source table (source NPC/faction id or null, pointer text or null) is added to data; no quest uses it yet.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "New RecipeKnowledge system module", "Recipe data", § Further Notes (collision branch).

**Blocked by:** None — can start immediately.

**Relevant files:**
- new `systems/recipe_knowledge.gd`, new `data/recipe_knowledge.json`
- `systems/lab.gd` — `grant_recipe`, `grant_steps`, `rung_steps`, `step_specificity`, `is_known`
- `data/lab.json` — `procedures.*.hints[].rung`, `specificities`, `rankThresholds`
- `systems/events.gd` — effect `match` (~l.950, next to `grant_recipe` / `grant_recipe_steps`)
- `autoload/GameData.gd` (load + validate new data file)
- `scripts/content_lint` / events lint (new op must be recognised)
- new `tests/test_recipe_knowledge.gd`; prior art `tests/test_lab*.gd`
- `CODEMAP.md`; `docs/REFERENCE.md` — new § "Recipe knowledge ladder" (rungs, ceilings, state, op)

**Status:** ready-for-agent

- [ ] A rung is "owned" when all its hidden steps are at least vague, and "exact" when all are exact. `base` is owned exactly when the recipe is known.
- [ ] Rung → rank ceiling (base 2, hint1 3, hint2 4, master 5) is read from data. A query returns a recipe's current ceiling.
- [ ] `grant_rung(recipe, rung, specificity)` grants the recipe if it's unknown (for `base`) and that rung's steps at that specificity. Vague→exact upgrades in place; a lower specificity than held changes nothing.
- [ ] Event op `grant_recipe_rung` calls `grant_rung`, default exact. Content lint accepts it.
- [ ] **Collision fallback:** if a grant from a source (NPC/faction id passed with the grant) would teach nothing new, it instead grants an equivalent item from the same source: same rung on another recipe that source sells / is master-source for, that the player doesn't hold yet. If the source has nothing left, it awards crafting XP plus a relation bump with that source, and returns an acknowledgement line. Amounts and line are in data. The result reports which path was taken so events can show the line.
- [ ] Master-source table in data covers all 17 recipes (entries may be null). A query returns source + pointer, with null pointer → "???".
- [ ] Headless tests: ceilings per rung, grant/upgrade/no-op, op via the events runner, every collision path, master table lookup.
- [ ] REFERENCE § and CODEMAP rows added. PROSE-REVIEW: acknowledgement line(s).
