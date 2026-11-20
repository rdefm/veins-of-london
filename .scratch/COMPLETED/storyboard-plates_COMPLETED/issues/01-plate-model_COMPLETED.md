# 01 — Plate model: add, delete, edit fields

**What to build:** The storyboard tool's data layer for plates, testable without the UI. A board can gain a new plate with the next free id, lose a plate (shots that used it have their plate cleared), and have any plate field edited from text. A plate's name is validated (lower-case letters, digits, underscore; unique on the board). A plate's variant-of must be an existing plate and never itself. A plate's "Used by" list is generated from the shots' plate fields, never hand-edited.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `tools/storyboard.html` (shot-board editing section: `SHOT_FIELDS`, `setShotField`, `addShot`, `deleteShot`; the `module.exports`-style export list at the test seam)
- `tools/test_storyboard.js` (export list at lines ~30 and ~48, existing shot tests)
- `.claude/skills/event-storyboard/reference/board-schema.md` (plate fields)

**Status:** ready-for-agent

- [ ] Add/delete/set-field functions exist and are exported to the test harness
- [ ] Tests cover: next free id, name validation (case, charset, duplicate), variant-of validation, delete clears shots' plate, blank field drops key, key order stays schema order
- [ ] Generated "Used by" matches shots' plate fields
- [ ] `node tools/test_storyboard.js` passes
