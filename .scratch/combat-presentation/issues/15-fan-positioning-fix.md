# 15 — Fix combat fan positioning

**What to build:** Combatants are meant to fan out per the existing "near/far
diagonal fan" design (front slot large, back slots smaller and offset —
`scenes/screens/combat.gd`'s `_fan_local_rects()` and related constants), but
in practice (confirmed via screenshot) they render flat, side-by-side, at the
same size, not fanned — and with more than one combatant per side, later
combatants end up positioned too high and too small relative to what the
design intends. Fix the positioning math so the fan actually reads as a fan
on-screen, for both the player+allies column and the enemy column, at 1, 2,
and 3-combatant counts per side.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] With a single combatant per side, that combatant renders at the
      front/large fan position (current single-combatant behavior confirmed
      unaffected, or fixed if also broken).
- [ ] With 2-3 combatants per side, they visibly fan (front large/near, back
      smaller/offset diagonally) rather than sitting in a flat row at
      matching size/height.
- [ ] Fix verified on-device with screenshots at 1, 2, and 3 combatants per
      side, for both the player/ally column and the enemy column.
