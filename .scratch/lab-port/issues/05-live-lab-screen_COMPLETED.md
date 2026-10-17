# 05 — Live Lab screen replaces the lottery UI

**What to build:** The HQ Lab zone shows the prototype's Lab plate and recipe book, wired to the live Lab system and real calc, instead of the lottery bench. The book lists only known recipes by ore tab; each recipe page shows the procedure as known (exact steps with band, vague as faded region + direction word, unknown hidden), best rank, an empty reserved ladder region, Craft manually, and batch (with multi when unlocked). Craft manually docks the book under the plate; jars show real calc counts and only the recipe's jars are tappable; apparatus pop their gauges; Finish shows result and clues; Rewind is offered. Screens only render and call Lab/Crafting. Spec: `.scratch/lab-port/spec.md` § Screens, user stories 3–7, P4.

**Blocked by:** 03, 04

**Relevant files:**
- `scenes/screens/bench_prototype.gd` (source plate, jars, gauges, docked book, recipe page, result view), `tests/test_bench_prototype_screen.gd` (prior art)
- `scenes/screens/hq_lab_bench.gd`, `scenes/modals/lab_bench_recipe_book_modal.gd`, `scenes/modals/recipe_book_page.gd`, `scenes/modal_layer.gd`, modal registry
- new `tests/test_lab_screen.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] HQ Lab zone opens the live plate + book; lottery gear/confirm flow no longer reachable
- [ ] Jar badges show real calc; only the run recipe's jars tappable during a run
- [ ] Recipe page: known procedure rendering, best rank, empty ladder region, Craft manually, batch (gated on performed once), multi (gated rank 3)
- [ ] Craft manually docks the book; Finish shows result + clues; crack shows lost-calc result
- [ ] Rewind action available per the Lab system's rules
- [ ] No state mutation in screen code
- [ ] Smoke test: plate builds with real calc, Craft manually docks, Finish shows result
- [ ] Report lists on-device QA checks (gauge feel, layout); `PROSE-REVIEW:` any new recipe-page copy
