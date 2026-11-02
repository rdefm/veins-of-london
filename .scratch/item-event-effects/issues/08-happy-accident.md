# 08 — Happy Accident (observation + craft bonus)

**What to build:** An active effect. The next prospecting read adds +N to its tier modifiers, and while the effect is active, crafts get +X success chance on top of the Lab's bench bonus (brainstorm §3.1).

**Blocked by:** 01

**Relevant files:** `systems/active_effects.gd`, `systems/observation.gd`, `systems/crafting.gd`, `systems/lab.gd`, `data/constants.json` (activeEffects.items), `tests/test_observation.gd`, `tests/test_crafting.gd`; REFERENCE §3.9d Observation.

**Status:** ready-for-agent

- [ ] Observation bonus is consumed by exactly one read
- [ ] Craft bonus applies only while the effect is active; tier scales both
