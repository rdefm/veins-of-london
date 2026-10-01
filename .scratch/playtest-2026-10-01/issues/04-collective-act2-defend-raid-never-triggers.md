# 04 — Bug: Collective Act 2 "Defend the vein Nadia's watching" raid never triggers

**What to build:** After `colA2DefendBriefed` is set, the scripted raid alarm on the vein Nadia is watching never fires, so `col_a2_nadia_defend` (type `alarm_defend_wins`) can't complete. Diagnose why (trigger condition, scheduling, vein lookup, alarm dispatch), fix so the raid alarm arrives; defending and winning completes the objective and sets `colA2NadiaDefendDone`.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/collective.gd` (~L426 colA2DefendBriefed handling, Act 2 scripted vein losses), `systems/raid_alarms.gd`, `systems/raiding.gd`, `systems/objectives.gd`, `data/objectives.json` (`col_a2_nadia_defend`), `scenes/phone_apps/alarms_app.gd`, `systems/debug_tools.gd`, REFERENCE.md Collective questline Act 2.

**Status:** ready-for-agent

- [ ] Root cause in commit message
- [ ] Test: from briefed state, advancing time produces the defend alarm; a win completes the objective
- [ ] Existing saves already past the briefing get the raid (or a recovery path)
