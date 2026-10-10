# 01 — Choice memory and option ids

**What to build:** Every choice the player commits in any event is remembered under the event id and card index: the option's stable `id` (a new optional option field, falling back to its index) and, once checks exist, success/fail. Later events, modifiers, `requires` and objectives can read it. Old saves load with an empty store.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`choose`, `rewind`), `autoload/GameState.gd` (state tree + load backfill), `autoload/SaveManager.gd`, `systems/objectives.gd`, `tests/test_events.gd`, `CODEMAP.md`. Spec: `.scratch/opening-choices/spec.md` "Choice memory". REFERENCE.md §2 (state paths/flags).

**Status:** ready-for-agent

- [ ] Choice memory lives in the flags area of the state tree, pure data only.
- [ ] Committing a plain choice records its `id` (or index) under event id + card index.
- [ ] Rewind past a choice removes its record.
- [ ] A save without the store loads with it backfilled empty (test).
- [ ] A read helper exists for other systems (used by 02/05 and objectives).
- [ ] Existing plain choices and the legacy `chance` effect behave unchanged.
- [ ] REFERENCE.md §2 documents the new state path.
