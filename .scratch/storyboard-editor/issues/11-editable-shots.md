# 11 — Editable shots

**What to build:** In the Shots tab, shot fields (brief, prompt, saveAs, reuse, etc.) are editable and saved back to the board's `board.json`, alongside the existing verdicts/notes/uploads.

**Blocked by:** 02 — Tabs shell; 03 — Save + Undo.

**Relevant files:** `tools/storyboard.html` (`renderShots`, `saveFeedback`), `.scratch/event-art/<board>/board.json`, `.claude/skills/event-storyboard/reference/board-schema.md`.

**Status:** ready-for-agent

- [ ] Edit shot fields inline; Save/Undo shared with the draft editor
- [ ] board.json stays valid per board-schema.md
- [ ] Verdict/note/upload flow unchanged
