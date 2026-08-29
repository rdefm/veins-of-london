# 90 — Notes: signal the Des tuition chain (S1→S4) instead of "nothing pressing"

**What to build:** After the first Des event (`col_a1_intro` — meeting Des at the lock-up), the Notes app currently shows nothing at all ("nothing pressing"), confirmed by human playtest — no badge, no notification, nothing pointing at what to do next. Root cause: the next step is a Map-tab pin (`col_a1_prospecting`, gated `showWhenFlagsTrue: ["colA1DesMet"]`) that `col_a1_intro`'s `on_complete` never announces — no `notify` op, no `objectives.json` entry. The player is left with a genuinely silent game state.

**Where:** `data/events/col_a1_intro.json` (`on_complete`), `data/objectives.json` (existing pattern: `activateFlag`/`completeFlag`/`questline` entries), `systems/objectives.gd`, `systems/todo.gd` (`get_active_questlines()`), `data/events/col_a1_prospecting.json` / `col_a1_seeding.json` (the pin-gated tuition chain, gated on `colA1DesMet` → `colA1ProspectingTaught` → ... → `col_a1_hub`).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `col_a1_intro.json`'s `on_complete` gains a `notify` op pointing the player at the map (e.g. "Des reckons there's ground worth checking. Take a look at the map.") — new prose, flag **PROSE-REVIEW** against `docs/CONTENT-GUIDE.md`'s tone bible.
- [ ] `data/objectives.json` gains entries (questline `"collective"`) for the S1→S4 tuition-chain steps (`col_a1_prospecting`, `col_a1_seeding` at minimum — whatever steps exist between `colA1DesMet` and `colA1HubReached`), following the existing `activateFlag`/`completeFlag` pattern, so Notes shows real "what to do next" guidance through the whole tuition chain, not just after it.
- [ ] Notes (`Todo.get_active_questlines()`) renders these new entries correctly, capped/ordered the same way existing questline items already are.
- [ ] Separately: investigate the lingering "Archie's time vein is yours. Cultivate it. Harvest. Make pearls. Archie sells them." line (`tut_archie_partner` in `objectives.json`) reported as reading like an active/unchecked task. `checklist_row()` (`scenes/components/ui.gd`) does render a ☑ + greyed text when `done` is true, so don't assume a render bug blind — first confirm on a repro save whether `state.objectives["tut_archie_partner"].complete` is actually `true` at the point of complaint (a `refresh()` timing/staleness bug would be a different, real fix) before concluding it's a legibility problem. Fix whichever it turns out to be.
- [ ] Test coverage: a fresh-state playthrough through `col_a1_intro` confirms a notification fires and the Collective questline section in Notes goes from empty to showing the tuition-chain objective; existing `tests/test_todo.gd`/`tests/test_col_a1_tuition.gd` extended rather than only patched if the shape changes.
- [ ] Manual check noted for the human: play from a fresh save through meeting Des and confirm Notes never goes silent, and the "Archie's time vein..." line shows visibly checked once its flag is true.
