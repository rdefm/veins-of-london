# 02 — Slice A: procedure run, heat only

**What to build:** In the Procedure slice, the player picks a recipe and runs its known procedure step by step. The recipes are authored as ordered steps: apparatus, target on a 0–100 gauge, weight, base tolerance. Only the **heat** step is interactive in this ticket: hold and the needle rises, release to commit the value. The screen animates and reports the raw released value; the system scores it.
- Band half-width = base_tol × (1 + skillFactor × craftingSkill).
- Accuracy is 1.0 inside the band and falls linearly to 0 at 2× the band.
- Score = Σ weight × accuracy over the ideal steps. A missing ideal step scores 0; each extra step costs −5.

Calc is spent step by step, so abandoning mid-run loses what was spent. Non-heat steps may auto-pass as placeholders until ticket 03. The run feeds the shared core (rank, bonus, flavour, Rewind, ledger). Knowledge is shown as exact bands for every base step (hints come in ticket 04). See spec §Slice A.

**Blocked by:** 01 — Sandbox core + Debug launcher.

**Relevant files:** `.scratch/lab-revamp/spec.md` §Slice A and §Recipes in the prototype; files created in 01 (bench prototype system/screen/data/tests); `systems/bench.gd` (apparatus ids, read only); `docs/ui-vision.md` (palette).

**Status:** ready-for-agent

- [ ] Authored ideal procedures and base procedures for all 3 recipes live in data. The base alone, executed perfectly, caps out around rank 2–3.
- [ ] Tolerance, accuracy falloff and score formula are unit-tested, including skill 0 vs 10 and missing/extra steps.
- [ ] Heat gauge: hold/release on a placeholder `_draw` gauge; the screen only reports the released value.
- [ ] Calc spent per step; abandon loses it; Rewind restores it.
- [ ] Completed run updates rank, bonus and ledger via the core.
