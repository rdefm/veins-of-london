# 29 — `context_flag` condition for skippable meeting cards

**What to build:** An event card's `goto` can branch on a flag in the event's context, so a fixed-slot event can skip slots that have no content. Needed so the debate skeleton (ticket 30) can run with 1, 2 or 3 offered goals without showing empty cards. Behaviour is verifiable alone with a test event.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/events.gd` (`condition_met`, `_card_goto`)
- `autoload/GameData.gd` (event lint, condition vocabulary)
- `docs/REFERENCE.md` §3.9a condition vocabulary
- `tests/test_events.gd`, `tests/test_event_content_lint.gd`
- `tools/storyboard.html` + `tools/lint_refs.json` (JS lint mirror; regenerate refs via `scripts/export_lint_refs.gd`)
- Spec: `.scratch/board-meetings/debate-rework.md` §Code/engine impact

**Status:** ready-for-agent

- [ ] New condition kind true when a named context key is present and truthy (non-empty string / true)
- [ ] Usable in card `goto` entries; falls through to the next entry when false
- [ ] Content lint accepts it and rejects it with no key; JS lint mirror and `lint_refs.json` stay in step
- [ ] REFERENCE.md §3.9a vocabulary updated
- [ ] Tests cover true, false, missing key
