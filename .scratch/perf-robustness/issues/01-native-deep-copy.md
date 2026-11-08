# 01 — Native deep copy

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** `GameState.deep_copy` runs natively (`duplicate(true)` for Dictionary/Array, primitives returned as-is). Rewind, event snapshots and saves get faster (10.3 ms → ~2.4 ms per copy) with no behaviour change.

**Blocked by:** None — can start immediately

**Relevant files:** `autoload/GameState.gd`, `tests/test_rewind.gd`; review §2.3 (`code-review.md`)

**Status:** ready-for-agent

- [ ] `deep_copy(s) == s` and mutating the copy leaves the original untouched (no shared sub-dicts), covered by a test
- [ ] Existing Rewind/snapshot tests pass
- [ ] Measured copy time recorded in the report
