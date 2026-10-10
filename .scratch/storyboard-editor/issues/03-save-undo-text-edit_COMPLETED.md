# 03 — Save + Undo, inline card text edit

**What to build:** Selecting a card in the Storyboard tab opens a card editor where its text can be edited. A manual **Save** writes the draft back into the proposal `.md`'s JSON block, leaving surrounding prose untouched. **Undo** steps back through edits. No autosave. Unsaved-changes indicator.

**Blocked by:** 01 — Draft model + test harness.

**Relevant files:** `tools/storyboard.html` (FS handle helpers ~267–305, proposal loading), `tools/test_storyboard.js`, `.scratch/writing-revamp/*-proposal*.md`, spec § Decisions (Save target, Saving).

**Status:** ready-for-agent

- [ ] Edit card text → preview updates live
- [ ] Save splices only the JSON block; prose before/after byte-identical (node test)
- [ ] Undo reverts edits one step at a time
- [ ] Dirty indicator; warn on leaving/switching board with unsaved changes
- [ ] Tool never writes under `data/events/`
