# 01 — Add and remove cards in the quest editor

**What to build:** In the desktop quest editor, the author can add a new card to an event and delete an existing one, with the result saved to the event JSON.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/quest-editor.html` (`defaultCard`, `renderCard`, `renderBuilderCard`), `tools/test_quest_editor.js`, `docs/agents/quest-drafts.md`. Desktop only; leave `tools/quest-editor-mobile.html` alone. Ask if delete should confirm or support undo, and where "add" inserts (end vs after selected).

**Status:** ready-for-agent

- [ ] Add card (sensible defaults) and delete card from UI; order and indices stay consistent
- [ ] Saved JSON loads in game without schema errors
- [ ] `node tools/test_quest_editor.js` passes with new tests
