# 02 — Diagnose + fix: collective quests don't fire after debug start

**What to build:** After Debug Start, the collective questline can't be triggered. Diagnose the cause and fix it so collective quests fire normally from a debug-start state. Leading hypothesis: Debug Start flips every boolean flag to `true`, so collective questline beats read as already done/seen and their triggers never pass. Fix Debug Start so questline progression flags stay at "not started" while everything else it unlocks stays unlocked.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/debug_start.gd` (flag loop in `apply()`), `systems/collective.gd` (`maybe_trigger_*`), `systems/events.gd`, `tests/test_col_a1_*.gd`, `tests/test_playthrough.gd`; REFERENCE §5 (Debug Start), §2 (flags).

**Status:** ready-for-agent

- [ ] Root cause confirmed and written up in this ticket before fixing
- [ ] After Debug Start, the first collective beat triggers under its normal conditions
- [ ] Debug Start still unlocks every screen/feature it did before
- [ ] Regression test: Debug Start state → collective trigger fires
- [ ] REFERENCE §5 updated if Debug Start's flag rule changes
