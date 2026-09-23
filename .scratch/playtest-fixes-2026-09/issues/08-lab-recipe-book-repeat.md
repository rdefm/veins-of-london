# 08 — Lab: Recipes book lists found recipes, tap to repeat

**What to build:** Tapping the Recipes notebook on the lab bench opens a list of every recipe the player has found. Tapping a recipe repeats it (crafts it) using the existing cost, chance and batch rules, with clear feedback on success, failure or unaffordability. The Experiments notebook stays a separate book and keeps its role (per-pairing survey notes). Both books open reliably when tapped.

Playtest: tapping a notebook showed no options.

**Blocked by:** 07 — shares the lab bench tap handling and notebook mode code.

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (`_tap_notebook_and_maybe_open_modal`, notebook regions)
- `systems/lab_bench_nav.gd` (`tap_notebook`, `MODE_RECIPES`, `MODE_EXPERIMENTS`)
- `scenes/modals/lab_bench_recipe_book_modal.gd`, `lab_bench_notes_modal.gd`, `lab_bench_modal_helpers.gd`
- `systems/bench.gd` (`found_recipe_keys`), `systems/crafting.gd` (`attempt_craft`)

**Status:** ready-for-agent

- [ ] Tapping the Recipes notebook always opens the recipe book, listing all found recipes (empty-state text if none)
- [ ] Tapping a recipe crafts it; result/feedback shown; unaffordable recipes shown disabled with reason
- [ ] Tapping the Experiments notebook always opens the survey-notes modal
- [ ] Tests cover notebook → modal routing; human on-device QA list in report
