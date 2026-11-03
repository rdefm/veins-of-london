# 20 — Prose: Office cards

**What to build:** card prose for the Office ladder, plus the meeting's venue-change beat when it first moves to HQ.

**Blocked by:** 19 — Office ladder

**Relevant files:**
- `docs/writing-guide.md` (required), `docs/CONTENT-GUIDE.md`, `docs/biz-meetings-vision.md`
- `data/board.json`, meeting event data

**Status:** needs-triage

- [ ] Written against `docs/writing-guide.md`; passes its audit
- [ ] Report flagged `PROSE-REVIEW:`

## Comments

- Debate rework (`.scratch/board-meetings/debate-rework.md`): write only a `case` per template (merged pitch + why), following its Prose principles; generic banter is ticket 32. Also blocked by 30.
- Prose packs (`.scratch/board-prose-cards/spec.md`, ticket 04): the goal's prose now goes into its prose pack `data/board_prose/<template>.json` (`case` prose cards: `id`, `slot`, `voice`, optional `when`/`weight`, `cards`), no longer `templates[*].case` in `data/board.json`. Template mechanics stay in `board.json`.
