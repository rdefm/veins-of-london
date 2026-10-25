# 03 — Triage and fix the 7 individual test FAILs

**What to build:** After 02, rerun and re-triage the 7 cases that failed in the poisoned run; fix each that still fails, document any that were cascade-only.

Cases: `every_event_fires_and_plays_through_from_debug_start_without_errors` (debug_tools.gd:69 `'contacts'` on Dictionary), `learn_all_recipes_grants_every_recipe_at_the_top_rung`, `learn_recipe_grants_exactly_that_rung` (got 0, expected 3), `attempt_craft_movement_success_records_the_chosen_ore_type_as_attunement_and_tier_from_skill`, `attempt_craft_movement_failure_leaves_no_partial_movement`, `apply_option_prospect_forwards_to_Sites_prospect_and_reports_ok_true_on_success`, `excludeIfFlag_drops_the_entry_once_the_flag_is_true`.

**Blocked by:** 02 — Stop one erroring case from poisoning the suite.

**Relevant files:** `systems/debug_tools.gd` (L~69 `prepare_event`), recipe-knowledge, crafting and district-events tests (grep the case names under `tests/`).

**Status:** ready-for-agent

- [ ] Each case passes, or has a written reason it was cascade-only and now passes
- [ ] Full suite + `scripts/check_all.sh` green
