# 05 — Insights

**What to build:** A rare, skill-scaled nudge toward self-discovery. After each completed manual run (never auto-craft or batch), roll `insightBase + insightPerSkill × craftingSkill` (defaults 0.02 / 0.01, in data) on the seeded RNG. On success, one hidden ideal step of the lowest rung the player doesn't own (master included) becomes an **insight**: the player sees its apparatus and position in the sequence, but not its target band. Insights show in the run result and the recipe book. A later run that performs that step makes it vague, using the existing experimenting rules; 3 in-band hits then make it exact. An insight step doesn't count toward a rung being owned.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "Insight roll"; § User Stories 22–27, 29; prereq P3 rule 10 (fourth step state).

**Blocked by:** 01 — RecipeKnowledge core; 04 — Recipe book rung ladder.

**Relevant files:**
- `data/lab.json` — `specificities` (add `insight` below `vague`), insight tuning or in `data/recipe_knowledge.json`
- `systems/lab.gd` — `grant_steps` (order), `hidden_ideal_steps`, `notebook_clues` ("changed" must still fire on an insight step), `known_procedure` (insight step inserted with apparatus/position, no target), `_learn`, `finish_run` result
- `EventBus.lab_run_completed` hook (emitted by `Lab._emit_hook`) — note `abandoned`/`cracked` outcomes
- `systems/recipe_knowledge.gd` (roll + targeting; rung-owned excludes insight)
- `autoload/Rng` (seeded)
- `scenes/screens/hq_lab_bench.gd` (result panel line, book step rendering)
- `tests/test_recipe_knowledge.gd`, `tests/test_lab*.gd`
- `CODEMAP.md`; `docs/REFERENCE.md` — § insights

**Status:** ready-for-agent

- [ ] Roll happens once per completed manual run (decide and document whether cracked/abandoned runs roll). Never on `batch`.
- [ ] Chance scales with crafting skill. A seeded test shows a deterministic hit/miss.
- [ ] Targets only the lowest rung not owned, master included. No roll target when every rung is owned.
- [ ] Revealed step shows apparatus + position, no band, in both book and result. Insight lines PROSE-REVIEW.
- [ ] Insight → vague on a matching run → exact after 3 in-band hits, via the existing learning path.
- [ ] Existing Lab tests still pass with the extra specificity.
- [ ] On-device QA block in report.
