# 10 — Effect content pass

**What to build:** Real, discoverable content behind the schema tickets 01–09 built — populate `data/recipes.json` with the vision-doc §11 effect catalogue's `discovery` (types + approach) and `refineStep` cell assignments, so pairings actually contain something to find. `timePearl`, `enhancementPowder`, and `rewind` get real `discovery` cells plus tutorial-grant marking so they start `Found` on a fresh save rather than `Untried`.

**Blocked by:** 09 — Bench notes screen.

**Status:** ready-for-agent

- [ ] Every effect in vision-doc §11 gets a `discovery: { "types": [...], "approach": "..." }` field on its recipe, placing it in a specific, real cell — enough prose/description to demonstrate the schema and let the effect be discovered and shown correctly, not a full content-polish pass.
- [ ] Every effect gets a `refineStep` appropriate to that effect (healing amount, freeze duration, passive duration, etc. — whatever field makes sense for that specific effect).
- [ ] `timePearl`, `enhancementPowder`, `rewind`: real `discovery` cells assigned (so they're census-counted and refinable like any other effect) plus a `taughtBy`/tutorial-grant marker so a fresh save's Lab cells for these three start `found`, not `untried`.
- [ ] No triple-type sets authored (schema tolerates an array of types; only single/pair are used at launch).
- [ ] `tests/test_bench.gd` or a new content-integrity test: every recipe with a `discovery` field resolves to a valid types+approach combination; the three tutorial recipes start in `found` state on a fresh `player.bench`.
- [ ] Syntax check clean on all touched files; `data/recipes.json` remains valid JSON.

**PROSE-REVIEW:** all new effect names/descriptions are new prose against `docs/CONTENT-GUIDE.md` — flag explicitly, this is the largest prose surface in the whole feature.
