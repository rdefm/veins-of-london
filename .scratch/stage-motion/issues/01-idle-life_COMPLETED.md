# 01 — Idle life (breath phase, sway, glances, tilt spring, talk nods)

**What to build:** Stop actors standing like mannequins between beats. All procedural in `StageActor`, no new art:
- Per-actor random breath phase/period jitter so a group never breathes in sync.
- Slow weight-shift sway: body group drifts ±1 px in x on a long, jittered period (integer px only).
- Occasional idle head micro-tilts (±1–3°) at random intervals while no card `tilt` is being eased; card-set `tilt` still wins.
- Head tilt eases with a damped spring (small overshoot, settles) instead of linear `move_toward`.
- Talking adds small head nods/bobs (tilt jitter ±2°, occasional 1 px head dip) on talk-flap beats.
- Tunables live in rig `behaviour` (generator: `build_stage_assets.py` base manifest), not code constants.

**Blocked by:** none

**Relevant files:** `scenes/stage/stage_actor.gd` (`step`, `_redraw`, `snap_tilt`), `tools/stage_art/build_stage_assets.py` (`behaviour`), `tools/stage_art/char_kit.py` (`manifest`), `tests/test_stage.gd`, `.scratch/stage-engine/ENGINE.md` (Rigs)

**Status:** ready-for-agent

- [ ] Two actors with the same rig don't share breath timing
- [ ] Sway/idle tilt never produce sub-pixel positions; reduced motion = none of it
- [ ] Card-set tilt reached (spring settles to target) — test via stepping the clock
- [ ] Slow fields scale all of it (it runs off the actor clock)
- [ ] ENGINE.md updated
