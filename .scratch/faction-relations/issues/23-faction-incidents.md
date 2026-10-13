# 23 — Faction incidents

**What to build:** The simulation produces stories. `data/faction_incidents.json` holds `{ id, trigger, eventId, cooldownDays, conditions }` entries. The daily tick fires these triggers:
- `raidedByFaction` (revenge offer)
- `warBetween` (both sides court the player)
- `truceExpiring`
- `turfFlip` (fallout)

Each queues its authored event (multi-card allowed). The trigger list is extensible so later tickets can add triggers (succession, defection).

**Blocked by:** 01 — Turf core

**Relevant files:** new `data/faction_incidents.json`, new incidents system (or `systems/faction_ai.gd` section), `autoload/GameData.gd`, `systems/time_system.gd` (tick step), `systems/turf.gd` (flip detection), `systems/faction_ai.gd` (war/truce state), `systems/raiding.gd`, `systems/events.gd`, placeholder events, new incidents test. REFERENCE.md new incidents table §, §3.1.

**Status:** ready-for-agent

- [ ] Each of the four triggers queues its event when its conditions hold
- [ ] Cooldowns and conditions respected; state pure + backfilled
- [ ] Adding a trigger is a registered-function + data change, documented
- [ ] Placeholder cards `PROSE-REVIEW`
