# 06 — Locked lesson bench session

**What to build:** An event card/op that opens the live bench in a **locked lesson session** for one recipe with a goal (a manual run at rank ≥ R), then hands control back to the event on success. Session state lives in the pure state tree.
- Calc comes from a session-scoped pool, not the player's stock, through the Lab's single calc-spend function. After each failed run the pool is refilled to one run's cost.
- The session costs no time block.
- **Both Rewinds are refused while the session is open**: the Lab's run/batch Rewind and the time-block Rewind.
- The bench can't be dismissed and nav is disabled until the goal is met.
- Escalation on failed runs (thresholds in data): after 3, the session's lesson hint is granted exact; after 6, a "talk-through" shows every remaining band of the goal's rungs exact.
- Items and crafting XP from every run go to the player as normal.

This ticket ships the mechanism with a test event; James's prose comes in 07.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "Bench lesson session"; § User Stories 4–11; § Testing Decisions Seam 2.

**Blocked by:** 01 — RecipeKnowledge core.

**Relevant files:**
- `systems/lab.gd` — `_spend_calc`, `calc_available`, `finish_run`, `_close_run`, `can_rewind`, `rewind`, `new_state`
- `systems/rewind.gd` (time-block Rewind gate)
- `systems/nav.gd`, `systems/events.gd` (new op/card type; pause + resume the event)
- `systems/recipe_knowledge.gd` (`grant_rung` for the hint and escalation)
- `scenes/screens/hq_lab_bench.gd`, `scenes/modals/modal_layer.gd` (no dismiss, nav lock)
- `data/lab.json` or `data/recipe_knowledge.json` (escalation thresholds)
- `tests/test_events.gd`, `tests/test_lab*.gd`
- `CODEMAP.md`; `docs/REFERENCE.md` — § lesson session + state path

**Status:** ready-for-agent

- [ ] Opening a session via the op puts the bench in lesson mode for the recipe. The pool is separate; the player's ore stock is untouched by session runs.
- [ ] A failed run (rank < goal, cracked, abandoned) refills the pool to one run's cost.
- [ ] No time block spent across the whole session.
- [ ] Lab Rewind and time-block Rewind both refused during the session, and available again after.
- [ ] Nav and dismiss refused until the goal is met. A run at rank ≥ goal ends the session and resumes the event at the next card.
- [ ] Fail 3 → lesson hint exact; fail 6 → remaining bands exact. Thresholds come from data.
- [ ] Items and XP from session runs land in the player's inventory/skill.
- [ ] Save mid-session round-trips. The state tree stays pure.
- [ ] On-device QA block in report.
