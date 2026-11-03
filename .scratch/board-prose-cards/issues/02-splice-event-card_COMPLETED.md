# 02 — Splice event card

**What to build:** a new event card type, `splice`, that names a context key. When an event starts, each splice is replaced in order by the event-card list at that key; a missing or empty key gives zero cards. The expanded list is stored on the live event (via 01's accessor) and is what plays, so a snapshot or Rewind mid-event sees the same cards. Spliced cards are ordinary event cards: `fillFromContext`, `speaker` fill, images and `goto` (authored cards → spliced, spliced → authored) all work. Spliced card keys are namespaced with the splice's key so they can't collide.

**Blocked by:** 01 — Live event card list accessor

**Relevant files:**
- `systems/events.gd` — `start_event`, `start_or_defer`, `_goto_target`, `fillFromContext` handling, `_with_context_choices`
- `tests/test_events.gd`, `tests/test_event_content_lint.gd`
- `tools/lint_refs.json` (if card types are listed there)
- `docs/REFERENCE.md` §3.9a; `CODEMAP.md` (events row)
- Spec: `.scratch/board-prose-cards/spec.md` → Implementation Decisions "Splice event card"

**Status:** ready-for-agent

- [ ] A fixture event with an empty splice, a multi-card splice, and gotos into and out of spliced cards plays the expected card run
- [ ] `{key}` tokens and `speaker` fill work inside spliced cards under `fillFromContext`
- [ ] Snapshot → restore mid-event resumes on the same card with the same expanded list
- [ ] Event content lint accepts `splice` and rejects one with no context key
- [ ] REFERENCE §3.9a and CODEMAP describe splice
