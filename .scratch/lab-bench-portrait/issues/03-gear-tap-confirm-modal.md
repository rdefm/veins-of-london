# 03 — Gear-tap confirm modal, notebook mode dropped

**What to build:** After picking ore, tapping a piece of gear opens a small modal. Which modal depends on the pairing's history (the ore set + approach cell state), not on a held notebook:

- **Untried, or tried with no find yet (`hot`)** → probe modal: ore held per selected type, probe cost (per-type), Confirm. No +/−. Confirm runs the probe, then the existing probe-result card. If the probe is blocked (e.g. not enough calc), Confirm is disabled and shows the reason.
- **Known recipe (`found`)** → craft modal: recipe name, ore held per type, cost per craft, a +/− quantity stepper (same stepper and batch-qty state as the recipe book), total cost, and Confirm ×N via the existing batch craft. Confirm is disabled with a reason when unaffordable.
- **Tested, does nothing (`inert`)** → warning modal ("Nothing here. Already confirmed."), no action.
- **No ore selected** → toast "Pick an ore type first." (as today)

Drag jar→gear triggers the same modal as a tap.

Notebook mode is removed: `labBenchNav.mode`, `LabBenchNav.tap_notebook()` and `MODE_*` go. The Recipes and Experiments books just open their existing modals. The "(open)" labelling goes.

Ready gear (any legal probe, or a found recipe, for the current selection) gets the gold selected-style outline. One status line in the band below the table summarises the selection, e.g. "Time + Life · Burner ready".

Discovery rule §5.6 still holds: nothing enumerates the 15 type sets.

**Blocked by:** 02 — Single-screen portrait bench

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` — `_run_apparatus()`, `_on_zone_tapped()`, `_tap_notebook_and_open_modal()`, `_filter_and_label_apparatus_regions()`, `_selected_ore_cost_label()`
- `systems/lab_bench_nav.gd` — `tap_notebook()`, `MODE_*`, `open()`
- new `scenes/modals/lab_bench_confirm_modal.gd` (register wherever the other `lab_bench_*` modals are registered for `Modal.open`)
- `scenes/modals/lab_bench_modal_helpers.gd`, `scenes/modals/lab_bench_recipe_book_modal.gd` (stepper + Craft ×N pattern), `scenes/modals/lab_bench_probe_result_modal.gd`
- `systems/bench.gd` — `cell_state()`, `find_recipe_for_cell()`, `discovery_cost()`, `probe_block_reason()`, `probe()`
- `systems/crafting.gd` — `calc_cost()`, `get_craft_qty()`, `adjust_craft_qty()`, `attempt_craft_batch()`, craft block reason
- `autoload/GameState.gd` — `labBenchNav` default drops `mode`
- tests: `tests/test_hq_lab_bench.gd`, `tests/test_lab_bench_nav.gd`, `tests/test_gamestate.gd`, new modal test
- `docs/hq-diorama-vision.md` §5.2 notebooks/mode, §5.3 arming rule, §5.4 cost communication
- `CODEMAP.md` — new modal row, updated `lab_bench_nav.gd` / `hq_lab_bench.gd` rows

**Status:** ready-for-agent

- [ ] untried/hot cell → probe modal without stepper; Confirm probes once and shows the result card
- [ ] found cell → craft modal with stepper; Confirm ×N crafts N via batch; disabled + reason when unaffordable
- [ ] inert cell → warning modal, no ore spent
- [ ] Drag jar→gear opens the same modal
- [ ] Notebook mode fully removed; books still open their modals
- [ ] Ready-gear outline + status line reflect the current selection
- [ ] Vision doc §5.2–5.4 updated; CODEMAP updated; full suite green
- [ ] PROSE-REVIEW: modal copy + status line strings
- [ ] Human on-device check: each of the three modal variants, stepper, outline, status line
