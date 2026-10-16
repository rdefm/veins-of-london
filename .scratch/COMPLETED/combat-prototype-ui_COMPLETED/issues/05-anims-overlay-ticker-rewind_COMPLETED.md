# 05 — Move/item anims, guard overlay, ticker, pacing, rewind playback

**What to build:** Every prototype beat reads on the stage using existing art only, plus the live combat niceties.

- Guard overlay on sprites: a shield marker while Guarded (including a Shield-item hold), an Open/Exposed marker otherwise. Updates as beats play.
- Beat → animation mapping (reuse only, no new art):
  - strike, stun → attack pose (already in 03); crit = bigger juice
  - feint → attack pose + afterimage, no damage number
  - guard, lure → no pose; overlay change only
  - leg it → wormhole-vanish exit; failed flee → recoil
  - item use → throw pose + the existing effect sheet (timePearl, blast, shield, healingBurst, blackHole); Time Pearl/Black Hole play on every affected enemy
  - enhancementPowder, prophetsBreath, beALady → cast pose
  - chip hits → smaller damage number/shake; shield absorb → shield crack
  - frozen enemies use the live frozen visual
- Beat lines push to the top-bar notification ticker during playback, as live combat does.
- The normal/quick pacing toggle is shown and works, as live.
- Rewind plays the undone beats in reverse (live rewind playback), then returns to the previous pick.

**Blocked by:** 03. (Independent of 04; if 04 is done, the strip also reverses during rewind playback.)

**Relevant files:** `scenes/components/combat_stage.gd` (`StageSlot`: `play_attack`, `spawn_afterimage`, `play_throw`, `play_cast`, `play_wormhole_vanish`, `flash_shield_crack`, `set_frozen_visual`, `set_shield_loop`, `play_effect`), `scenes/screens/combat.gd` (`_on_beat_played`, `_on_combat_rewind_played`, `_play_juice`, `_pacing_button_label`), `systems/combat_pacing.gd`, `scenes/components/top_bar.gd`, `scenes/components/notification_ticker.gd`, `scenes/screens/combat_prototype.gd`, `data/combat_prototype.json` (beat kinds), `data/combat_visuals.json` (`effects`).

**Status:** ready-for-agent

- [ ] Screen test: each prototype beat kind maps to its stage call (spy or recorded calls), none unmapped.
- [ ] Screen test: ticker receives beat lines during playback.
- [ ] Rewind plays back and lands at the previous pick with the correct state.
- [ ] Pacing toggle persists via the existing pacing system.
- [ ] On-device QA list in the report (each move/item animation, overlay markers, rewind playback).
