# 01 — Nadia's Collective quests require time ore instead of emotion

**What to build:** Both of Nadia's Collective Act 1 objectives currently key off `emotion` ore; switch both to `time`, keeping her arc internally consistent, and update every place that names the ore type in player-facing text.

Mechanical changes (`data/objectives.json`):
- `col_a1_nadia_supply`: `params.oreType` `"emotion"` → `"time"`; `detail` text ("Thirty units of emotion calc...") updated to reference time calc.
- `col_a1_nadia_vein`: `params.oreType` `"emotion"` → `"time"`; `title`/`detail` text updated to reference a time vein.

Prose changes — rewrite the explicit "emotion" references (dialogue and resolution lines) in:
- `data/events/col_a1_nadia_meet.json` (e.g. "Emotion calc, every fortnight..." and "Thirty units of emotion calc, no deadline...")
- `data/events/col_a1_nadia_vein.json` (e.g. "You seed me an emotion vein and I buy it off you.")

`col_a1_nadia_done.json` doesn't name an ore type and needs no change. Before finishing, grep the repo for other "emotion" + "Nadia" co-occurrences (e.g. `data/collective_barks.json`'s `nadia` bark list, any contact-card copy) to catch anything missed above — none were found in this ticket's own scoping pass, but confirm rather than assume.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `col_a1_nadia_supply` and `col_a1_nadia_vein` both have `oreType: "time"` in `data/objectives.json`, with `title`/`detail` text updated to match.
- [ ] Dialogue and resolution lines in `col_a1_nadia_meet.json` and `col_a1_nadia_vein.json` no longer mention emotion, and read naturally with time substituted (not a mechanical find-replace — check the lines still scan against the tone bible in `docs/CONTENT-GUIDE.md`).
- [ ] A repo-wide check confirms no other Nadia-adjacent copy (barks, contact card) still references emotion in a way that now contradicts her quest.
- [ ] Existing tests referencing Nadia's emotion requirement (`tests/test_col_a1_nadia_*.gd`) are updated to time and still pass.
- [ ] Rewritten/new prose flagged `PROSE-REVIEW` in the completion report per the content guide.
