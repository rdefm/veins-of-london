# 16 — Bigger combatant sprites

**What to build:** All combatants (player, allies, enemies) render larger on
the combat stage than they currently do — confirmed too small to read clearly
via screenshot. Retune `StageSlot`'s sizing constants; exact target size is a
tuning call, verify visually on-device rather than against a fixed number.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Combatant sprites render visibly larger than before at every fan
      position (front and back).
- [ ] Sprites stay proportioned and don't clip/overflow their stage slot or
      overlap neighboring combatants' slots at the new size.
- [ ] Verified on-device across 1-3 combatants per side.
