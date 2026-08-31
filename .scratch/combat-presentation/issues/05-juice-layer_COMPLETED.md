# 05 — Juice layer

**What to build:** The §4.1 juice layer, playing per-beat against the
beat-queue director from ticket 04. Style-independent, no art required —
this is the highest feel-per-line item in the whole vision doc and works
identically well against placeholder boxes or final sprites:

- Hit-stop, 60–90ms on a landed hit (a brief pause in beat playback)
- Damage numbers rising and fading from the struck combatant's fan/strip
  position
- Screen shake, 3–6px, scaled to damage as a fraction of the target's
  `hpMax`
- HP bar lag-drain — a ghost bar on the turn-order strip's HP bar chasing
  the real (already-updated) value down
- Flash-to-white on the struck placeholder/sprite (a `CanvasItem` material
  flash, not new art)

Each effect keys off the `beats` array ticket 04 introduced (a `dmg` field
present, target identified by type+index) — no new state shape needed.

**Blocked by:** 04 (needs the beat queue to attach juice to individual
beats; without it there's no per-turn timeline to hang a hit-stop or damage
number on)

**Assets needed:** none — shader/tween/Label work only, all placeholder-art
compatible.

**Status:** ready-for-agent

- [ ] A landed hit (player, ally, or enemy attack beat with `dmg > 0`)
      triggers a 60–90ms hit-stop pausing beat playback briefly
- [ ] A damage number rises and fades from the struck combatant's on-stage
      position for every damaging beat (attack, Blast, Black Hole per-enemy
      hit)
- [ ] Screen shake magnitude scales with `dmg / target_hpMax`, capped at
      3–6px
- [ ] The turn-order strip's HP bar shows a lagging "ghost" bar draining
      down to the real value after each hit, not an instant jump
- [ ] The struck combatant's placeholder flashes white briefly on hit
- [ ] All five effects work identically against ticket 01's placeholder
      boxes and (once landed) ticket 09/10's real sprites — no juice-layer
      code assumes real art exists
