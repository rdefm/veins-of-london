# 14 — Harassment rung core

**What to build:** Hostile factions wear the player down before they raid. A new escalation rung `harass` sits between warning and market lines, set by a per-faction `harassAboveRaid` offset (TBD). `menus` gains `harass: [harassmentId]` per faction. A harassment entry is `{ id, factionId, eventId, cost, target: vein|player, requires }`. Picking one queues its authored event, targeting a player vein in that faction's turf (control or foothold); with no eligible vein the move is skipped. Persistent effects live in `state.harassment.active = [{ id, factionId, veinId?, kind, params, sinceDay, untilDay?, escalation }]`, and ignored effects escalate over time (TBD). The Collective and Guild raid/conquer thresholds drop much lower (TBD, ~−60/−50), and their offset lines move with them. The district panel lists active harassment and penalties affecting the player there. This ticket also settles the exact event-action list that 15 and 16 implement and documents it in REFERENCE.

**Blocked by:** 01 — Turf core; 06 — District panel Turf section

**Relevant files:** `systems/faction_ai.gd` (escalation rungs, cooldown, warn-first, one-move-per-target), `data/factions.json` (`factionEscalation`, `menus`, thresholds), new harassment data (in factions.json or a new `data/faction_harassment.json`), `systems/events.gd` (queueing), `autoload/GameData.gd`, `autoload/SaveManager.gd` (backfill `harassment`), the turf panel decision layer, one placeholder event in `data/events/`, tests: `test_faction_ai`, new `test_harassment`. REFERENCE.md §1.8, §1.11, new Harassment §, §3.9a. CONTEXT.md: Harassment.

**Status:** ready-for-agent

- [ ] `harass` rung fires between warning and market lines; respects cooldown, warn-first, one-move-per-target
- [ ] Target is a player vein in the faction's turf; with no eligible vein the move is skipped
- [ ] `state.harassment.active` exists, is pure data, is backfilled on load, and survives Rewind
- [ ] Ignored effects escalate per the data-defined cadence
- [ ] Collective/Guild thresholds lowered (marked TBD)
- [ ] Panel shows active harassment rows for the district
- [ ] Action list settled and written into REFERENCE; one `PROSE-REVIEW` placeholder card
