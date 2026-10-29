# 01 — Status glyphs 2x

**What to build:** Every status glyph on the combat stage is drawn at twice its current size, for every combatant (player, allies, enemies). That covers the status-icon row above heads, the guard marker (Guarded/Open), the Open/stun hold pip, and the pause/frozen icon. Only the glyph scales: count digits stay at their current size. Layout should stay sensible, meaning rows don't overlap the sprite head or each other, and the `+N` overflow chip and the hold-to-peek hit areas still line up.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/status_icon_row.gd` (chip/glyph size, `draw_digit()`)
- `scenes/components/combat_stage.gd` (`GUARD_MARKER_SIZE`, `GUARD_MARKER_INSET`, `PAUSE_ICON_BAR`/`GAP`/`TOP`, overlay draw ~1940-1990, guard marker position ~1465, `_icon_row` placement ~267)
- `tests/test_combat_stage.gd`
- `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Status-icon row glyphs/chips are 2x their current size on every combatant
- [ ] Guard marker, Open/stun pip and pause/frozen icon are 2x
- [ ] Count digits are unchanged in size
- [ ] No overlap between the icon row, the pause icon, the guard marker and the sprite; the `+N` chip and peek still work
- [ ] On-device check listed in the report (human visual QA)
