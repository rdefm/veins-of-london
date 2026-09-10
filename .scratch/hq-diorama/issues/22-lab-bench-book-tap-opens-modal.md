# 22 — Lab bench: tapping a notebook opens its modal directly

**What to build:** `scenes/screens/hq_lab_bench.gd`'s `_on_zone_tapped()`
currently only sets the session mode on a notebook tap
(`LabBenchNav.tap_notebook()`, growing the region's label to "(open)");
opening the actual modal (`Modal.open("lab_bench_recipe_book")` /
`Modal.open("lab_bench_notes")`) requires a second tap on the separate
"Recipe book"/"Notebook" button `_build_mode_button()` renders once a mode
is held. Change so tapping a notebook sets the mode AND opens its modal in
the same tap. Remove `_build_mode_button()` and its button entirely — the
modal is only ever reachable by tapping the book itself (i.e. by arrowing
back to the books stop); there is no shortcut on the apparatus stop.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Tapping `notebookRecipes` sets Recipes mode and opens `lab_bench_recipe_book` in one tap
- [ ] Tapping `notebookExperiments` sets Experiments mode and opens `lab_bench_notes` in one tap
- [ ] `_build_mode_button()` and its rendered button are removed from every stop
- [ ] `tests/test_hq_lab_bench.gd` updated: notebook-tap tests assert the modal opens; mode-button tests removed
