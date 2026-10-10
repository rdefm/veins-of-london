# 06 — Event timing (`at`) and Tuesday calendar start

**What to build:** Events can declare `at: { "block": "morning"|"afternoon"|"evening"|"night", "advance": true|false }`. With `advance`, starting the event moves the world clock forward to that block on the current day — never backwards; if the block has passed, the event runs in the current block (lint flags it, ticket 08). `night` (rollover-time events like the home raid) never moves the clock. The top board updates the moment the block changes. The calendar's start weekday becomes data-configurable so day 1 is a Tuesday and the intro runs in the Evening block; Monday billing still lands first on day 7, and the tutorial's "rest to next morning" flow is unchanged.

Note for the report: moving the start weekday shifts every dated string in existing saves' first week. Acceptable for playtest saves.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`start_event`), `systems/time_system.gd` (blocks, rest, Monday bill, `_apply_tutorial_day_triggers`), `systems/calendar.gd`, `data/constants.json` ("calendar"), `scenes/components/top_bar.gd`, `autoload/GameState.gd` (new-game state), `tests/test_calendar.gd`, `tests/test_events.gd`, `tests/test_home.gd`, ADR 0006 in `docs/adr/`, REFERENCE.md §3.1 "Calendar", `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] `at` advance moves forward only (test); `night` never moves the clock (test).
- [ ] Skipped blocks run the same per-block steps a normal block advance does (staff step etc.); if that's unclear, ask the owner before choosing.
- [ ] Start weekday in data; new game day 1 = Tuesday; intro in Evening; first bill on day 7 (test).
- [ ] Top board refreshes on block change.
- [ ] Old saves load.
- [ ] REFERENCE.md §3.1 updated.
