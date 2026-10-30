# 09 — Raid event by location: each vein raids as its location's event

**What to build:** Starting a vein raid picks its event from the vein's location type instead of the single hard-coded `vein_raid`. The vein's location already ends in a place suffix ("under the railway arch", "in the car park", …). A data map links each suffix to a raid event id. The same site always gets the same event, so its stored observation reads stay valid and the prose matches the vein sheet. An unmapped suffix, or a mapped event that doesn't exist yet, falls back to `vein_raid`, so with only `vein_raid` live, behaviour is identical to today. Anything that keys off "is this the vein raid event" (raid-factor observation mods, combat prep, site observation memory) recognises every mapped event.

Map (proposal §1.10): car park, bus stop → `vein_raid` (the Yard); railway arch → the Arches (10); off-licence, Tesco Metro, bookies → the Shop (11).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/raiding.gd` (`RAID_EVENT_ID` ~L135), `systems/cultivating.gd` (`LOCATION_SUFFIXES` ~L19, location generator ~L44), `systems/combat_prep.gd` (`KIND_VEIN_RAID`), `systems/observation.gd` (`raid_mods()`, site memory), `data/constants.json` (raid config), `tests/test_raiding.gd`, `tests/test_observation.gd`, `.scratch/raid-events/raid-variants-proposal.md` §1.10, REFERENCE.md §3.12 Vein raiding, §3.9d Observation (Site memory).

**Status:** ready-for-agent

- [ ] Suffix → event map in data; unmapped suffix and missing event fall back to `vein_raid`; existing raid tests pass unchanged
- [ ] Tests: two sites with different suffixes start different events (test fixture events); the same site starts the same event every raid; raid mods and site memory apply to every mapped event
- [ ] REFERENCE.md §3.12 documents the map
- [ ] CODEMAP updated if responsibilities change
