# 04 — Observation engine

**Phase:** MVP

**What to build:** The core `Observation` system, verifiable headless. Events can define `observations`; cards reference one via `observe` (absent = inherit from the previous card in the scene, `null` = clear). Performing a read rolls once per listed ore, lands the best tier or a miss, awards Sense XP, and returns display rows. Authors can gate and boost content with an `observed` condition (current run). The content lint rejects malformed observations.

Schema (from spec):
```
"observations": { "<id>": {
  "mods": [ <mod> ],
  "blocks": { "<ore>": { "tiers": [ { "base": 0.2, "text": "...", "effects": [], "min"?:, "max"?: }, ... ], "miss": "..." } } } }
card: "observe": "<id>" | null
condition: { "observed": { "event"?, "id", "ore", "atLeast": 1..n } }   // `event` form lands in ticket 08
```

Roll rules: tier k lands iff `roll < clamp(tier.base + Σmods, min, max)` (defaults `eventChecks.defaultMin`/`defaultMax`), best landed wins. Σmods here = Sense (`sensePerLevel × (level − 1)`) + the observation's own `mods`. Seed `Rng.stable_unit("rollSeed|eventId|observationId|ore|runKey|rollCount")`; no global RNG. First read rolls; later reads return stored results. Display: shown roll = `100 − roll×100`, needed = `100 − p×100` for the landed or next tier. XP per block rolled + per tier landed. Observing never costs anything or triggers detection. Leave room for future `variants` (not implemented).

**Blocked by:** 02 (runKey), 03 (Sense skill).

**Relevant files:** new `systems/observation.gd`, `systems/events.gd` (`condition_met`, card resolution, `state.event`), `data/constants.json` (`sensePerLevel`, XP amounts — placeholders), new `tests/test_observation.gd` (prior art: synthetic events in `tests/test_events.gd`), `tests/test_event_content_lint.gd`; REFERENCE.md §3.9a, §3.9c, new Observation §; CODEMAP.md; CONTEXT.md (*observation*, *read*, *tier*).

**Status:** ready-for-agent

- [ ] Observation in effect resolves by inheritance; `null` clears; consecutive cards share one observation
- [ ] Unread state reported for the observation in effect
- [ ] Independent per-ore rolls; nested tiers; miss returns miss text
- [ ] Sense + own mods summed per ore, applied to every tier, clamped per tier
- [ ] Same runKey replays; different runKey differs
- [ ] Once per id per run: second read returns stored results, no new rolls/XP
- [ ] Sense XP per block + per tier landed
- [ ] `observed` (no `event`) works in `requires`, `mods`, conditional `goto`
- [ ] Display rows: ore, shown roll, needed, tier landed, tier count, text, hit/miss
- [ ] Observation state is pure data under `state.event` (snapshots/save OK)
- [ ] Lint rejects: unknown ore, tiers not best-first, missing miss, card `observe` id not defined, bad `observed` refs
- [ ] REFERENCE Observation § (schema, roll rules, seeding), CONTEXT terms, CODEMAP row added
