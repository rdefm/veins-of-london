# 12 — Balance pass against §7 provisional numbers

**What to build:** Tune the discovery-chance formula, pity increment, refinement-chance floor, ore costs, and XP rewards that tickets 04/05 implemented as vision-doc §7's provisional placeholders, into shipped constants — without touching schema or architecture. This is a numbers-only pass; no new mechanics, screens, or state shape changes.

**Blocked by:** 11 — Bench.grant_effect() + NPC/faction collision wiring.

**Status:** ready-for-agent

- [ ] Discovery-chance formula constants (base chance, skill/workshop-bonus weighting) reviewed and adjusted in `systems/bench.gd`.
- [ ] Pity increment-per-miss constant reviewed and adjusted.
- [ ] Refinement cost-per-tier curve and odds-floor constant reviewed and adjusted.
- [ ] Ore costs and XP rewards for both probing and refinement reviewed and adjusted.
- [ ] `tests/test_bench.gd` updated to assert against the new constants (not the §7 provisional placeholders) — test intent (transitions, invariants, curve shapes) unchanged, only expected numeric values move.
- [ ] Syntax check clean; full test suite green.
