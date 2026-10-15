# 09 — Freeform manual run

**What to build:** Manual crafting on the lab plate, freeform.

- **Docked book.** "Craft manually" on a recipe page docks the book to the bottom half of the screen, showing that recipe's known steps (exact steps show their band). The book stays pinned until Finish and cannot be closed mid-run.
- **Jars.**
  - Only jars for ores the recipe uses can be tapped. Other jars are inert, with a short notice.
  - Each jar tap adds that ore's **fixed amount from the recipe** to the mixture and spends it from the pool.
  - The **first jar tap starts the run** and takes the Rewind snapshot.
  - Jars can be tapped at any point in the run (e.g. healingBurst adds time calc after grinding life).
- **Apparatus.**
  - Tapping an apparatus (only after a run has started) pops that apparatus's existing gauge **over the plate**, above the docked book.
  - The step works on the current mixture. The step records its apparatus, the performed reading, and the ore(s) added since the previous step.
  - Steps can be done in any order and repeated. The book is reference only.
  - Compress overshoot still cracks the vessel and ends the run as today.
- **Finish.** A **Finish** button on the docked book is the only way to end a run. There is no Abandon.
  - Scoring matches the performed steps against the ideal, now **ore-aware**: an ideal step matches only if the apparatus matches and the required ore was in the mixture for it. Missing ideal steps = 0, extra steps −5 each, as today.
  - The rank/best-rank, re-run bonus and bad-run flavour rules are unchanged.
  - The result (score, rank, new best, bonus, flavour line, Rewind) shows on the docked book page. Dismissing it returns to the recipe page.
- **Data.** Ideal steps gain an `ore` (or none, for steps that work the existing mixture), taken from each recipe's base procedure. A hint-only step such as healingSalve's distil adds no ore.

The plan editor (insert/nudge/remove/reset plan) is gone. Off-book steps are now just steps the player chooses to perform.

**Blocked by:** 08 — Prototype on the lab plate + known-recipe book

**Relevant files:**
- `systems/bench_prototype.gd` (`begin_procedure_run`, `current_step`, `perform_step`/`perform_grind`/`perform_distil`, `_perform`, `_advance`, `match_ideal`, `score_procedure`, `procedure_cost`, `finish_run`, plan funcs `planned_procedure` through `_plan` to delete)
- `scenes/screens/bench_prototype.gd` (`StepGauge`, `HoldGauge`, `GrindGauge`, `DistilGauge`: reuse, reposition over the plate)
- `data/bench_prototype.json` (`ideal` steps gain ore; `base` `calc` amounts are the fixed jar amounts)
- `tests/test_bench_prototype.gd`
- `CODEMAP.md`
- `.scratch/lab-revamp/spec.md` §Slice A (update to the freeform flow)

**Status:** ready-for-agent

- [ ] "Craft manually" docks the book; Finish is the only exit
- [ ] Off-recipe jars can't be tapped. A jar tap spends the recipe's fixed amount; the first tap starts the run and snapshots
- [ ] An apparatus tap before any jar does nothing (notice). After one, it opens the right gauge over the plate and records the step with its ore(s)
- [ ] Tests:
  - ore-aware matching (right apparatus + wrong/missing ore = no match);
  - any order and repeats;
  - missing = 0 and extras −5;
  - Finish with zero steps scores 0;
  - crack ends the run;
  - Rewind restores to before the first jar tap
- [ ] The result shows on the book; best rank, ledger, bonus and flavour behave as before
- [ ] No plan-editor code remains
- [ ] CODEMAP + spec updated; check_all + full suite green
- [ ] On-device checklist in the report (gauge placement over plate, book height, tap targets, Finish reachable)
