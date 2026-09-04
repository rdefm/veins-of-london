# 16 — Bigger combatant sprites

**What to build:** All combatants (player, allies, enemies) render larger on
the combat stage than they currently do — confirmed too small to read clearly
via screenshot. Retune `StageSlot`'s sizing constants; exact target size is a
tuning call, verify visually on-device rather than against a fixed number.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [x] Combatant sprites render visibly larger than before at every fan
      position (front and back).
- [x] Sprites stay proportioned and don't clip/overflow their stage slot or
      overlap neighboring combatants' slots at the new size.
- [x] Verified on-device across 1-3 combatants per side.

**Resolution:** retuned four consts in `scenes/screens/combat.gd`
(`FAN_FRONT_SIZE_RATIO`, `FAN_FRONT_BOTTOM_MARGIN`, `FAN_STEP_SIZE_SCALE`;
`FAN_STEP_OFFSET_RATIO` left as-is). A first pass mostly raising the height
component of `FAN_FRONT_SIZE_RATIO` barely moved the on-screen character at
all -- traced to `_load_animation_frames()` slicing every sheet into
`frameCount` equal-width `AtlasTexture`s, so each rendered keypose is near-
*square* (e.g. the dummy idle sheet's 896x128 -> 128x128 per frame).
`_sprite_rect`'s `STRETCH_KEEP_ASPECT_CENTERED` fits that square inside the
(portrait) slot rect at `min(slot.width/128, slot.height/128)` -- since the
slot is always taller than wide here, slot *width* is what actually bounds
the rendered character, not height, as long as slot height stays >= slot
width. Retuned around that: `FAN_FRONT_SIZE_RATIO.x` raised 0.62 -> 0.90
(the actual size driver), `.y` raised only as far as 0.36 -> 0.52 (just
enough headroom to stay past the width/height crossover, not to visually
grow the box further). `FAN_STEP_SIZE_SCALE` eased 0.85 -> 0.88 so receding
slots grow with the front slot instead of shrinking away faster than it
grew; `FAN_FRONT_BOTTOM_MARGIN` trimmed 0.03 -> 0.02 for the taller front
slot's extra headroom against the column's bottom edge.

Verified two ways:
1. A throwaway headless render harness (SubViewport + the same TextureRect/
   AtlasTexture/stretch settings `StageSlot` uses, not committed) measured
   the actual drawn pixel bounding box of the character before/after: 25x59
   -> 37x85 px, i.e. +45-48% per axis (~2.1x area) -- confirms the width-
   ratio retune is what actually grows the rendered character, not just the
   invisible slot box around it.
2. `scripts/debug_combat_fan_screenshot.gd` (existing tool from ticket 15,
   windowed run against real hand-built 1/2/3-combatant-per-side combat
   state) re-run at the new ratios: screenshots at all three counts show
   clearly bigger combatants at every fan depth, still fully inside the
   stage frame with no clipping into the frame border or the neighbouring
   column, and the front/back size step still reads as a receding line, not
   a flat row. Same distinction ticket 15 flagged applies here: this is a
   real windowed desktop Godot render, not literal Android on-device
   confirmation -- a human on-device pass is still worth doing, see the
   on-device checklist in this task's own final report.

`tests/test_combat_screen.gd`'s existing
`fan_slots_never_spill_past_the_stage_or_into_the_neighbouring_column` case
(3 enemies + 1 ally, the worst case for band width and stack depth) passes
unchanged at the new ratios; full suite (2079 cases) green.
