# 07 — End-of-block lag: profile and optimise

**What to build:** Ending a time block — especially the final block of the day / rest into rollover — lags on device. Measure each step of block advance, rest and the daily tick headless against a mid/late-game save, find the hotspots, and optimise without changing outcomes (same seed → same state).

**Blocked by:** None — can start immediately

**Relevant files:** `systems/time_system.gd` (`advance_time_block`, `do_rest`, `run_staff_block`, `daily_tick`), `systems/rooms.gd`, `systems/faction_sim.gd`, `systems/faction_ai.gd`, `systems/market.gd`, `systems/shares.gd`, `systems/morning_accounts.gd`, `systems/barometer.gd`, `autoload/GameState.gd` (snapshot cost), EventBus `state_changed` listeners (redundant re-renders), `docs/REFERENCE.md` §3.1

**Status:** ready-for-agent

- [ ] Profiling script + before/after per-step timings in report
- [ ] Hotspots fixed (e.g. repeated full scans, redundant state_changed emits, snapshot duplication, screen rebuilds)
- [ ] Same seed → identical state before/after (test)
- [ ] Full suite passes
