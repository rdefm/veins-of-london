# 17 — Pre-fight preparation for every encounter

**What to build:** Every combat entry path — offensive vein and stockpile raids, vein/HQ defences, muggings, tutorial/story/event and debug fights — passes through one pending preparation state before the first turn. Planned raids and defences show preparation before travel/time costs, raid rolls and encounter commitment; pressing Fight commits them, and backing out costs nothing. Forced/scripted encounters may already be committed and offer no cancel. The screen shows participants and their equipped units. Flee remains an in-combat command. Pending preparation survives save/load.

**Blocked by:** 04, 13

**Relevant files:** `systems/combat.gd` (`start_mugging`, `start_home_raid_combat`, `start_home_alarm_defend_combat`, `start_debug_combat`), `systems/raiding.gd`, `systems/home.gd`, `systems/events.gd`, `systems/map_events.gd`, `scenes/phone_apps/alarms_app.gd`, `scenes/components/map_canvas.gd` (stockpile raid pins), `scenes/modals/combat_setup_modal.gd`, new preparation screen under `scenes/`, `autoload/SaveManager.gd`, `autoload/GameState.gd` (screen ids), `tests/test_combat.gd`, `tests/test_raiding.gd`, `tests/test_raid_alarms.gd`, `CODEMAP.md`. Update REFERENCE §2 (screens/state), §3.7 with the change.

**Status:** ready-for-agent

- [ ] Each entry path reaches preparation before the first combat turn (test per path)
- [ ] Planned raid/defence: no time, cost or roll spent until Fight; cancel leaves state unchanged
- [ ] Forced encounters: no cancel route; trigger consequences stand
- [ ] Prep screen lists participants + equipped units
- [ ] Pending prep round-trips save/load
- [ ] PROSE-REVIEW flag for new strings; on-device QA block
