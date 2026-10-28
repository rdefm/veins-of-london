# 06 — Removal effects: Stunned look, Black Hole, Time Pearl landing

**What to build:** The three ways a fighter loses actions each look different (proposal §3.3, §3.4, §4.4 Stunned row):

- **Stunned / Lost** (any lost actions that aren't a freeze, from Stun or Black Hole): a slow head-bob drift on the sprite (shear of the top, ~0.8s loop) alongside ticket 01's spinner icon. It clears when the last lost action passes.
- **Black Hole:** an overhand throw, then a dark bead with an orange rim lifts to the enemy band's centre and hangs ~150ms. The inward warp lands there: the backdrop pinches toward the centre (radial UV pull, 6–10%), each affected enemy leans 8–12° toward it and stretches, hit flashes, and damage numbers spawn at the singularity and fly out to each target. It ends with a 1-frame outward pop and a small shake. Affected enemies then take the Stunned look, never Time Pearl's pause look.
- **Time Pearl:** a pale frost/tape ripple expands once from the landing point *before* the existing tape-stop, so the effect has a visible cause.

Uses 03's stand-in drawing while effect images are empty.

**Blocked by:** 01 — Status icon row; 03 — Effect plumbing + Blast

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()` timePearl/blackHole/stun/stunThrough, `_apply_marks()`)
- `scenes/components/combat_stage.gd` (`set_slot_frozen()`, freeze tape-stop, backdrop, `spawn_damage_number()`, `shake()`)
- `systems/combat_rounds.gd` (`stage_marks()`: a stunned flag if 01 doesn't already expose it)
- `data/combat_visuals.json` (`effects.blackHole`, `effects.timePearl`, `freezeFx`)
- `tests/test_combat_stage.gd`, `tests/test_combat_rounds.gd`
- REFERENCE.md §3.7b Removal, Items (timePearl, blackHole), Moves (stun)

**Status:** ready-for-agent

- [ ] Stunned head-bob on lost-action fighters; never on frozen ones; clears on time
- [ ] Black Hole: singularity, backdrop pinch, enemy lean/stretch, numbers fly from centre, pop out
- [ ] Time Pearl ripple plays before the tape-stop
- [ ] Rewind restore sets stunned state directly; KO clears instantly; quick pacing halves; reduced motion drops pinch, lean and shake
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: Stun vs Time Pearl vs Black Hole side by side read differently
