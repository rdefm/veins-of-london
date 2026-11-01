# 05 — Monday meeting event + rollover + Act 1 hand-off

**What to build:** the board meeting as a playable scene. Business Empire Act 1's closing enables board meetings; the first Monday on or after that is Week 1. On each rollover into a Monday, after payday and contract renewal, the active goal is judged, then the meeting is queued start-or-defer. The meeting event (James's workshop) runs Minutes cards (last week's result) → Agenda hub (three cards from `agenda(week)` via context options, each with pitcher, pitch, why-this-week, tier numbers, reward preview) → AOB cards → exit. The hub's exit calls `skip()` (Archie picks his own). The meeting spends no time block and needs no travel. Week 1 uses a scripted variant. A debug action jumps straight to a Monday meeting with current state. Prose is placeholder only — prose tickets follow.

**Blocked by:** 02 — Board core + Financial ladder (James); 04 — Events: hub options from a context-supplied list

**Relevant files:**
- `systems/time_system.gd` — Monday rollover steps (⑥.4 / ⑥.4b payday, ⑧h closing)
- `systems/business_quest.gd` — `maybe_trigger_closing()`, closing flags (`bizA1*`)
- `systems/calendar.gd` — `is_monday()`, next-Monday helpers
- `systems/events.gd`, `systems/modal.gd` (defer), new `data/events/board_meeting*.json`
- `systems/board_meetings.gd` — token context builder
- `systems/debug_tools.gd` / `systems/debug_start.gd`
- `tests/test_time_system.gd`, `tests/test_events.gd`, `tests/test_business_quest.gd` (prior art)
- `docs/REFERENCE.md` §3 rollover ordering; `CODEMAP.md`
- Spec: §"Modules" → Meeting event, Rollover, Business quest hand-off

**Status:** ready-for-agent

- [ ] Act 1 closing enables meetings; first Monday on/after = Week 1 scripted meeting
- [ ] Rollover into Monday judges the active goal after payday, then queues the meeting (one integration test)
- [ ] Agenda hub shows three cards with tokens filled plus a skip exit (thin events test)
- [ ] Leaving without choosing → Archie's card active
- [ ] Meeting costs no time block; raids / alarms / wages stay live and unaffected
- [ ] Debug jump to a meeting works
- [ ] On-device check block in report
