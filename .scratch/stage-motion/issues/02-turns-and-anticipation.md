# 02 — Turns and anticipation/settle

**What to build:** 
- Facing change during motion plays a short turn: 1 px body dip, flip, settle (~0.15 s) instead of an instant mirror. Snapshot/card-snap paths still flip instantly.
- Big arm actions (any rig action, and arm `set`s that change the arm frame) get a 1 px anticipation dip just before and a settle after; tunable in `behaviour`.

**Blocked by:** 01 (shares body offset composition)

**Relevant files:** `scenes/stage/stage_actor.gd` (`apply_attrs`, `play`, `_redraw`), `scenes/stage/stage_player.gd` (`_run_step` set/play), `tests/test_stage.gd`, `.scratch/stage-engine/ENGINE.md`

**Status:** ready-for-agent

- [ ] Live facing change passes through dip before flip; snapshot apply is instant
- [ ] Reduced motion: no dips, instant flip
- [ ] ENGINE.md updated
