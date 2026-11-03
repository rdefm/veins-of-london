# 18 — Prose: Landmark deals cards + supplier beat

**What to build:** card prose for the Landmark deals ladder and the pinned supplier-contract card — pitch, why-this-week, labels, reward/vignette text; the buyers' names and flavour for each authored landmark contract.

**Blocked by:** 17 — Landmark deals ladder (Archie) + supplier-contract spine beat

**Relevant files:**
- `docs/writing-guide.md` (required), `docs/CONTENT-GUIDE.md`, `docs/biz-meetings-vision.md`
- `data/board.json`, landmark contract data

**Status:** needs-triage

- [ ] Written against `docs/writing-guide.md`; passes its audit
- [ ] Report flagged `PROSE-REVIEW:`

## Comments

- Debate rework (`.scratch/board-meetings/debate-rework.md`): write only a `case` per template (merged pitch + why), following its Prose principles; generic banter is ticket 32. Also blocked by 30.
- Prose packs (`.scratch/board-prose-cards/spec.md`, ticket 04): the goal's prose now goes into its prose pack `data/board_prose/<template>.json` (`case` prose cards: `id`, `slot`, `voice`, optional `when`/`weight`, `cards`), no longer `templates[*].case` in `data/board.json`. Template mechanics stay in `board.json`.
