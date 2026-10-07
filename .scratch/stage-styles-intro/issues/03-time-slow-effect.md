# 03 — Time-slow effect (thrown vial → syrupy field → slow motion)

**What to build:** The intro's card 5 beat as stage direction: Archie flicks a small vial that arcs through the air and lands on the floor between the buyers, shatters with a brief burst, and the air around them "goes thick and syrupy": a visible distortion field (shimmer/ripple, tinted) grows over a set radius and stays. Actors inside the field drop to slow motion — their idle, blink, talk and walking (including in-progress moves) run at a reduced time scale — "not stop, but slow, like a video buffering". Actors outside the field (Archie walking off) keep normal speed. The field and the slowed state persist into later staged cards (folded into snapshots). Reduced motion: no animation; the field shows as a static tint and slowed actors hold still.

**Blocked by:** 02 — Stage movement and cast steps (slowed walking needs moves).

**Relevant files:** `scenes/stage/stage_player.gd` (existing `throw`/`drop` effects, lights/additive blend, shared clock `advance`), `scenes/stage/stage_actor.gd` (`step()` timing, behaviour), `scenes/stage/stage_direction.gd`, `tests/test_stage.gd`, `.scratch/stage-engine/ENGINE.md`; prose of the beat in `data/events/intro.json` (card 5)

**Status:** ready-for-agent

- [ ] A throw can target a floor point (not only a set object), ending in a shatter burst
- [ ] A slow-field step creates a persistent field at a position/radius; actors inside get a per-actor time scale, outside actors unaffected (tested via actor clock advancement)
- [ ] Field + slowed actors fold into snapshots, so jumping straight to a later card shows the field and slowed state
- [ ] Reduced-motion path shows the static-tint version with no motion
- [ ] Visual check via a windowed screenshot harness frame showing the field
- [ ] ENGINE.md updated
