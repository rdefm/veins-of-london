# 07 — Flow editing

**What to build:** the author can build and rewire a questline from the map and the sheet.

- "+ Quest" in the toolbar adds a root quest with no predecessor.
- On the sheet: "+ Next" adds a follower. "+ Branch" adds another follower and asks whether it's parallel or a choice, with an optional choice label. "Follows…" sets which quests this one follows (multi-select, across questlines too). "Insert after" and "Insert before" splice a quest into the chain.
- A choice edge's label can be edited, and an edge can switch between parallel and choice.
- "Delete" reattaches the deleted quest's followers to its predecessors. It warns first when the quest has mechanics or linked drafts.
- Any edit that would create a follow loop, within or across questlines, is refused with a message.

A follows-link is the same data the quest-editor spec later turns into the unlock condition. All operations are pure planning-model functions, each one undoable and autosaved.

**Mockup:** https://claude.ai/artifact/2iHxNhNundq3VL5EiGMmvv, saved copy in `.scratch/questline-planner/mockup/` (see its README). Artboards: `QuestSheet.dc.html` (Flow section and its six action buttons), `States.dc.html` ("+ Branch" dialog, "Follows…" multi-select with "would loop" rows and the other-questlines group, delete warning). Build to match the mockup's layout, labels, controls and styling. Its quest content is sample data.

**Blocked by:** 06 — Quest sheet: fields, statuses, mechanics state, undo.

**Relevant files:** `tools/storyboard.html` (planning-model section), `tools/test_storyboard.js`, `.scratch/questline-planner/spec.md` (§ Adding and rewiring quests, § Planning data, cross-questline follows and loops).

**Status:** ready-for-agent

- [ ] Human check: Flow section and its dialogs match the mockup
- [ ] Node tests: add root/next/branch, insert before/after, delete with reattach (single and multiple predecessors), set follows, set edge kind/label, loop refusal within and across questlines
- [ ] Delete warning shown for quests with mechanics or linked drafts
- [ ] Human check (phone): build a branching chain with a choice fork and a converge, and the map updates after each step
