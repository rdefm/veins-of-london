# 14 — Balance evaluation pass

**What to build:** A comparison of production behaviour before and after this restructuring, under the same three-block daily budget and controlled scenarios: first-vein stabilization time, actions yielding little useful progress, available bill-paying opportunities, time/harvests forgone to develop, raid exposure during development, and pressure from managing a second vein. Explicitly compare character cultivation skill levels against vein development levels to demonstrate stronger skill supports more productive holdings, rather than assuming it. This is an evaluation/report deliverable, not a code change — do not claim the design improves balance without it.

**Blocked by:** 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13 (needs the complete mechanic in place to evaluate).

**Relevant files:**
- `tests/` (controlled-scenario harnesses, if built as automated comparisons)
- `.scratch/cultivation-refining/spec.md` §9 (evaluation plan detail)

**Status:** ready-for-agent

- [ ] Deterministic constraints, sampled outcomes, and human judgments are reported separately, not conflated
- [ ] First-vein stabilization time and second-vein pressure are measured under the same three-block budget as before
- [ ] Character skill vs. vein level relationship is demonstrated with concrete scenario data, not asserted
- [ ] Report explicitly states whether balance improved, regressed, or is inconclusive — no unverified balance claims
