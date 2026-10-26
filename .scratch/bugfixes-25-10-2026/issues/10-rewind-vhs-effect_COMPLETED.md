# 10 — Rewind: faster reverse and VHS distortion

**What to build:** When the player uses Rewind in combat, the reversed animations play twice as fast as they do now (rewindSpeed 2.5 → 5.0). While the reverse plays, the stage gets a VHS-rewind look that clearly says "time is being rewound": scanlines, horizontal tracking wobble/tear, colour bleed, and a VHS-style "◀◀ REW" label in a corner. The effect starts when the reverse starts and clears cleanly when it ends.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/combat_director.gd` (rewind_speed, play speed), `scenes/components/combat_stage.gd`, `scenes/screens/combat_rounds.gd` (Rewind flow), `data/combat_visuals.json` (pacing.rewindSpeed; effect tuning goes here), new shader file (e.g. under `shaders/` or `assets/`), `CODEMAP.md` if a new file is added.

**Status:** ready-for-agent

- [ ] pacing.rewindSpeed is 5.0
- [ ] The VHS distortion and "◀◀ REW" label show only during the reverse playback
- [ ] The effect is fully gone once the restored state shows
- [ ] Effect parameters live in data
- [ ] Existing rewind tests pass

On-device check: use Rewind mid-fight. The reverse should be clearly faster and unmistakably VHS-rewind.
