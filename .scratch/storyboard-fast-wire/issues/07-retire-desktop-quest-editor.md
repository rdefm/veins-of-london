# 07 — Retire the desktop quest editor

**What to build:** The desktop quest editor is removed. The mobile quest editor and the storyboard tool keep working, and their shared mechanics section is still enforced byte-identical. Docs and CODEMAP no longer point at the desktop editor; anything the quest-drafts workflow referenced it for points at the mobile editor or the storyboard tool instead.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/quest-editor.html`, `tools/test_quest_editor.js` (parser/builder/notes tests read the desktop file; shared-section check), `tools/quest-editor-mobile.html`, `tools/storyboard.html` (shared-section comment, `showDirectoryPicker` comment), `CODEMAP.md` (~L353), `docs/agents/quest-drafts.md`.

**Status:** ready-for-agent

- [ ] Desktop editor deleted; no live reference to it remains outside `.scratch/COMPLETED`
- [ ] `node tools/test_quest_editor.js` green against mobile + storyboard; tests that only covered desktop-only features removed
- [ ] `docs/agents/quest-drafts.md` and CODEMAP updated
