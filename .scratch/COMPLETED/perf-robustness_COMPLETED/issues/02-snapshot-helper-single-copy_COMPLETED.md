# 02 — Whole-state snapshot helper + single event-snapshot copy

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** One `GameState` snapshot function (shallow copy, null `blockStart`, empty `event.snapshots`, then deep copy) used by Rewind block-start, Events pre-mutation snapshot and SaveManager saveable state. Event cards copy the state once, not twice (`Snapshots` gets an owned-push path, or callers pass live data). Combat snapshot path is untouched.

**Blocked by:** 01 (native-deep-copy)

**Relevant files:** `autoload/GameState.gd`, `autoload/Snapshots.gd` (CAUTION note at top to remove), `systems/rewind.gd`, `systems/events.gd` (`_snapshot_before_mutation`), `autoload/SaveManager.gd` (`_saveable_state`), `systems/combat_rounds.gd` (`_push_snapshot`, leave alone), `tests/test_rewind.gd`; review §2.4, §4.7

**Status:** ready-for-agent

- [ ] Snapshot never contains `blockStart` or nested snapshot stacks (tested)
- [ ] An event card pushes exactly one whole-state copy (tested)
- [ ] Rewind and save behaviour unchanged; existing tests pass
- [ ] The three call sites use the helper; CAUTION note removed
