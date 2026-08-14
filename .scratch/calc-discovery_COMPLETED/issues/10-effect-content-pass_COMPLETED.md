# 10 — Effect content pass

**What to build:** Real, discoverable content behind the schema tickets 01–09 built — populate `data/recipes.json` with the vision-doc §11 effect catalogue's `discovery` (types + approach) and `refineStep` cell assignments, so pairings actually contain something to find. `timePearl`, `enhancementPowder`, and `rewind` get real `discovery` cells plus tutorial-grant marking so they start `Found` on a fresh save rather than `Untried`. **Also wires refinement's effect on actual crafted potency** — ticket 05 built `Bench.refined_value()` but nothing calls it yet, so today refining an effect costs ore and climbs a tier with zero effect on what gets crafted. This ticket is the first place real `refineStep` data exists to close that gap against, so it closes it rather than leaving it for later.

**Blocked by:** 09 — Bench notes screen.

**Status:** ready-for-agent

- [ ] Every effect in vision-doc §11 gets a `discovery: { "types": [...], "approach": "..." }` field on its recipe, placing it in a specific, real cell — enough prose/description to demonstrate the schema and let the effect be discovered and shown correctly, not a full content-polish pass.
- [ ] Every effect gets a `refineStep` appropriate to that effect (healing amount, freeze duration, passive duration, etc. — whatever field makes sense for that specific effect).
- [ ] `timePearl`, `enhancementPowder`, `rewind`: real `discovery` cells assigned (so they're census-counted and refinable like any other effect) plus a `taughtBy`/tutorial-grant marker so a fresh save's Lab cells for these three start `found`, not `untried`.
- [ ] No triple-type sets authored (schema tolerates an array of types; only single/pair are used at launch).
- [ ] **Resolve the `effectPower` schema collision, then wire it:** existing recipes already use `effectPower` as an array indexed by crafting skill (`[0, 1, 1, 2, 2, 3]`, `data/recipes.json`), but `Bench.refined_value()` (`systems/bench.gd`) assumes a scalar it can add `refineStep.add * tier` to — calling it on a skill-array `effectPower` throws a runtime type error (`Array + int` isn't valid). Decide whether Lab-discovered effects stack refinement on top of the skill array (effective power = `effectPower[skill] + add * tier`) or keep refined fields scalar and separate from the skill-indexed convention, then update `Crafting.effect_power()` (`systems/crafting.gd:23`) to consult `Bench.refined_value()` for any recipe with a `refine` tier > 0. Applies to any refined field actually authored in this pass, not just `effectPower` specifically.
- [ ] `tests/test_bench.gd` or a new content-integrity test: every recipe with a `discovery` field resolves to a valid types+approach combination; the three tutorial recipes start in `found` state on a fresh `player.bench`.
- [ ] `tests/test_crafting.gd` extended: crafting a recipe at a refine tier > 0 produces the refined potency, not the base value; crafting at tier 0 is unaffected (regression check against the existing skill-array behaviour).
- [ ] Syntax check clean on all touched files; `data/recipes.json` remains valid JSON.

**PROSE-REVIEW:** all new effect names/descriptions are new prose against `docs/CONTENT-GUIDE.md` — flag explicitly, this is the largest prose surface in the whole feature.
