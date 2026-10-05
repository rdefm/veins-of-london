# 03 — Migrate old refine levels to tiers

**What to build:** Existing saves with refine levels load with equivalent item tiers and empty progress; nothing is lost or breaks.

**Blocked by:** 01 — Tier state and progress-bar experiments.

**Relevant files:** `systems/bench.gd` (cell `refine` field), `autoload/` save load/migration (grep `migrat`), `tests/fixtures/`, `tests/test_bench.gd`. Propose the level→tier mapping in the report for human approval.

**Status:** ready-for-agent

- [ ] Old-save fixture loads; each refined cell maps to a tier, progress 0
- [ ] Inventory tier buckets remain valid after migration
- [ ] New saves unaffected; test covers migration
