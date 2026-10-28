# 07 — Panic + Pan's Rapture

**What to build:** The two emotion control items read as opposites, Panic fast and small, Rapture slow and wide (proposal §3.9, §3.10):

- **Launch (both):** `throw`; a vial travels (ticket 03 travel cue), magenta for Panic and rose-gold for Rapture.
- **Panic land:** a rose-pink flinch ring and a recoil without the white flash. **Linger:** a 1-px jitter at ~12Hz on the sprite, slightly desaturated. **`cower` beat:** the sprite squashes down ~15% and shudders for the beat. **`bolt` beat:** ticket 02's run-off exit.
- **Rapture land:** a soft bloom, and the idle drops to half speed. **Linger:** a slow sway (±2° around the feet, ~1.5s sine) with a ~25% warm pink tint. **`enraptured` beat:** the sway holds at peak lean and a pink motes puff rises.
- Lingers end when the status ends (the icon from 01 already counts down).

**Blocked by:** 01 — Status icon row; 02 — Run-off exit; 03 — Effect plumbing + Blast

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()` panic/rapture/cower/enraptured/bolt; `_OVERLAY_KINDS`)
- `scenes/components/combat_stage.gd` (sprite shader/modulate, idle fps)
- `systems/combat_rounds.gd` (`stage_marks()` flags if needed)
- `data/combat_visuals.json`
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Table 4 (panic, pansRapture)

**Status:** ready-for-agent

- [ ] Vial launch for both; distinct land effects
- [ ] Panic jitter and desaturation; cower beat; bolt uses the run-off
- [ ] Rapture sway, tint, slowed idle; enraptured beat
- [ ] Multi units apply per target; Rewind restore sets lingers directly; KO clears instantly
- [ ] Data-driven; quick pacing halves; reduced motion drops jitter and sway, keeps the tint and icons
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: a Panic fight with a cower and a bolt; a Rapture fight
