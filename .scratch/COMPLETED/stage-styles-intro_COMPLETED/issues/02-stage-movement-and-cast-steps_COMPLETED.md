# 02 — Stage movement and cast steps

**What to build:** Stage direction can move things and bring people on and off. New direction vocabulary:
- **move** — an actor or a set object travels to a target x over a duration (eased). Actors whose rig has a walk cycle animate their legs while moving and stand still on arrival; rigs without one just slide. Objects (e.g. a car) can drive in from off-screen.
- **facing** — actor attribute, left or right; flips the whole rig (anchors flip with it so hand/mouth effects still originate correctly).
- **show / hide** — an actor can start hidden and appear at a given card/time (e.g. a buyer stepping out from behind a car door), or leave.

All lasting effects (final position, facing, visibility) fold into the card snapshots like existing steps, so show_card, Rewind, skipping, and reduced motion (snap to end state) all land correctly. Actors keep integer positions. Context: the intro (tickets 05–07) needs a car pulling in, three buyers getting out and one walking towards Archie, and Archie walking to the alley exit.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/stage/stage_direction.gd` (`apply_step_end`, `resolve_start`/`resolve_end`), `scenes/stage/stage_player.gd` (`_run_step`, near node, objects), `scenes/stage/stage_actor.gd` (attrs, parts, anchors), `tools/stage_art/build_stage_assets.py` (rig/set manifest shape), `tests/test_stage.gd` (`_assert_step_valid`), `.scratch/stage-engine/ENGINE.md` ("New step kind" workflow, snapshot shape)

**Status:** ready-for-agent

- [ ] Snapshot shape extended for actor x / facing / visibility and object x; folding is covered by tests (start/end of a card after moves, hides, facing changes)
- [ ] A rig can declare a walk cycle (legs frames + timing) in its manifest; walking plays it, idle restores the standing legs
- [ ] Facing flip keeps hand/mouth anchors correct (test on anchor positions)
- [ ] Reduced motion snaps actors/objects to end positions with no walk animation
- [ ] Step validation in tests covers the new steps (unknown targets, missing frames)
- [ ] ENGINE.md step table and snapshot shape updated
