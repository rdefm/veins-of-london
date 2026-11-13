# 09 — Seed existing questlines

**What to build:** a one-time seed of planning files for Tutorial, Collective Act 1, Collective Act 2 and Business Act 1, so planning starts from what's already in the game. There is no re-runnable importer.

- **Sources.** Built from `data/objectives.json` (each objective's `questline` field is its ToDo page), `data/events/`, existing storyboard drafts and `data/todo.json`'s questline pages.
- **Quests.** Marked hard-coded, with their objective id and events.
- **Order.** Guessed from objective order and event naming. The Collective Act 1/2 split is guessed too. The author fixes order and branches by hand afterwards.
- **Statuses.** Start at `todo`, or `na` where obviously not applicable.

The planning-model test also validates every committed planning file under `.scratch/questlines/` against the model and the real objective and event ids. That covers the seed now and later edits.

Note: `.scratch/` is public, so seeded notes are public once committed.

**Blocked by:** 04 — Quests tab: planning files and questline list.

**Relevant files:** `data/objectives.json`, `data/todo.json`, `data/events/`, `.scratch/writing-revamp/` (drafts), new `.scratch/questlines/*.json`, `tools/test_storyboard.js`, `CODEMAP.md` (planning-files row), `.scratch/questline-planner/spec.md` (§ Seed).

**Status:** ready-for-agent

- [ ] Four planning files committed; every quest is hard-coded with a valid objective id
- [ ] Node test validates all committed planning files against real objective and event ids
- [ ] Human check (once 05 lands): each seeded map reads as a plausible order of the act
