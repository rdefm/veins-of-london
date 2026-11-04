# 87 — Fix the save/load round-trip failures

**What to build:** Diagnose and fix the root cause of the save round-trip failures so saving, loading and exporting reproduce state exactly. Fails at HEAD with no local changes: 15 cases in `test_savemanager.gd` (`save_mutate_load_round_trips_exactly`, `export_string_is_compressed_and_round_trips_identical_state`, `export_string_reimports_to_an_equal_state`, the `..._round_trips_<field>_as_int(s)` cases for bankLog, messages, sites, mapSlotFreePool, offer quotes, mapView, home guardCount, home tenure/arrears, combat locationKey, contact salesSkill/XP, plus `guard_cost_history_backfills_empty_and_round_trips_with_int_values` and `pending_guard_shortfall_backfills_null_round_trips_and_rewinds`). Likely the same cause: `faction_resources_round_trip_through_save_load`, `full_playthrough_tutorial_economy_ticks_and_save_roundtrip`, `reduced_motion_holds_destination_frame_and_preference_survives_load`. Suspect a recently added state key not normalised on load (ints returning as floats) or a new key missing from backfill. Fix code or test, whichever is wrong; don't weaken assertions. Use a fork subagent for diagnosis.

**Blocked by:** None — can start immediately.

**Relevant files:** `autoload/SaveManager.gd` (`_int_key`, `_int_dict_values`, backfill), `autoload/GameState.gd`, `tests/test_savemanager.gd`, `tests/test_base.gd`

**Status:** ready-for-agent

- [ ] Root cause written in the commit message
- [ ] All listed save/export/round-trip cases pass
- [ ] The three probably-related cases pass or have their own diagnosed cause
