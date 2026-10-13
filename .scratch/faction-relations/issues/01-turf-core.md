# 01 — Turf core

**What to build:** Each district gets a live controller worked out from who holds the most veins there: the five factions plus the player. The top contender controls the district when its count is at least second place + `controlMargin` (2). Otherwise the district is Contested. Any non-controller holding at least `footholdShare` (TBD, ~25%) of the district's claimed veins has a Foothold. The result is recomputed once per daily tick, after claims, raids, rivalry and transfers resolve, and stored as `state.turf = { districtId: { controller, shares, tiers } }`. A flip (detected against the previous stored value) queues a Ticker headline and a map event. Existing saves get turf computed on load. A new game seeds turf from the heritage `factionPresence`.

**Blocked by:** None — can start immediately

**Relevant files:** new `systems/turf.gd`, `systems/time_system.gd` (`daily_tick`, new step after ⑤d), `autoload/SaveManager.gd`, `autoload/GameState.gd`, `systems/map_events.gd`, `systems/barometer.gd` (`push_headline`), `data/constants.json` (or a new turf config block), `data/districts.json`; new `tests/test_turf.gd`. REFERENCE.md §3.1 (daily tick order) plus a new Turf §. CONTEXT.md: Turf, Control, Foothold, Contested. Spec: `.scratch/faction-relations/spec.md` "Turf (new system)".

**Status:** ready-for-agent

- [ ] Pure queries: per-district contender counts and shares, controller, tier for a contender (`control`/`foothold`/`none`), contested status
- [ ] Faction count = faction veins on sites in the district; player count = player veins in the district
- [ ] Control-margin and foothold rules hold, with `controlMargin` and `footholdShare` in data (footholdShare marked TBD in REFERENCE)
- [ ] `state.turf` is recomputed once per daily tick at the documented step; within a day the value is stable
- [ ] A flip queues a Ticker headline and a map event; no flip, no headline
- [ ] Save backfill computes turf on load; save/load/Rewind round-trip keeps `state.turf` pure data
- [ ] REFERENCE (new Turf §, §3.1 step), CONTEXT terms and CODEMAP row added
