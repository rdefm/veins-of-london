# 03 — Per-block staff step

**What to build:** All staffed cultivators and producers act at the end of every player time block (Morning, Afternoon, Evening), whether staffed via a room or a founder role. Resting runs the skipped blocks first, so a day always yields 3 actions per worker. Cultivators tend the assigned vein furthest outside its band; producers make one craft attempt per block. The once-daily Vein Station and Lab passes go away; the rollover staff phase keeps only Sales partial deliveries, settlements/renewals, the payday hook point, and offer sourcing. The Morning Brief summarises the previous day's block actions.

**Blocked by:** 02 — Per-cultivator vein lists

**Relevant files:** `systems/time_system.gd` (`advance_time_block`, `do_rest`, `daily_tick`), `systems/rooms.gd` (`process_lab`, `process_vein_station`, `_production_order`, `effective_lab_target`), `systems/contacts.gd` (`award_contact_xp`), `systems/morning_accounts.gd` (`capture_lab`, `capture_vein_station`), `systems/cultivating.gd`, `systems/crafting.gd`, `data/constants.json`, `tests/test_time_system.gd`, `tests/test_rooms.gd`, `tests/test_morning_accounts.gd`; REFERENCE.md §3.10 Contacts, rooms, jobs; spec §"One staff system, per time block".

**Status:** ready-for-agent

- [ ] `advance_time_block()` runs the staff step for the block that just ended, before any rollover
- [ ] `do_rest()` runs the staff step once per block still remaining that day, then rolls over (always 3 actions/day)
- [ ] Order within a block: cultivators, then producers, then Sales' instant-delivery re-check (`shared_stock_increased` path)
- [ ] A worker acts only if their wage is paid (an `unpaid` query ticket 04 fills in; defaults to paid)
- [ ] Cultivator: takes the vein furthest outside target ±5; above → prune to target, yield to shared stock; below → one cultivate roll at worker skill; all in band → idle; ties by assignment order
- [ ] Cultivator XP 2 per action (prune or cultivate, success or fail), a data value, replacing 15/20/8
- [ ] Producer: one attempt per block toward effective Production targets (contract-card order, then target order), worker's crafting skill, shared-stock ore only, existing XP (full or ⅓); idle if nothing below target or ore short
- [ ] Rollover no longer runs station/lab passes; Morning Brief aggregates the previous day's block actions
- [ ] Pure checks: vein pick (furthest, ties, idle). Scenario: one cultivator with more veins than it can keep in band falls behind
- [ ] REFERENCE.md §3.10 and CODEMAP.md updated
