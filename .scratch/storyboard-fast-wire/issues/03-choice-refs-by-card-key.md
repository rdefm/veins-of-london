# 03 — Choice refs and choice memory by card key

**What to build:** A `choice` condition names the earlier choice card by its key, not its position, and the game remembers picks by card key. Inserting or reordering cards in an event no longer breaks conditions in other events. The index form is gone: lint and boot validation reject it. `buyer`'s refs to `cold_open` use the key. No save migration — old saves' index-keyed choice memory may be ignored. Both editors that author `choice` conditions (storyboard tool, mobile quest editor) write the key form.

**Blocked by:** 02 — Live cards carry stable keys.

**Relevant files:** `systems/events.gd` (`_remember_choice`, `choice_record`, `choice_id`, condition evaluation `"choice"` branch, `choose`), `autoload/GameState.gd` (choices backfill comment ~L397), `data/events/buyer.json`, `data/events/cold_open.json`, `tests/test_event_content_lint.gd` (`_lint_choice_ref`), `tests/test_events.gd` (choice-memory cases), the "Choice mechanics (shared)" section in `tools/storyboard.html` and `tools/quest-editor-mobile.html` (+ `tools/quest-editor.html` if 07 hasn't landed), `tools/test_quest_editor.js`, REFERENCE.md §2 (`choices` row), §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] Picks are remembered under the card's key; Rewind still drops a rewound pick
- [ ] `choice` condition resolves by card key; index form fails lint and boot validation
- [ ] `buyer.json` refs use `cold_open`'s key; inserting a card before it in a test copy keeps `buyer`'s options gated correctly (test)
- [ ] Shared mechanics section authors the key form and stays byte-identical across editors
- [ ] REFERENCE.md §2 and §3.9a updated
- [ ] Full suite + `scripts/check_all.sh` green
