# 04 — Quests tab: planning files and questline list

**What to build:** a new Quests tab in the storyboard. It opens on a list of questlines (one act each) grouped by ToDo page, with "+ Questline". Each row shows its quest count and per-category status roll-ups (e.g. Art 3/9 done).

- The author can create a questline: name, an id made from the name, a ToDo page (pick `tutorial`, `collective`, `business_empire`, or name a new one), act order on that page, a one-line premise and notes.
- The author can rename a questline and edit its premise and notes, and can delete one that has no data-driven quests.
- The last-opened questline is remembered in browser storage, as a convenience only.

This ticket also lays the foundation the later Quests tickets build on:

- **Pure planning model.** A new marker-delimited section of `storyboard.html`, with no DOM or storage access. It parses, serialises and validates the full planning-file format: questline fields; quest fields including follows, edge kind/label, events, statuses, mechanics state and objective id; the status category config list with defaults Writing, Choices, Observations, Art; and the status values `na`, `todo`, `doing`, `review`, `done`. It also does roll-ups.
- **Planning files.** One file per questline under `.scratch/questlines/`. The game never loads them.
- **Autosave.** About 1s after each planning edit, through the version-checked write. A saving / saved / error indicator. A refused save shows "Changed elsewhere: reload" with the unsaved change described. Planning files reload when the window regains focus.

The Quests tab must be usable at phone width with no page side-scroll, use thumb-sized targets, and follow the storyboard's palette tokens and light/dark handling.

**Mockup:** https://claude.ai/artifact/2iHxNhNundq3VL5EiGMmvv, saved copy in `.scratch/questline-planner/mockup/` (see its README). Artboards: `Main.dc.html` (questline list), `PhoneMap.dc.html` (header save indicator), `States.dc.html` (save indicator states, conflict banner). Build to match the mockup's layout, labels, controls and styling. Its quest content is sample data.

**Blocked by:** 01 — Storage interface, folder-picker backend.

**Relevant files:** `tools/storyboard.html` (`TABS`/`showTab` and the `.tabs` markup; `makeHistory`; the draft-model markers as the pattern; the `focus` reload listener; palette tokens in `:root`), `tools/test_storyboard.js` (extraction pattern for a new "Planning model (pure)" marker pair), `data/todo.json` (`questlines` = ToDo page ids), new `.scratch/questlines/`, `CODEMAP.md` (planning-files row; storyboard row mentions the Quests tab), `.scratch/questline-planner/spec.md` (§ Planning data, § Planning model, § Quests tab UI).

**Status:** ready-for-agent

- [ ] Human check: List rows, save indicator and conflict banner match the mockup
- [ ] Node tests: planning-file round trip, validation errors for malformed files, roll-ups
- [ ] Create / edit / delete questline works; delete is blocked when the questline has data-driven quests
- [ ] Autosave writes with the version check; a conflict shows the reload banner and the refused change
- [ ] Human check (phone and laptop): list grouped by page, create a questline, saving/saved indicator, edit the file on the other device and see the conflict banner, no page side-scroll
