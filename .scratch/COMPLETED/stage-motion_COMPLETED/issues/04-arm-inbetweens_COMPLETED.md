# 04 — Arm in-betweens and overshoot

**What to build:**
- Kit generates in-between arm frames between pose pairs by interpolating the IK targets (hand target, elbow hint, prop angle) — 2 tweens per pair, plus an optional overshoot frame on fast moves. Only pairs a rig can actually reach (same side, frames it has).
- Manifest `tweens: {"<side>": {"a>b": [frames...]}}`; engine plays them with ease-out timing (~0.15–0.25 s, tunable) whenever an arm attr changes live; snapshot applies still snap to the end frame.
- Waves (`bag_wave`, `wave`) become multi-frame arcs rather than 2-frame flaps.
- Keep PNG count sane: tweens shared both directions (played reversed).

**Blocked by:** 03 (shoulder pivots / regenerated rigs)

**Relevant files:** `tools/stage_art/char_kit.py` (`POSE_L/R`, `arm_pose`, `arm_canvas`, `ACTIONS`, `manifest`), `tools/stage_art/rig_archie.py` (legacy archie rig: leave as is unless trivial), `scenes/stage/stage_actor.gd`, `tests/test_stage.gd`, ENGINE.md

**Status:** ready-for-agent

- [ ] Live arm change shows tween frames in order then the target (tested via shown_frame over time)
- [ ] Fold/snapshot unaffected (end frames only)
- [ ] Every tween frame exists on disk (rig file check)
- [ ] ENGINE.md updated
