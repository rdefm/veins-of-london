# 24 — Prose: Defuse cards + Act 2 debrief

**What to build:** card prose for the Defuse ladder and the Act 2 closing debrief scene.

**Blocked by:** 23 — Defuse ladder + weather-or-soften + Act 2 debrief

**Relevant files:**
- `docs/writing-guide.md` (required), `docs/CONTENT-GUIDE.md`, `docs/biz-meetings-vision.md`
- `data/board.json`, debrief event data

**Status:** needs-triage

- [ ] Written against `docs/writing-guide.md`; passes its audit
- [ ] Report flagged `PROSE-REVIEW:`

## Comments

- Debate rework (`.scratch/board-meetings/debate-rework.md`): write only a `case` per template (merged pitch + why), following its Prose principles; generic banter is ticket 32. Also blocked by 30.
- Prose packs (`.scratch/board-prose-cards/spec.md`, ticket 04): the goal's prose now goes into its prose pack `data/board_prose/<template>.json` (`case` prose cards: `id`, `slot`, `voice`, optional `when`/`weight`, `cards`), no longer `templates[*].case` in `data/board.json`. Template mechanics stay in `board.json`.
