# 14 — Shared test helpers

**What to build:** Helpers re-implemented across test files — playing an event through to completion, playing to a choice and finishing after it, building a synthetic site or vein, synthesising a tap — exist once under the test support directory and every test file uses that copy. Behaviour of every test is unchanged; the suite runs in the same time.

**Blocked by:** None — can start immediately.

**Relevant files:** `tests/support/` (new helper script(s)), `tests/test_base.gd`, and the duplicating files: `tests/test_col_a1_*.gd`, `tests/test_events.gd`, `tests/test_event_screen.gd`, `tests/test_district_events.gd`, `tests/test_sites.gd`, `tests/test_raiding.gd`, `tests/test_map_*.gd`, `tests/test_hq_lab_bench.gd`. Find the full set with a grep for duplicate `func _` names across `tests/`.

**Status:** ready-for-agent

- [x] No private helper function name is defined in more than one test file.
- [x] Same number of test cases run and pass as before; suite wall-clock within 10%.
- [x] `tests/test_base.gd` or a support script documents the shared helpers in a one-line-each header.

## Progress log (2026-09-18, session 1 — WIP, uncommitted, nothing verified yet)

**Baseline (clean tree, before any edits):** `scripts/run_tests.sh` = 61s wall, `TOTAL: 2472 passed, 1 failed`. The 1 pre-existing failure is `test_playthrough.gd :: full_playthrough_tutorial_economy_ticks_and_save_roundtrip` (save-roundtrip dict mismatch) — NOT caused by this ticket.

**Done so far (all in working tree, LF line endings, not yet syntax-checked or test-run):**

New support scripts under `tests/support/` (static funcs, each has a one-line-per-helper header; test files use them via `const X := preload("res://tests/support/x.gd")` inserted right after `extends`):
- `event_play.gd` (`EventPlay`): `play_event(id, ctx={})`, `play_to_choice(id)->int`, `finish_after_choice(id, idx)`, `play_through_choice(id)`, `play_event_with_choices(id, choices)`.
- `fixtures.gd` (`Fixtures`): `site(id, ore, tier, claimed=false, faction_vein=null, district="shoreditch", bonuses=[])`, `site_with_vein(id, vein)`, `player_vein(id, site_id, district, ore, growth, tier, bonuses=[])`, `player_vein_with(overrides)`, `alarmed_vein(id, district, ore)`, `seed_vein(id, growth, ore="life")`, `seed_faction_vein(id, growth, faction="collective", ore="life")`, `enemy(name, hp, hp_max, koed, speed, is_mugging=false, ability=null)`, `ally(name, hp, hp_max, koed, speed=10)`, `dial(keys, cur, max)`, `dial_with_loaded(key, tier, charge)`, `install_objectives(entries)`, `has_notification(text)`.
- `node_query.gd` (`NodeQuery`): `label_texts`, `label_texts_with_symbols`, `symbol_row_texts`, `effective_text`, `find_button`, `find_button_by_effective_text`, `button_texts`, `find_tiles`.
- `ui_sim.gd` (`UiSim`): `synthetic_tap`, `tap_at`, `touch(index, pressed, pos)`, `drag(index, pos)`, `tap_zone(screen, zone_id)`, `advance(node, seconds)`.
- `seed_search.gd` (`SeedSearch`): `find_seed_for(max_tries, fn)` (snapshot/restore variant; the two no-restore copies in weather/objectives both `GameState.reset()` inside fn so behaviour is identical).

~60 test files rewritten: local duplicate defs removed, call sites → `Module.fn(`. Arg reshuffles done: `test_turn_order_strip.gd` enemy calls got `false` inserted before the `ability` arg; `test_touch_scroll_container.gd` `_touch(i, pos, pressed)` → `UiSim.touch(i, pressed, pos)`; `test_cultivating.gd` `_site(id, district, claimed)` → `Fixtures.site(id, "physics", "fair", claimed, null, district)`; hakim_done/nadia_done `_site(id, district, ore, tier)` → `Fixtures.site(id, ore, tier, true, null, district)`; objectives `_vein(id, growth)` → `Fixtures.player_vein(id, "s1", "shoreditch", "time", growth, "fair")`; `test_phone_bizbrief.gd` got a local `_brief_vein()` wrapper over `player_vein_with`.

Genuinely-different helpers that shared a name were RENAMED (file-local, unique): events `_faction_vein_of_level`, factions `_faction_vein_claimed_on`, raiding `_faction_vein_of_growth`, map_screen `_faction_vein_with`, objectives `_faction_vein_sold` (sites keeps `_faction_vein`), turn_order_strip `_site_held_by`, district_events `_district_site`, playthrough `_soak_site` (sites keeps `_make_site`), map_canvas `_canvas_vein` (cultivating keeps `_vein`), vein_trade `_seed_tiered_vein`, modal_layer `_find_cost_button`. `test_col_a1_archie_pry.gd` keeps its own no-arg `_play_to_choice()` (asserts cardIndex==2; now unique).

Verified: `grep -hoE "^(static )?func _[a-z_0-9]*" tests/*.gd | sed 's/static //' | sort | uniq -c | awk '$1>1'` → empty (acceptance box 1 met on paper).

Orphaned comment blocks that sat above removed helpers were deleted; stale comment mentions were rewritten to the `Module.fn` names.

## Session 2 (2026-09-18) — closed out

1. Deleted the stale `test_col_a1_tuition.gd` comment; also tidied the same file's `const` block (blank line between `Fixtures`/`EventPlay` preloads) and 5 other files with the same `add_const`-insertion blank-line artifact (`test_alarm_presentation.gd`, `test_col_a1_des_report.gd`, `test_col_a1_hakim_done.gd`, `test_col_a1_weather.gd`, `test_raid_alarms.gd`, `test_time_transition.gd`).
2. Skimmed the full diff for orphaned comments — none found beyond the tuition.gd one above; the rest of the "comment, blank, code" shapes are pre-existing legitimate const-documentation comments, not artifacts of this ticket.
3. `godot --headless -s scripts/check_runner.gd` clean on all 60 touched files + 5 new support files; `scripts/check_all.sh` clean (lint_tokens.sh flags in `map_canvas.gd` are pre-existing/unrelated to this diff).
4. `scripts/run_tests.sh`: `TOTAL: 2472 passed, 1 failed` — same count and same pre-existing failure as baseline.
5. `/code-review` (Standards + Spec axes): Spec axis found zero issues (all 3 acceptance criteria independently re-verified). Standards axis found one hard violation — `test_playthrough.gd`'s `_soak_site` comment claimed "GDScript test files ... have no import mechanism between them," which this very ticket falsifies — reworded to state the helper's actual distinguishing shape instead. No other action items.
6. CODEMAP.md: confirmed no update needed — it already documents `tests/support/` generically without listing individual files, matching the pre-existing `draw_spy.gd` precedent.
