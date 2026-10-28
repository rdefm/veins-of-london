# 02 — Rewind overlay sits below the turn cards

**What to build:** During a combat Rewind, the VHS overlay's two arrows and "REWIND" text are partly covered by the turn-order cards at the top. Move them lower so they're fully visible below the card strip.

**Blocked by:** None — can start immediately.

**Relevant files:** `shaders/vhs_rewind.gdshader`, `scenes/components/combat_stage.gd` (`set_rewind_effect`), `data/combat_visuals.json` (`pacing.rewindEffect`), `scenes/components/turn_order_strip.gd` (strip height/anchor), `scenes/screens/combat_rounds.gd` (layout of stage vs strip).

**Status:** ready-for-agent

- [ ] Arrows + "REWIND" text render below the turn-order strip, not overlapped by any card (incl. a selected/expanded card)
- [ ] Offset is data-driven or derived from strip layout, not a magic number in the shader
- [ ] Rest of the VHS effect unchanged
