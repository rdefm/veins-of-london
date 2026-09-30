# 06 — Guard shortfall: grace day and auto-drop

**What to build:** When a Monday guard bill is short (pre-pot from 03, or pot era from 05), the game records a single pending guard shortfall and gives the player one grace day before guards walk.

- **The shortfall record holds:**
  - the payday day
  - the grace deadline: the next rollover (`graceDays` 1)
  - each place's guard count
  - the reserve: £ set aside from pot and float, or 0 before the pot exists
- **During grace**, all its guards stay on duty and still count for raid resist and guard repel.
- **Auto-resolve.** If the player hasn't resolved it by the grace rollover, it resolves early in that rollover:
  - Guards are kept in priority order (the reverse of the drop order), funded only by the reserve (pot era) or player cash (pre-pot). Each kept guard is paid `weeklyWage`.
  - Unfunded guards walk.
  - Drop order: extra guards on the least valuable vein first (shared value order), then tier guards least valuable first (`guarded` → `warded`), then HQ guards last.
  - Leftover reserve goes to the float (pot era) or player cash (pre-pot).
- **Notices:**
  - The morning account and notification warn of the shortfall, naming the places at risk and the deadline.
  - Walk-offs produce a notice naming each place that lost guards.
- Only one shortfall is ever pending.

**Blocked by:** 05 — Monday guard bill inside payday.

**Relevant files:**
- `systems/guard_upkeep.gd`, `systems/time_system.gd` (early rollover step), `systems/business.gd`
- `systems/cultivating.gd` / shared drop + value-order helpers from 01, `systems/home.gd`
- `systems/raiding.gd` (`_guards_repel_defend_raid`), `systems/home.gd` (`_guards_repel_pending_raid`) — check guards still count during grace
- `systems/morning_accounts.gd`, `systems/notify.gd`
- `autoload/GameState.gd`, `autoload/SaveManager.gd` (backfill `guardUpkeep.pendingShortfall` = null)
- `tests/test_guard_upkeep.gd`, `tests/test_time_system.gd`, `tests/test_raiding.gd`, `tests/test_savemanager.gd`
- Spec §Short-pay flow (State, Grace, Auto-resolve); REFERENCE.md §2, §3.1

**Status:** ready-for-agent

- [x] A short Monday (pre-pot and pot era) creates the pending shortfall with the right counts, deadline and reserve
- [x] Guards defend normally during grace (raid resist and repel unchanged)
- [x] An ignored shortfall drops extras from the least valuable vein first, then tier guards (`guarded` → `warded`), then HQ guards; lock and ward stay
- [x] Kept guards are paid from the reserve (pot era) or cash (pre-pot); leftover reserve goes to the float or cash
- [x] The shortfall clears after auto-resolve; there are never two pending
- [x] Shortfall warning and walk-off notices (PROSE-REVIEW)
- [x] `pendingShortfall` is backfilled null, survives save/load, and Rewind restores it exactly
- [x] REFERENCE §2 and §3.1 updated; CODEMAP updated
