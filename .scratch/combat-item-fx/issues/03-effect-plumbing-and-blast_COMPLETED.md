# 03 — Effect plumbing + Blast

**What to build:** A Blast reads as a Blast. This also lays the shared plumbing the other item tickets reuse:

- A **travel** cue: a projectile (tinted pixel spark with a short trail) arcs from the actor to the target before the land effect plays. Colour and duration come from data.
- A **stand-in land effect**: when an effect's `image` in `combat_visuals.json` is empty (all of them today), the stage draws a code-drawn placeholder in the effect's colour (e.g. an expanding ring) instead of nothing. Real sheets drop in later with no code change.
- Per-effect data in `combat_visuals.json` `effects`: colour, travel duration, land duration, shake scale.

Blast itself (proposal §3.1): a harder throw, orange spark travel, a 6-frame shockwave ring, white flash, a 2-frame hit-stop and crit-scale shake (it ignores guard). The target's guard marker flickers once to show it was ignored, not broken. On a `disarm` beat, a small generic weapon shape spins up and out of frame (~400ms, 720°). After a Blast, the actor's Leg it boost shows as an orange streak at its feet when the boosted Leg it runs (works with or without ticket 02's run-off).

Design: `.scratch/combat-item-fx/proposal.md` §1 (ore colours: physics = sodium orange), §3.1.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`_ITEM_EFFECTS`, `beat_cues()`, `_play_cue()`; `disarm` is in `_OVERLAY_KINDS` today)
- `scenes/components/combat_stage.gd` (`play_effect()`, `StageSlot.play_effect_sheet()`, `play_throw()`, `shake()`, guard marker)
- `scenes/components/combat_director.gd` (`beat_is_damaging()`, pacing)
- `data/combat_visuals.json` (`effects`)
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Items (blast), Table 4 (disarm)

**Status:** ready-for-agent

- [ ] Travel cue exists and is used by Blast; data-driven colour/duration
- [ ] An empty effect `image` draws the stand-in instead of nothing, for all five existing effects
- [ ] Blast: landing ring, flash, hit-stop, crit-scale shake, guard-marker flicker
- [ ] Disarm beat spins a weapon shape off stage
- [ ] Leg it boost streak shows on the boosted Leg it
- [ ] Rewind plays cleanly (no damage numbers, no stuck effects); quick pacing halves; reduced motion drops shake and hit-stop
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: Blast on Guarded and Open targets, a disarm, a boosted Leg it
