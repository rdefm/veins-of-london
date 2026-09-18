# 08 — Apparatus + Train animations

**What to build:** One short animation per apparatus, played while a
craft/experiment roll resolves — burner flares, mortar grinds, press
descends, still drips — replacing the current "Working the bench…" text
state. The Gym's existing Train action (`hq.gd`'s `_build_gym_card()` /
`Combat.train()`, now reached via the room's Gym zone) gets its own
training animation on the same pattern.

**Blocked by:** 07

**Status:** ready-for-agent

- [ ] Each of the four apparatus (burner, mortar, press, still) plays a distinct short animation while its roll resolves
- [ ] "Working the bench…" text state is removed, replaced entirely by the animation
- [ ] Train action plays a training animation on the same manifest-driven pattern
- [ ] Animations use ticket 01's manifest/placeholder mechanism (empty path = no animation, not an error)
