# 06 — Delete the lottery bench

**What to build:** One way to craft. The lottery bench system, its cells/census/probes/survey notes/tier progress, the lottery modals and the player's chance-roll craft path are deleted. The approaches data survives only as the apparatus list. Remaining references (`item_tier`, `found_recipe_keys`, `grant_effect`, `quality_tier`) point at Lab equivalents. FactionSim's crafting curve stays. Spec: `.scratch/lab-port/spec.md` § Module structure "Bench (lottery)", user story 40.

**Blocked by:** 05

**Relevant files:**
- `systems/bench.gd`, `systems/lab_bench_nav.gd`
- `scenes/modals/lab_bench_confirm_modal.gd`, `lab_bench_probe_result_modal.gd`, `lab_bench_notes_modal.gd`, `lab_bench_recipe_detail_modal.gd`, `lab_bench_modal_helpers.gd`, `craft_result_modal.gd`, `craft_batch_result_modal.gd` (if lottery-only)
- `systems/crafting.gd` (`attempt_craft`, `attempt_craft_batch`, `craft_chance`, `quality_tier`; keep `faction_craft_chance` + faction `calc_cost`)
- `autoload/SaveManager.gd` (bench migrations), `autoload/GameState.gd` (survey/notes state), `autoload/GameData.gd`, `data/approaches.json`
- `systems/collective.gd`, `systems/objectives.gd` (comments referencing `attempt_craft`)
- `tests/test_bench.gd`, `tests/test_lab_bench_confirm_modal.gd`, `tests/test_lab_bench_nav.gd`, `tests/test_recipe_book.gd`, `tests/test_multi_target.gd`, `tests/test_modal_layer.gd`, `tests/test_savemanager.gd`
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Lottery system, nav, modals and their tests deleted; no remaining references (grep clean)
- [ ] Survey/notes/cell state removed from the state tree
- [ ] Approaches data holds the apparatus list only, no cells
- [ ] Player chance-roll craft path gone; FactionSim crafting unchanged and its tests pass
- [ ] CODEMAP bench + lottery-modal rows deleted
- [ ] check_all + full suite green
