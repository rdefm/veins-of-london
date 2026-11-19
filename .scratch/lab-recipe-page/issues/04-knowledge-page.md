# 04 — Recipe page 2: knowledge checklist

**What to build:** page 2 of the recipe page shows the knowledge ladder as a notebook checklist, with one row per rung from `RecipeKnowledge.ladder_rows`.

- **Each row:**
  - An inked tick (owned) or empty box (locked).
  - The rung label.
  - For owned rungs, the state word (exact / rough). A rough tick may use the squiggle motif.
  - Its max rank, in a right-hand column.
- **Locked rows:** put their `note` (seller, gate, insight; for Master, its pointer or "???") on pencilled lines underneath.
- **Last line:** "You can reach: rank N", from `RecipeKnowledge.rank_ceiling` ("—" for 0).
- **Strings:** new strings go in `data/recipe_knowledge.json` under `ladder`, flagged PROSE-REVIEW.
- **Node names:** keep `LadderRegion` and `Rung_<rung>`.

**Blocked by:** 02

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (`_add_ladder`)
- `systems/recipe_knowledge.gd` (`ladder_rows`, `rank_ceiling`; read-only)
- `data/recipe_knowledge.json` (`ladder` block)
- `docs/REFERENCE.md` §3.5a Recipe knowledge ladder
- `tests/test_lab_screen.gd` (ladder cases), `tests/test_recipe_knowledge.gd`
- `docs/CONTENT-GUIDE.md`

**Status:** ready-for-agent

- [ ] One row per rung with the correct state, ceiling and note, on ruled lines
- [ ] "You can reach" equals `rank_ceiling`
- [ ] A rung grant redraws page 2 (existing test adapted)
- [ ] No strings hard-coded in the screen; PROSE-REVIEW flagged in the report
