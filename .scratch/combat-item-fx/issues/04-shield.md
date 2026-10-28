# 04 — Shield

**What to build:** A Shield's life is readable without numbers (proposal §3.2):

- **Land:** hex panels assemble bottom-up across the sprite (self `shield`, or toward an ally `shieldOther` using ticket 03's travel cue).
- **Linger:** the shimmer loop's opacity/density scales with the pool remaining. It's full at a fresh pool and sparse, flickering panels near empty.
- **Absorb** (a hit with `absorbed` > 0): keep the crack flash, plus 1–2 panels fall off and fade downward.
- **Break** (pool → 0): remaining panels burst outward, then the guard marker settles on the real guard state.

Uses the stand-in drawing from 03 while the shield image is empty.

**Blocked by:** 03 — Effect plumbing + Blast

**Relevant files:**
- `scenes/components/combat_stage.gd` (`set_slot_shield()`, `StageSlot.set_shield_loop()`, `flash_shield_crack()`)
- `scenes/screens/combat_rounds.gd` (`beat_cues()` shield/shieldOther/shieldCrack, `_apply_marks()` `shielded`)
- `systems/combat_rounds.gd` (`stage_marks()`: add pool fraction as pure data if needed)
- `data/combat_visuals.json` (`effects.shield`)
- `tests/test_combat_stage.gd`, `tests/test_combat_rounds.gd`
- REFERENCE.md §3.7b Damage (shield pool), Items (shield)

**Status:** ready-for-agent

- [ ] Assemble on apply; travel to an ally for `shieldOther`
- [ ] Shimmer scales with the pool fraction
- [ ] Panels shed on absorb; burst on break; the guard marker then shows the real state
- [ ] Rewind restore sets the shimmer at the right density with no assemble/break animation; KO clears instantly
- [ ] Data-driven durations; quick pacing halves; reduced motion keeps the shimmer and drops the burst
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: a full shield wearing down over several hits, then breaking
