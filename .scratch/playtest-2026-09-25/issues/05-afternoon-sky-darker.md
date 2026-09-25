# 05 — Afternoon sky darker in end-of-block animation

**What to build:** In the animation that plays as each time block ends, the afternoon clip's sky gets a darker blue shading into orange, so the day visibly winds towards evening. Other clips unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/daily_cycle.json` (`clips[].sky`), `scenes/components/time_transition.gd` (`_sky_frame`), `docs/ui-vision.md` (Readable day clock section).

**Status:** ready-for-agent

- [ ] Afternoon clip sky colours darker blue → orange
- [ ] Colours live in data, not code
- [ ] Morning/evening/night clips unchanged
- [ ] Transition still blends smoothly into the next clip
