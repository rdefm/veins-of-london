# 23 — Defuse ladder + weather-or-soften + Act 2 debrief

**What to build:** the **Defuse** ladder, a second framing of the overlap detector: spot a coming clash with a faction and ask the player to get ahead of it. Also the unordered Act 2 weather-or-soften beat (weather: keep guards paid, lose no vein for N days; or soften: spend on a relation action with the rival) and the closing debrief event, which fires when all Act 2 beats are done and marks Act 2 complete while meetings carry on.

**Blocked by:** 21 — Partner ladder + overlap detector + rival-move / Partner beats

**Relevant files:**
- `systems/guard_upkeep.gd`, `systems/raiding.gd`, `systems/diplomacy.gd`, `systems/faction_ai.gd`
- `systems/objectives.gd`, `systems/board_meetings.gd`, `data/board.json`, new debrief event data
- `systems/todo.gd` (Act 2 complete)
- Spec: stories 57–58, 65, 67–69, §"Act 2 spine rules"

**Status:** needs-triage

- [ ] Weather and soften each complete the beat (tests)
- [ ] Unordered beats complete in any order; debrief fires when all done; Act 2 marked complete
- [ ] Meetings continue after Act 2
