# 04 — Card CRUD

**What to build:** In the card editor the writer can add, remove and reorder cards within a branch, and edit speaker, label and type. Cards keep stable hidden `key`s so links survive insert/reorder.

**Blocked by:** 03 — Save + Undo, inline card text edit.

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `data/events/*.json` (card fields), spec § Draft format.

**Status:** ready-for-agent

- [ ] Insert before/after, delete, move up/down; all undoable and saved
- [ ] Speaker / label / type editable; preview reflects them
- [ ] Links (`goto {branch, card}`) to a moved card still resolve; deleting a linked-to card warns and lists the dangling links (node test)
