# Ticket 01 verification — 2026-09-13

Runtime: Godot 4.7 stable (`5b4e0cb0f`), Windows headless. Test saves isolated from player saves.

- All 18 touched GDScript files pass the required autoload-aware syntax checker.
- `scripts/run_tests.sh`: **2293 passed, 8 failed**.
- Separate pre-change copy, retaining existing unrelated event edits: **2289 passed, the same 8 failures**. No new failing tests.
- Four additional cases cover all phases/markers, automatic rollover, Rest, save export/import, free/blocked labels, the real Evening Train button (one tick/XP award), and the paid/free event choices.
- Existing screen tests also exercise map/list, HQ/bench, Train/refine and notification/bag behavior with the updated labels.
- `scripts/check_all.sh` additionally discovers four unrelated Android template test scripts under `android/build/src/instrumented/assets/`; they require Android test classes unavailable to desktop syntax checking. Touched-file checks are clean.

## Existing test failures

- `col_a1_archie_pry_debt_names_the_exact_amount_and_date`
- `play_ko_holds_on_its_fallen_faded_pose_instead_of_reverting_to_idle`
- `add_money_control_adds_the_entered_amount_to_cash`
- `add_calc_control_adds_the_entered_amount_to_the_selected_ore_type`
- `debug_screen_lists_a_relation_control_for_every_contact_and_faction_regardless_of_lock_state`
- `contact_relation_control_calls_award_relation_with_the_entered_delta`
- `locked_contact_relation_control_still_calls_award_relation`
- `faction_relation_control_calls_adjust_player_relation_with_the_entered_delta`

Both runs also report existing runtime errors in `tests/test_debug_start.gd:47` (int/bool comparison), `scenes/screens/phone.gd:325` (off-tree timer; twice), and `tests/test_raiding.gd:560` (empty array). Existing engine resource-leak diagnostics also remain. These unrelated failures were not changed.

## Human checks still required

390px portrait and notched/gesture-nav device: full phase/day and cash fit; sun/moon and all three marker states readable without colour; bag/notifications/content do not overlap; Evening paid labels fit on map/list, Train, jobs, event choices and bench; blocked/free actions have no time-cost suffix; Rest and experiment captions remain readable over artwork; reload/rollover return the correct clock.

PROSE-REVIEW: `data/constants.json.dayClock`.

Ticket remains `ready-for-human`, not `_COMPLETED`: the repository's all-tests-pass requirement is blocked by the verified pre-existing failures, and device QA remains outstanding. Ticket 02 has not been implemented.
