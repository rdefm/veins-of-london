# 20 — Warmonger meter

**What to build:** Sustained aggression is tracked and London closes ranks. `state.warmonger = { score, log }` is a rolling sum of the player's violent hostile acts (raids, stockpile raids, ambush fights the player initiated and won) over `warmonger.windowDays`, with per-act weights (TBD). Non-violent moves don't count. Above `coalitionAt`, every faction gains a pressure term against the player, and factions not at war with the player drift friendlier with each other daily. Above `coordinateAt`, factions share intel on the player, and two factions' raid moves on the same day get an odds bonus as a joint raid.

**Blocked by:** 19 — Ambush squads

**Relevant files:** `systems/faction_ai.gd` (pressure, pair relations, raid moves), `systems/raiding.gd`, `systems/intel.gd`, `systems/time_system.gd` (daily decay/roll-off), the ambush outcome from 19, `data/factions.json` config (TBD values), `autoload/SaveManager.gd`, tests: `test_faction_ai`, `test_raiding`, `test_intel`, new warmonger test. REFERENCE.md new Warmonger/aid §, §3.1. CONTEXT.md: Warmonger.

**Status:** ready-for-agent

- [ ] Violent acts are logged with weights; entries older than the window drop off
- [ ] Non-violent moves (18) are not logged; test asserts it
- [ ] `coalitionAt`: pressure term plus pair-relation drift among factions not at war with the player
- [ ] `coordinateAt`: intel sharing and the same-day joint-raid odds bonus
- [ ] Backfill + Rewind safe
