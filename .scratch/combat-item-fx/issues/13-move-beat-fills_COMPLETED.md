# 13 — Move beats that play nothing today

**What to build:** Move outcomes that currently look identical (or invisible) each get a cheap, distinct cue (proposal §5):

| Beat | Cue |
|---|---|
| `block` | a cyan "tink" spark at the contact point, a cyan `0` number, and a guard-marker pulse |
| `autoguard` | the afterimage, plus the guard marker sliding in from the side |
| `retaliate` | a 1-frame white outline flash on the defender, then its attack pose (it's a free swing) |
| `stunThrough` | the guard marker shatters over 2 frames, then ticket 01's Stunned icon pops |
| `fizzle` (Stun on Guarded) | a grey glance spark and a small backward recoil on the *attacker* |
| `evade` | the defender sidesteps ~6px and back, leaving an afterimage at its original spot |
| `fleeFailed` | a stumble: forward 4px, rotate −8°, recover |
| `levelUp` | a brass `L↑` pip rises from the sprite with a small sparkle |
| `enter` (reinforcement) | the sprite slides in from its band's off-screen edge (~250ms) |

`fled` (a successful Leg it) is ticket 02, not this one.

**Blocked by:** 01 — Status icon row

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()`, `_move_pose_cues()`, `_OVERLAY_KINDS` for `enter`)
- `scenes/components/combat_stage.gd` (guard marker, `spawn_afterimage()`, `spawn_damage_number()`, `play_hit()`)
- `data/combat_visuals.json`
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Evade, Moves, Move-level effects (block, autoguard, retaliate, stunThrough), KO and outcome (reinforcements), Move levels (levelUp)

**Status:** ready-for-agent

- [ ] Each beat in the table plays its cue (`beat_cues` tests per kind)
- [ ] Rewind plays them cleanly (no numbers, `enter` reverses out)
- [ ] Data-driven; quick pacing halves; reduced motion keeps sparks/numbers, drops slides and stumbles
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: a block, an evade, a fizzled Stun, a Stun through a guard, a retaliate, a failed Leg it, a reinforcement entering
