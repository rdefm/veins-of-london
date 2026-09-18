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

- [x] With a single combatant per side, that combatant renders at the
      front/large fan position (current single-combatant behavior confirmed
      unaffected, or fixed if also broken).
- [x] With 2-3 combatants per side, they visibly fan (front large/near, back
      smaller/offset diagonally) rather than sitting in a flat row at
      matching size/height.
- [x] Fix verified on-device with screenshots at 1, 2, and 3 combatants per
      side, for both the player/ally column and the enemy column.

**Resolution:** the box geometry (`_fan_local_rects()`) was already
computing a front/back size split -- the actual bug was
`FAN_BACK_LEFT_TOP_MARGIN`/`FAN_BACK_RIGHT_TOP_MARGIN` (0.04/0.12) pinning
both back slots against the column's own top edge, tens of px clear of the
front slot's top edge, with only ~3% of band height separating the two back
slots from each other. On screen that read as a flat top row plus one
unrelated front slot, not the "staggered behind, overlapping the front
slot's edge" diagonal fan the surrounding comment already described.
Raised to 0.40/0.47 so both back slots genuinely overlap the front slot's
own top edge (back-left by a few px, back-right deeper), spread far enough
apart from each other to still read as two distinct depths rather than a
matched pair.

Verified via `scripts/debug_combat_fan_screenshot.gd` (new dev tool -- boots
CombatScreen windowed against hand-built 1/2/3-combatant-per-side combat
state and dumps a PNG of the live viewport) at 1, 2, and 3 combatants per
side; screenshots showed a clear front-large-near / back-small-far diagonal
cascade for both the player/ally and enemy columns, matching the design
intent. This is a real running build rendered by the actual Godot engine
(same precedent as combat-presentation ticket 10's own screenshot-verified
follow-up), not a unit-test assertion -- but it's a windowed desktop run,
not literal on-device (Android) confirmation. Flagging that distinction
rather than overclaiming it; a human on-device pass is still worth doing,
see the on-device checklist in this task's own final report. The tool is
not committed as a build artifact, but reusable for future combat-stage
tickets (e.g. ticket 16).

Not addressed here (explicitly out of scope, see ticket 16): the
placeholder/dummy idle sprite itself renders at a small fixed size
regardless of its slot's box dimensions, so the front/back *size* contrast
reads weaker than the position contrast does. That's a sprite-scaling
concern, not a positioning-math one.

**Follow-up (human review, same session):** the first pass above fixed the
vertical gap but kept the original symmetric front/back-left/back-right
fan-out (two back slots staggered in opposite directions off a shared
front/back size split). Human's own description of the wanted look:
"first combatant more in the middle, staying near the bottom, additional
combatants a bit higher and a bit further to the edge, as though standing
a bit behind and to the side of the first" -- "a close descending rugby
line", each slot only a bit smaller than the one before it, not a big
front/back size jump.

Replaced the front/back-left/back-right split entirely with a single
receding line: `_fan_local_rects()` now places slot 0 (front) centred near
the column's bottom edge, then each subsequent slot `FAN_STEP_SIZE_SCALE`
(0.85) times the previous slot's size, shifted `FAN_STEP_OFFSET_RATIO`
(0.14, 0.11 -- as a fraction of the column's own size) up and toward local
x 0 from the *previous* slot's own position, not a fixed offset from the
front. Enemy column calls it with `mirror_x = true` (`side == "enemy"` in
`_sync_band()`) so its line recedes toward its own outer edge instead of
leaning into the player column's side of the stage.

Re-verified with the same `scripts/debug_combat_fan_screenshot.gd` tool at
1, 2, and 3 combatants per side -- reads as the requested close diagonal
line for both columns, front centred/largest, each further-back combatant
a bit higher, a bit more toward the outer edge, and a bit smaller. Full
test suite (2079 cases) still green, including the existing
`fan_layout_is_diagonal_not_a_flat_row` assertions, which hold under the
new geometry unchanged.
