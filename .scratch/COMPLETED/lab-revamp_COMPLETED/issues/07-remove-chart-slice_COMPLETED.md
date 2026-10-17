# 07 — Remove chart slice

**What to build:** The bench prototype becomes procedure-only. The Resonance chart slice (Slice B) is deleted outright: its system functions, its chart view and pour-jar controls, its data block, its tests, and the slice switcher. Per-slice state collapses to a single procedure state (pool, best ranks, hints, ledger, snapshots, notebook, active run). Apart from the missing switcher and chart, the prototype plays exactly as it does today.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/bench_prototype.gd` (chart funcs from `chart_def` through `chart_knowledge`, `SLICES`/`SLICE_CHART`, `new_slice`, `set_active_slice`, every `slice_id` parameter)
- `scenes/screens/bench_prototype.gd` (`_build_slice_switcher`, `_build_chart_card`, `_add_chart_view`, inner classes `ChartView`, `PourJar`)
- `data/bench_prototype.json` (`chart` block, per-recipe chart regions/hints)
- `tests/test_bench_prototype.gd`
- `autoload/GameState.gd`, `autoload/SaveManager.gd`, `autoload/Snapshots.gd` (check `benchPrototype` shape refs)
- `CODEMAP.md` (bench_prototype rows)
- `.scratch/lab-revamp/spec.md` §Slice B (mark it dropped)

**Status:** ready-for-agent

- [ ] No chart code, data or tests remain. A grep for `chart` and `pour` in the prototype files finds nothing chart-related
- [ ] State has no slice layer. Existing procedure tests pass after being adapted to the flattened state
- [ ] The prototype opens from the Debug app and a procedure run still works end to end, including batch and Rewind
- [ ] The spec marks Slice B as dropped (procedure chosen, 2026-10-15)
- [ ] CODEMAP rows updated; check_all + full suite green
