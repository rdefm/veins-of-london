# 11 — Failsafe + Wormhole polish

**What to build:** The last-ditch saves and the escape item get their moment (proposal §3.13, §3.14). Failsafe stays invisible until it fires — no equipped icon.

- **Player Failsafe** (lethal hit): the killing hit lands, freeze-frame ~200ms, the player sprite goes to a white silhouette, then a short fast local rewind (VHS look at 2× rewind speed, vignetted around the player only, ~400ms) into the restored snapshot. A small ⚑ pops above the player and falls away to show the unit was spent.
- **Ally's own Failsafe** (kept on 1 hp): the same silhouette beat with no rewind; the sprite staggers, the flag pops, and the HP bar lands on a hair.
- **Guard-kit rewind** (an ally spends a `rewind` to save the player): the ally's sprite glows cyan briefly, then the normal full-stage Rewind plays.
- **Wormhole:** keep the fold-to-a-line vanish; add a 1-frame cyan-orange lens tear at the vanish point and a ~300ms hold on the empty slot before the outcome card.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()` failsafe/wormhole; Rewind playback of undone beats)
- `scenes/components/combat_stage.gd` (`set_rewind_effect()`, `vhs_rewind.gdshader` usage, `play_wormhole_vanish()`)
- `scenes/components/combat_director.gd` (`pacing.rewindSpeed`)
- `systems/combat_rounds.gd` (failsafe / guard-kit rewind beats: confirm which beat kinds each emits)
- `data/combat_visuals.json`
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Rewind (Failsafe, Guard-kit rewind), Table 4 (wormhole, failsafe)

**Status:** ready-for-agent

- [ ] Player Failsafe: freeze, silhouette, local rewind, flag pop
- [ ] Ally Failsafe: silhouette, stagger, flag, 1-hp bar
- [ ] Guard-kit rewind: ally glow before the full Rewind
- [ ] Wormhole lens tear and empty-slot hold
- [ ] No Failsafe cue while merely equipped
- [ ] Quick pacing halves; reduced motion drops the local VHS and tear, keeps silhouette and flag
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: each of the three saves, a Wormhole escape
