# 21 — ToDo page projection and saved marks

**What to build:** `Todo` gains a page projection: one page per questline in display order, then Board. Pages carry label, subtitle, accent, status, new-goal pip, active goals, done goals, ledger, empty text and Board ladder steps. Questline presentation moves to data. `MAX_ITEMS_PER_SECTION` is removed. A new saved `todo` state records seen and last-changed marks per questline, backfilled on load. Marking a page seen is a system call. Started questlines come first, unstarted next and finished last, with Board after live questlines. No "n of N" total for a questline is projected.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/todo.gd`, `systems/objectives.gd`, `data/objectives.json`, `autoload/GameData.gd`, `autoload/GameState.gd`, `autoload/SaveManager.gd`, `tests/test_todo.gd`, `tests/test_savemanager.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Pure tests cover pages, ordering, pips and page choice
- [ ] The projection picks the most recently changed questline to open on
- [ ] Active goals keep checklists and counts; done goals are complete and separate
- [ ] Collective ledger is available on its page
- [ ] Board page carries base, target and stretch steps
- [ ] Old saves load with `todo` backfilled
- [ ] Questline presentation lives in data
- [ ] The existing ToDo app still renders until ticket 22
