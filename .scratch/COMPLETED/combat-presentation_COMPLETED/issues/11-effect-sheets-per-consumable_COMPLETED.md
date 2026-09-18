# 11 — Effect sheets per consumable

**What to build:** Per §5, one signature visual verb per combat item —
identifiable from the corner of the eye, no two alike:

| Item | Effect |
|---|---|
| `timePearl` | Frost ring; enemy desaturates via shader; enemy tweens drop to ~10% speed |
| `enhancementPowder` | Afterimage trail (duplicate sprite on an alpha ramp — no new art) + 2–3 rapid lunges matching the attack count |
| `blast` | Shockwave ring, ~6 frames; on disarm, the weapon sprite spins out of frame |
| `shield` | Shimmer plane, 4-frame loop; cracks and sheds a layer per absorb |
| `blackHole` | Inward warp, ~8 frames — the one expensive effect |
| `healingBurst` | Rising motes, ~5 frames; HP bar refill with overshoot bounce |
| `prophetsBreath` | Handled in ticket 10 (needs real next-pose art to ghost) |
| `wormhole` | Player folds to a vertical line and vanishes; parting-shot beat never plays |
| `rewind`/`failsafe` | Free — the beat queue (ticket 04) plays backward, no new art |

Each effect fires from the corresponding `Combat.use_*()`/`cast_complication()`
call's beat (ticket 04) instead of the current plain log line, keyed through
`data/combat_visuals.json`'s effect-sheet section.

**Blocked by:** 04 (beats to attach effects to), 07 (palette/pipeline)

**Assets needed:** **7 effect sheets** at 96×96 native (`timePearl`,
`blast`, `shield`, `healingBurst`, and the shockwave/frost/shimmer/mote
frame counts in the table above) plus **1 large effect sheet at 160×160**
(`blackHole`, ~8 frames). `enhancementPowder`, `wormhole`, and `rewind`/
`failsafe` need no new art per the table (afterimage is a duplicate-sprite
alpha ramp, the fold/reverse effects are transform-only).

**Status:** ready-for-agent

- [ ] `timePearl`, `blast`, `shield`, `healingBurst`, `blackHole` each play
      their signature effect sheet from the table above when used, replacing
      today's plain log-line-only feedback
- [ ] `enhancementPowder` shows the afterimage trail (alpha-ramped duplicate
      sprite, no new art) synced to its 2–3 rapid attack beats
- [ ] `wormhole` plays the fold-and-vanish transform and the parting-shot
      beat is confirmed skipped (matches existing `use_wormhole()` logic
      bypassing `flee()`'s failed-flee attack)
- [ ] `rewind`/`failsafe` play the beat queue backward with no new asset
- [ ] Every effect is identifiable from a quick glance — no two items share
      a silhouette/motion shape
- [ ] `blackHole`'s AoE (`Combat._apply_black_hole_aoe`, hits every non-koed
      enemy) plays its effect once per hit enemy, not once for the whole
      screen
