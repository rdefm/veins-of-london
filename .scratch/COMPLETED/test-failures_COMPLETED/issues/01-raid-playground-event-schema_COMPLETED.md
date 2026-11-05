# 01 — Diagnose and fix raid_playground event schema/content failures

**Status:** ready-for-agent

**What to build:** `data/events/raid_playground.json` fails event schema validation, which cascades to every test that validates shipped data. Diagnose the cause (likely the playground migration in `f94ee366` item-event-effects-22: cards missing `label`/`speaker`, choices missing `effects`) and fix the data (or the schema, if the data is intentionally new-format). Then fix the two playground gameplay tests that fail alongside it: the blast spend/alert count is off by one, and a script error reads `.check` on a dict at `tests/test_raid_playground.gd:82`.

**Relevant files:** `data/events/raid_playground.json`, `systems/events.gd`, `autoload/GameData.gd` (validate), `tests/test_raid_playground.gd`, `tests/test_events.gd`, `tests/test_recipe_knowledge.gd`, `tests/test_gamedata.gd`, `tests/test_faction_incidents.gd`, `docs/writing-guide.md`, REFERENCE.md event schema section

**Failing tests (all pre-existing, not caused by london-market-04):**
- `test_events.gd`: `schema_all_event_files_validate`
- `test_gamedata.gd`: `real_data_loads_and_validates`
- `test_faction_incidents.gd`: `data_validates_and_every_trigger_resolves`
- `test_recipe_knowledge.gd`: `content_lint_accepts_the_op`
- `test_raid_playground.gd`: `blasting_the_hall_door_spends_a_blast_and_raises_alert` (got 1, expected 0 / got 0, expected 1), `the_blasted_gate_needs_and_spends_a_blast` (got 1, expected 0), plus SCRIPT ERROR "Invalid access to key 'check'" at line 82

- [ ] Root cause identified and noted in the ticket
- [ ] `GameData.validate()` returns no errors for raid_playground
- [ ] All seven tests above pass

**Root cause:** 012359e5 content rewrite left c18/c19 without label/speaker, two requires-only options (Use a Skeleton Key c5, Cut the camera signal) without effects, dropped `optional: true` from the two Blast requires (item never spent/alert never raised), and removed the "Guess the door code" option the prophets-breath test targeted (test deleted).
