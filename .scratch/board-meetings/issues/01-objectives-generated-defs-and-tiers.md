# 01 — Objectives: evaluate generated definitions and tiers

**What to build:** the objectives evaluator can evaluate an objective definition passed in by a caller (a generated board goal stored in board state), not only definitions loaded from objectives data. A definition can carry three tier thresholds (base / target / stretch) for one condition, and the evaluator reports the highest tier currently met. Existing data-driven objectives behave exactly as today. This is the prefactor that lets board goals ride the one existing tracker.

**Blocked by:** None — can start immediately

**Relevant files:**
- `systems/objectives.gd` — `refresh()`, `_refresh_one()`, `_evaluate()`, `condition_met()`, `count_progress()`
- `data/objectives.json`
- `tests/test_objectives.gd` (prior art)
- Spec: `.scratch/board-meetings/spec.md` §"Modules" → Objectives

**Status:** ready-for-agent

- [ ] A passed-in definition (not present in objectives data) evaluates through the same engine as data objectives
- [ ] A tiered definition returns `none | base | target | stretch` for the current state
- [ ] Existing objectives tests pass unchanged
- [ ] Threshold tests (just below / at / above) for a tiered passed-in definition
