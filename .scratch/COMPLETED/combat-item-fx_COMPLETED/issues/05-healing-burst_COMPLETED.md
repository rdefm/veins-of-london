# 05 — Healing Burst

**What to build:** Healing reads as healing (proposal §3.5):

- **Launch:** `throw` to an ally (`heal`) or `cast` on self (`healSelf`); the ally throw uses ticket 03's travel cue.
- **Land:** gold-and-cyan motes rise from the feet (time+life colours), plus a soft gold rim pulse on the sprite (one sine, ~300ms).
- **Number:** a green `+N` rises from the healed fighter (damage-number spawner gains a colour/sign option).
- **Fizzle** (heal aimed at a KO'd ally): the motes rise, then fall and scatter grey.

The strip's HP bar refill bounce is out of scope unless it's trivial.

**Blocked by:** 03 — Effect plumbing + Blast

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()` heal/healSelf, `_move_pose_cues()` fizzled item)
- `scenes/components/combat_stage.gd` (`spawn_damage_number()`, `play_effect()`, `play_cast()`)
- `data/combat_visuals.json` (`effects.healingBurst`)
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Items (healingBurst), Removal (heal at KO'd ally fizzles)

**Status:** ready-for-agent

- [ ] Heal and self-heal play motes + rim pulse; ally heal travels
- [ ] Green `+N` number with the healed amount
- [ ] Fizzle plays the grey scatter
- [ ] Rewind shows no number; quick pacing halves; reduced motion keeps motes and number
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: self heal, ally heal, a fizzled heal
