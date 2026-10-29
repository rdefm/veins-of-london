# 01 — Remove the passive `observeBonus` hook

**What to build:** Holding an item no longer boosts observation rolls. The raid-events spec rules out passive holding bonuses: item bonuses come only from a toggled, consumed item. No item data uses `observeBonus` today, so the hook is dormant; remove it and its test fixture. Observation-driven bonuses (Sense, Mind perk, observation `mods`, seated attunement, Be A Lady, Prophet's Breath, raid-factor mods) are unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/observation.gd` (`_mods()`, the `observeBonus` loop and its comment), `tests/test_observation.gd` (the `obs_charm` fixture), `docs/REFERENCE.md` §3.9d Observation (drop any `observeBonus` mention), `.scratch/COMPLETED/observation_COMPLETED/raid-events-spec.md`.

**Status:** ready-for-agent

- [ ] `observeBonus` appears nowhere in code, data, tests or REFERENCE.md
- [ ] Observation breakdown still lists every remaining mod source; `tests/test_observation.gd` passes
- [ ] Syntax check clean on touched files
