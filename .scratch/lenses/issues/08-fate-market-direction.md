# 08 — Fate lens: tomorrow's market direction

**What to build:** Spec `.scratch/lenses/spec.md` "Fate: roll range" (market part). With a Fate lens and Sense >= world gate, the market screen shows tomorrow's direction (up/flat/down) per line. Investigate first whether `Market` can project tomorrow's quote deterministically without mutating state (e.g. `target_price` vs `quote`, plus any seeded noise). If it can't be cleanly projected, STOP and report options to the human before building. Strings PROSE-REVIEW.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/market.gd`
- `systems/lenses.gd`
- `data/market.json`
- `tests/test_market.gd`
- `docs/REFERENCE.md` §3.13

**Acceptance:**
- [ ] Shown direction matches the next daily tick's actual move (test over several days).
- [ ] Projection reads state only, never writes.
- [ ] Hidden without lens / below gate.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
