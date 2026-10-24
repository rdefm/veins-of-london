# 04 — ? context modal; % always

**What to build:** An option that has context behind it gets a ? symbol in a circle at the right-hand end of its button. Tapping the ? (not the button) opens a modal explaining the decision:

- **Check options:** the % chance of success (always a percentage, never a hint word), tries, and every modifier with its source and signed delta — items, skills, the Lady, a Rewind re-roll, an earlier choice or other state the mod's condition reads.
- **Requirement-locked options** (shown greyed): the reason they're locked.
- **Optional-item toggles:** the "use item X" toggles move from beside the button into this modal.

Plain dialogue options with none of the above get no ?. The modal replaces the existing odds popover — one pattern only.

The hint-word display mode is removed entirely: the check `show` field, `eventChecks.hints` and the hint-word logic go from the engine, constants, the three editors and REFERENCE. (Only one event sets `show`, to `"odds"`.)

**Blocked by:** 03 — Buttons-only choice step + footer row.

**Relevant files:** `scenes/screens/event.gd` (`_build_choice_button`, `_build_disabled_option`, `_build_item_toggle`, `_toggle_odds_sheet`, `odds_sheet_lines`), `systems/events.gd` (`check_odds`, `odds_for`, `_mod_delta`, `hint_word`, `option_gate`, `active_toggles`), `data/constants.json` `eventChecks`, `data/events/fav_conclave_sealed_errand.json`, `tools/storyboard.html`, `tools/quest-editor.html`, `tools/quest-editor-mobile.html` (shared "Choice mechanics" section stays byte-identical), `tools/test_quest_editor.js`, `tests/test_event_screen.gd`, `tests/test_events.gd`, `tests/test_event_items.gd`, `docs/REFERENCE.md` §3.9a "Event choice checks", `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Check options and locked options show a circled ? on the right of the button; plain options don't
- [ ] Tapping ? opens the modal without picking the option; tapping the button still picks it
- [ ] Modal shows % success, tries and each modifier (source label + signed %) for checks
- [ ] Modal shows the lock reason for a locked option
- [ ] Optional-item toggles live in the modal and still change the shown % and the roll
- [ ] Old odds popover removed
- [ ] `show` field and hint words gone from engine, constants, editors, REFERENCE; no data file uses them
- [ ] Human on-device check listed: ? hit target size, modal readability, toggles in modal
